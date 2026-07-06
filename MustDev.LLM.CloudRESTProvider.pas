unit MustDev.LLM.CloudRESTProvider;

{$CODEPAGE 65001}

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Cloud REST LLM Provider                                           }
{  Description: Connecteur pour API distantes (OpenAI, Gemini, Claude...).   }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.Classes, System.SysUtils, System.JSON,
  REST.Types, REST.Client,
  MustDev.LLM.Interfaces, MustDev.LLM.BaseProvider;

type
  TCloudRESTLLMProvider = class(TBaseLLMProvider)
  private
    FCloudType: Integer; // 0=OpenAI/Standard, 1=Gemini, 2=Claude
  protected
    function GetProviderType: TProviderType; override;
  public
    procedure SetCloudType(ACloudType: Integer);
    function Ask(const APrompt: string; AKeepHistory: Boolean = False): string; override;
  end;

implementation

{ TCloudRESTLLMProvider }

procedure TCloudRESTLLMProvider.SetCloudType(ACloudType: Integer);
begin
  FCloudType := ACloudType;
end;

function TCloudRESTLLMProvider.GetProviderType: TProviderType;
begin
  Result := ptCloudREST;
end;

function TCloudRESTLLMProvider.Ask(const APrompt: string; AKeepHistory: Boolean = False): string;
var
  RestClient: TRESTClient;
  RestRequest: TRESTRequest;
  RestResponse: TRESTResponse;
  JSONPayload: TJSONObject;
  MessagesArray, PartsArray: TJSONArray;
  MessageObj, PartObj, RespJSON: TJSONObject;
  Msg: TLLMMessage;
  TargetURL, CleanApiKey: string;
  KeyPos: Integer;
begin
  Result := '';
  TargetURL := FEndpoint;
  CleanApiKey := FApiKey;
  
  // Nettoyage de l'URL si la clé API y est déjà intégrée (ex: copier/coller depuis la doc Gemini)
  KeyPos := Pos('?key=', TargetURL);
  if KeyPos = 0 then KeyPos := Pos('&key=', TargetURL);
  if KeyPos > 0 then
  begin
    if CleanApiKey = '' then
      CleanApiKey := Copy(TargetURL, KeyPos + 5, Length(TargetURL));
    TargetURL := Copy(TargetURL, 1, KeyPos - 1);
  end;

  // Remplacement dynamique du modèle dans l'URL pour Google Gemini
  if (FCloudType = 1) and (FModel <> '') and (Pos('/models/', TargetURL) > 0) then
  begin
    var StartPos := Pos('/models/', TargetURL) + 8;
    var EndPos := Pos(':generateContent', TargetURL);
    if EndPos > StartPos then
    begin
      var OldModel := Copy(TargetURL, StartPos, EndPos - StartPos);
      TargetURL := StringReplace(TargetURL, '/models/' + OldModel, '/models/' + FModel, [rfIgnoreCase]);
    end;
  end;

  RestClient := TRESTClient.Create(TargetURL);
  RestRequest := TRESTRequest.Create(nil);
  RestResponse := TRESTResponse.Create(nil);
  JSONPayload := TJSONObject.Create;
  try
    RestRequest.Client := RestClient;
    RestRequest.Response := RestResponse;
    RestRequest.Method := rmPOST;
    
    // Configuration des paramètres selon le fournisseur d'IA
    if FCloudType = 1 then // Gemini (Google)
    begin
      MessagesArray := TJSONArray.Create;
      
      // Injection de l'historique
      if AKeepHistory then
      begin
        for Msg in FHistory do
        begin
          MessageObj := TJSONObject.Create;
          PartsArray := TJSONArray.Create;
          PartObj := TJSONObject.Create;
          PartObj.AddPair('text', Msg.Content);
          PartsArray.AddElement(PartObj);
          
          var GemRole := Msg.Role;
          if GemRole = 'assistant' then GemRole := 'model';
          
          MessageObj.AddPair('role', GemRole);
          MessageObj.AddPair('parts', PartsArray);
          MessagesArray.AddElement(MessageObj);
        end;
      end;
      
      // Message courant
      MessageObj := TJSONObject.Create;
      PartsArray := TJSONArray.Create;
      PartObj := TJSONObject.Create;
      PartObj.AddPair('text', APrompt);
      PartsArray.AddElement(PartObj);
      MessageObj.AddPair('role', 'user');
      MessageObj.AddPair('parts', PartsArray);
      MessagesArray.AddElement(MessageObj);
      
      JSONPayload.AddPair('contents', MessagesArray);
      
      // L'API Key de Gemini doit être passée en paramètre pkQUERY pour éviter les erreurs de format d'URL
      if CleanApiKey <> '' then
      begin
        var Param := RestRequest.Params.AddItem;
        Param.Name := 'key';
        Param.Value := CleanApiKey;
        Param.Kind := pkQUERY;
      end;
    end
    else if FCloudType = 2 then // Claude (Anthropic)
    begin
      JSONPayload.AddPair('model', FModel);
      JSONPayload.AddPair('max_tokens', TJSONNumber.Create(4096));
      
      MessagesArray := TJSONArray.Create;
      
      if AKeepHistory then
      begin
        for Msg in FHistory do
        begin
          MessageObj := TJSONObject.Create;
          MessageObj.AddPair('role', Msg.Role);
          MessageObj.AddPair('content', Msg.Content);
          MessagesArray.AddElement(MessageObj);
        end;
      end;
      
      MessageObj := TJSONObject.Create;
      MessageObj.AddPair('role', 'user');
      MessageObj.AddPair('content', APrompt);
      MessagesArray.AddElement(MessageObj);
      
      JSONPayload.AddPair('messages', MessagesArray);
      
      // Headers Claude sécurisés avec TRESTRequestParameter
      if CleanApiKey <> '' then
      begin
        var ParamKey := RestRequest.Params.AddItem;
        ParamKey.Name := 'x-api-key';
        ParamKey.Value := CleanApiKey;
        ParamKey.Kind := pkHTTPHEADER;
        ParamKey.Options := [poDoNotEncode];
      end;
      
      var ParamVer := RestRequest.Params.AddItem;
      ParamVer.Name := 'anthropic-version';
      ParamVer.Value := '2023-06-01';
      ParamVer.Kind := pkHTTPHEADER;
      ParamVer.Options := [poDoNotEncode];
    end
    else // 0 = OpenAI / DeepSeek / Qwen / Standard
    begin
      JSONPayload.AddPair('model', FModel);
      
      MessagesArray := TJSONArray.Create;
      
      if AKeepHistory then
      begin
        for Msg in FHistory do
        begin
          MessageObj := TJSONObject.Create;
          MessageObj.AddPair('role', Msg.Role);
          MessageObj.AddPair('content', Msg.Content);
          MessagesArray.AddElement(MessageObj);
        end;
      end;
      
      MessageObj := TJSONObject.Create;
      MessageObj.AddPair('role', 'user');
      MessageObj.AddPair('content', APrompt);
      MessagesArray.AddElement(MessageObj);
      
      JSONPayload.AddPair('messages', MessagesArray);
      
      // Header standard Authorization Bearer sécurisé
      if CleanApiKey <> '' then
      begin
        var ParamAuth := RestRequest.Params.AddItem;
        ParamAuth.Name := 'Authorization';
        ParamAuth.Value := 'Bearer ' + CleanApiKey;
        ParamAuth.Kind := pkHTTPHEADER;
        ParamAuth.Options := [poDoNotEncode];
      end;
    end;

    RestRequest.AddBody(JSONPayload.ToString, ctAPPLICATION_JSON);
    RestRequest.Execute;
    
    if RestResponse.StatusCode = 200 then
    begin
      RespJSON := RestResponse.JSONValue as TJSONObject;
      if Assigned(RespJSON) then
      begin
        if FCloudType = 1 then // Parsing Gemini
        begin
          var CandidatesArray := RespJSON.GetValue<TJSONArray>('candidates');
          if Assigned(CandidatesArray) and (CandidatesArray.Count > 0) then
          begin
            var FirstCand := CandidatesArray.Items[0] as TJSONObject;
            var ContentNode := FirstCand.GetValue<TJSONObject>('content');
            if Assigned(ContentNode) then
            begin
              var Parts := ContentNode.GetValue<TJSONArray>('parts');
              if Assigned(Parts) and (Parts.Count > 0) then
              begin
                var FirstPart := Parts.Items[0] as TJSONObject;
                Result := FirstPart.GetValue<string>('text');
              end;
            end;
          end;
        end
        else if FCloudType = 2 then // Parsing Claude
        begin
          var ContentArray := RespJSON.GetValue<TJSONArray>('content');
          if Assigned(ContentArray) and (ContentArray.Count > 0) then
          begin
            var FirstContent := ContentArray.Items[0] as TJSONObject;
            Result := FirstContent.GetValue<string>('text');
          end;
        end
        else // Parsing OpenAI/Standard
        begin
          var ChoicesArray := RespJSON.GetValue<TJSONArray>('choices');
          if Assigned(ChoicesArray) and (ChoicesArray.Count > 0) then
          begin
            var FirstChoice := ChoicesArray.Items[0] as TJSONObject;
            var MsgNode := FirstChoice.GetValue<TJSONObject>('message');
            if Assigned(MsgNode) then
              Result := MsgNode.GetValue<string>('content');
          end;
        end;
        
        if AKeepHistory and (Result <> '') then
        begin
          AddToHistory('user', APrompt);
          AddToHistory('assistant', Result);
        end;
      end;
    end
    else
      raise Exception.CreateFmt('Erreur API Cloud (Code: %d): %s' + sLineBreak + '%s', 
        [RestResponse.StatusCode, RestResponse.StatusText, RestResponse.Content]);

  finally
    JSONPayload.Free;
    RestResponse.Free;
    RestRequest.Free;
    RestClient.Free;
  end;
end;

end.

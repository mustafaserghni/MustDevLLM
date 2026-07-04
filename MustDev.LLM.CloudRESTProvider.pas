unit MustDev.LLM.CloudRESTProvider;

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
    constructor Create(const AEndpoint, AApiKey, AModel: string; ACloudType: Integer); reintroduce;
    function Ask(const APrompt: string): string; override;
  end;

implementation

{ TCloudRESTLLMProvider }

constructor TCloudRESTLLMProvider.Create(const AEndpoint, AApiKey, AModel: string; ACloudType: Integer);
begin
  inherited Create(AEndpoint, AApiKey, AModel);
  FCloudType := ACloudType;
end;

function TCloudRESTLLMProvider.GetProviderType: TProviderType;
begin
  Result := ptCloudREST;
end;

function TCloudRESTLLMProvider.Ask(const APrompt: string): string;
var
  RestClient: TRESTClient;
  RestRequest: TRESTRequest;
  RestResponse: TRESTResponse;
  JSONPayload: TJSONObject;
  MessagesArray, PartsArray: TJSONArray;
  MessageObj, PartObj, RespJSON: TJSONObject;
begin
  Result := '';
  
  RestClient := TRESTClient.Create(FEndpoint);
  RestRequest := TRESTRequest.Create(nil);
  RestResponse := TRESTResponse.Create(nil);
  JSONPayload := TJSONObject.Create;
  try
    RestRequest.Client := RestClient;
    RestRequest.Response := RestResponse;
    RestRequest.Method := rmPOST;
    
    if FCloudType = 1 then // Gemini (Google)
    begin
      // Structure JSON pour Gemini
      MessagesArray := TJSONArray.Create;
      MessageObj := TJSONObject.Create;
      PartsArray := TJSONArray.Create;
      PartObj := TJSONObject.Create;
      
      PartObj.AddPair('text', APrompt);
      PartsArray.AddElement(PartObj);
      MessageObj.AddPair('parts', PartsArray);
      MessagesArray.AddElement(MessageObj);
      
      JSONPayload.AddPair('contents', MessagesArray);
      
      // L'API Key de Gemini passe souvent dans l'URL (si non configurée dans le Header)
      if (FApiKey <> '') and (Pos('key=', FEndpoint) = 0) then
      begin
        if Pos('?', FEndpoint) > 0 then
          RestClient.BaseURL := FEndpoint + '&key=' + FApiKey
        else
          RestClient.BaseURL := FEndpoint + '?key=' + FApiKey;
      end;
      
      // Alternative: Header x-goog-api-key
      RestRequest.Params.AddHeader('x-goog-api-key', FApiKey);
    end
    else if FCloudType = 2 then // Claude (Anthropic)
    begin
      // Structure JSON pour Claude
      JSONPayload.AddPair('model', FModel);
      JSONPayload.AddPair('max_tokens', TJSONNumber.Create(4096)); // Requis par l'API Claude
      
      MessagesArray := TJSONArray.Create;
      MessageObj := TJSONObject.Create;
      MessageObj.AddPair('role', 'user');
      MessageObj.AddPair('content', APrompt);
      MessagesArray.AddElement(MessageObj);
      
      JSONPayload.AddPair('messages', MessagesArray);
      
      // Headers spécifiques Anthropic
      if FApiKey <> '' then
        RestRequest.Params.AddHeader('x-api-key', FApiKey);
      RestRequest.Params.AddHeader('anthropic-version', '2023-06-01');
    end
    else // 0 = OpenAI / DeepSeek / QWen / Standard
    begin
      // Structure JSON Standard (OpenAI)
      JSONPayload.AddPair('model', FModel);
      
      MessagesArray := TJSONArray.Create;
      MessageObj := TJSONObject.Create;
      MessageObj.AddPair('role', 'user');
      MessageObj.AddPair('content', APrompt);
      MessagesArray.AddElement(MessageObj);
      
      JSONPayload.AddPair('messages', MessagesArray);
      
      // Header standard
      if FApiKey <> '' then
        RestRequest.Params.AddHeader('Authorization', 'Bearer ' + FApiKey);
    end;

    RestRequest.AddBody(JSONPayload.ToString, ctAPPLICATION_JSON);
    
    // Exécution de la requête REST (Bloquante mais déjà dans un thread via l'appelant)
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

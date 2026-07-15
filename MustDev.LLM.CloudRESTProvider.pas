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
  System.Classes, System.SysUtils, System.JSON, System.IOUtils, System.NetEncoding,
  REST.Types, REST.Client, System.Net.HttpClient,
  MustDev.LLM.Interfaces, MustDev.LLM.BaseProvider;

type
  TCloudRESTLLMProvider = class(TBaseLLMProvider)
  private
    FCloudType: Integer; // 0=OpenAI/Standard, 1=Gemini, 2=Claude
    FActiveRequest: TRESTRequest;
  protected
    function GetProviderType: TProviderType; override;
  public
    procedure SetCloudType(ACloudType: Integer);
    function Ask(const APrompt: string; AKeepHistory: Boolean = False; const AAttachments: TStrings = nil): string; override;
    procedure CancelRequest; override;
    
    // Récupération dynamique des modèles pour les services Cloud
    class function FetchModels(ACloudType: Integer; const AEndpoint, AApiKey: string): TArray<string>;
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

function IsImageFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.png') or (Ext = '.gif') or (Ext = '.webp');
end;

function IsTextFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.pas') or (Ext = '.dpr') or (Ext = '.txt') or (Ext = '.xml') or (Ext = '.json') or (Ext = '.html') or (Ext = '.css') or (Ext = '.md');
end;

function GetMimeType(const AFileName: string): string;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  if (Ext = '.jpg') or (Ext = '.jpeg') then Result := 'image/jpeg'
  else if Ext = '.png' then Result := 'image/png'
  else if Ext = '.gif' then Result := 'image/gif'
  else if Ext = '.webp' then Result := 'image/webp'
  else if Ext = '.pdf' then Result := 'application/pdf'
  else Result := 'application/octet-stream';
end;

function FileToBase64(const AFileName: string): string;
var
  MS: TMemoryStream;
begin
  Result := '';
  MS := TMemoryStream.Create;
  try
    MS.LoadFromFile(AFileName);
    Result := TNetEncoding.Base64.EncodeBytesToString(MS.Memory, MS.Size);
    Result := StringReplace(Result, sLineBreak, '', [rfReplaceAll]);
    Result := StringReplace(Result, #10, '', [rfReplaceAll]);
    Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  finally
    MS.Free;
  end;
end;

function TCloudRESTLLMProvider.Ask(const APrompt: string; AKeepHistory: Boolean = False; const AAttachments: TStrings = nil): string;
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
  FinalPrompt: string;
  HasImages: Boolean;
  AttachmentPath: string;
  I: Integer;
begin
  Result := '';
  TargetURL := FEndpoint;
  CleanApiKey := FApiKey;
  FinalPrompt := APrompt;
  HasImages := False;
  
  // Analyse des pièces jointes
  if Assigned(AAttachments) then
  begin
    for I := 0 to AAttachments.Count - 1 do
    begin
      AttachmentPath := AAttachments[I];
      if TFile.Exists(AttachmentPath) then
      begin
        if IsImageFile(AttachmentPath) then
          HasImages := True
        else if IsTextFile(AttachmentPath) then
        begin
          FinalPrompt := FinalPrompt + sLineBreak + sLineBreak + 
            '=== PIECE JOINTE : ' + ExtractFileName(AttachmentPath) + ' ===' + sLineBreak + 
            TFile.ReadAllText(AttachmentPath, TEncoding.UTF8) + sLineBreak +
            '==============================' + sLineBreak;
        end;
      end;
    end;
  end;
  
  KeyPos := Pos('?key=', TargetURL);
  if KeyPos = 0 then KeyPos := Pos('&key=', TargetURL);
  if KeyPos > 0 then
  begin
    if CleanApiKey = '' then
      CleanApiKey := Copy(TargetURL, KeyPos + 5, Length(TargetURL));
    TargetURL := Copy(TargetURL, 1, KeyPos - 1);
  end;

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
  RestClient.ConnectTimeout := 60000;
  RestClient.ReadTimeout := 120000;
  RestRequest := TRESTRequest.Create(nil);
  FActiveRequest := RestRequest;
  RestResponse := TRESTResponse.Create(nil);
  JSONPayload := TJSONObject.Create;
  try
    RestRequest.Client := RestClient;
    RestRequest.Response := RestResponse;
    RestRequest.Method := rmPOST;
    
    if FCloudType = 1 then // Gemini (Google)
    begin
      MessagesArray := TJSONArray.Create;
      
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
      
      MessageObj := TJSONObject.Create;
      PartsArray := TJSONArray.Create;
      
      PartObj := TJSONObject.Create;
      PartObj.AddPair('text', FinalPrompt);
      PartsArray.AddElement(PartObj);
      
      if Assigned(AAttachments) then
      begin
        for I := 0 to AAttachments.Count - 1 do
        begin
          AttachmentPath := AAttachments[I];
          if IsImageFile(AttachmentPath) and TFile.Exists(AttachmentPath) then
          begin
            var InlineDataObj := TJSONObject.Create;
            InlineDataObj.AddPair('mimeType', GetMimeType(AttachmentPath));
            InlineDataObj.AddPair('data', FileToBase64(AttachmentPath));
            
            PartObj := TJSONObject.Create;
            PartObj.AddPair('inlineData', InlineDataObj);
            PartsArray.AddElement(PartObj);
          end;
        end;
      end;
      
      MessageObj.AddPair('role', 'user');
      MessageObj.AddPair('parts', PartsArray);
      MessagesArray.AddElement(MessageObj);
      JSONPayload.AddPair('contents', MessagesArray);
      
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
      
      if HasImages then
      begin
        var ContentArray := TJSONArray.Create;
        
        var TextObj := TJSONObject.Create;
        TextObj.AddPair('type', 'text');
        TextObj.AddPair('text', FinalPrompt);
        ContentArray.AddElement(TextObj);
        
        if Assigned(AAttachments) then
        begin
          for I := 0 to AAttachments.Count - 1 do
          begin
            AttachmentPath := AAttachments[I];
            if IsImageFile(AttachmentPath) and TFile.Exists(AttachmentPath) then
            begin
              var SourceObj := TJSONObject.Create;
              SourceObj.AddPair('type', 'base64');
              SourceObj.AddPair('media_type', GetMimeType(AttachmentPath));
              SourceObj.AddPair('data', FileToBase64(AttachmentPath));
              
              var ImageObj := TJSONObject.Create;
              ImageObj.AddPair('type', 'image');
              ImageObj.AddPair('source', SourceObj);
              ContentArray.AddElement(ImageObj);
            end;
          end;
        end;
        MessageObj.AddPair('content', ContentArray);
      end
      else
        MessageObj.AddPair('content', FinalPrompt);
        
      MessagesArray.AddElement(MessageObj);
      JSONPayload.AddPair('messages', MessagesArray);
      
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
      
      if HasImages then
      begin
        var ContentArray := TJSONArray.Create;
        
        var TextObj := TJSONObject.Create;
        TextObj.AddPair('type', 'text');
        TextObj.AddPair('text', FinalPrompt);
        ContentArray.AddElement(TextObj);
        
        if Assigned(AAttachments) then
        begin
          for I := 0 to AAttachments.Count - 1 do
          begin
            AttachmentPath := AAttachments[I];
            if IsImageFile(AttachmentPath) and TFile.Exists(AttachmentPath) then
            begin
              var ImageUrlObj := TJSONObject.Create;
              ImageUrlObj.AddPair('url', 'data:' + GetMimeType(AttachmentPath) + ';base64,' + FileToBase64(AttachmentPath));
              
              var ImageObj := TJSONObject.Create;
              ImageObj.AddPair('type', 'image_url');
              ImageObj.AddPair('image_url', ImageUrlObj);
              ContentArray.AddElement(ImageObj);
            end;
          end;
        end;
        MessageObj.AddPair('content', ContentArray);
      end
      else
        MessageObj.AddPair('content', FinalPrompt);
        
      MessagesArray.AddElement(MessageObj);
      JSONPayload.AddPair('messages', MessagesArray);
      
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
    FActiveRequest := nil;
    JSONPayload.Free;
    RestResponse.Free;
    RestRequest.Free;
    RestClient.Free;
  end;
end;

procedure TCloudRESTLLMProvider.CancelRequest;
begin
  if Assigned(FActiveRequest) then
  begin
    try
      FActiveRequest.Cancel;
    except
    end;
  end;
end;

class function TCloudRESTLLMProvider.FetchModels(ACloudType: Integer; const AEndpoint, AApiKey: string): TArray<string>;
var
  Http: THTTPClient;
  Resp: IHTTPResponse;
  BaseURL: string;
  JSONObj: TJSONObject;
  ModelsArray: TJSONArray;
  I: Integer;
  CleanApiKey: string;
  KeyPos: Integer;
begin
  SetLength(Result, 0);
  Http := THTTPClient.Create;
  try
    try
      BaseURL := AEndpoint;
      CleanApiKey := AApiKey;
      
      // Extraction de la clé API si elle est codée dans l'URL
      KeyPos := Pos('?key=', BaseURL);
      if KeyPos = 0 then KeyPos := Pos('&key=', BaseURL);
      if KeyPos > 0 then
      begin
        if CleanApiKey = '' then
          CleanApiKey := Copy(BaseURL, KeyPos + 5, Length(BaseURL));
        BaseURL := Copy(BaseURL, 1, KeyPos - 1);
      end;
      
      if ACloudType = 1 then // Google Gemini
      begin
        // Normalisation de l'URL d'extraction des modèles : remplacer models/... par models
        if Pos('/models/', BaseURL) > 0 then
          BaseURL := Copy(BaseURL, 1, Pos('/models/', BaseURL) + 7)
        else if not BaseURL.EndsWith('/') then
          BaseURL := BaseURL + '/models'
        else
          BaseURL := BaseURL + 'models';
          
        if CleanApiKey <> '' then
          BaseURL := BaseURL + '?key=' + CleanApiKey;
      end
      else if ACloudType = 2 then // Anthropic Claude (liste fixe car pas d'API publique)
      begin
        SetLength(Result, 3);
        Result[0] := 'claude-3-5-sonnet-latest';
        Result[1] := 'claude-3-5-haiku-latest';
        Result[2] := 'claude-3-opus-latest';
        Exit;
      end;
      
      // Standard OpenAI / DeepSeek / Qwen
      if ACloudType = 0 then 
      begin
        // Remplacer chat/completions par models
        BaseURL := StringReplace(BaseURL, '/chat/completions', '/models', [rfIgnoreCase]);
        if CleanApiKey <> '' then
          Http.CustomHeaders['Authorization'] := 'Bearer ' + CleanApiKey;
      end;
      
      Resp := Http.Get(BaseURL);
      if Resp.StatusCode = 200 then
      begin
        JSONObj := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
        if Assigned(JSONObj) then
        try
          if ACloudType = 1 then // Parsing Gemini
            ModelsArray := JSONObj.GetValue<TJSONArray>('models')
          else // Parsing standard OpenAI (contient les modèles sous la clé 'data')
            ModelsArray := JSONObj.GetValue<TJSONArray>('data');
            
          if Assigned(ModelsArray) then
          begin
            SetLength(Result, ModelsArray.Count);
            for I := 0 to ModelsArray.Count - 1 do
            begin
              var ModelObj := ModelsArray.Items[I] as TJSONObject;
              if ACloudType = 1 then
              begin
                // Gemini retourne "models/gemini-1.5-flash", on garde la partie après models/
                var FullName := ModelObj.GetValue<string>('name');
                if Pos('models/', FullName) > 0 then
                  Result[I] := Copy(FullName, Pos('models/', FullName) + 7, Length(FullName))
                else
                  Result[I] := FullName;
              end
              else
                Result[I] := ModelObj.GetValue<string>('id');
            end;
          end;
        finally
          JSONObj.Free;
        end;
      end;
    except
      // Renvoie un tableau vide en cas d'erreur réseau
    end;
  finally
    Http.Free;
  end;
end;

end.

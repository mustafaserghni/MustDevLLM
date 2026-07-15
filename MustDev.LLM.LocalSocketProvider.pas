unit MustDev.LLM.LocalSocketProvider;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Local Socket LLM Provider                                         }
{  Description: Connecteur pour modèles locaux via TCP Sockets (Ollama etc). }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.IOUtils, System.NetEncoding,
  System.Net.Socket, System.Net.HttpClient,
  MustDev.LLM.Interfaces, MustDev.LLM.BaseProvider;

type
  TLocalSocketLLMProvider = class(TBaseLLMProvider)
  private
    FIsCancelled: Boolean;
    procedure HttpReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
  protected
    function GetProviderType: TProviderType; override;
  public
    function Ask(const APrompt: string; AKeepHistory: Boolean = False; const AAttachments: TStrings = nil): string; override;
    procedure CancelRequest; override;
    
    // Interroge l'API locale (Ollama ou LM Studio) pour lister les modèles installés
    class function FetchModels(const AEndpoint, AApiKey: string): TArray<string>;
  end;

implementation

uses
  MustDev.LLM.Logger;

{ TLocalSocketLLMProvider }

function TLocalSocketLLMProvider.GetProviderType: TProviderType;
begin
  Result := ptLocalSocket;
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

function TLocalSocketLLMProvider.Ask(const APrompt: string; AKeepHistory: Boolean = False; const AAttachments: TStrings = nil): string;
var
  Http: THTTPClient;
  Resp: IHTTPResponse;
  JSONPayload: TJSONObject;
  StringStream: TStringStream;
  MessagesArray: TJSONArray;
  MessageObj: TJSONObject;
  Msg: TLLMMessage;
  TargetURL: string;
  IsOllamaChat: Boolean;
  FinalPrompt: string;
  HasImages: Boolean;
  AttachmentPath: string;
  I: Integer;
begin
  Result := '';
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

  Http := THTTPClient.Create;
  Http.OnReceiveData := HttpReceiveData;
  FIsCancelled := False;
  if FApiKey <> '' then
    Http.CustomHeaders['Authorization'] := 'Bearer ' + FApiKey;
  Http.ConnectionTimeout := 60000;
  Http.ResponseTimeout := 120000;
  JSONPayload := TJSONObject.Create;
  try
    JSONPayload.AddPair('model', FModel);
    
    // Remplacement automatique de localhost par 127.0.0.1 pour contourner les problèmes de résolution IPv6 Windows
    TargetURL := StringReplace(FEndpoint, 'localhost', '127.0.0.1', [rfIgnoreCase]);
    IsOllamaChat := False;
    
    // Redirection automatique vers /api/chat pour Ollama si l'historique est demandé
    if AKeepHistory and (Pos('/api/generate', TargetURL) > 0) then
    begin
      TargetURL := StringReplace(TargetURL, '/api/generate', '/api/chat', [rfIgnoreCase]);
      IsOllamaChat := True;
    end;
    
    if IsOllamaChat or (Pos('/v1/', TargetURL) > 0) then
    begin
      // Format chat standard (messages array)
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
      
      if IsOllamaChat then
      begin
        MessageObj.AddPair('content', FinalPrompt);
        if HasImages and Assigned(AAttachments) then
        begin
          var ImagesArray := TJSONArray.Create;
          for I := 0 to AAttachments.Count - 1 do
          begin
            AttachmentPath := AAttachments[I];
            if IsImageFile(AttachmentPath) and TFile.Exists(AttachmentPath) then
              ImagesArray.Add(FileToBase64(AttachmentPath));
          end;
          MessageObj.AddPair('images', ImagesArray);
        end;
      end
      else // OpenAI-compatible (/v1/)
      begin
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
      end;
      
      MessagesArray.AddElement(MessageObj);
      JSONPayload.AddPair('messages', MessagesArray);
      
      if IsOllamaChat then
        JSONPayload.AddPair('stream', TJSONBool.Create(False));
    end
    else
    begin
      // Format de complétion classique (sans historique)
      JSONPayload.AddPair('prompt', FinalPrompt);
      if HasImages and Assigned(AAttachments) then
      begin
        var ImagesArray := TJSONArray.Create;
        for I := 0 to AAttachments.Count - 1 do
        begin
          AttachmentPath := AAttachments[I];
          if IsImageFile(AttachmentPath) and TFile.Exists(AttachmentPath) then
            ImagesArray.Add(FileToBase64(AttachmentPath));
        end;
        JSONPayload.AddPair('images', ImagesArray);
      end;
      JSONPayload.AddPair('stream', TJSONBool.Create(False));
    end;
    
    StringStream := TStringStream.Create(JSONPayload.ToString, TEncoding.UTF8);
    try
      Http.ContentType := 'application/json';
      TLLMLogger.LogInfo(Format('Requête HTTP POST vers le serveur local : %s (Modèle : %s, Taille : %d octets)', [TargetURL, FModel, StringStream.Size]));
      Resp := Http.Post(TargetURL, StringStream);
      TLLMLogger.LogInfo(Format('Réponse HTTP reçue du serveur local. Code : %d (%s)', [Resp.StatusCode, Resp.StatusText]));
      
      if Resp.StatusCode = 200 then
      begin
        var RespJSON := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
        if Assigned(RespJSON) then
        try
          if IsOllamaChat or (Pos('/v1/', TargetURL) > 0) then
          begin
            if IsOllamaChat then
            begin
              var MsgNode := RespJSON.GetValue<TJSONObject>('message');
              if Assigned(MsgNode) then
                Result := MsgNode.GetValue<string>('content');
            end
            else
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
          end
          else
            Result := RespJSON.GetValue<string>('response');
            
          if AKeepHistory and (Result <> '') then
          begin
            AddToHistory('user', APrompt);
            AddToHistory('assistant', Result);
          end;
        finally
          RespJSON.Free;
        end;
      end
      else
      begin
        var ErrDetail := Resp.ContentAsString(TEncoding.UTF8);
        TLLMLogger.LogError(Format('Erreur serveur local HTTP %d : %s', [Resp.StatusCode, Resp.StatusText]), ErrDetail);
        
        var ErrMsg := '';
        try
          var ErrJSON := TJSONObject.ParseJSONValue(ErrDetail) as TJSONObject;
          if Assigned(ErrJSON) then
          try
            var ErrNode := ErrJSON.GetValue<TJSONObject>('error');
            if Assigned(ErrNode) then
              ErrMsg := ErrNode.GetValue<string>('message')
            else
              ErrMsg := ErrJSON.GetValue<string>('error');
          finally
            ErrJSON.Free;
          end;
        except
        end;
        
        if ErrMsg <> '' then
          raise Exception.CreateFmt('Erreur serveur local (Code: %d): %s' + sLineBreak + 'Message : %s', [Resp.StatusCode, Resp.StatusText, ErrMsg])
        else if ErrDetail <> '' then
          raise Exception.CreateFmt('Erreur serveur local (Code: %d): %s' + sLineBreak + 'Détails : %s', [Resp.StatusCode, Resp.StatusText, Copy(ErrDetail, 1, 500)])
        else
          raise Exception.CreateFmt('Erreur serveur local (Code: %d): %s', [Resp.StatusCode, Resp.StatusText]);
      end;
    finally
      StringStream.Free;
    end;
  finally
    JSONPayload.Free;
    Http.Free;
  end;
end;

procedure TLocalSocketLLMProvider.CancelRequest;
begin
  FIsCancelled := True;
end;

procedure TLocalSocketLLMProvider.HttpReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
begin
  AAbort := FIsCancelled;
end;

class function TLocalSocketLLMProvider.FetchModels(const AEndpoint, AApiKey: string): TArray<string>;
var
  Http: THTTPClient;
  Resp: IHTTPResponse;
  BaseURL: string;
  JSONObj: TJSONObject;
  ModelsArray: TJSONArray;
  I: Integer;
begin
  Result := [];
  Http := THTTPClient.Create;
  try
    if AApiKey <> '' then
      Http.CustomHeaders['Authorization'] := 'Bearer ' + AApiKey;
    try
      BaseURL := StringReplace(AEndpoint, 'localhost', '127.0.0.1', [rfIgnoreCase]);
      
      // Reconstruction de l'URL Ollama ou LM Studio
      if (Pos('11434', BaseURL) > 0) then
      begin
        var P := Pos('11434', BaseURL);
        BaseURL := Copy(BaseURL, 1, P + 4) + '/api/tags';
      end
      else if (Pos('1234', BaseURL) > 0) then
      begin
        var P := Pos('1234', BaseURL);
        BaseURL := Copy(BaseURL, 1, P + 3) + '/v1/models';
      end
      else if (Pos('/v1/', BaseURL) > 0) then
      begin
        var P := Pos('/v1/', BaseURL);
        BaseURL := Copy(BaseURL, 1, P + 3) + 'models';
      end
      else
        Exit;
        
      Resp := Http.Get(BaseURL);
      if Resp.StatusCode = 200 then
      begin
        JSONObj := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
        if Assigned(JSONObj) then
        try
          if Pos('11434', BaseURL) > 0 then
            ModelsArray := JSONObj.GetValue<TJSONArray>('models')
          else
            ModelsArray := JSONObj.GetValue<TJSONArray>('data');
            
          if Assigned(ModelsArray) then
          begin
            SetLength(Result, ModelsArray.Count);
            for I := 0 to ModelsArray.Count - 1 do
            begin
              var ModelObj := ModelsArray.Items[I] as TJSONObject;
              if Pos('11434', BaseURL) > 0 then
                Result[I] := ModelObj.GetValue<string>('name')
              else
                Result[I] := ModelObj.GetValue<string>('id');
            end;
          end;
        finally
          JSONObj.Free;
        end;
      end
      else
      begin
        var ErrDetail := Resp.ContentAsString(TEncoding.UTF8);
        TLLMLogger.LogError(Format('Erreur FetchModels HTTP %d : %s', [Resp.StatusCode, Resp.StatusText]), ErrDetail);
        raise Exception.CreateFmt('HTTP %d: %s (Détails: %s)', [Resp.StatusCode, Resp.StatusText, Copy(ErrDetail, 1, 200)]);
      end;
    except
      on E: Exception do
        raise Exception.Create('Erreur de connexion au serveur local : ' + E.Message);
    end;
  finally
    Http.Free;
  end;
end;

end.

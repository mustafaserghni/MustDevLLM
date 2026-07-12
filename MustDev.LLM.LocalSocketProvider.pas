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
  System.Classes, System.SysUtils, System.JSON,
  System.Net.Socket, System.Net.HttpClient,
  MustDev.LLM.Interfaces, MustDev.LLM.BaseProvider;

type
  TLocalSocketLLMProvider = class(TBaseLLMProvider)
  protected
    function GetProviderType: TProviderType; override;
  public
    function Ask(const APrompt: string; AKeepHistory: Boolean = False): string; override;
    
    // Interroge l'API locale (Ollama ou LM Studio) pour lister les modèles installés
    class function FetchModels(const AEndpoint: string): TArray<string>;
  end;

implementation

{ TLocalSocketLLMProvider }

function TLocalSocketLLMProvider.GetProviderType: TProviderType;
begin
  Result := ptLocalSocket;
end;

function TLocalSocketLLMProvider.Ask(const APrompt: string; AKeepHistory: Boolean = False): string;
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
begin
  Result := '';
  Http := THTTPClient.Create;
  Http.ConnectionTimeout := 60000; // 60 secondes max pour se connecter
  Http.ResponseTimeout := 120000;   // 120 secondes max pour attendre la réponse
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
      MessageObj.AddPair('content', APrompt);
      MessagesArray.AddElement(MessageObj);
      
      JSONPayload.AddPair('messages', MessagesArray);
      
      if IsOllamaChat then
        JSONPayload.AddPair('stream', TJSONBool.Create(False));
    end
    else
    begin
      // Format de complétion classique (sans historique)
      JSONPayload.AddPair('prompt', APrompt);
      JSONPayload.AddPair('stream', TJSONBool.Create(False));
    end;
    
    StringStream := TStringStream.Create(JSONPayload.ToString, TEncoding.UTF8);
    try
      Http.ContentType := 'application/json';
      Resp := Http.Post(TargetURL, StringStream);
      
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
        raise Exception.CreateFmt('Erreur fournisseur local (Code: %d): %s', [Resp.StatusCode, Resp.StatusText]);
    finally
      StringStream.Free;
    end;
  finally
    JSONPayload.Free;
    Http.Free;
  end;
end;

class function TLocalSocketLLMProvider.FetchModels(const AEndpoint: string): TArray<string>;
var
  Http: THTTPClient;
  Resp: IHTTPResponse;
  BaseURL: string;
  JSONObj: TJSONObject;
  ModelsArray: TJSONArray;
  I: Integer;
begin
  SetLength(Result, 0);
  Http := THTTPClient.Create;
  try
    try
      // Résolution du localhost Windows (IPv6 ::1) en 127.0.0.1 pour contacter LM Studio / Ollama à coup sûr
      BaseURL := StringReplace(AEndpoint, 'localhost', '127.0.0.1', [rfIgnoreCase]);
      
      if Pos('11434', BaseURL) > 0 then
      begin
        BaseURL := StringReplace(BaseURL, '/generate', '/tags', [rfIgnoreCase]);
        BaseURL := StringReplace(BaseURL, '/chat', '/tags', [rfIgnoreCase]);
      end
      else if Pos('/v1/', BaseURL) > 0 then
      begin
        BaseURL := StringReplace(BaseURL, '/chat/completions', '/models', [rfIgnoreCase]);
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
      end;
    except
    end;
  finally
    Http.Free;
  end;
end;

end.

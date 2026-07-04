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
    function Ask(const APrompt: string): string; override;
    
    // Interroge l'API locale (Ollama ou LM Studio) pour lister les modèles installés
    class function FetchModels(const AEndpoint: string): TArray<string>;
  end;

implementation

{ TLocalSocketLLMProvider }

function TLocalSocketLLMProvider.GetProviderType: TProviderType;
begin
  Result := ptLocalSocket;
end;

function TLocalSocketLLMProvider.Ask(const APrompt: string): string;
var
  Http: THTTPClient;
  Resp: IHTTPResponse;
  JSONPayload: TJSONObject;
  StringStream: TStringStream;
begin
  Result := '';
  
  Http := THTTPClient.Create;
  JSONPayload := TJSONObject.Create;
  try
    JSONPayload.AddPair('model', FModel);
    
    // Pour LM Studio v1 on doit utiliser un format de messages, 
    // Pour Ollama api/generate on utilise prompt. 
    // Simplification : si endpoint contient v1, on envoie le format standard OpenAI
    if Pos('/v1/', FEndpoint) > 0 then
    begin
      var MessagesArray := TJSONArray.Create;
      var MessageObj := TJSONObject.Create;
      MessageObj.AddPair('role', 'user');
      MessageObj.AddPair('content', APrompt);
      MessagesArray.AddElement(MessageObj);
      JSONPayload.AddPair('messages', MessagesArray);
    end
    else
    begin
      JSONPayload.AddPair('prompt', APrompt);
      JSONPayload.AddPair('stream', TJSONBool.Create(False));
    end;
    
    StringStream := TStringStream.Create(JSONPayload.ToString, TEncoding.UTF8);
    try
      Http.ContentType := 'application/json';
      Resp := Http.Post(FEndpoint, StringStream);
      
      if Resp.StatusCode = 200 then
      begin
        var RespJSON := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
        if Assigned(RespJSON) then
        try
          if Pos('/v1/', FEndpoint) > 0 then
          begin
            var ChoicesArray := RespJSON.GetValue<TJSONArray>('choices');
            if Assigned(ChoicesArray) and (ChoicesArray.Count > 0) then
            begin
              var FirstChoice := ChoicesArray.Items[0] as TJSONObject;
              var MsgNode := FirstChoice.GetValue<TJSONObject>('message');
              if Assigned(MsgNode) then
                Result := MsgNode.GetValue<string>('content');
            end;
          end
          else
            Result := RespJSON.GetValue<string>('response');
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
      if Pos('11434', AEndpoint) > 0 then
      begin
        // Ollama: Remplacer /api/generate par /api/tags
        BaseURL := AEndpoint;
        BaseURL := StringReplace(BaseURL, '/generate', '/tags', [rfIgnoreCase]);
      end
      else if Pos('/v1/', AEndpoint) > 0 then
      begin
        // LM Studio: Remplacer /v1/chat/completions par /v1/models
        BaseURL := AEndpoint;
        BaseURL := StringReplace(BaseURL, '/chat/completions', '/models', [rfIgnoreCase]);
      end
      else
        Exit; // Format inconnu
        
      Resp := Http.Get(BaseURL);
      if Resp.StatusCode = 200 then
      begin
        JSONObj := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
        if Assigned(JSONObj) then
        try
          if Pos('11434', AEndpoint) > 0 then
            ModelsArray := JSONObj.GetValue<TJSONArray>('models')
          else
            ModelsArray := JSONObj.GetValue<TJSONArray>('data');
            
          if Assigned(ModelsArray) then
          begin
            SetLength(Result, ModelsArray.Count);
            for I := 0 to ModelsArray.Count - 1 do
            begin
              var ModelObj := ModelsArray.Items[I] as TJSONObject;
              if Pos('11434', AEndpoint) > 0 then
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
      // Erreur silencieuse si serveur injoignable
    end;
  finally
    Http.Free;
  end;
end;

end.

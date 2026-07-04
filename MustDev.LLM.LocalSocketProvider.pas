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
  
  // Implémentation basique HTTP vers l'API locale (ex: Ollama http://127.0.0.1:11434/api/generate)
  // Bien que le nom indique Socket, l'API Ollama est exposée via HTTP localement
  // On utilise THTTPClient qui gère les sockets TCP en dessous de manière robuste
  
  Http := THTTPClient.Create;
  JSONPayload := TJSONObject.Create;
  try
    JSONPayload.AddPair('model', FModel);
    JSONPayload.AddPair('prompt', APrompt);
    JSONPayload.AddPair('stream', TJSONBool.Create(False));
    
    StringStream := TStringStream.Create(JSONPayload.ToString, TEncoding.UTF8);
    try
      Http.ContentType := 'application/json';
      Resp := Http.Post(FEndpoint, StringStream);
      
      if Resp.StatusCode = 200 then
      begin
        var RespJSON := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
        if Assigned(RespJSON) then
        try
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

end.

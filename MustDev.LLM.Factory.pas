unit MustDev.LLM.Factory;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: LLM Factory                                                       }
{  Description: Factory pour l'instanciation des différents fournisseurs IA. }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.SysUtils, MustDev.LLM.Interfaces, MustDev.LLM.LocalSocketProvider, MustDev.LLM.CloudRESTProvider;

type
  TLLMProviderFactory = class
  public
    // ACloudType: 0=Standard(OpenAI), 1=Gemini, 2=Claude
    class function CreateProvider(AType: TProviderType; const AEndpoint, AApiKey, AModel: string; ACloudType: Integer = 0): ILLMProvider;
  end;

implementation

{ TLLMProviderFactory }

class function TLLMProviderFactory.CreateProvider(AType: TProviderType; const AEndpoint, AApiKey, AModel: string; ACloudType: Integer): ILLMProvider;
begin
  case AType of
    ptLocalSocket: Result := TLocalSocketLLMProvider.Create(AEndpoint, AApiKey, AModel);
    ptCloudREST: Result := TCloudRESTLLMProvider.Create(AEndpoint, AApiKey, AModel, ACloudType);
  else
    raise Exception.Create('Type de fournisseur non supporté.');
  end;
end;

end.

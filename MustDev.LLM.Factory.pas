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
  System.SysUtils, MustDev.LLM.Interfaces, MustDev.LLM.BaseProvider,
  MustDev.LLM.LocalSocketProvider, MustDev.LLM.CloudRESTProvider;

type
  TLLMProviderFactory = class
  public
    // ACloudType: 0=Standard(OpenAI), 1=Gemini, 2=Claude
    class function CreateProvider(AType: TProviderType; const AEndpoint, AApiKey, AModel: string; ACloudType: Integer = 0): ILLMProvider;
  end;

implementation

{ TLLMProviderFactory }

class function TLLMProviderFactory.CreateProvider(AType: TProviderType; const AEndpoint, AApiKey, AModel: string; ACloudType: Integer): ILLMProvider;
var
  Prov: TBaseLLMProvider;
begin
  case AType of
    ptLocalSocket: Prov := TLocalSocketLLMProvider.Create;
    ptCloudREST: 
      begin
        Prov := TCloudRESTLLMProvider.Create;
        TCloudRESTLLMProvider(Prov).SetCloudType(ACloudType);
      end;
  else
    raise Exception.Create('Type de fournisseur non supporté.');
  end;
  
  Prov.InitProvider(AEndpoint, AApiKey, AModel);
  Result := Prov;
end;

end.

unit MustDev.LLM.Factory;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: LLM Provider Factory                                              }
{  Description: Instancie dynamiquement le bon fournisseur d'IA.             }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.SysUtils, MustDev.LLM.Interfaces, MustDev.LLM.LocalSocketProvider, 
  MustDev.LLM.CloudRESTProvider;

type
  TLLMProviderFactory = class
  public
    // Instancie un fournisseur selon le type choisi par l'utilisateur
    class function CreateProvider(const AType: TProviderType; 
      const AEndpoint, AApiKey, AModel: string): ILLMProvider;
  end;

implementation

{ TLLMProviderFactory }

class function TLLMProviderFactory.CreateProvider(const AType: TProviderType;
  const AEndpoint, AApiKey, AModel: string): ILLMProvider;
begin
  case AType of
    ptLocalSocket: 
      Result := TLocalSocketLLMProvider.Create;
    ptCloudREST: 
      Result := TCloudRESTLLMProvider.Create;
  else
    raise Exception.Create('Type de fournisseur LLM inconnu.');
  end;
  
  // Initialisation du fournisseur avec les paramètres
  Result.Initialize(AEndpoint, AApiKey, AModel);
end;

end.

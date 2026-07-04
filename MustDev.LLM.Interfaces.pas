unit MustDev.LLM.Interfaces;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: LLM Interfaces                                                    }
{  Description: Contient l'interface commune à tous les fournisseurs d'IA.   }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.Classes, System.SysUtils;

type
  // Enumération des types de fournisseurs
  TProviderType = (ptLocalSocket, ptCloudREST);

  // Interface commune pour les fournisseurs LLM
  ILLMProvider = interface
    ['{8A5D6B10-E7A4-4B33-A2C3-D5C2B1B7D14D}']
    
    // Initialise le fournisseur avec ses paramètres (URL, Port ou Clé API)
    procedure InitProvider(const AEndpoint, AApiKey: string; const AModel: string);
    
    // Méthode principale pour envoyer un prompt et récupérer une réponse
    function Ask(const APrompt: string): string;
    
    // Propriétés
    function GetProviderType: TProviderType;
    function GetModelName: string;
    
    property ProviderType: TProviderType read GetProviderType;
    property ModelName: string read GetModelName;
  end;

implementation

end.

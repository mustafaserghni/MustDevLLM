unit MustDev.LLM.BaseProvider;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Base LLM Provider                                                 }
{  Description: Classe abstraite de base implémentant l'interface commune.   }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.Classes, System.SysUtils, MustDev.LLM.Interfaces;

type
  TBaseLLMProvider = class(TInterfacedObject, ILLMProvider)
  protected
    FEndpoint: string;
    FApiKey: string;
    FModel: string;
    
    function GetProviderType: TProviderType; virtual; abstract;
    function GetModelName: string; virtual;
  public
    procedure Initialize(const AEndpoint, AApiKey: string; const AModel: string); virtual;
    function Ask(const APrompt: string): string; virtual; abstract;
    
    property ProviderType: TProviderType read GetProviderType;
    property ModelName: string read GetModelName;
  end;

implementation

{ TBaseLLMProvider }

procedure TBaseLLMProvider.Initialize(const AEndpoint, AApiKey, AModel: string);
begin
  FEndpoint := AEndpoint;
  FApiKey := AApiKey;
  FModel := AModel;
end;

function TBaseLLMProvider.GetModelName: string;
begin
  Result := FModel;
end;

end.

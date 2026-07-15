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
  System.Classes, System.SysUtils, System.Generics.Collections, MustDev.LLM.Interfaces;

type
  TBaseLLMProvider = class(TInterfacedObject, ILLMProvider)
  protected
    FEndpoint: string;
    FApiKey: string;
    FModel: string;
    FHistory: TList<TLLMMessage>;
    
    function GetProviderType: TProviderType; virtual; abstract;
    function GetModelName: string; virtual;
    
    // Ajoute un message à l'historique et gère la limite (max 10 messages pour économiser les tokens)
    procedure AddToHistory(const ARole, AContent: string);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    
    procedure InitProvider(const AEndpoint, AApiKey: string; const AModel: string); virtual;
    function Ask(const APrompt: string; AKeepHistory: Boolean = False; const AAttachments: TStrings = nil): string; virtual; abstract;
    procedure ClearHistory; virtual;
    
    property ProviderType: TProviderType read GetProviderType;
    property ModelName: string read GetModelName;
  end;

implementation

{ TBaseLLMProvider }

constructor TBaseLLMProvider.Create;
begin
  inherited Create;
  FHistory := TList<TLLMMessage>.Create;
end;

destructor TBaseLLMProvider.Destroy;
begin
  FHistory.Free;
  inherited Destroy;
end;

procedure TBaseLLMProvider.InitProvider(const AEndpoint, AApiKey, AModel: string);
begin
  FEndpoint := AEndpoint;
  FApiKey := AApiKey;
  FModel := AModel;
end;

function TBaseLLMProvider.GetModelName: string;
begin
  Result := FModel;
end;

procedure TBaseLLMProvider.ClearHistory;
begin
  FHistory.Clear;
end;

procedure TBaseLLMProvider.AddToHistory(const ARole, AContent: string);
var
  Msg: TLLMMessage;
begin
  Msg.Role := ARole;
  Msg.Content := AContent;
  FHistory.Add(Msg);
  
  // Limiter l'historique aux 10 derniers messages (5 allers-retours)
  // On supprime par bloc de 2 (1 question, 1 réponse) pour garder la cohérence
  while FHistory.Count > 10 do
  begin
    FHistory.Delete(0);
    if FHistory.Count > 0 then
      FHistory.Delete(0);
  end;
end;

end.

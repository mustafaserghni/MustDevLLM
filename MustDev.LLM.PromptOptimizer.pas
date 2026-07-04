unit MustDev.LLM.PromptOptimizer;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Prompt Optimizer                                                  }
{  Description: Moteur d'optimisation et d'enrichissement des Prompts.       }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.SysUtils, System.IOUtils, System.Win.Registry, Winapi.Windows, 
  MustDev.LLM.ProjectManager, MustDev.LLM.Logger;

type
  TPromptOptimizer = class
  private
    class function GetActiveProviderName: string;
  public
    // Enrichit un prompt utilisateur avec des directives Delphi et le contexte Projet/Agent
    class function Optimize(const ABasePrompt, ACodeContext: string): string;
  end;

implementation

{ TPromptOptimizer }

class function TPromptOptimizer.GetActiveProviderName: string;
var
  Reg: TRegistry;
  ProviderType, CloudType: Integer;
begin
  Result := 'Local';
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('\Software\MustDev\LLMIntegration\Settings') then
    begin
      if Reg.ValueExists('ProviderType') then
        ProviderType := Reg.ReadInteger('ProviderType')
      else
        ProviderType := 0;
        
      if ProviderType = 0 then
        Result := 'Local'
      else
      begin
        if Reg.ValueExists('CloudType') then
          CloudType := Reg.ReadInteger('CloudType')
        else
          CloudType := 0;
          
        case CloudType of
          0: Result := 'OpenAI';
          1: Result := 'Gemini';
          2: Result := 'Claude';
        end;
      end;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

class function TPromptOptimizer.Optimize(const ABasePrompt, ACodeContext: string): string;
var
  ContextRules, ProjectPath, AgentFile, ProviderFile, ProviderName: string;
begin
  TLLMLogger.LogInfo('Optimisation du prompt (Chargement des agents...)');

  // Règles de base communes
  ContextRules := 
    '=== DELPHI DEVELOPMENT RULES ===' + sLineBreak +
    '1. Use modern Object Pascal syntax (Delphi 10.3+).' + sLineBreak +
    '2. Favor inline variables where appropriate.' + sLineBreak +
    '3. Ensure absolute memory safety: ALWAYS use try..finally blocks when instantiating objects.' + sLineBreak +
    '4. Keep code highly readable and follow standard Delphi naming conventions.' + sLineBreak +
    '================================' + sLineBreak;
    
  // Injection Dynamique des fichiers Agents (Contexte Projet)
  ProjectPath := TMustDevProjectManager.GetActiveProjectPath;
  if ProjectPath <> '' then
  begin
    // Chargement de l'Agent générique du projet
    AgentFile := TPath.Combine(ProjectPath, 'Agent.md');
    if TFile.Exists(AgentFile) then
    begin
      ContextRules := ContextRules + sLineBreak + 
        '=== PROJECT CONTEXT (Agent.md) ===' + sLineBreak + 
        TFile.ReadAllText(AgentFile, TEncoding.UTF8) + sLineBreak +
        '==================================' + sLineBreak;
      TLLMLogger.LogInfo('Fichier Agent.md injecté dans le contexte.');
    end;
    
    // Chargement de l'Agent spécifique au fournisseur (Gemini.md, Claude.md, OpenAI.md...)
    ProviderName := GetActiveProviderName;
    ProviderFile := TPath.Combine(ProjectPath, ProviderName + '.md');
    if TFile.Exists(ProviderFile) then
    begin
      ContextRules := ContextRules + sLineBreak + 
        '=== SPECIFIC ' + UpperCase(ProviderName) + ' RULES ===' + sLineBreak + 
        TFile.ReadAllText(ProviderFile, TEncoding.UTF8) + sLineBreak +
        '================================' + sLineBreak;
      TLLMLogger.LogInfo('Fichier ' + ProviderName + '.md injecté dans le contexte.');
    end;
  end;
    
  // Construction du Prompt Final
  Result := ContextRules + sLineBreak + 
            'USER REQUEST: ' + ABasePrompt + sLineBreak;
            
  if Trim(ACodeContext) <> '' then
  begin
    Result := Result + sLineBreak + 
              'CODE CONTEXT:' + sLineBreak + 
              '```pascal' + sLineBreak + 
              ACodeContext + sLineBreak + 
              '```';
  end;
end;

end.

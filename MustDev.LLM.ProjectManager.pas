unit MustDev.LLM.ProjectManager;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Project Manager                                                   }
{  Description: Gestion du projet actif (Création de fichiers Agent.md).     }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, ToolsAPI, MustDev.LLM.Logger;

type
  TMustDevProjectManager = class
  public
    // Retourne le chemin du répertoire du projet actif dans l'IDE
    class function GetActiveProjectPath: string;
    
    // Génère les fichiers Agent.md, Gemini.md, Claude.md à la racine du projet
    class procedure GenerateAgentFiles;
  end;

implementation

{ TMustDevProjectManager }

class function TMustDevProjectManager.GetActiveProjectPath: string;
var
  ModuleServices: IOTAModuleServices;
  ProjectGroup: IOTAProjectGroup;
  Project: IOTAProject;
begin
  Result := '';
  if Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then
  begin
    ProjectGroup := ModuleServices.MainProjectGroup;
    if Assigned(ProjectGroup) then
    begin
      Project := ProjectGroup.ActiveProject;
      if Assigned(Project) then
        Result := ExtractFilePath(Project.FileName);
    end
    else
    begin
      // Si aucun groupe de projet n'est ouvert mais un module est ouvert
      if ModuleServices.ModuleCount > 0 then
        Result := ExtractFilePath(ModuleServices.Modules[0].FileName);
    end;
  end;
end;

class procedure TMustDevProjectManager.GenerateAgentFiles;
var
  ProjectPath: string;
  
  procedure CreateMDFile(const FileName, Content: string);
  var
    FilePath: string;
  begin
    FilePath := TPath.Combine(ProjectPath, FileName);
    if not TFile.Exists(FilePath) then
    begin
      TFile.WriteAllText(FilePath, Content, TEncoding.UTF8);
      TLLMLogger.LogSuccess('Fichier généré : ' + FileName);
    end
    else
      TLLMLogger.LogInfo('Le fichier ' + FileName + ' existe déjà, génération ignorée.');
  end;

begin
  ProjectPath := GetActiveProjectPath;
  
  if ProjectPath = '' then
  begin
    TLLMLogger.LogError('Impossible de générer les fichiers Agent : Aucun projet actif trouvé.');
    Exit;
  end;
  
  TLLMLogger.LogInfo('Génération des fichiers Agent dans : ' + ProjectPath);
  
  CreateMDFile('Agent.md', 
    '# Agent Configuration' + sLineBreak +
    'Project specific instructions for the general Must@Dev AI Agent.' + sLineBreak +
    '- Language: Delphi / Object Pascal' + sLineBreak +
    '- Style: Modern (Inline variables, Generics)');
    
  CreateMDFile('Gemini.md', 
    '# Gemini Context' + sLineBreak +
    'Specific rules for Google Gemini interactions in this project.' + sLineBreak +
    '- Be highly analytical.' + sLineBreak +
    '- Prioritize clean architecture.');
    
  CreateMDFile('Claude.md', 
    '# Claude Context' + sLineBreak +
    'Specific rules for Anthropic Claude interactions in this project.' + sLineBreak +
    '- Provide detailed refactoring steps.' + sLineBreak +
    '- Focus on memory safety and SOLID principles.');
end;

end.

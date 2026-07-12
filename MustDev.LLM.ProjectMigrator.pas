unit MustDev.LLM.ProjectMigrator;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Project Migration Agent                                           }
{  Description: Agent de migration de code Delphi (Unicode, modernisation)   }
{               sur tout un projet ouvert de manière asynchrone.             }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.Classes, System.SysUtils, MustDev.LLM.Interfaces;

type
  TMigrationLogEvent = reference to procedure(const LogMsg: string);

  TProjectMigrator = class
  private
    FProvider: ILLMProvider;
    FOnLog: TMigrationLogEvent;
    procedure Log(const Msg: string);
    function MigrateFile(const AFileName: string): Boolean;
  public
    constructor Create(const AProvider: ILLMProvider; ALogCallback: TMigrationLogEvent);
    
    // Lance la migration asynchrone de tout le projet actif
    procedure MigrateProject;
  end;

implementation

uses
  System.IOUtils, ToolsAPI;

{ TProjectMigrator }

constructor TProjectMigrator.Create(const AProvider: ILLMProvider; ALogCallback: TMigrationLogEvent);
begin
  inherited Create;
  FProvider := AProvider;
  FOnLog := ALogCallback;
end;

procedure TProjectMigrator.Log(const Msg: string);
begin
  if Assigned(FOnLog) then
  begin
    TThread.Queue(nil,
      procedure
      begin
        FOnLog(Msg);
      end);
  end;
end;

function TProjectMigrator.MigrateFile(const AFileName: string): Boolean;
var
  OriginalCode, MigratedCode: string;
  Prompt: string;
  ActionServices: IOTAActionServices;
begin
  Result := False;
  try
    if not TFile.Exists(AFileName) then Exit;
    
    // 1. Lire le code source d'origine
    OriginalCode := TFile.ReadAllText(AFileName, TEncoding.UTF8);
    if Trim(OriginalCode) = '' then Exit;
    
    // 2. Prompt expert de migration Delphi
    Prompt := 'ROLE: Tu es l''Agent de Migration de Code Delphi.' + sLineBreak +
              'Ton rôle est de migrer le code Delphi obsolète (Delphi 7, 2007) fourni vers le Delphi moderne (Delphi 11/12).' + sLineBreak +
              'Applique les règles suivantes :' + sLineBreak +
              '1. Assure la compatibilité Unicode (remplace AnsiString par string, PAnsiChar par PChar).' + sLineBreak +
              '2. Modernise la syntaxe (utilise les inline variables, for var i := 0 to...).' + sLineBreak +
              '3. Remplace les vieilles classes de listes par des Generics (TList<T>, TDictionary).' + sLineBreak +
              '4. Assure la libération propre de la mémoire dans des blocs try..finally.' + sLineBreak +
              'Retourne UNIQUEMENT le code Pascal migré valide dans un bloc de code ```pascal.' + sLineBreak +
              'CODE SOURCE A MIGRER :' + sLineBreak +
              OriginalCode;
              
    // 3. Appel de l'IA
    MigratedCode := FProvider.Ask(Prompt, False);
    
    // Nettoyage des balises Markdown
    MigratedCode := StringReplace(MigratedCode, '```pascal', '', [rfReplaceAll, rfIgnoreCase]);
    MigratedCode := StringReplace(MigratedCode, '```delphi', '', [rfReplaceAll, rfIgnoreCase]);
    MigratedCode := StringReplace(MigratedCode, '```', '', [rfReplaceAll]);
    MigratedCode := Trim(MigratedCode);
    
    if MigratedCode = '' then Exit;
    
    // 4. Sauvegarde de sécurité (.bak)
    var BackupFile := AFileName + '.bak';
    if TFile.Exists(BackupFile) then
      TFile.Delete(BackupFile);
    TFile.Copy(AFileName, BackupFile);
    
    // 5. Écriture du code migré sur disque
    TFile.WriteAllText(AFileName, MigratedCode, TEncoding.UTF8);
    
    // 6. Demander à l'éditeur de RAD Studio de recharger le fichier
    TThread.Queue(nil,
      procedure
      begin
        if Supports(BorlandIDEServices, IOTAActionServices, ActionServices) then
          ActionServices.ReloadFile(AFileName);
      end);
      
    Result := True;
  except
    on E: Exception do
      Log('Erreur d''écriture / migration sur le fichier : ' + E.Message);
  end;
end;

procedure TProjectMigrator.MigrateProject;
var
  ModuleServices: IOTAModuleServices;
  ProjectGroup: IOTAProjectGroup;
  Project: IOTAProject;
  I: Integer;
  ModInfo: IOTAModuleInfo;
  FilesToMigrate: TStringList;
  FileName: string;
  CountSuccess: Integer;
begin
  FilesToMigrate := TStringList.Create;
  try
    Log('Recherche des fichiers du projet actif dans l''IDE...');
    
    if Supports(BorlandIDEServices, IOTAModuleServices, ModuleServices) then
    begin
      ProjectGroup := ModuleServices.MainProjectGroup;
      if Assigned(ProjectGroup) then
      begin
        Project := ProjectGroup.ActiveProject;
        if Assigned(Project) then
        begin
          for I := 0 to Project.GetModuleCount - 1 do
          begin
            ModInfo := Project.GetModule(I);
            FileName := ModInfo.FileName;
            // Ne migrer que les fichiers Pascal et fichiers projets
            if SameText(ExtractFileExt(FileName), '.pas') or SameText(ExtractFileExt(FileName), '.dpr') then
              FilesToMigrate.Add(FileName);
          end;
        end;
      end;
    end;

    if FilesToMigrate.Count = 0 then
    begin
      Log('Aucun fichier source (.pas, .dpr) trouvé dans le projet actif.');
      Exit;
    end;

    Log(Format('Trouvé %d fichier(s) à traiter. Début de la migration...', [FilesToMigrate.Count]));
    CountSuccess := 0;

    for I := 0 to FilesToMigrate.Count - 1 do
    begin
      FileName := FilesToMigrate[I];
      Log(Format('[%d/%d] Migration de : %s...', [I + 1, FilesToMigrate.Count, ExtractFileName(FileName)]));
      
      if MigrateFile(FileName) then
        Inc(CountSuccess)
      else
        Log(Format('[ERREUR] Échec de la migration de : %s', [ExtractFileName(FileName)]));
    end;

    Log(Format('Migration du projet terminée. %d/%d fichiers migrés avec succès !', [CountSuccess, FilesToMigrate.Count]));
    
  finally
    FilesToMigrate.Free;
  end;
end;

end.

unit MustDev.LLM.Logger;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: IDE Logger                                                        }
{  Description: Système de journalisation intégré à la fenêtre Messages      }
{               et écriture dans un fichier log physique horodaté.           }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, ToolsAPI;

type
  TLLMLogger = class
  private
    class var FMessageGroup: IOTAMessageGroup;
    class var FLock: TCriticalSection;
    class procedure EnsureGroupExists;
    class procedure WriteToFile(const APrefix, AMessage: string);
  public
    class constructor Create;
    class destructor Destroy;
    
    class procedure LogInfo(const AMessage: string);
    class procedure LogError(const AMessage: string; const AExceptionMessage: string = '');
    class procedure LogSuccess(const AMessage: string);
  end;

implementation

uses
  System.IOUtils;

{ TLLMLogger }

class constructor TLLMLogger.Create;
begin
  FLock := TCriticalSection.Create;
end;

class destructor TLLMLogger.Destroy;
begin
  FLock.Free;
end;

class procedure TLLMLogger.EnsureGroupExists;
var
  MsgServices: IOTAMessageServices;
begin
  if not Assigned(FMessageGroup) then
  begin
    if Supports(BorlandIDEServices, IOTAMessageServices, MsgServices) then
      FMessageGroup := MsgServices.AddMessageGroup('Must@Dev AI');
  end;
end;

class procedure TLLMLogger.WriteToFile(const APrefix, AMessage: string);
var
  LogDir, LogFile: string;
  LogLine: string;
  Writer: TStreamWriter;
begin
  FLock.Acquire;
  try
    try
      // Création du répertoire Logs dans le dossier utilisateur racine (C:\Users\<Nom>\MustDevLLM)
      LogDir := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), 'MustDevLLM');
      if not TDirectory.Exists(LogDir) then
        TDirectory.CreateDirectory(LogDir);
        
      // Fichier journal horodaté par jour : MustDevLLM_AAAAMMJJ.log
      LogFile := TPath.Combine(LogDir, 'MustDevLLM_' + FormatDateTime('yyyymmdd', Now) + '.log');
      
      // Format : [AAAA-MM-JJ HH:MM:SS] [PREFIXE] Message
      LogLine := Format('[%s] [%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), APrefix, AMessage]);
      
      // Écriture sécurisée et thread-safe dans le fichier log
      Writer := TStreamWriter.Create(LogFile, True, TEncoding.UTF8);
      try
        Writer.WriteLine(LogLine);
      finally
        Writer.Free;
      end;
    except
      // Mode silencieux pour éviter de planter l'IDE en cas d'erreur d'accès disque
    end;
  finally
    FLock.Release;
  end;
end;

class procedure TLLMLogger.LogInfo(const AMessage: string);
var
  MsgServices: IOTAMessageServices;
begin
  WriteToFile('INFO', AMessage);
  
  EnsureGroupExists;
  if Supports(BorlandIDEServices, IOTAMessageServices, MsgServices) then
  begin
    TThread.Queue(nil, TThreadProcedure(
      procedure
      begin
        MsgServices.AddTitleMessage('[' + TimeToStr(Now) + '] INFO : ' + AMessage, FMessageGroup);
      end));
  end;
end;

class procedure TLLMLogger.LogSuccess(const AMessage: string);
var
  MsgServices: IOTAMessageServices;
begin
  WriteToFile('SUCCES', AMessage);
  
  EnsureGroupExists;
  if Supports(BorlandIDEServices, IOTAMessageServices, MsgServices) then
  begin
    TThread.Queue(nil, TThreadProcedure(
      procedure
      begin
        MsgServices.AddTitleMessage('[' + TimeToStr(Now) + '] SUCCÈS : ' + AMessage, FMessageGroup);
      end));
  end;
end;

class procedure TLLMLogger.LogError(const AMessage: string; const AExceptionMessage: string);
var
  MsgServices: IOTAMessageServices;
  FullMsg, FileMsg: string;
begin
  FileMsg := AMessage;
  if AExceptionMessage <> '' then
    FileMsg := FileMsg + ' (' + AExceptionMessage + ')';
    
  WriteToFile('ERREUR', FileMsg);
  
  EnsureGroupExists;
  FullMsg := '[' + TimeToStr(Now) + '] ERREUR : ' + AMessage;
  if AExceptionMessage <> '' then
    FullMsg := FullMsg + ' (' + AExceptionMessage + ')';
    
  if Supports(BorlandIDEServices, IOTAMessageServices, MsgServices) then
  begin
    TThread.Queue(nil, TThreadProcedure(
      procedure
      begin
        MsgServices.AddTitleMessage(FullMsg, FMessageGroup);
      end));
  end;
end;

end.

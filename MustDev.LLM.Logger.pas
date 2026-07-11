unit MustDev.LLM.Logger;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: IDE Logger                                                        }
{  Description: Système de journalisation intégré à la fenêtre Messages.     }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.SysUtils, System.Classes, ToolsAPI;

type
  TLLMLogger = class
  private
    class var FMessageGroup: IOTAMessageGroup;
    class procedure EnsureGroupExists;
  public
    class procedure LogInfo(const AMessage: string);
    class procedure LogError(const AMessage: string; const AExceptionMessage: string = '');
    class procedure LogSuccess(const AMessage: string);
  end;

implementation

{ TLLMLogger }

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

class procedure TLLMLogger.LogInfo(const AMessage: string);
var
  MsgServices: IOTAMessageServices;
begin
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
  FullMsg: string;
begin
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

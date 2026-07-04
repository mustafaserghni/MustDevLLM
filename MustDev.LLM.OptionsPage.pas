unit MustDev.LLM.OptionsPage;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Options Page (OTA)                                                }
{  Description: Intègre le TFrame dans la boîte de dialogue Tools Options.   }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, ToolsAPI, MustDev.LLM.OptionsFrame;

type
  TMustDevOptionsPage = class(TInterfacedObject, INTAAddInOptions)
  private
    FFrame: TLLMOptionsFrame;
  public
    // INTAAddInOptions implementation
    function GetArea: string;
    function GetCaption: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    procedure DialogClosed(Accepted: Boolean);
    function ValidateContents: Boolean;
    function GetHelpContext: Integer;
    function IncludeInIDEInsight: Boolean;
  end;

implementation

{ TMustDevOptionsPage }

function TMustDevOptionsPage.GetArea: string;
begin
  // Utiliser 'ThirdParty' pour s'assurer que la page s'affiche dans la catégorie 
  // "Tierce partie" des nouvelles versions de RAD Studio, car '' peut être ignoré.
  Result := 'ThirdParty'; 
end;

function TMustDevOptionsPage.GetCaption: string;
begin
  Result := 'Must@Dev AI';
end;

function TMustDevOptionsPage.GetFrameClass: TCustomFrameClass;
begin
  Result := TLLMOptionsFrame;
end;

procedure TMustDevOptionsPage.FrameCreated(AFrame: TCustomFrame);
begin
  FFrame := TLLMOptionsFrame(AFrame);
end;

procedure TMustDevOptionsPage.DialogClosed(Accepted: Boolean);
begin
  if Accepted and Assigned(FFrame) then
  begin
    FFrame.btnSaveClick(nil);
  end;
  FFrame := nil;
end;

function TMustDevOptionsPage.ValidateContents: Boolean;
begin
  Result := True;
end;

function TMustDevOptionsPage.GetHelpContext: Integer;
begin
  Result := 0;
end;

function TMustDevOptionsPage.IncludeInIDEInsight: Boolean;
begin
  Result := True;
end;

end.

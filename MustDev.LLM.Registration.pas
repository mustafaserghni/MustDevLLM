unit MustDev.LLM.Registration;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Package Registration                                              }
{  Description: Enregistre les composants de l'extension dans l'IDE.         }
{                                                                            }
{ ************************************************************************** }

interface

procedure Register;

implementation

uses
  System.SysUtils, ToolsAPI, DeskUtil, Vcl.Forms, Vcl.Menus, System.Classes, Vcl.Controls,
  MustDev.LLM.OptionsPage, MustDev.LLM.DockableForm, MustDev.LLM.EditorIntegration,
  MustDev.LLM.OptionsFrame, MustDev.LLM.ProjectManager;

type
  TMustDevMenuHandler = class
  public
    class procedure MenuClick(Sender: TObject);
    class procedure OptionsClick(Sender: TObject);
    class procedure GenerateAgentFilesClick(Sender: TObject);
  end;

var
  MustDevOptions: INTAAddInOptions;
  MustDevMainMenu: TMenuItem;
  MustDevMenuItem: TMenuItem;
  MustDevOptionsMenuItem: TMenuItem;
  MustDevAgentFilesMenuItem: TMenuItem;

{ TMustDevMenuHandler }

class procedure TMustDevMenuHandler.MenuClick(Sender: TObject);
begin
  if not Assigned(DockableLLMForm) then
    DockableLLMForm := TDockableLLMForm.Create(Application);
  DockableLLMForm.Show;
end;

class procedure TMustDevMenuHandler.OptionsClick(Sender: TObject);
var
  FSettingsForm: TForm;
  FFrame: TLLMOptionsFrame;
begin
  FSettingsForm := TForm.Create(nil);
  try
    FSettingsForm.Caption := 'Paramètres Must@Dev AI';
    FSettingsForm.Width := 500;
    FSettingsForm.Height := 460;
    FSettingsForm.Position := poScreenCenter;
    FSettingsForm.BorderStyle := bsDialog;
    
    FFrame := TLLMOptionsFrame.Create(FSettingsForm);
    FFrame.Parent := FSettingsForm;
    FFrame.Align := alClient;
    
    FSettingsForm.ShowModal;
  finally
    FSettingsForm.Free;
  end;
end;

class procedure TMustDevMenuHandler.GenerateAgentFilesClick(Sender: TObject);
begin
  TMustDevProjectManager.GenerateAgentFiles;
end;

procedure Register;
var
  EnvOptions: INTAEnvironmentOptionsServices;
  NTAServices: INTAServices;
begin
  // 1. Enregistrement de la page d'options
  if Supports(BorlandIDEServices, INTAEnvironmentOptionsServices, EnvOptions) then
  begin
    MustDevOptions := TMustDevOptionsPage.Create;
    EnvOptions.RegisterAddInOptions(MustDevOptions);
  end;

  // 2. Enregistrement de la fenêtre ancrable (Dockable Form)
  if @RegisterFieldAddress <> nil then
    RegisterFieldAddress('DockableLLMForm', @DockableLLMForm);

  RegisterDesktopFormClass(TDockableLLMForm, TDockableLLMForm.ClassName, 'MustDevLLMWindow');

  // 3. Menu principal DÉDIÉ dans l'IDE
  if Supports(BorlandIDEServices, INTAServices, NTAServices) then
  begin
    MustDevMainMenu := TMenuItem.Create(nil);
    MustDevMainMenu.Caption := 'Must@Dev';
    
    // A. Lancement de l'assistant
    MustDevMenuItem := TMenuItem.Create(MustDevMainMenu);
    MustDevMenuItem.Caption := 'AI Assistant...';
    MustDevMenuItem.OnClick := TMustDevMenuHandler.MenuClick;
    MustDevMainMenu.Add(MustDevMenuItem);
    
    // B. Génération des fichiers MD Agent
    MustDevAgentFilesMenuItem := TMenuItem.Create(MustDevMainMenu);
    MustDevAgentFilesMenuItem.Caption := 'Générer les fichiers Agent (MD)';
    MustDevAgentFilesMenuItem.OnClick := TMustDevMenuHandler.GenerateAgentFilesClick;
    MustDevMainMenu.Add(MustDevAgentFilesMenuItem);
    
    // Séparateur
    var Separator: TMenuItem := TMenuItem.Create(MustDevMainMenu);
    Separator.Caption := '-';
    MustDevMainMenu.Add(Separator);
    
    // C. Configuration
    MustDevOptionsMenuItem := TMenuItem.Create(MustDevMainMenu);
    MustDevOptionsMenuItem.Caption := 'Configuration...';
    MustDevOptionsMenuItem.OnClick := TMustDevMenuHandler.OptionsClick;
    MustDevMainMenu.Add(MustDevOptionsMenuItem);
    
    if NTAServices.MainMenu.Items.Count > 0 then
      NTAServices.MainMenu.Items.Insert(NTAServices.MainMenu.Items.Count - 1, MustDevMainMenu)
    else
      NTAServices.MainMenu.Items.Add(MustDevMainMenu);
  end;
  
  // 4. Raccourcis Clavier
  RegisterEditorBinding;
end;

initialization
  MustDevOptions := nil;
  MustDevMainMenu := nil;
finalization
  if Assigned(MustDevMainMenu) then
  begin
    MustDevMainMenu.Free;
    MustDevMainMenu := nil;
  end;

  if Assigned(MustDevOptions) and Assigned(BorlandIDEServices) then
  begin
    (BorlandIDEServices as INTAEnvironmentOptionsServices).UnregisterAddInOptions(MustDevOptions);
    MustDevOptions := nil;
  end;
  
  UnregisterEditorBinding;

end.

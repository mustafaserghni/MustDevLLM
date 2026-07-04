unit MustDev.LLM.OptionsFrame;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Options Frame                                                     }
{  Description: TFrame multi-onglets pour la configuration de l'outil.       }
{                                                                            }
{ ************************************************************************** }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TLLMOptionsFrame = class(TFrame)
    PageControl1: TPageControl;
    TabGeneral: TTabSheet;
    TabShortcuts: TTabSheet;
    TabPrompts: TTabSheet;
    rgProviderType: TRadioGroup;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    edtEndpoint: TEdit;
    Label2: TLabel;
    edtApiKey: TEdit;
    Label3: TLabel;
    cbModel: TComboBox;
    btnRefreshModels: TButton;
    LabelCloudType: TLabel;
    cbCloudType: TComboBox;
    btnSave: TButton;
    GroupBox2: TGroupBox;
    Label4: TLabel;
    edtShortcutAutocomplete: TEdit;
    Label5: TLabel;
    edtShortcutRefactor: TEdit;
    GroupBox3: TGroupBox;
    Label6: TLabel;
    memoPromptAutocomplete: TMemo;
    Label7: TLabel;
    memoPromptRefactor: TMemo;
    procedure btnSaveClick(Sender: TObject);
    procedure rgProviderTypeClick(Sender: TObject);
    procedure btnRefreshModelsClick(Sender: TObject);
  private
    procedure LoadSettings;
    procedure SaveSettings;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.dfm}

uses
  MustDev.LLM.Security, MustDev.LLM.Interfaces, MustDev.LLM.LocalSocketProvider, System.Win.Registry;

{ TLLMOptionsFrame }

constructor TLLMOptionsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  LoadSettings;
end;

procedure TLLMOptionsFrame.LoadSettings;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('\Software\MustDev\LLMIntegration\Settings') then
    begin
      // Tab Général
      if Reg.ValueExists('ProviderType') then
        rgProviderType.ItemIndex := Reg.ReadInteger('ProviderType')
      else
        rgProviderType.ItemIndex := 0;
        
      if Reg.ValueExists('Endpoint') then
        edtEndpoint.Text := Reg.ReadString('Endpoint');
        
      if Reg.ValueExists('Model') then
        cbModel.Text := Reg.ReadString('Model');
        
      if Reg.ValueExists('CloudType') then
        cbCloudType.ItemIndex := Reg.ReadInteger('CloudType')
      else
        cbCloudType.ItemIndex := 0;
        
      // Tab Raccourcis
      if Reg.ValueExists('ShortcutAutocomplete') then
        edtShortcutAutocomplete.Text := Reg.ReadString('ShortcutAutocomplete')
      else
        edtShortcutAutocomplete.Text := 'Ctrl+Alt+Space';
        
      if Reg.ValueExists('ShortcutRefactor') then
        edtShortcutRefactor.Text := Reg.ReadString('ShortcutRefactor')
      else
        edtShortcutRefactor.Text := 'Ctrl+Alt+R';
        
      // Tab Prompts
      if Reg.ValueExists('PromptAutocomplete') then
        memoPromptAutocomplete.Text := Reg.ReadString('PromptAutocomplete')
      else
        memoPromptAutocomplete.Text := 'Complète ce code Delphi à partir de la position du curseur. Retourne UNIQUEMENT le code complété, sans aucun texte explicatif ni markdown.';
        
      if Reg.ValueExists('PromptRefactor') then
        memoPromptRefactor.Text := Reg.ReadString('PromptRefactor')
      else
        memoPromptRefactor.Text := 'Tu es un expert Delphi senior. Refactore le code suivant pour l''optimiser, le moderniser (utiliser les inline variables, generics si approprié) et le sécuriser. Retourne UNIQUEMENT le code, sans aucun markdown ni formatage supplémentaire.';
        
      Reg.CloseKey;
    end
    else
    begin
      // Valeurs par défaut si le registre n'existe pas encore
      edtShortcutAutocomplete.Text := 'Ctrl+Alt+Space';
      edtShortcutRefactor.Text := 'Ctrl+Alt+R';
      cbCloudType.ItemIndex := 0;
      memoPromptAutocomplete.Text := 'Complète ce code Delphi à partir de la position du curseur. Retourne UNIQUEMENT le code complété, sans aucun texte explicatif ni markdown.';
      memoPromptRefactor.Text := 'Tu es un expert Delphi senior. Refactore le code suivant pour l''optimiser, le moderniser et le sécuriser. Retourne UNIQUEMENT le code, sans markdown.';
    end;
  finally
    Reg.Free;
  end;
  
  edtApiKey.Text := TSecurityUtils.LoadApiKey('GlobalAPIKey');
  rgProviderTypeClick(nil);
end;

procedure TLLMOptionsFrame.SaveSettings;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('\Software\MustDev\LLMIntegration\Settings', True) then
    begin
      Reg.WriteInteger('ProviderType', rgProviderType.ItemIndex);
      Reg.WriteString('Endpoint', edtEndpoint.Text);
      Reg.WriteString('Model', cbModel.Text);
      Reg.WriteInteger('CloudType', cbCloudType.ItemIndex);
      
      Reg.WriteString('ShortcutAutocomplete', edtShortcutAutocomplete.Text);
      Reg.WriteString('ShortcutRefactor', edtShortcutRefactor.Text);
      
      Reg.WriteString('PromptAutocomplete', memoPromptAutocomplete.Text);
      Reg.WriteString('PromptRefactor', memoPromptRefactor.Text);
      
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
  
  TSecurityUtils.SaveApiKey('GlobalAPIKey', edtApiKey.Text);
end;

procedure TLLMOptionsFrame.btnSaveClick(Sender: TObject);
begin
  SaveSettings;
  ShowMessage('Configuration Must@Dev - AI sauvegardée avec succès.');
end;

procedure TLLMOptionsFrame.rgProviderTypeClick(Sender: TObject);
begin
  if rgProviderType.ItemIndex = 0 then // Local
  begin
    edtApiKey.Enabled := False;
    edtApiKey.Color := clBtnFace;
    cbCloudType.Enabled := False;
    cbCloudType.Color := clBtnFace;
    btnRefreshModels.Enabled := True;
    
    if edtEndpoint.Text = '' then
      edtEndpoint.Text := 'http://127.0.0.1:11434/api/generate';
  end
  else // Cloud
  begin
    edtApiKey.Enabled := True;
    edtApiKey.Color := clWindow;
    cbCloudType.Enabled := True;
    cbCloudType.Color := clWindow;
    btnRefreshModels.Enabled := False;
    
    if edtEndpoint.Text = 'http://127.0.0.1:11434/api/generate' then
      edtEndpoint.Text := 'https://api.openai.com/v1/chat/completions';
  end;
end;

procedure TLLMOptionsFrame.btnRefreshModelsClick(Sender: TObject);
var
  Models: TArray<string>;
  I: Integer;
begin
  if rgProviderType.ItemIndex <> 0 then Exit;
  
  Screen.Cursor := crHourGlass;
  try
    Models := TLocalSocketLLMProvider.FetchModels(edtEndpoint.Text);
    if Length(Models) > 0 then
    begin
      cbModel.Items.Clear;
      for I := Low(Models) to High(Models) do
        cbModel.Items.Add(Models[I]);
        
      if cbModel.Items.Count > 0 then
        cbModel.ItemIndex := 0;
        
      ShowMessage('Modèles locaux récupérés avec succès.');
    end
    else
      ShowMessage('Aucun modèle trouvé. Vérifiez que votre serveur local tourne sur l''URL indiquée.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.

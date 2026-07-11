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
    btnSave: TButton;
    pnlGeneralConfig: TPanel;
    lblEndpoint: TLabel;
    edtEndpoint: TEdit;
    lblApiKey: TLabel;
    edtApiKey: TEdit;
    lblCloudType: TLabel;
    cbCloudType: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    btnRefreshModels: TButton;
    lblQuickProfile: TLabel;
    cbQuickProfile: TComboBox;
    pnlShortcuts: TPanel;
    lblShortcutAutocomplete: TLabel;
    edtShortcutAutocomplete: TEdit;
    lblShortcutRefactor: TLabel;
    edtShortcutRefactor: TEdit;
    pnlPrompts: TPanel;
    lblPromptAutocomplete: TLabel;
    memoPromptAutocomplete: TMemo;
    lblPromptRefactor: TLabel;
    memoPromptRefactor: TMemo;
    lblTitleGeneral: TLabel;
    lblTitleShortcuts: TLabel;
    lblTitlePrompts: TLabel;
    procedure btnSaveClick(Sender: TObject);
    procedure rgProviderTypeClick(Sender: TObject);
    procedure btnRefreshModelsClick(Sender: TObject);
    procedure cbQuickProfileChange(Sender: TObject);
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
  
  // Assignation directe des textes avec accents standards
  TabGeneral.Caption := 'Connexion LLM';
  TabShortcuts.Caption := 'Raccourcis';
  TabPrompts.Caption := 'System Prompts';
  
  lblTitleGeneral.Caption := 'Configuration du fournisseur';
  lblTitleShortcuts.Caption := 'Raccourcis clavier de l''IDE';
  lblTitlePrompts.Caption := 'Prompts Système de l''Assistant';
  
  rgProviderType.Caption := ' Type de fournisseur d''IA ';
  rgProviderType.Items.Clear;
  rgProviderType.Items.Add('Serveur Local (Ollama, LM Studio)');
  rgProviderType.Items.Add('API Cloud (OpenAI, Gemini, Claude)');
  
  lblQuickProfile.Caption := 'Profil Rapide :';
  lblEndpoint.Caption := 'URL de l''API :';
  lblApiKey.Caption := 'Clé API :';
  lblCloudType.Caption := 'API Cloud :';
  lblModel.Caption := 'Modèle :';
  btnRefreshModels.Caption := '🔄 Actualiser';
  
  lblShortcutAutocomplete.Caption := 'Autocomplétion :';
  lblShortcutRefactor.Caption := 'Refactoring :';
  
  lblPromptAutocomplete.Caption := 'Autocomplétion :';
  lblPromptRefactor.Caption := 'Refactoring :';
  
  btnSave.Caption := 'Sauvegarder';
  
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
        
      if Reg.ValueExists('QuickProfile') then
        cbQuickProfile.ItemIndex := Reg.ReadInteger('QuickProfile')
      else
        cbQuickProfile.ItemIndex := -1;
        
      if Reg.ValueExists('ShortcutAutocomplete') then
        edtShortcutAutocomplete.Text := Reg.ReadString('ShortcutAutocomplete')
      else
        edtShortcutAutocomplete.Text := 'Ctrl+Alt+Space';
        
      if Reg.ValueExists('ShortcutRefactor') then
        edtShortcutRefactor.Text := Reg.ReadString('ShortcutRefactor')
      else
        edtShortcutRefactor.Text := 'Ctrl+Alt+R';
        
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
      edtShortcutAutocomplete.Text := 'Ctrl+Alt+Space';
      edtShortcutRefactor.Text := 'Ctrl+Alt+R';
      cbCloudType.ItemIndex := 0;
      cbQuickProfile.ItemIndex := -1;
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
      Reg.WriteInteger('QuickProfile', cbQuickProfile.ItemIndex);
      
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
  end
  else // Cloud
  begin
    edtApiKey.Enabled := True;
    edtApiKey.Color := clWindow;
    cbCloudType.Enabled := True;
    cbCloudType.Color := clWindow;
    btnRefreshModels.Enabled := False;
  end;
end;

procedure TLLMOptionsFrame.cbQuickProfileChange(Sender: TObject);
begin
  cbModel.Items.Clear;
  case cbQuickProfile.ItemIndex of
    0: // Ollama (Local)
      begin
        rgProviderType.ItemIndex := 0;
        edtEndpoint.Text := 'http://127.0.0.1:11434/api/generate';
        edtApiKey.Text := '';
        cbModel.Items.Add('qwen2.5-coder');
        cbModel.Items.Add('llama3');
        cbModel.Items.Add('codellama');
        cbModel.ItemIndex := 0;
      end;
    1: // LM Studio (Local)
      begin
        rgProviderType.ItemIndex := 0;
        edtEndpoint.Text := 'http://127.0.0.1:1234/v1/chat/completions';
        edtApiKey.Text := '';
        cbModel.Text := ''; // Rempli lors du clic sur Actualiser
      end;
    2: // OpenAI (Cloud)
      begin
        rgProviderType.ItemIndex := 1;
        edtEndpoint.Text := 'https://api.openai.com/v1/chat/completions';
        cbCloudType.ItemIndex := 0;
        cbModel.Items.Add('gpt-4o');
        cbModel.Items.Add('gpt-4o-mini');
        cbModel.Items.Add('gpt-4-turbo');
        cbModel.Items.Add('o1-mini');
        cbModel.ItemIndex := 0;
      end;
    3: // Google Gemini (Cloud)
      begin
        rgProviderType.ItemIndex := 1;
        edtEndpoint.Text := 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
        cbCloudType.ItemIndex := 1;
        cbModel.Items.Add('gemini-2.5-flash');
        cbModel.Items.Add('gemini-2.5-pro');
        cbModel.Items.Add('gemini-1.5-flash');
        cbModel.Items.Add('gemini-1.5-pro');
        cbModel.ItemIndex := 0;
      end;
    4: // Anthropic Claude (Cloud)
      begin
        rgProviderType.ItemIndex := 1;
        edtEndpoint.Text := 'https://api.anthropic.com/v1/messages';
        cbCloudType.ItemIndex := 2;
        cbModel.Items.Add('claude-3-5-sonnet-latest');
        cbModel.Items.Add('claude-3-5-haiku-latest');
        cbModel.Items.Add('claude-3-opus-latest');
        cbModel.ItemIndex := 0;
      end;
    5: // Alibaba Qwen (Cloud)
      begin
        rgProviderType.ItemIndex := 1;
        edtEndpoint.Text := 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions';
        cbCloudType.ItemIndex := 0;
        cbModel.Items.Add('qwen-coder-turbo');
        cbModel.Items.Add('qwen-max');
        cbModel.Items.Add('qwen-plus');
        cbModel.Items.Add('qwen-turbo');
        cbModel.ItemIndex := 0;
      end;
    6: // DeepSeek (Cloud)
      begin
        rgProviderType.ItemIndex := 1;
        edtEndpoint.Text := 'https://api.deepseek.com/chat/completions';
        cbCloudType.ItemIndex := 0;
        cbModel.Items.Add('deepseek-chat');
        cbModel.Items.Add('deepseek-coder');
        cbModel.ItemIndex := 0;
      end;
  end;
  rgProviderTypeClick(nil);
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

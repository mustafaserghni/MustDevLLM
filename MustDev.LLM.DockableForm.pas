unit MustDev.LLM.DockableForm;

{$CODEPAGE 65001} // Force le compilateur Delphi à traiter ce fichier source en UTF-8

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Dockable Form                                                     }
{  Description: Fenêtre ancrable de l'IDE pour interagir avec le LLM.        }
{                                                                            }
{ ************************************************************************** }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, 
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.ToolWin, SHDocVw, // SHDocVw pour TWebBrowser
  ToolsAPI, DockForm, MustDev.LLM.Interfaces, MustDev.LLM.Factory;

type
  TDockableLLMForm = class(TDockableForm)
    ToolBar1: TToolBar;
    btnSettings: TToolButton;
    btnClearHistory: TToolButton;
    btnSeparator: TToolButton;
    cbChatMode: TComboBox;
    lblSource: TLabel;
    pnlTop: TPanel;
    richChat: TRichEdit;
    Splitter1: TSplitter;
    pnlBottom: TPanel;
    memoPrompt: TMemo;
    btnAsk: TButton;
    chkOptimizeContext: TCheckBox;
    procedure btnAskClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnClearHistoryClick(Sender: TObject);
    procedure cbChatModeChange(Sender: TObject);
  private
    FProvider: ILLMProvider;
    FWebChat: TWebBrowser; // Navigateur créé dynamiquement à l'exécution
    procedure InitProvider;
    procedure AddChatMsg(const ASender, AMessage: string; IsUser: Boolean);
    procedure SetUIBusy(IsBusy: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  DockableLLMForm: TDockableLLMForm;

implementation

{$R *.dfm}

uses
  System.Win.Registry, MustDev.LLM.Security, MustDev.LLM.OptionsFrame, 
  MustDev.LLM.Logger, MustDev.LLM.PromptOptimizer;

{ TDockableLLMForm }

constructor TDockableLLMForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DeskSection := 'MustDevLLMWindow';
  AutoSave := True;
  SaveStateNecessary := True;
end;

procedure TDockableLLMForm.FormCreate(Sender: TObject);
var
  Reg: TRegistry;
  LMode: Integer;
begin
  Caption := 'Must@Dev - AI Assistant';
  
  // Création dynamique du TWebBrowser pour éviter les erreurs d'ActiveX blobs dans le DFM
  FWebChat := TWebBrowser.Create(Self);
  FWebChat.Parent := Self;
  FWebChat.Align := alClient;
  FWebChat.Visible := False;
  
  // Configuration du moteur Edge Chromium (WebView2)
  try
    FWebChat.WindowsEngine := TWindowsEngine.EdgeOnly;
  except
    on E: Exception do
      TLLMLogger.LogError('Impossible d''initialiser le moteur Edge Chromium (WebView2)', E);
  end;

  // Actions de la barre d'outils
  btnSettings.Caption := ' ⚙️ Paramètres ';
  btnClearHistory.Caption := ' 🗑️ Nouvelle conversation ';
  
  lblSource.Caption := 'Source : Non initialisé';
  chkOptimizeContext.Caption := 'Optimiser le prompt avec le contexte (Agents.md)';
  btnAsk.Caption := 'Envoyer';
  
  richChat.Clear;
  richChat.Font.Name := 'Segoe UI';
  richChat.Font.Size := 10;

  // Remplissage du ComboBox du mode Chat
  cbChatMode.Items.Clear;
  cbChatMode.Items.Add('Mode API (Clé de sécurité)');
  cbChatMode.Items.Add('ChatGPT (Compte)');
  cbChatMode.Items.Add('Google Gemini (Compte)');
  cbChatMode.Items.Add('Anthropic Claude (Compte)');
  
  // Chargement du dernier mode sauvegardé
  LMode := 0;
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('\Software\MustDev\LLMIntegration\Settings') then
    begin
      if Reg.ValueExists('ChatMode') then
        LMode := Reg.ReadInteger('ChatMode');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
  
  cbChatMode.ItemIndex := LMode;
  cbChatModeChange(nil);
end;

procedure TDockableLLMForm.cbChatModeChange(Sender: TObject);
var
  Reg: TRegistry;
begin
  // Sauvegarde du mode sélectionné
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('\Software\MustDev\LLMIntegration\Settings', True) then
    begin
      Reg.WriteInteger('ChatMode', cbChatMode.ItemIndex);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;

  // Basculement de l'UI
  if cbChatMode.ItemIndex = 0 then
  begin
    // Mode API : Afficher le chat natif
    FWebChat.Visible := False;
    
    richChat.Visible := True;
    Splitter1.Visible := True;
    pnlBottom.Visible := True;
    pnlTop.Visible := True;
    btnClearHistory.Enabled := True;
    
    InitProvider;
  end
  else
  begin
    // Mode Web : Cacher le chat natif et afficher le WebBrowser Edge
    richChat.Visible := False;
    Splitter1.Visible := False;
    pnlBottom.Visible := False;
    pnlTop.Visible := False;
    btnClearHistory.Enabled := False;
    
    FWebChat.Visible := True;
    
    // Navigation vers la page officielle
    case cbChatMode.ItemIndex of
      1: FWebChat.Navigate('https://chatgpt.com');
      2: FWebChat.Navigate('https://gemini.google.com');
      3: FWebChat.Navigate('https://claude.ai');
    end;
  end;
end;

procedure TDockableLLMForm.InitProvider;
var
  Reg: TRegistry;
  LType: TProviderType;
  LCloudType: Integer;
  LEndpoint, LApiKey, LModel: string;
begin
  LType := ptLocalSocket;
  LCloudType := 0;
  LEndpoint := '';
  LModel := '';
  
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('\Software\MustDev\LLMIntegration\Settings') then
    begin
      if Reg.ValueExists('ProviderType') then
        LType := TProviderType(Reg.ReadInteger('ProviderType'));
      if Reg.ValueExists('CloudType') then
        LCloudType := Reg.ReadInteger('CloudType');
      if Reg.ValueExists('Endpoint') then
        LEndpoint := Reg.ReadString('Endpoint');
      if Reg.ValueExists('Model') then
        LModel := Reg.ReadString('Model');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
  
  LApiKey := TSecurityUtils.LoadApiKey('GlobalAPIKey');
  FProvider := TLLMProviderFactory.CreateProvider(LType, LEndpoint, LApiKey, LModel, LCloudType);
  
  if FProvider.ProviderType = ptLocalSocket then
    lblSource.Caption := 'Source : Local Socket (' + FProvider.ModelName + ')'
  else
    lblSource.Caption := 'Source : Cloud REST (' + FProvider.ModelName + ')';
end;

procedure TDockableLLMForm.AddChatMsg(const ASender, AMessage: string; IsUser: Boolean);
begin
  richChat.SelStart := Length(richChat.Text);
  richChat.SelAttributes.Style := [fsBold];
  
  if ASender = 'Système' then
    richChat.SelAttributes.Color := clGray
  else if IsUser then
    richChat.SelAttributes.Color := clHighlight
  else
    richChat.SelAttributes.Color := clGreen;
    
  richChat.Lines.Add(ASender + ' :');
  
  richChat.SelStart := Length(richChat.Text);
  richChat.SelAttributes.Style := [];
  richChat.SelAttributes.Color := clWindowText;
  richChat.Lines.Add(AMessage);
  richChat.Lines.Add(''); // Espacement
  
  // Scroller en bas
  SendMessage(richChat.Handle, EM_LINESCROLL, 0, richChat.Lines.Count);
end;

procedure TDockableLLMForm.SetUIBusy(IsBusy: Boolean);
begin
  btnAsk.Enabled := not IsBusy;
  memoPrompt.Enabled := not IsBusy;
  btnClearHistory.Enabled := not IsBusy;
  cbChatMode.Enabled := not IsBusy;
  if IsBusy then
  begin
    btnAsk.Caption := 'Patience...';
    Screen.Cursor := crHourGlass;
  end
  else
  begin
    btnAsk.Caption := 'Envoyer';
    Screen.Cursor := crDefault;
  end;
end;

procedure TDockableLLMForm.btnAskClick(Sender: TObject);
var
  UserPrompt: string;
  OptimizeContext: Boolean;
begin
  if Trim(memoPrompt.Text) = '' then Exit;
  
  if not Assigned(FProvider) then
    InitProvider;
    
  if not Assigned(FProvider) then
  begin
    ShowMessage('Veuillez configurer l''extension Must@Dev LLM dans les paramètres.');
    Exit;
  end;
  
  UserPrompt := memoPrompt.Text;
  AddChatMsg('Vous', UserPrompt, True);
  memoPrompt.Clear;
  SetUIBusy(True);
  
  TLLMLogger.LogInfo('Requête LLM déclenchée depuis le Chat (Asynchrone)...');
  OptimizeContext := chkOptimizeContext.Checked;
  
  // Multithreading : Exécution en arrière-plan
  TThread.CreateAnonymousThread(
    procedure
    var
      ResponseText, FinalPrompt: string;
    begin
      try
        if OptimizeContext then
          FinalPrompt := TPromptOptimizer.Optimize(UserPrompt, '')
        else
          FinalPrompt := UserPrompt;
          
        ResponseText := FProvider.Ask(FinalPrompt, True);
        
        System.Classes.TThread.Queue(
          procedure
          begin
            AddChatMsg('Must@Dev AI', ResponseText, False);
            SetUIBusy(False);
            TLLMLogger.LogSuccess('Réponse du Chat reçue.');
          end);
      except
        on E: Exception do
        begin
          System.Classes.TThread.Queue(
            procedure
            begin
              AddChatMsg('Erreur', E.Message, False);
              SetUIBusy(False);
              TLLMLogger.LogError('Erreur de réponse LLM dans le Chat', E);
            end);
        end;
      end;
    end).Start;
end;

procedure TDockableLLMForm.btnClearHistoryClick(Sender: TObject);
begin
  if not Assigned(FProvider) then
    InitProvider;
    
  if Assigned(FProvider) then
    FProvider.ClearHistory;
    
  richChat.Clear;
  AddChatMsg('Système', 'Historique de la conversation effacé.', False);
  TLLMLogger.LogInfo('Historique de conversation effacé.');
end;

procedure TDockableLLMForm.btnSettingsClick(Sender: TObject);
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
  
  InitProvider;
end;

end.

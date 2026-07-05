unit MustDev.LLM.DockableForm;

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
  Vcl.ComCtrls, Vcl.ToolWin,
  ToolsAPI, DockForm, MustDev.LLM.Interfaces, MustDev.LLM.Factory;

type
  TDockableLLMForm = class(TDockableForm)
    ToolBar1: TToolBar;
    btnSettings: TToolButton;
    btnClearHistory: TToolButton;
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
  private
    FProvider: ILLMProvider;
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
begin
  Caption := 'Must@Dev - AI Assistant';
  
  // Raccourcis / Actions de la barre d'outils
  btnSettings.Caption := ' '#$2699' Param'#232'tres ';
  btnClearHistory.Caption := ' '#$D83D#$DDD1' Nouvelle conversation ';
  
  lblSource.Caption := 'Source : Non initialis'#233;';
  chkOptimizeContext.Caption := 'Optimiser le prompt avec le contexte (Agents.md)';
  btnAsk.Caption := 'Envoyer';
  
  richChat.Clear;
  richChat.Font.Name := 'Segoe UI';
  richChat.Font.Size := 10;
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
        // Si l'optimisation est activée, on injecte les fichiers Agent et règles Delphi
        if OptimizeContext then
          FinalPrompt := TPromptOptimizer.Optimize(UserPrompt, '')
        else
          FinalPrompt := UserPrompt;
          
        // Envoi avec AKeepHistory = True pour conserver la mémoire de la conversation
        ResponseText := FProvider.Ask(FinalPrompt, True);
        
        TThread.Queue(nil,
          procedure
          begin
            AddChatMsg('Must@Dev AI', ResponseText, False);
            SetUIBusy(False);
            TLLMLogger.LogSuccess('Réponse du Chat reçue.');
          end);
      except
        on E: Exception do
        begin
          TThread.Queue(nil,
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

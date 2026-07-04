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
    lblSource: TLabel;
    pnlTop: TPanel;
    richChat: TRichEdit;
    Splitter1: TSplitter;
    pnlBottom: TPanel;
    memoPrompt: TMemo;
    btnAsk: TButton;
    procedure btnAskClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
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
  lblSource.Caption := 'Source : Non initialisé';
  richChat.Clear;
  richChat.Font.Name := 'Consolas';
  richChat.Font.Size := 10;
end;

procedure TDockableLLMForm.InitProvider;
var
  Reg: TRegistry;
  LType: TProviderType;
  LEndpoint, LApiKey, LModel: string;
begin
  LType := ptLocalSocket;
  LEndpoint := '';
  LModel := '';
  
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('\Software\MustDev\LLMIntegration\Settings') then
    begin
      if Reg.ValueExists('ProviderType') then
        LType := TProviderType(Reg.ReadInteger('ProviderType'));
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
  FProvider := TLLMProviderFactory.CreateProvider(LType, LEndpoint, LApiKey, LModel);
  
  if FProvider.ProviderType = ptLocalSocket then
    lblSource.Caption := 'Source : Local Socket (' + FProvider.ModelName + ')'
  else
    lblSource.Caption := 'Source : Cloud REST (' + FProvider.ModelName + ')';
end;

procedure TDockableLLMForm.AddChatMsg(const ASender, AMessage: string; IsUser: Boolean);
begin
  richChat.SelStart := Length(richChat.Text);
  richChat.SelAttributes.Style := [fsBold];
  if IsUser then
    richChat.SelAttributes.Color := clBlue
  else
    richChat.SelAttributes.Color := clGreen;
    
  richChat.Lines.Add(ASender + ' :');
  
  richChat.SelStart := Length(richChat.Text);
  richChat.SelAttributes.Style := [];
  richChat.SelAttributes.Color := clWindowText;
  richChat.Lines.Add(AMessage);
  richChat.Lines.Add(''); // Ligne vide d'espacement
  
  // Scroller en bas
  SendMessage(richChat.Handle, EM_LINESCROLL, 0, richChat.Lines.Count);
end;

procedure TDockableLLMForm.SetUIBusy(IsBusy: Boolean);
begin
  btnAsk.Enabled := not IsBusy;
  memoPrompt.Enabled := not IsBusy;
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
begin
  if Trim(memoPrompt.Text) = '' then Exit;
  
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
  
  // Multithreading : Ne bloque pas l'IDE !
  TThread.CreateAnonymousThread(
    procedure
    var
      ResponseText, OptimizedPrompt: string;
    begin
      try
        OptimizedPrompt := TPromptOptimizer.Optimize(UserPrompt, '');
        ResponseText := FProvider.Ask(OptimizedPrompt);
        
        // Synchronisation avec le thread principal VCL pour mettre à jour l'UI
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

procedure TDockableLLMForm.btnSettingsClick(Sender: TObject);
var
  FSettingsForm: TForm;
  FFrame: TLLMOptionsFrame;
begin
  FSettingsForm := TForm.Create(nil);
  try
    FSettingsForm.Caption := 'Paramètres Must@Dev AI';
    FSettingsForm.Width := 480;
    FSettingsForm.Height := 400;
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

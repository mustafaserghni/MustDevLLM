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
  Vcl.ComCtrls, Vcl.ToolWin, SHDocVw, // SHDocVw pour TWebBrowser
  ToolsAPI, MustDev.LLM.Interfaces, MustDev.LLM.Factory;

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
    pnlInputActions: TPanel;
    chkOptimizeContext: TCheckBox;
    procedure btnAskClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnClearHistoryClick(Sender: TObject);
    procedure cbChatModeChange(Sender: TObject);
  private
    FProvider: ILLMProvider;
    FWebChat: TWebBrowser; // Navigateur créé dynamiquement sur demande (Lazy)
    
    // Composants d'interface créés dynamiquement pour éviter les problèmes DFM
    cbQuickActions: TComboBox;
    chkIncludeActiveUnit: TCheckBox;
    
    procedure InitProvider;
    procedure AddChatMsg(const ASender, AMessage: string; IsUser: Boolean);
    procedure SetUIBusy(IsBusy: Boolean);
    procedure TrySetEdgeEngine;
    
    // Actions rapides sur le code Delphi
    procedure cbQuickActionsChange(Sender: TObject);
    // Récupération de l'unité de travail actuelle dans l'éditeur de l'IDE
    function GetActiveEditorCode(out AFileName: string): string;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  DockableLLMForm: TDockableLLMForm;

implementation

{$R *.dfm}

uses
  System.Win.Registry, Winapi.ShellAPI, System.Rtti, MustDev.LLM.Security, MustDev.LLM.OptionsFrame, 
  MustDev.LLM.Logger, MustDev.LLM.PromptOptimizer;

{ TDockableLLMForm }

constructor TDockableLLMForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DeskSection := 'MustDevLLMWindow';
  AutoSave := True;
  SaveStateNecessary := True;
  FWebChat := nil;
end;

procedure TDockableLLMForm.TrySetEdgeEngine;
var
  Context: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
begin
  if not Assigned(FWebChat) then Exit;
  
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(FWebChat.ClassType);
    if Assigned(RttiType) then
    begin
      Prop := RttiType.GetProperty('WindowsEngine');
      // Sécurité : Vérifier également que PropertyType est bien assigné pour éviter un Access Violation RTTI
      if Assigned(Prop) and Prop.IsWritable and Assigned(Prop.PropertyType) then
      begin
        // TWindowsEngine.EdgeOnly a la valeur ordinale 2
        Prop.SetValue(FWebChat, TValue.FromOrdinal(Prop.PropertyType.Handle, 2));
        TLLMLogger.LogInfo('Moteur Edge Chromium (WebView2) forcé avec succès via RTTI.');
      end;
    end;
  except
    on E: Exception do
      TLLMLogger.LogError('Impossible de forcer le moteur Edge (WebView2) via RTTI', E);
  end;
end;

function TDockableLLMForm.GetActiveEditorCode(out AFileName: string): string;
var
  EditorServices: IOTAEditorServices;
  EditBuffer: IOTAEditBuffer;
  Reader: IOTAEditReader;
  BytesRead, ChunkRead: Integer;
  Buf: array[0..4095] of AnsiChar;
  RawText: AnsiString;
begin
  Result := '';
  AFileName := '';
  RawText := '';
  
  if Supports(BorlandIDEServices, IOTAEditorServices, EditorServices) then
  begin
    EditBuffer := EditorServices.TopBuffer;
    if Assigned(EditBuffer) then
    begin
      AFileName := ExtractFileName(EditBuffer.FileName);
      Reader := EditBuffer.CreateReader;
      if Assigned(Reader) then
      begin
        BytesRead := 0;
        repeat
          ChunkRead := Reader.GetText(BytesRead, Buf, Length(Buf) - 1);
          if ChunkRead > 0 then
          begin
            Buf[ChunkRead] := #0;
            RawText := RawText + AnsiString(Buf);
            Inc(BytesRead, ChunkRead);
          end;
        until ChunkRead = 0;
      end;
    end;
  end;
  
  if RawText <> '' then
  begin
    // Décodage UTF-8 natif si possible, sinon ANSI standard
    Result := UTF8ToString(RawText);
    if Result = '' then
      Result := string(RawText);
  end;
end;

procedure TDockableLLMForm.FormCreate(Sender: TObject);
var
  Reg: TRegistry;
  LMode: Integer;
begin
  Caption := 'Must@Dev - AI Assistant';
  
  // Actions de la barre d'outils
  btnSettings.Caption := ' ⚙️ Paramètres ';
  btnClearHistory.Caption := ' 🗑️ Nouvelle conversation ';
  
  lblSource.Caption := 'Source : Non initialisé';
  btnAsk.Caption := 'Envoyer';
  
  richChat.Clear;
  richChat.Font.Name := 'Segoe UI';
  richChat.Font.Size := 10;

  // Configuration dynamique des options de prompt dans pnlInputActions
  chkOptimizeContext.Caption := 'Contextes projet (Agents.md)';
  chkOptimizeContext.Width := 200;
  chkOptimizeContext.Left := 8;
  
  // Création du checkbox d'unité active de travail
  chkIncludeActiveUnit := TCheckBox.Create(Self);
  chkIncludeActiveUnit.Parent := pnlInputActions;
  chkIncludeActiveUnit.Caption := 'Inclure l''unité active de l''IDE';
  chkIncludeActiveUnit.Width := 200;
  chkIncludeActiveUnit.Left := 215;
  chkIncludeActiveUnit.Top := 6;
  chkIncludeActiveUnit.Checked := True;
  chkIncludeActiveUnit.Anchors := [akLeft, akTop];

  // Création du ComboBox d'actions rapides sur le code Delphi
  cbQuickActions := TComboBox.Create(Self);
  cbQuickActions.Parent := pnlInputActions;
  cbQuickActions.Style := csDropDownList;
  cbQuickActions.Width := 260;
  cbQuickActions.Height := 23;
  cbQuickActions.Left := pnlInputActions.Width - cbQuickActions.Width - 10;
  cbQuickActions.Top := 3;
  cbQuickActions.Anchors := [akRight, akTop];
  
  cbQuickActions.Items.Add('-- Actions rapides sur le code --');
  cbQuickActions.Items.Add('Expliquer le code sélectionné / actif');
  cbQuickActions.Items.Add('Rechercher des bugs ou fuites');
  cbQuickActions.Items.Add('Générer des tests unitaires DUnitX');
  cbQuickActions.Items.Add('Générer la documentation XMLDoc');
  cbQuickActions.Items.Add('Optimiser les performances et la mémoire');
  cbQuickActions.Items.Add('Moderniser le code (inline vars, generics)');
  cbQuickActions.ItemIndex := 0;
  cbQuickActions.OnChange := cbQuickActionsChange;

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

procedure TDockableLLMForm.cbQuickActionsChange(Sender: TObject);
begin
  case cbQuickActions.ItemIndex of
    1: memoPrompt.Text := 'Explique de manière synthétique ce code Delphi. Donne les points clés de sa logique, ses dépendances et son utilité.';
    2: memoPrompt.Text := 'Analyse ce code Delphi à la recherche de bugs potentiels (fuites de mémoire, non-libération d''objets, exceptions non gérées, index hors limites, variables non initialisées) et propose des corrections.';
    3: memoPrompt.Text := 'Génère une classe de tests unitaires DUnitX complète et moderne pour tester les fonctions ou méthodes de ce code. Inclus les Setup, TearDown et des assertions précises.';
    4: memoPrompt.Text := 'Ajoute des commentaires de documentation XML structurés (XMLDoc avec <summary>, <param>, <returns>, <exception>) au-dessus de chaque méthode de ce code Delphi.';
    5: memoPrompt.Text := 'Propose des optimisations de performance et de gestion mémoire pour ce code Delphi (réduction des allocations, passage de paramètres en const, utilisation de boucles optimisées).';
    6: memoPrompt.Text := 'Refactore ce code Delphi pour le moderniser selon les standards récents : utilise des inline variables, déclare les boucles ''for var i'', emploie des Generics (TList, TDictionary) si approprié, et sécurise la destruction.';
  end;
  
  if cbQuickActions.ItemIndex > 0 then
  begin
    memoPrompt.SetFocus;
    memoPrompt.SelStart := Length(memoPrompt.Text);
  end;
end;

procedure TDockableLLMForm.cbChatModeChange(Sender: TObject);
var
  Reg: TRegistry;
  TargetURL: string;
  HasEdgeProp: Boolean;
  Context: TRttiContext;
  RttiType: TRttiType;
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
    if Assigned(FWebChat) then
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
    // Mode Web : Cacher le chat natif
    richChat.Visible := False;
    Splitter1.Visible := False;
    pnlBottom.Visible := False;
    pnlTop.Visible := False;
    btnClearHistory.Enabled := False;
    
    // Détermination de l'URL cible
    case cbChatMode.ItemIndex of
      1: TargetURL := 'https://chatgpt.com';
      2: TargetURL := 'https://gemini.google.com';
      3: TargetURL := 'https://claude.ai';
    else
      TargetURL := '';
    end;

    // Initialisation LAZY du TWebBrowser (seulement à la demande et après affichage de la fiche)
    if not Assigned(FWebChat) then
    begin
      try
        FWebChat := TWebBrowser.Create(Self);
        TWinControl(FWebChat).Parent := Self;
        FWebChat.Align := alClient;
        FWebChat.Visible := False;
        
        // Configuration dynamique du moteur Edge Chromium
        TrySetEdgeEngine;
      except
        on E: Exception do
          TLLMLogger.LogError('Erreur d''instanciation du navigateur', E);
      end;
    end;

    if Assigned(FWebChat) then
    begin
      // Détection dynamique si la propriété WindowsEngine existe (Delphi >= 10.4)
      HasEdgeProp := False;
      Context := TRttiContext.Create;
      try
        RttiType := Context.GetType(FWebChat.ClassType);
        if Assigned(RttiType) and Assigned(RttiType.GetProperty('WindowsEngine')) then
          HasEdgeProp := True;
      except
        HasEdgeProp := False;
      end;

      // Si on est sur une ancienne version de Delphi (sans support Edge Chromium), 
      // on ouvre dans le navigateur externe pour éviter les plantages d'Internet Explorer
      if not HasEdgeProp then
      begin
        if TargetURL <> '' then
        begin
          cbChatMode.ItemIndex := 0; // Repasse en mode API dans l'IHM
          cbChatModeChange(nil);
          ShellExecute(0, 'open', PChar(TargetURL), nil, nil, SW_SHOWNORMAL);
          TLLMLogger.LogInfo('Ouverture du navigateur externe pour : ' + TargetURL);
        end;
      end
      else
      begin
        // Version moderne : utilisation de WebView2 intégré
        FWebChat.Visible := True;
        if TargetURL <> '' then
          FWebChat.Navigate(TargetURL);
      end;
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
  cbQuickActions.Enabled := not IsBusy;
  chkIncludeActiveUnit.Enabled := not IsBusy;
  chkOptimizeContext.Enabled := not IsBusy;
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
  LocalProvider: ILLMProvider; // Copie locale pour garantir la thread-safety
  ActiveFileCode, ActiveFileName: string;
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
  
  // Rétablissement de la liste déroulante des actions
  cbQuickActions.ItemIndex := 0;
  
  SetUIBusy(True);
  
  TLLMLogger.LogInfo('Requête LLM déclenchée depuis le Chat (Asynchrone)...');
  OptimizeContext := chkOptimizeContext.Checked;
  
  // Récupération de l'unité active de l'IDE en tant qu'unité de travail
  ActiveFileCode := '';
  ActiveFileName := '';
  if chkIncludeActiveUnit.Checked then
  begin
    ActiveFileCode := GetActiveEditorCode(ActiveFileName);
    if ActiveFileCode <> '' then
      ActiveFileCode := '// Unite de travail actuelle dans l''editeur de l''IDE : ' + ActiveFileName + sLineBreak + ActiveFileCode;
  end;
  
  LocalProvider := FProvider; // Incrémente le compteur de références et protège l'instance dans le thread
  
  // Multithreading : Exécution en arrière-plan
  TThread.CreateAnonymousThread(
    procedure
    var
      ResponseText, FinalPrompt: string;
    begin
      try
        if OptimizeContext then
          FinalPrompt := TPromptOptimizer.Optimize(UserPrompt, ActiveFileCode)
        else if ActiveFileCode <> '' then
          // Si on n'optimise pas via les agents globaux mais qu'on veut injecter le code
          FinalPrompt := UserPrompt + sLineBreak + sLineBreak + 
                         '=== CONTEXTE DE L''UNITE ACTIVE ===' + sLineBreak + 
                         '```pascal' + sLineBreak + ActiveFileCode + sLineBreak + '```'
        else
          FinalPrompt := UserPrompt;
          
        ResponseText := LocalProvider.Ask(FinalPrompt, True);
        
        // Cast explicite TThreadProcedure pour lever toute ambiguïté de surcharge de Queue
        System.Classes.TThread.Queue(nil, TThreadProcedure(
          procedure
          begin
            AddChatMsg('Must@Dev AI', ResponseText, False);
            SetUIBusy(False);
            TLLMLogger.LogSuccess('Réponse du Chat reçue.');
          end));
      except
        on E: Exception do
        begin
          var ErrMsg := E.Message;
          System.Classes.TThread.Queue(nil, TThreadProcedure(
            procedure
            begin
              AddChatMsg('Erreur', ErrMsg, False);
              SetUIBusy(False);
              TLLMLogger.LogError('Erreur de réponse LLM dans le Chat', ErrMsg);
            end));
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

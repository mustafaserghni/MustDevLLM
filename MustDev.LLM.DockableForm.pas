unit MustDev.LLM.DockableForm;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Dockable Form                                                     }
{  Description: Fenêtre ancrable de l'IDE pour interagir avec le LLM.        }
{               Interface utilisateur moderne, adaptative et thématisée.     }
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
    cbAgents: TComboBox;
    btnInsertCode: TToolButton;
    btnCreateUnit: TToolButton;
    btnAttach: TToolButton;
    FAttachments: TStringList;
    
    procedure InitProvider;
    procedure AddChatMsg(const ASender, AMessage: string; IsUser: Boolean);
    procedure SetUIBusy(IsBusy: Boolean);
    procedure TrySetEdgeEngine;
    
    // Actions rapides sur le code Delphi
    procedure cbQuickActionsChange(Sender: TObject);
    // Récupération de l'unité de travail actuelle dans l'éditeur de l'IDE
    // Pièces jointes
    procedure btnAttachClick(Sender: TObject);
    function GetActiveEditorCode(out AFileName: string): string;
    
    // Chargement de la liste des agents standard et utilisateur (*.md)
    procedure InitAgentsList;
    
    // Extraction intelligente du code du Chat pour insertion/création
    function GetTextToInteract: string;
    procedure btnInsertCodeClick(Sender: TObject);
    procedure btnCreateUnitClick(Sender: TObject);
    
    // Application dynamique du thème de l'IDE de l'utilisateur (Clair / Sombre)
    function IsIDEDarkMode: Boolean;
    procedure ApplyIDETheme;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  DockableLLMForm: TDockableLLMForm;

implementation

{$R *.dfm}

uses
  System.Win.Registry, Winapi.ShellAPI, System.Rtti, System.IOUtils, Vcl.Themes, 
  MustDev.LLM.Security, MustDev.LLM.OptionsFrame, MustDev.LLM.Logger, 
  MustDev.LLM.PromptOptimizer, MustDev.LLM.ProjectManager, MustDev.LLM.AgentOrchestrator,
  MustDev.LLM.ProjectMigrator;

type
  // Implémentation requise de IOTAFile pour fournir le code source du fichier créé
  TMustDevFile = class(TInterfacedObject, IOTAFile)
  private
    FSource: string;
  public
    constructor Create(const ASource: string);
    function GetSource: string;
    function GetAge: TDateTime;
  end;

  // Implémentation de IOTAModuleCreator pour créer une nouvelle unité dans RAD Studio
  TMustDevUnitCreator = class(TInterfacedObject, IOTACreator, IOTAModuleCreator)
  private
    FSourceCode: string;
  public
    constructor Create(const ASourceCode: string);
    // IOTACreator
    function GetCreatorType: string;
    function GetExisting: Boolean;
    function GetFileSystem: string;
    function GetOwner: IOTAModule;
    function GetUnnamed: Boolean;
    // IOTAModuleCreator
    function GetAncestorName: string;
    function GetImplFileName: string;
    function GetIntfFileName: string;
    function GetFormName: string;
    function GetMainForm: Boolean;
    function GetShowForm: Boolean;
    function GetShowSource: Boolean;
    function NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
    function NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    function NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
    procedure FormCreated(const FormEditor: IOTAFormEditor);
  end;

{ TMustDevFile }

constructor TMustDevFile.Create(const ASource: string);
begin
  inherited Create;
  FSource := ASource;
end;

function TMustDevFile.GetSource: string;
begin
  Result := FSource;
end;

function TMustDevFile.GetAge: TDateTime;
begin
  Result := -1; // Indique un fichier virtuel non sauvegardé
end;

{ TMustDevUnitCreator }

constructor TMustDevUnitCreator.Create(const ASourceCode: string);
begin
  inherited Create;
  FSourceCode := ASourceCode;
end;

function TMustDevUnitCreator.GetCreatorType: string;
begin
  Result := 'Unit'; // Type de créateur : Unité Pascal (.pas)
end;

function TMustDevUnitCreator.GetExisting: Boolean;
begin
  Result := False;
end;

function TMustDevUnitCreator.GetFileSystem: string;
begin
  Result := ''; // Utiliser le système de fichiers par défaut de l'IDE
end;

function TMustDevUnitCreator.GetOwner: IOTAModule;
begin
  Result := nil; // Pas de module propriétaire spécifique
end;

function TMustDevUnitCreator.GetUnnamed: Boolean;
begin
  Result := True; // Créer le fichier en tant que "Untitled" (ex: Unit2.pas)
end;

function TMustDevUnitCreator.GetAncestorName: string;
begin
  Result := '';
end;

function TMustDevUnitCreator.GetImplFileName: string;
begin
  Result := '';
end;

// Alias pour compatibilité ToolsAPI moderne / héritée
function TMustDevUnitCreator.NewImplSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := TMustDevFile.Create(FSourceCode);
end;

function TMustDevUnitCreator.NewIntfSource(const ModuleIdent, FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

function TMustDevUnitCreator.GetIntfFileName: string;
begin
  Result := '';
end;

function TMustDevUnitCreator.GetFormName: string;
begin
  Result := '';
end;

function TMustDevUnitCreator.GetMainForm: Boolean;
begin
  Result := False;
end;

// Méthodes requises par l'interface IOTAModuleCreator
function TMustDevUnitCreator.GetShowForm: Boolean;
begin
  Result := False;
end;

function TMustDevUnitCreator.GetShowSource: Boolean;
begin
  Result := True; // Ouvrir l'éditeur de code automatiquement
end;

procedure TMustDevUnitCreator.FormCreated(const FormEditor: IOTAFormEditor);
begin
end;

function TMustDevUnitCreator.NewFormFile(const FormIdent, AncestorIdent: string): IOTAFile;
begin
  Result := nil;
end;

{ TDockableLLMForm }

constructor TDockableLLMForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DeskSection := 'MustDevLLMWindow';
  AutoSave := True;
  SaveStateNecessary := True;
  FWebChat := nil;
  FAttachments := TStringList.Create;
end;

destructor TDockableLLMForm.Destroy;
begin
  FAttachments.Free;
  inherited Destroy;
end;

function TDockableLLMForm.IsIDEDarkMode: Boolean;
var
  LColor: TColor;
  RGBVal: Cardinal;
  R, G, B: Byte;
begin
  Result := False;
  try
    if Assigned(TStyleManager.ActiveStyle) then
    begin
      // Récupération de la couleur système de la fenêtre sous le style VCL actif de l'IDE
      LColor := TStyleManager.ActiveStyle.GetSystemColor(clWindow);
      RGBVal := ColorToRGB(LColor);
      R := GetRValue(RGBVal);
      G := GetGValue(RGBVal);
      B := GetBValue(RGBVal);
      // Formule de luminosité relative Y = 0.299*R + 0.587*G + 0.114*B
      Result := (0.299 * R + 0.587 * G + 0.114 * B) < 128;
    end;
  except
    Result := False;
  end;
end;

procedure TDockableLLMForm.ApplyIDETheme;
var
  IsDark: Boolean;
begin
  IsDark := IsIDEDarkMode;

  if IsDark then
  begin
    // Mode Sombre (Style moderne type VS Code)
    richChat.Color := $001E1E1E;      // Fond gris anthracite
    richChat.Font.Color := $00E0E0E0; // Texte blanc cassé
    
    memoPrompt.Color := $00252526;    // Fond de saisie légèrement plus clair
    memoPrompt.Font.Color := $00E0E0E0;
    
    pnlBottom.Color := $001E1E1E;
    pnlTop.Color := $001E1E1E;
    pnlInputActions.Color := $001E1E1E;
    
    chkIncludeActiveUnit.Font.Color := $00E0E0E0;
    lblSource.Font.Color := $0085E3B2; // Vert clair émeraude
  end
  else
  begin
    // Mode Clair (Style RAD Studio classique)
    richChat.Color := clWindow;
    richChat.Font.Color := clWindowText;
    
    memoPrompt.Color := clWindow;
    memoPrompt.Font.Color := clWindowText;
    
    pnlBottom.Color := clBtnFace;
    pnlTop.Color := clBtnFace;
    pnlInputActions.Color := clBtnFace;
    
    chkIncludeActiveUnit.Font.Color := clWindowText;
    lblSource.Font.Color := clHotLight; // Bleu standard
  end;
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
      TLLMLogger.LogError('Impossible de forcer le moteur Edge (WebView2) via RTTI', E.Message);
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

procedure TDockableLLMForm.InitAgentsList;
var
  ProjectPath: string;
  Files: TArray<string>;
  F: string;
begin
  cbAgents.Items.Clear;
  cbAgents.Items.Add('-- Agent : Développeur Pascal/Delphi (Standard) --');
  cbAgents.Items.Add('Agent : Architecte Logiciel (Conception)');
  cbAgents.Items.Add('Agent : Auditeur de Code (Sécurité & Perf)');
  cbAgents.Items.Add('Agent : Testeur Senior (DUnitX)');
  cbAgents.Items.Add('Équipe d''Agents AI (Coder + Auditeur + Testeur)');
  cbAgents.Items.Add('Agent : Migrateur de Projet (Ancien ➔ Delphi 11/12)');
  
  // Recherche dynamique de fichiers d'agents utilisateur (*.md) dans le dossier du projet actif
  ProjectPath := TMustDevProjectManager.GetActiveProjectPath;
  if ProjectPath <> '' then
  begin
    try
      if TDirectory.Exists(ProjectPath) then
      begin
        Files := TDirectory.GetFiles(ProjectPath, '*.md', TSearchOption.soTopDirectoryOnly);
        for F in Files do
        begin
          var Name := TPath.GetFileName(F);
          cbAgents.Items.Add('Agent : ' + Name);
        end;
      end;
    except
      // Mode silencieux si accès dossier impossible
    end;
  end;
  cbAgents.ItemIndex := 0;
end;

function TDockableLLMForm.GetTextToInteract: string;
var
  SelText: string;
  Lines: TStrings;
  I: Integer;
  InsideBlock: Boolean;
  BlockText: TStringBuilder;
begin
  Result := '';
  
  // 1. Récupérer la sélection de l'utilisateur dans le chat
  SelText := richChat.SelText;
  if Trim(SelText) <> '' then
  begin
    Result := SelText;
    Exit;
  end;
  
  // 2. Sinon, parcourir le texte du chat de bas en haut pour extraire le dernier bloc de code ```pascal / ```delphi / ```
  Lines := richChat.Lines;
  InsideBlock := False;
  BlockText := TStringBuilder.Create;
  try
    for I := Lines.Count - 1 downto 0 do
    begin
      var Line := Trim(Lines[I]);
      if Line.StartsWith('```') then
      begin
        if not InsideBlock then
          InsideBlock := True // Début de l'extraction (fin du bloc en lisant de bas en haut)
        else
          Break; // Fin du bloc (début du bloc en remontant), on a tout extrait
      end
      else if InsideBlock then
      begin
        BlockText.Insert(0, Lines[I] + sLineBreak);
      end;
    end;
    Result := Trim(BlockText.ToString);
  finally
    BlockText.Free;
  end;
end;

procedure TDockableLLMForm.btnInsertCodeClick(Sender: TObject);
var
  CodeToInsert: string;
  EditorServices: IOTAEditorServices;
  EditBuffer: IOTAEditBuffer;
  Block: IOTAEditBlock;
begin
  CodeToInsert := GetTextToInteract;
  if CodeToInsert = '' then
  begin
    ShowMessage('Aucun code ou texte sélectionné trouvé dans l''historique du chat.');
    Exit;
  end;
  
  if Supports(BorlandIDEServices, IOTAEditorServices, EditorServices) then
  begin
    EditBuffer := EditorServices.TopBuffer;
    if Assigned(EditBuffer) then
    begin
      Block := EditBuffer.EditBlock;
      
      // Remplacer la sélection active de l'éditeur ou insérer à la position du curseur
      if Block.Size > 0 then
      begin
        EditBuffer.EditPosition.Move(Block.StartingRow, Block.StartingColumn);
        EditBuffer.EditPosition.Delete(Block.Size);
      end;
      
      EditBuffer.EditPosition.InsertText(CodeToInsert);
      TLLMLogger.LogSuccess('Code inséré avec succès dans l''éditeur.');
    end
    else
      ShowMessage('Aucun fichier ouvert au premier plan dans l''éditeur de RAD Studio.');
  end;
end;

procedure TDockableLLMForm.btnCreateUnitClick(Sender: TObject);
var
  CodeToInsert: string;
  ModServices: IOTAModuleServices;
begin
  CodeToInsert := GetTextToInteract;
  if CodeToInsert = '' then
  begin
    ShowMessage('Aucun code ou texte sélectionné à utiliser pour créer une unité.');
    Exit;
  end;
  
  if Supports(BorlandIDEServices, IOTAModuleServices, ModServices) then
  begin
    // Utilisation du créateur personnalisé pour instancier proprement une nouvelle unité dans l'IDE
    ModServices.CreateModule(TMustDevUnitCreator.Create(CodeToInsert));
    TLLMLogger.LogSuccess('Nouvelle unité créée avec succès dans l''éditeur.');
  end;
end;

procedure TDockableLLMForm.FormCreate(Sender: TObject);
var
  Reg: TRegistry;
  LMode: Integer;
  Sep2: TToolButton;
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

  // Remplissage du ComboBox du mode Chat
  cbChatMode.Items.Clear;
  cbChatMode.Items.Add('Mode API (Clé de sécurité)');
  cbChatMode.Items.Add('ChatGPT (Compte)');
  cbChatMode.Items.Add('Google Gemini (Compte)');
  cbChatMode.Items.Add('Anthropic Claude (Compte)');
  
  // Création dynamique des boutons d'interaction en temps réel avec l'IDE
  Sep2 := TToolButton.Create(Self);
  Sep2.Parent := ToolBar1;
  Sep2.Style := tbsSeparator;
  
  btnInsertCode := TToolButton.Create(Self);
  btnInsertCode.Parent := ToolBar1;
  btnInsertCode.Caption := ' 📥 Insérer ';
  btnInsertCode.Hint := 'Insérer le code sélectionné ou le dernier bloc généré dans l''éditeur';
  btnInsertCode.ShowHint := True;
  btnInsertCode.OnClick := btnInsertCodeClick;
  
  btnCreateUnit := TToolButton.Create(Self);
  btnCreateUnit.Parent := ToolBar1;
  btnCreateUnit.Caption := ' 📄 Nouvelle unité ';
  btnCreateUnit.Hint := 'Créer un nouveau fichier contenant le code sélectionné ou généré';
  btnCreateUnit.ShowHint := True;
  btnCreateUnit.OnClick := btnCreateUnitClick;
  
  var Sep3 := TToolButton.Create(Self);
  Sep3.Parent := ToolBar1;
  Sep3.Style := tbsSeparator;
  
  btnAttach := TToolButton.Create(Self);
  btnAttach.Parent := ToolBar1;
  btnAttach.Caption := ' 📎 Joindre ';
  btnAttach.Hint := 'Joindre des fichiers ou des images à la conversation';
  btnAttach.ShowHint := True;
  btnAttach.OnClick := btnAttachClick;

  // Masquer la case à cocher contextuelle statique
  chkOptimizeContext.Visible := False;

  // Création dynamique du ComboBox de gestion des Agents / Skills
  cbAgents := TComboBox.Create(Self);
  cbAgents.Parent := pnlInputActions;
  cbAgents.Style := csDropDownList;
  cbAgents.Width := 200;
  cbAgents.Left := 8;
  cbAgents.Top := 3;
  cbAgents.Anchors := [akLeft, akTop];
  InitAgentsList;

  // Création du checkbox d'unité active de travail
  chkIncludeActiveUnit := TCheckBox.Create(Self);
  chkIncludeActiveUnit.Parent := pnlInputActions;
  chkIncludeActiveUnit.Caption := 'Inclure l''unité active de l''IDE';
  chkIncludeActiveUnit.Width := 200;
  chkIncludeActiveUnit.Left := 215;
  chkIncludeActiveUnit.Top := 6;
  chkIncludeActiveUnit.Checked := True;
  chkIncludeActiveUnit.Anchors := [akLeft, akTop];

  // Création du ComboBox d'actions rapides sur le code Delphi + Diagrammes UML
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
  cbQuickActions.Items.Add('UML : Diagramme de Classes de l''Unité (Mermaid)');
  cbQuickActions.Items.Add('UML : Diagramme de Séquence (Mermaid)');
  cbQuickActions.Items.Add('UML : Flowchart de l''Unité Globale (Mermaid)');
  cbQuickActions.Items.Add('UML : Flowchart d''une Procédure/Fonction (Mermaid)');
  cbQuickActions.Items.Add('UML : Diagramme d''État (Mermaid)');
  cbQuickActions.Items.Add('UML : Diagramme d''Activité (Mermaid)');
  cbQuickActions.ItemIndex := 0;
  cbQuickActions.OnChange := cbQuickActionsChange;
  
  // Application du thème initial (Clair / Sombre) basé sur l'IDE de l'utilisateur
  ApplyIDETheme;

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
    7: memoPrompt.Text := 'Génère un diagramme de classes au format Mermaid UML représentant l''arborescence, les relations, attributs et méthodes de cette unité Delphi. Utilise la syntaxe ''classDiagram''. Retourne uniquement le code Mermaid.';
    8: memoPrompt.Text := 'Génère un diagramme de séquence au format Mermaid UML représentant les appels de méthodes et interactions entre les objets de ce code Delphi. Utilise la syntaxe ''sequenceDiagram''. Retourne uniquement le code Mermaid.';
    9: memoPrompt.Text := 'Génère un diagramme de flux (Flowchart) au format Mermaid représentant l''architecture logique globale de cette unité Delphi. Utilise la syntaxe ''graph TD''. Retourne uniquement le code Mermaid.';
    10: memoPrompt.Text := 'Génère un diagramme de flux (Flowchart) au format Mermaid représentant la logique d''exécution interne, ' + 
                           'les embranchements conditionnels (if, case) et les boucles (for, while, repeat) de la procédure ou ' + 
                           'fonction Delphi active/sélectionnée. Utilise la syntaxe ''graph TD''. Retourne uniquement le code Mermaid.';
    11: memoPrompt.Text := 'Génère un diagramme d''état (State Diagram) au format Mermaid UML représentant les différents états possibles et les transitions logiques de ce code Delphi. Utilise la syntaxe ''stateDiagram-v2''. Retourne uniquement le code Mermaid.';
    12: memoPrompt.Text := 'Génère un diagramme d''activité au format Mermaid UML décrivant le flux d''activité et les décisions de ce code Delphi. Utilise la syntaxe ''graph TB''. Retourne uniquement le code Mermaid.';
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
          TLLMLogger.LogError('Erreur d''instanciation du navigateur', E.Message);
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
    
  ApplyIDETheme;
end;

procedure TDockableLLMForm.AddChatMsg(const ASender, AMessage: string; IsUser: Boolean);
var
  SenderColor, TextColor: TColor;
  IsDark: Boolean;
begin
  IsDark := IsIDEDarkMode;

  richChat.SelStart := Length(richChat.Text);
  richChat.SelAttributes.Style := [fsBold];
  
  if ASender = 'Système' then
    SenderColor := clGray
  else if IsUser then
  begin
    if IsDark then
      SenderColor := $00FFB366 // Bleu ciel doux HSL en mode sombre
    else
      SenderColor := clHighlight; // Bleu classique en mode clair
  end
  else
  begin
    if IsDark then
      SenderColor := $0085E3B2 // Vert menthe doux HSL en mode sombre
    else
      SenderColor := clGreen; // Vert classique en mode clair
  end;
  
  richChat.SelAttributes.Color := SenderColor;
  richChat.Lines.Add(ASender + ' :');
  
  richChat.SelStart := Length(richChat.Text);
  richChat.SelAttributes.Style := [];
  
  if IsDark then
    TextColor := $00E0E0E0 // Blanc cassé
  else
    TextColor := clWindowText; // Noir
    
  richChat.SelAttributes.Color := TextColor;
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
  cbAgents.Enabled := not IsBusy;
  btnInsertCode.Enabled := not IsBusy;
  btnCreateUnit.Enabled := not IsBusy;
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
  LocalProvider: ILLMProvider; // Copie locale pour garantir la thread-safety
  ActiveFileCode, ActiveFileName: string;
  SelectedAgentName, SelectedAgentRules: string;
  ThreadAttachments: TStringList;
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
  
  // Récupération des règles de l'Agent/Skill sélectionné
  SelectedAgentRules := '';
  SelectedAgentName := cbAgents.Text;
  
  if cbAgents.ItemIndex = 1 then
  begin
    // Agent Architecte
    SelectedAgentRules := '=== AGENT PERSONA: ARCHITECTE LOGICIEL ===' + sLineBreak +
                          'Tu es un architecte logiciel Delphi senior. Concentre-toi sur la conception propre,' + sLineBreak +
                          'les patrons de conception (design patterns), le decouplage et le respect des principes SOLID.' + sLineBreak +
                          '==========================================' + sLineBreak;
  end
  else if cbAgents.ItemIndex = 2 then
  begin
    // Agent Auditeur
    SelectedAgentRules := '=== AGENT PERSONA: AUDITEUR DE CODE ===' + sLineBreak +
                          'Tu es un auditeur de code et expert en securite Delphi. Concentre-toi sur les fuites memoire,' + sLineBreak +
                          'la securite des threads, la gestion des exceptions et l''optimisation des algorithmes.' + sLineBreak +
                          '=======================================' + sLineBreak;
  end
  else if cbAgents.ItemIndex = 3 then
  begin
    // Agent Testeur
    SelectedAgentRules := '=== AGENT PERSONA: TESTEUR SENIOR ===' + sLineBreak +
                          'Tu es un testeur Delphi senior. Concentre-toi sur la testabilite du code, la creation' + sLineBreak +
                          'de faux objets (mocks) et l''ecriture de scenarios de tests unitaires DUnitX robustes.' + sLineBreak +
                          '=====================================' + sLineBreak;
  end
  else if cbAgents.ItemIndex > 5 then
  begin
    // Agent utilisateur (Fichier .md trouve dans le projet)
    var ProjectPath := TMustDevProjectManager.GetActiveProjectPath;
    if ProjectPath <> '' then
    begin
      var MdFileName := StringReplace(SelectedAgentName, 'Agent : ', '', []);
      var FullMdPath := TPath.Combine(ProjectPath, MdFileName);
      if TFile.Exists(FullMdPath) then
      begin
        SelectedAgentRules := '=== AGENT CUSTOM RULES (' + MdFileName + ') ===' + sLineBreak +
                              TFile.ReadAllText(FullMdPath, TEncoding.UTF8) + sLineBreak +
                              '=======================================' + sLineBreak;
        TLLMLogger.LogInfo('Regles de l''agent utilisateur ' + MdFileName + ' chargees.');
      end;
    end;
  end;
  
  // Récupération de l'unité active de l'IDE en tant qu'unité de travail
  ActiveFileCode := '';
  ActiveFileName := '';
  if chkIncludeActiveUnit.Checked then
  begin
    ActiveFileCode := GetActiveEditorCode(ActiveFileName);
    if ActiveFileCode <> '' then
      ActiveFileCode := '// Unite de travail actuelle dans l''editeur de l''IDE : ' + ActiveFileName + sLineBreak + ActiveFileCode;
  end;

  // Si c'est l'équipe d'agents autonomes, on délègue à l'orchestrateur asynchrone
  if cbAgents.ItemIndex = 4 then
  begin
    var Orchestrator := TAgentOrchestrator.Create(FProvider,
      procedure(const AgentName, LogMsg: string)
      begin
        AddChatMsg(AgentName, LogMsg, False);
      end);
      
    Orchestrator.ExecuteOrchestration(UserPrompt, ActiveFileCode,
      procedure(ResultReport: string)
      begin
        AddChatMsg('Coordonnateur', ResultReport, False);
        SetUIBusy(False);
      end);
    Exit;
  end;

  // Si c'est l'agent de migration globale de projet
  if cbAgents.ItemIndex = 5 then
  begin
    if MessageDlg('Attention : Vous vous appretez a lancer la migration automatique de tout le projet ouvert.' + sLineBreak +
                  'Des fichiers de sauvegarde (.bak) seront crees pour chaque unite modifiee.' + sLineBreak + sLineBreak +
                  'Souhaitez-vous continuer ?', mtWarning, [mbYes, mbNo], 0) = mrYes then
    begin
      SetUIBusy(True);
      AddChatMsg('Migrateur', 'Initialisation de la migration du projet...', False);
      
      var Migrator := TProjectMigrator.Create(FProvider,
        procedure(const LogMsg: string)
        begin
          AddChatMsg('Migrateur', LogMsg, False);
        end);
        
      TThread.CreateAnonymousThread(
        procedure
        begin
          try
            Migrator.MigrateProject;
          finally
            TThread.Queue(nil, TThreadProcedure(
              procedure
              begin
                SetUIBusy(False);
              end));
          end;
        end).Start;
    end;
    Exit;
  end;
  
  LocalProvider := FProvider; // Incrémente le compteur de références et protège l'instance dans le thread
  
  ThreadAttachments := TStringList.Create;
  ThreadAttachments.Assign(FAttachments);
  FAttachments.Clear;
  
  // Multithreading : Exécution en arrière-plan
  TThread.CreateAnonymousThread(
    procedure
    var
      ResponseText, FinalPrompt: string;
    begin
      try
        try
          // Optimisation du prompt via TPromptOptimizer avec les regles de l'agent selectionne
          FinalPrompt := TPromptOptimizer.Optimize(UserPrompt, ActiveFileCode, SelectedAgentRules);
            
          ResponseText := LocalProvider.Ask(FinalPrompt, True, ThreadAttachments);
          
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
      finally
        ThreadAttachments.Free;
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

procedure TDockableLLMForm.btnAttachClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  I: Integer;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Options := OpenDlg.Options + [ofAllowMultiSelect, ofFileMustExist];
    OpenDlg.Filter := 'Tous les fichiers supportés|*.pas;*.dpr;*.txt;*.xml;*.json;*.html;*.css;*.md;*.jpg;*.jpeg;*.png;*.gif;*.webp;*.pdf|' +
                      'Fichiers Delphi (*.pas;*.dpr)|*.pas;*.dpr|' +
                      'Images (*.jpg;*.jpeg;*.png;*.gif;*.webp)|*.jpg;*.jpeg;*.png;*.gif;*.webp|' +
                      'Tous les fichiers (*.*)|*.*';
    if OpenDlg.Execute then
    begin
      for I := 0 to OpenDlg.Files.Count - 1 do
      begin
        if FAttachments.IndexOf(OpenDlg.Files[I]) < 0 then
        begin
          FAttachments.Add(OpenDlg.Files[I]);
          AddChatMsg('Système', '📎 Fichier joint : ' + ExtractFileName(OpenDlg.Files[I]), False);
        end;
      end;
    end;
  finally
    OpenDlg.Free;
  end;
end;

end.

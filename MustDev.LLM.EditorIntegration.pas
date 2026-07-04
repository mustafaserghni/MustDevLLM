unit MustDev.LLM.EditorIntegration;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Editor Integration (OTA)                                          }
{  Description: Ajoute les raccourcis d'autocomplétion et de refactoring.    }
{                                                                            }
{ ************************************************************************** }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Menus, Vcl.Forms, Vcl.Dialogs, Vcl.Controls,
  ToolsAPI, MustDev.LLM.Interfaces, MustDev.LLM.Factory, MustDev.LLM.Security;

type
  TMustDevEditorBinding = class(TNotifierObject, IOTAKeyboardBinding)
  private
    FShortcutAutocomplete: TShortcut;
    FShortcutRefactor: TShortcut;
    FPromptAutocomplete: string;
    FPromptRefactor: string;
    procedure LoadSettings;
    function GetProvider: ILLMProvider;
    procedure DoLLMAction(const Context: IOTAKeyContext; const APrompt: string);
    procedure ExecuteAutocomplete(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
    procedure ExecuteRefactor(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
  public
    constructor Create;
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  end;

var
  EditorBindingIndex: Integer = -1;

procedure RegisterEditorBinding;
procedure UnregisterEditorBinding;

implementation

uses
  System.Win.Registry, MustDev.LLM.Logger, MustDev.LLM.PromptOptimizer;

{ TMustDevEditorBinding }

constructor TMustDevEditorBinding.Create;
begin
  inherited Create;
  LoadSettings;
end;

procedure TMustDevEditorBinding.LoadSettings;
var
  Reg: TRegistry;
  SAuto, SRef: string;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('\Software\MustDev\LLMIntegration\Settings') then
    begin
      if Reg.ValueExists('ShortcutAutocomplete') then
        SAuto := Reg.ReadString('ShortcutAutocomplete')
      else
        SAuto := 'Ctrl+Alt+Space';
        
      if Reg.ValueExists('ShortcutRefactor') then
        SRef := Reg.ReadString('ShortcutRefactor')
      else
        SRef := 'Ctrl+Alt+R';
        
      if Reg.ValueExists('PromptAutocomplete') then
        FPromptAutocomplete := Reg.ReadString('PromptAutocomplete')
      else
        FPromptAutocomplete := 'Complète ce code Delphi. Retourne UNIQUEMENT le code, sans markdown.';
        
      if Reg.ValueExists('PromptRefactor') then
        FPromptRefactor := Reg.ReadString('PromptRefactor')
      else
        FPromptRefactor := 'Refactore ce code Delphi. Retourne UNIQUEMENT le code, sans markdown.';
        
      Reg.CloseKey;
    end
    else
    begin
      SAuto := 'Ctrl+Alt+Space';
      SRef := 'Ctrl+Alt+R';
      FPromptAutocomplete := 'Complète ce code Delphi. Retourne UNIQUEMENT le code, sans markdown.';
      FPromptRefactor := 'Refactore ce code Delphi. Retourne UNIQUEMENT le code, sans markdown.';
    end;
  finally
    Reg.Free;
  end;
  
  FShortcutAutocomplete := TextToShortCut(SAuto);
  FShortcutRefactor := TextToShortCut(SRef);
end;

function TMustDevEditorBinding.GetProvider: ILLMProvider;
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
  Result := TLLMProviderFactory.CreateProvider(LType, LEndpoint, LApiKey, LModel);
end;

procedure TMustDevEditorBinding.DoLLMAction(const Context: IOTAKeyContext; const APrompt: string);
var
  Provider: ILLMProvider;
  SelectedText: string;
  Block: IOTAEditBlock;
begin
  Block := Context.EditBuffer.EditBlock;
  if Block.Size = 0 then
  begin
    TLLMLogger.LogInfo('Sélection vide dans l''éditeur ignorée.');
    ShowMessage('Must@Dev AI : Veuillez sélectionner un bloc de code dans l''éditeur.');
    Exit;
  end;
  
  SelectedText := Block.Text;
  
  try
    Provider := GetProvider;
    TLLMLogger.LogInfo('Requête LLM déclenchée depuis l''éditeur (Asynchrone)...');
    
    // Lancement de la requête dans un thread d'arrière-plan
    TThread.CreateAnonymousThread(
      procedure
      var
        ResponseText, OptimizedPrompt: string;
      begin
        try
          // Optimisation du prompt
          OptimizedPrompt := TPromptOptimizer.Optimize(APrompt, SelectedText);
          
          // Requête réseau bloquante exécutée en arrière-plan (ne fige pas l'IDE)
          ResponseText := Provider.Ask(OptimizedPrompt);
          
          // On retire les éventuelles balises Markdown renvoyées par l'IA
          ResponseText := StringReplace(ResponseText, '```pascal', '', [rfReplaceAll, rfIgnoreCase]);
          ResponseText := StringReplace(ResponseText, '```delphi', '', [rfReplaceAll, rfIgnoreCase]);
          ResponseText := StringReplace(ResponseText, '```', '', [rfReplaceAll]);
          ResponseText := Trim(ResponseText);
          
          // Mise à jour de l'éditeur sur le thread principal (VCL)
          TThread.Queue(nil,
            procedure
            begin
              try
                // Vérification basique si l'éditeur est toujours là
                if Assigned(Context) and Assigned(Context.EditBuffer) then
                begin
                  Context.EditBuffer.EditPosition.Move(Block.StartingRow, Block.StartingColumn);
                  Context.EditBuffer.EditPosition.Delete(Block.Size);
                  Context.EditBuffer.EditPosition.InsertText(ResponseText);
                  TLLMLogger.LogSuccess('Code généré et inséré avec succès.');
                end;
              except
                on E: Exception do
                  TLLMLogger.LogError('Erreur lors de l''insertion dans l''éditeur', E);
              end;
            end);
            
        except
          on E: Exception do
            TLLMLogger.LogError('Erreur lors de l''appel LLM', E);
        end;
      end).Start;
      
  except
    on E: Exception do
      TLLMLogger.LogError('Erreur de préparation LLM', E);
  end;
end;

procedure TMustDevEditorBinding.ExecuteAutocomplete(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
begin
  LoadSettings;
  DoLLMAction(Context, FPromptAutocomplete);
  BindingResult := krHandled;
end;

procedure TMustDevEditorBinding.ExecuteRefactor(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
begin
  LoadSettings;
  DoLLMAction(Context, FPromptRefactor);
  BindingResult := krHandled;
end;

function TMustDevEditorBinding.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TMustDevEditorBinding.GetDisplayName: string;
begin
  Result := 'Must@Dev LLM Bindings';
end;

function TMustDevEditorBinding.GetName: string;
begin
  Result := 'MustDev.LLM.KeyboardBindings';
end;

procedure TMustDevEditorBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  LoadSettings;
  
  if FShortcutAutocomplete <> 0 then
    BindingServices.AddKeyBinding([FShortcutAutocomplete], ExecuteAutocomplete, nil);
    
  if FShortcutRefactor <> 0 then
    BindingServices.AddKeyBinding([FShortcutRefactor], ExecuteRefactor, nil);
end;

{ Global Registration }

procedure RegisterEditorBinding;
var
  KeyboardServices: IOTAKeyboardServices;
begin
  if Supports(BorlandIDEServices, IOTAKeyboardServices, KeyboardServices) then
    EditorBindingIndex := KeyboardServices.AddKeyboardBinding(TMustDevEditorBinding.Create);
end;

procedure UnregisterEditorBinding;
var
  KeyboardServices: IOTAKeyboardServices;
begin
  if (EditorBindingIndex >= 0) and Supports(BorlandIDEServices, IOTAKeyboardServices, KeyboardServices) then
  begin
    KeyboardServices.RemoveKeyboardBinding(EditorBindingIndex);
    EditorBindingIndex := -1;
  end;
end;

end.

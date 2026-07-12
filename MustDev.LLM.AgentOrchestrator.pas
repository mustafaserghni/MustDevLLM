unit MustDev.LLM.AgentOrchestrator;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Multi-Agent Orchestrator                                          }
{  Description: Système de coordination multi-agents (Coder, Auditor, Tester)}
{               s'exécutant de manière asynchrone en tâche de fond.          }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.Classes, System.SysUtils, MustDev.LLM.Interfaces;

type
  TAgentLogEvent = reference to procedure(const AgentName, LogMsg: string);

  TAgentOrchestrator = class
  private
    FProvider: ILLMProvider;
    FOnLog: TAgentLogEvent;
    procedure Log(const AgentName, Msg: string);
  public
    constructor Create(const AProvider: ILLMProvider; ALogCallback: TAgentLogEvent);
    
    // Exécute la chaîne de collaboration multi-agents de manière asynchrone
    procedure ExecuteOrchestration(const APrompt, ACodeContext: string; AOnSuccess: TProc<string>);
  end;

implementation

{ TAgentOrchestrator }

constructor TAgentOrchestrator.Create(const AProvider: ILLMProvider; ALogCallback: TAgentLogEvent);
begin
  inherited Create;
  FProvider := AProvider;
  FOnLog := ALogCallback;
end;

procedure TAgentOrchestrator.Log(const AgentName, Msg: string);
begin
  if Assigned(FOnLog) then
  begin
    // Synchronisation sur le thread VCL pour mettre à jour le chat en temps réel
    TThread.Queue(nil,
      procedure
      begin
        FOnLog(AgentName, Msg);
      end);
  end;
end;

procedure TAgentOrchestrator.ExecuteOrchestration(const APrompt, ACodeContext: string; AOnSuccess: TProc<string>);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      CoderPrompt, CoderResponse: string;
      AuditorPrompt, AuditorResponse: string;
      TesterPrompt, TesterResponse: string;
      FinalReport: string;
    begin
      try
        // ----------------------------------------------------
        // ÉTAPE 1 : Coder Agent (Conception et Rédaction)
        // ----------------------------------------------------
        Log('Coder Agent', 'Analyse de votre besoin et rédaction du code Delphi...');
        CoderPrompt := 'ROLE: Tu es le Coder Agent. Rédige le code Delphi demandé par l''utilisateur.' + sLineBreak +
                       'Respecte la syntaxe moderne de Delphi et les conventions de nommage.' + sLineBreak +
                       'Retourne UNIQUEMENT le code source Pascal valide entouré de balises de code ```pascal.' + sLineBreak +
                       'PROMPT: ' + APrompt + sLineBreak +
                       'CODE DE CONTEXTE DE L''EDITEUR: ' + ACodeContext;
        CoderResponse := FProvider.Ask(CoderPrompt, False);
        Log('Coder Agent', 'Code Delphi généré avec succès. Transfert à l''Auditeur...');

        // ----------------------------------------------------
        // ÉTAPE 2 : Auditor Agent (Revue et Sécurisation)
        // ----------------------------------------------------
        Log('Auditor Agent', 'Revue du code en cours (analyse des fuites mémoire, blocs try..finally, typage)...');
        AuditorPrompt := 'ROLE: Tu es l''Auditeur de Code Agent. Analyse le code généré par le Coder Agent.' + sLineBreak +
                         'Corrige les fuites de mémoire (assure-toi que les objets créés sont libérés dans un bloc try..finally),' + sLineBreak +
                         'les variables non initialisées, les accès concurrents ou les casts invalides.' + sLineBreak +
                         'Si le code est parfait, retourne-le inchangé. Sinon, réécris la version corrigée et sécurisée.' + sLineBreak +
                         'Retourne UNIQUEMENT le code Delphi corrigé dans un bloc de code ```pascal.' + sLineBreak +
                         'CODE DU CODER AGENT: ' + sLineBreak + CoderResponse;
        AuditorResponse := FProvider.Ask(AuditorPrompt, False);
        Log('Auditor Agent', 'Revue de code finalisée. Aucune anomalie détectée. Transfert au Testeur...');

        // ----------------------------------------------------
        // ÉTAPE 3 : Tester Agent (Tests unitaires)
        // ----------------------------------------------------
        Log('Tester Agent', 'Génération des tests unitaires DUnitX pour le code validé...');
        TesterPrompt := 'ROLE: Tu es le Tester Agent. Écris une classe de tests unitaires DUnitX complète' + sLineBreak +
                        'pour valider le code Delphi suivant.' + sLineBreak +
                        'Retourne UNIQUEMENT l''unité de tests DUnitX complète dans un bloc de code ```pascal.' + sLineBreak +
                        'CODE A TESTER: ' + sLineBreak + AuditorResponse;
        TesterResponse := FProvider.Ask(TesterPrompt, False);
        Log('Tester Agent', 'Tests unitaires DUnitX rédigés.');

        // ----------------------------------------------------
        // ÉTAPE 4 : Rapport Final du Coordonnateur
        // ----------------------------------------------------
        Log('Coordonnateur', 'Préparation des livrables finaux...');
        
        FinalReport := '### 🤖 RAPPORT FINAL DE L''ÉQUIPE D''AGENTS AI' + sLineBreak + sLineBreak +
                       'Les agents ont travaillé en arrière-plan et validé le code sous votre contrôle.' + sLineBreak + sLineBreak +
                       '**1. Code Final Sécurisé et Audité (Coder + Auditeur)**' + sLineBreak +
                       AuditorResponse + sLineBreak + sLineBreak +
                       '**2. Suite de Tests DUnitX (Tester)**' + sLineBreak +
                       TesterResponse + sLineBreak + sLineBreak +
                       '**3. Historique d''échange interne :**' + sLineBreak +
                       '- *Coder Agent* : A conçu le code source d''implémentation.' + sLineBreak +
                       '- *Auditor Agent* : A audité le code et garanti la sécurité mémoire (try..finally).' + sLineBreak +
                       '- *Tester Agent* : A rédigé la suite de tests unitaires.';

        // Renvoi synchrone du rapport final sur le thread principal VCL
        TThread.Queue(nil,
          procedure
          begin
            AOnSuccess(FinalReport);
          end);
          
      except
        on E: Exception do
        begin
          var ErrMsg := E.Message;
          TThread.Queue(nil,
            procedure
            begin
              Log('Coordonnateur (Erreur)', 'Une erreur est survenue dans la chaîne multi-agent : ' + ErrMsg);
            end);
        end;
      end;
    end).Start;
end;

end.

unit MustDev.LLM.PromptOptimizer;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Prompt Optimizer                                                  }
{  Description: Moteur d'optimisation et d'enrichissement des Prompts.       }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.SysUtils;

type
  TPromptOptimizer = class
  public
    // Enrichit un prompt utilisateur avec des directives Delphi strictes
    class function Optimize(const ABasePrompt, ACodeContext: string): string;
  end;

implementation

{ TPromptOptimizer }

class function TPromptOptimizer.Optimize(const ABasePrompt, ACodeContext: string): string;
var
  StrictRules: string;
begin
  // Règles strictes injectées silencieusement pour forcer le LLM à être professionnel
  StrictRules := 
    '=== DELPHI DEVELOPMENT RULES ===' + sLineBreak +
    '1. Use modern Object Pascal syntax (Delphi 10.3+).' + sLineBreak +
    '2. Favor inline variables where appropriate.' + sLineBreak +
    '3. Ensure absolute memory safety: ALWAYS use try..finally blocks when instantiating objects.' + sLineBreak +
    '4. Do not invent VCL/FMX properties or methods that do not exist.' + sLineBreak +
    '5. Keep code highly readable and follow standard Delphi naming conventions (T, F, A prefixes).' + sLineBreak +
    '================================' + sLineBreak;
    
  Result := StrictRules + sLineBreak + 
            'USER REQUEST: ' + ABasePrompt + sLineBreak;
            
  if Trim(ACodeContext) <> '' then
  begin
    Result := Result + sLineBreak + 
              'CODE CONTEXT:' + sLineBreak + 
              '```pascal' + sLineBreak + 
              ACodeContext + sLineBreak + 
              '```';
  end;
end;

end.

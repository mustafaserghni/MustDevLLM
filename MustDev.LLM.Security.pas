unit MustDev.LLM.Security;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Security Utilities                                                }
{  Description: Utilitaires pour le stockage sécurisé des clés API.          }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.SysUtils, System.Classes, System.Win.Registry, Winapi.Windows;

type
  TSecurityUtils = class
  private
    // XOR basique pour l'obfuscation (à remplacer par DPAPI pour une vraie sécurité)
    class function XorString(const AStr: string): string;
  public
    class procedure SaveApiKey(const AProviderName, AKey: string);
    class function LoadApiKey(const AProviderName: string): string;
  end;

const
  REG_BASE_KEY = '\Software\MustDev\LLMIntegration';
  XOR_KEY = $A5; // Clé arbitraire pour l'obfuscation

implementation

{ TSecurityUtils }

class function TSecurityUtils.XorString(const AStr: string): string;
var
  I: Integer;
begin
  Result := AStr;
  for I := 1 to Length(Result) do
    Result[I] := Char(Ord(Result[I]) xor XOR_KEY);
end;

class procedure TSecurityUtils.SaveApiKey(const AProviderName, AKey: string);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(REG_BASE_KEY, True) then
    begin
      // Stockage de la clé obfusquée
      Reg.WriteString(AProviderName + '_ApiKey', XorString(AKey));
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

class function TSecurityUtils.LoadApiKey(const AProviderName: string): string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(REG_BASE_KEY) then
    begin
      if Reg.ValueExists(AProviderName + '_ApiKey') then
        Result := XorString(Reg.ReadString(AProviderName + '_ApiKey'));
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

end.

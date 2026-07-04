unit MustDev.LLM.CloudRESTProvider;

{ ************************************************************************** }
{                                                                            }
{  Must@Dev - AI Integration Module                                          }
{  Module: Cloud REST LLM Provider                                           }
{  Description: Connecteur pour API distantes (OpenAI, Gemini, Claude...).   }
{                                                                            }
{ ************************************************************************** }

interface

uses
  System.Classes, System.SysUtils, System.JSON,
  REST.Types, REST.Client,
  MustDev.LLM.Interfaces, MustDev.LLM.BaseProvider;

type
  TCloudRESTLLMProvider = class(TBaseLLMProvider)
  protected
    function GetProviderType: TProviderType; override;
  public
    function Ask(const APrompt: string): string; override;
  end;

implementation

{ TCloudRESTLLMProvider }

function TCloudRESTLLMProvider.GetProviderType: TProviderType;
begin
  Result := ptCloudREST;
end;

function TCloudRESTLLMProvider.Ask(const APrompt: string): string;
var
  RestClient: TRESTClient;
  RestRequest: TRESTRequest;
  RestResponse: TRESTResponse;
  JSONPayload: TJSONObject;
  MessagesArray: TJSONArray;
  MessageObj: TJSONObject;
begin
  Result := '';
  
  RestClient := TRESTClient.Create(FEndpoint);
  RestRequest := TRESTRequest.Create(nil);
  RestResponse := TRESTResponse.Create(nil);
  JSONPayload := TJSONObject.Create;
  try
    RestRequest.Client := RestClient;
    RestRequest.Response := RestResponse;
    RestRequest.Method := rmPOST;
    
    // Exemple de structure JSON commune (style OpenAI)
    JSONPayload.AddPair('model', FModel);
    
    MessagesArray := TJSONArray.Create;
    MessageObj := TJSONObject.Create;
    MessageObj.AddPair('role', 'user');
    MessageObj.AddPair('content', APrompt);
    MessagesArray.AddElement(MessageObj);
    
    JSONPayload.AddPair('messages', MessagesArray);
    
    // Configuration du corps de la requête
    RestRequest.AddBody(JSONPayload.ToString, ctAPPLICATION_JSON);
    
    // ******************************************************
    // Gestion sécurisée des Header HTTP pour la clé API
    // ******************************************************
    // Note: Pour Gemini on pourrait utiliser un header 'x-goog-api-key',
    // pour OpenAI/Claude c'est un Bearer token 'Authorization'
    if FApiKey <> '' then
      RestRequest.Params.AddHeader('Authorization', 'Bearer ' + FApiKey);

    // Exécution de la requête REST
    RestRequest.Execute;
    
    if RestResponse.StatusCode = 200 then
    begin
      // Parsing de la réponse (Adapté au format OpenAI pour l'exemple)
      var RespJSON := RestResponse.JSONValue as TJSONObject;
      if Assigned(RespJSON) then
      begin
        var ChoicesArray := RespJSON.GetValue<TJSONArray>('choices');
        if Assigned(ChoicesArray) and (ChoicesArray.Count > 0) then
        begin
          var FirstChoice := ChoicesArray.Items[0] as TJSONObject;
          var MsgNode := FirstChoice.GetValue<TJSONObject>('message');
          if Assigned(MsgNode) then
            Result := MsgNode.GetValue<string>('content');
        end;
      end;
    end
    else
      raise Exception.CreateFmt('Erreur API Cloud (Code: %d): %s' + sLineBreak + '%s', 
        [RestResponse.StatusCode, RestResponse.StatusText, RestResponse.Content]);

  finally
    JSONPayload.Free;
    RestResponse.Free;
    RestRequest.Free;
    RestClient.Free;
  end;
end;

end.

object LLMOptionsFrame: TLLMOptionsFrame
  Left = 0
  Top = 0
  Width = 480
  Height = 420
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 480
    Height = 370
    ActivePage = TabGeneral
    Align = alTop
    TabOrder = 0
    object TabGeneral: TTabSheet
      Caption = 'Connexion'
      object lblTitleGeneral: TLabel
        Left = 16
        Top = 12
        Width = 180
        Height = 17
        Caption = 'Configuration du fournisseur'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object rgProviderType: TRadioGroup
        Left = 16
        Top = 38
        Width = 440
        Height = 55
        Columns = 2
        ItemIndex = 0
        Items.Strings = (
          'Serveur Local (Ollama, LM Studio)'
          'API Cloud (OpenAI, Gemini, Claude)')
        TabOrder = 0
        OnClick = rgProviderTypeClick
      end
      object pnlGeneralConfig: TPanel
        Left = 16
        Top = 102
        Width = 440
        Height = 225
        BevelOuter = bvNone
        TabOrder = 1
        object lblQuickProfile: TLabel
          Left = 10
          Top = 13
          Width = 73
          Height = 15
          Caption = 'Profil Rapide :'
        end
        object lblEndpoint: TLabel
          Left = 10
          Top = 53
          Width = 70
          Height = 15
          Caption = 'URL de l'#39'API :'
        end
        object lblApiKey: TLabel
          Left = 10
          Top = 93
          Width = 44
          Height = 15
          Caption = 'Cle API :'
        end
        object lblCloudType: TLabel
          Left = 10
          Top = 133
          Width = 59
          Height = 15
          Caption = 'API Cloud :'
        end
        object lblModel: TLabel
          Left = 10
          Top = 173
          Width = 46
          Height = 15
          Caption = 'Modele :'
        end
        object cbQuickProfile: TComboBox
          Left = 90
          Top = 10
          Width = 340
          Height = 23
          Style = csDropDownList
          TabOrder = 0
          OnChange = cbQuickProfileChange
          Items.Strings = (
            'Ollama (Localhost - 11434)'
            'LM Studio (Localhost - 1234)'
            'OpenAI (Cloud GPT)'
            'Google Gemini (Cloud)'
            'Anthropic Claude (Cloud)'
            'Alibaba Qwen (Cloud Compatible)'
            'DeepSeek (Cloud Compatible)')
        end
        object edtEndpoint: TEdit
          Left = 90
          Top = 50
          Width = 340
          Height = 23
          TabOrder = 1
        end
        object edtApiKey: TEdit
          Left = 90
          Top = 90
          Width = 340
          Height = 23
          PasswordChar = '*'
          TabOrder = 2
        end
        object cbCloudType: TComboBox
          Left = 90
          Top = 130
          Width = 340
          Height = 23
          Style = csDropDownList
          TabOrder = 3
          Items.Strings = (
            'OpenAI / DeepSeek / Qwen (Standard)'
            'Google Gemini'
            'Anthropic Claude')
        end
        object cbModel: TComboBox
          Left = 90
          Top = 170
          Width = 230
          Height = 23
          TabOrder = 4
        end
        object btnRefreshModels: TButton
          Left = 330
          Top = 169
          Width = 100
          Height = 25
          Caption = 'Actualiser'
          TabOrder = 5
          OnClick = btnRefreshModelsClick
        end
      end
    end
    object TabShortcuts: TTabSheet
      Caption = 'Raccourcis'
      ImageIndex = 1
      object lblTitleShortcuts: TLabel
        Left = 16
        Top = 12
        Width = 160
        Height = 17
        Caption = 'Raccourcis clavier de l'#39'IDE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object pnlShortcuts: TPanel
        Left = 16
        Top = 42
        Width = 440
        Height = 150
        BevelOuter = bvNone
        TabOrder = 0
        object lblShortcutAutocomplete: TLabel
          Left = 10
          Top = 23
          Width = 93
          Height = 15
          Caption = 'Autocompletion :'
        end
        object lblShortcutRefactor: TLabel
          Left = 10
          Top = 73
          Width = 67
          Height = 15
          Caption = 'Refactoring :'
        end
        object edtShortcutAutocomplete: TEdit
          Left = 130
          Top = 20
          Width = 290
          Height = 23
          TabOrder = 0
        end
        object edtShortcutRefactor: TEdit
          Left = 130
          Top = 70
          Width = 290
          Height = 23
          TabOrder = 1
        end
      end
    end
    object TabPrompts: TTabSheet
      Caption = 'Prompts'
      ImageIndex = 2
      object lblTitlePrompts: TLabel
        Left = 16
        Top = 12
        Width = 194
        Height = 17
        Caption = 'Prompts Systeme de l'#39'Assistant'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object pnlPrompts: TPanel
        Left = 16
        Top = 38
        Width = 440
        Height = 285
        BevelOuter = bvNone
        TabOrder = 0
        object lblPromptAutocomplete: TLabel
          Left = 10
          Top = 10
          Width = 93
          Height = 15
          Caption = 'Autocompletion :'
        end
        object lblPromptRefactor: TLabel
          Left = 10
          Top = 145
          Width = 67
          Height = 15
          Caption = 'Refactoring :'
        end
        object memoPromptAutocomplete: TMemo
          Left = 10
          Top = 30
          Width = 420
          Height = 95
          ScrollBars = ssVertical
          TabOrder = 0
        end
        object memoPromptRefactor: TMemo
          Left = 10
          Top = 165
          Width = 420
          Height = 95
          ScrollBars = ssVertical
          TabOrder = 1
        end
      end
    end
  end
  object btnSave: TButton
    Left = 356
    Top = 382
    Width = 110
    Height = 28
    Caption = 'Sauvegarder'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = btnSaveClick
  end
end

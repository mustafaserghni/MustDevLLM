object LLMOptionsFrame: TLLMOptionsFrame
  Left = 0
  Top = 0
  Width = 450
  Height = 350
  TabOrder = 0
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 450
    Height = 310
    ActivePage = TabGeneral
    Align = alTop
    TabOrder = 0
    object TabGeneral: TTabSheet
      Caption = 'Fournisseur d''IA'
      object rgProviderType: TRadioGroup
        Left = 16
        Top = 10
        Width = 400
        Height = 55
        Caption = ' Type de fournisseur d''IA '
        ItemIndex = 0
        Items.Strings = (
          'Fournisseur Local (Ollama, LM Studio)'
          'Fournisseur Cloud (OpenAI, Gemini, Claude)')
        TabOrder = 0
        OnClick = rgProviderTypeClick
      end
      object GroupBox1: TGroupBox
        Left = 16
        Top = 75
        Width = 400
        Height = 190
        Caption = ' Param'#232'tres '
        TabOrder = 1
        object Label1: TLabel
          Left = 16
          Top = 24
          Width = 63
          Height = 15
          Caption = 'URL / Port :'
        end
        object Label2: TLabel
          Left = 16
          Top = 64
          Width = 45
          Height = 15
          Caption = 'Cl'#233' API :'
        end
        object LabelCloudType: TLabel
          Left = 16
          Top = 104
          Width = 65
          Height = 15
          Caption = 'API Cloud :'
        end
        object Label3: TLabel
          Left = 16
          Top = 144
          Width = 45
          Height = 15
          Caption = 'Mod'#232'le :'
        end
        object edtEndpoint: TEdit
          Left = 90
          Top = 21
          Width = 290
          Height = 23
          TabOrder = 0
        end
        object edtApiKey: TEdit
          Left = 90
          Top = 61
          Width = 290
          Height = 23
          PasswordChar = '*'
          TabOrder = 1
        end
        object cbCloudType: TComboBox
          Left = 90
          Top = 101
          Width = 290
          Height = 23
          Style = csDropDownList
          TabOrder = 2
          Items.Strings = (
            'OpenAI / DeepSeek / QWen (Standard)'
            'Google Gemini'
            'Anthropic Claude')
        end
        object cbModel: TComboBox
          Left = 90
          Top = 141
          Width = 195
          Height = 23
          TabOrder = 3
        end
        object btnRefreshModels: TButton
          Left = 290
          Top = 140
          Width = 90
          Height = 25
          Caption = 'Actualiser'
          TabOrder = 4
          OnClick = btnRefreshModelsClick
        end
      end
    end
    object TabShortcuts: TTabSheet
      Caption = 'Raccourcis '#201'diteur'
      ImageIndex = 1
      object GroupBox2: TGroupBox
        Left = 16
        Top = 16
        Width = 400
        Height = 150
        Caption = ' Raccourcis Clavier '
        TabOrder = 0
        object Label4: TLabel
          Left = 16
          Top = 32
          Width = 90
          Height = 15
          Caption = 'Autocompl'#233'tion :'
        end
        object Label5: TLabel
          Left = 16
          Top = 80
          Width = 65
          Height = 15
          Caption = 'Refactoring :'
        end
        object edtShortcutAutocomplete: TEdit
          Left = 120
          Top = 29
          Width = 250
          Height = 23
          TabOrder = 0
        end
        object edtShortcutRefactor: TEdit
          Left = 120
          Top = 77
          Width = 250
          Height = 23
          TabOrder = 1
        end
      end
    end
    object TabPrompts: TTabSheet
      Caption = 'System Prompts'
      ImageIndex = 2
      object GroupBox3: TGroupBox
        Left = 16
        Top = 16
        Width = 400
        Height = 250
        Caption = ' Instructions syst'#232'me par d'#233'faut '
        TabOrder = 0
        object Label6: TLabel
          Left = 16
          Top = 24
          Width = 90
          Height = 15
          Caption = 'Autocompl'#233'tion :'
        end
        object Label7: TLabel
          Left = 16
          Top = 136
          Width = 65
          Height = 15
          Caption = 'Refactoring :'
        end
        object memoPromptAutocomplete: TMemo
          Left = 16
          Top = 45
          Width = 360
          Height = 75
          ScrollBars = ssVertical
          TabOrder = 0
        end
        object memoPromptRefactor: TMemo
          Left = 16
          Top = 157
          Width = 360
          Height = 75
          ScrollBars = ssVertical
          TabOrder = 1
        end
      end
    end
  end
  object btnSave: TButton
    Left = 336
    Top = 316
    Width = 100
    Height = 25
    Caption = 'Sauvegarder'
    TabOrder = 1
    OnClick = btnSaveClick
  end
end

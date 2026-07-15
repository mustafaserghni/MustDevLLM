object DockableLLMForm: TDockableLLMForm
  Left = 0
  Top = 0
  Caption = 'Must@Dev - AI Assistant'
  ClientHeight = 833
  ClientWidth = 826
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 0
    Top = 683
    Width = 826
    Height = 5
    Cursor = crVSplit
    Align = alBottom
    Beveled = True
    ExplicitTop = 310
    ExplicitWidth = 400
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 826
    Height = 29
    ButtonHeight = 21
    ButtonWidth = 136
    Caption = 'ToolBar1'
    List = True
    ShowCaptions = True
    TabOrder = 0
    ExplicitWidth = 820
    object btnSettings: TToolButton
      Left = 0
      Top = 0
      Caption = ' Parametres '
      OnClick = btnSettingsClick
    end
    object btnClearHistory: TToolButton
      Left = 136
      Top = 0
      Caption = ' Nouvelle conversation '
      OnClick = btnClearHistoryClick
    end
    object btnSeparator: TToolButton
      Left = 272
      Top = 0
      Width = 8
      ImageIndex = 2
      Style = tbsSeparator
    end
    object cbChatMode: TComboBox
      Left = 280
      Top = 0
      Width = 160
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbChatModeChange
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 29
    Width = 826
    Height = 30
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 820
    object lblSource: TLabel
      Left = 8
      Top = 8
      Width = 119
      Height = 15
      Caption = 'Source : Non initialise'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHotLight
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object richChat: TRichEdit
    Left = 0
    Top = 59
    Width = 826
    Height = 624
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 2
    ExplicitWidth = 820
    ExplicitHeight = 615
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 688
    Width = 826
    Height = 145
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 679
    ExplicitWidth = 820
    object pnlInputActions: TPanel
      Left = 0
      Top = 115
      Width = 826
      Height = 30
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitWidth = 820
      object chkOptimizeContext: TCheckBox
        Left = 8
        Top = 6
        Width = 350
        Height = 17
        Caption = 'Optimiser le prompt avec le contexte (Agents.md)'
        Checked = True
        State = cbChecked
        TabOrder = 0
      end
    end
    object memoPrompt: TMemo
      Left = 0
      Top = 0
      Width = 746
      Height = 115
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 1
      ExplicitWidth = 740
    end
    object btnAsk: TButton
      Left = 746
      Top = 0
      Width = 80
      Height = 115
      Align = alRight
      Caption = 'Envoyer'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = btnAskClick
      ExplicitLeft = 740
    end
  end
end

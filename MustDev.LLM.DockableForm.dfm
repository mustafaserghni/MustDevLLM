object DockableLLMForm: TDockableLLMForm
  Left = 0
  Top = 0
  Caption = 'Must@Dev - AI Assistant'
  ClientHeight = 450
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 400
    Height = 29
    Caption = 'ToolBar1'
    TabOrder = 0
    object btnSettings: TToolButton
      Left = 0
      Top = 0
      Caption = 'Param'#232'tres'
      ImageIndex = 0
      OnClick = btnSettingsClick
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 29
    Width = 400
    Height = 30
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblSource: TLabel
      Left = 8
      Top = 8
      Width = 111
      Height = 15
      Caption = 'Source : Non initialis'#233
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
    Width = 400
    Height = 251
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 2
    Zoom = 100
  end
  object Splitter1: TSplitter
    Left = 0
    Top = 310
    Width = 400
    Height = 5
    Cursor = crVSplit
    Align = alBottom
    Beveled = True
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 315
    Width = 400
    Height = 135
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object memoPrompt: TMemo
      Left = 0
      Top = 0
      Width = 320
      Height = 135
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object btnAsk: TButton
      Left = 320
      Top = 0
      Width = 80
      Height = 135
      Align = alRight
      Caption = 'Envoyer'
      TabOrder = 1
      OnClick = btnAskClick
    end
  end
end

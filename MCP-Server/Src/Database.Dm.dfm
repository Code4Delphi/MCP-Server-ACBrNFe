object DatabaseDm: TDatabaseDm
  OnCreate = DataModuleCreate
  Height = 480
  Width = 640
  object FDConnection1: TFDConnection
    Params.Strings = (
      'Database=C:\IA\MCP-Server-ACBrNFe\BD\dados_acbr.db'
      'DriverID=SQLite')
    LoginPrompt = False
    Left = 128
    Top = 88
  end
  object QNFe: TFDQuery
    Connection = FDConnection1
    SQL.Strings = (
      'select *'
      'from nfe')
    Left = 128
    Top = 152
    object QNFeid: TFDAutoIncField
      FieldName = 'id'
      Origin = 'id'
      ProviderFlags = [pfInWhere, pfInKey]
      ReadOnly = False
    end
    object QNFeid_destinatario: TIntegerField
      FieldName = 'id_destinatario'
      Origin = 'id_destinatario'
    end
    object QNFeserie: TIntegerField
      FieldName = 'serie'
      Origin = 'serie'
    end
    object QNFenumero: TIntegerField
      FieldName = 'numero'
      Origin = 'numero'
    end
    object QNFechave: TWideStringField
      FieldName = 'chave'
      Origin = 'chave'
      Size = 44
    end
    object QNFexml_arquivo: TWideStringField
      FieldName = 'xml_arquivo'
      Origin = 'xml_arquivo'
      Size = 100
    end
  end
  object QPessoas: TFDQuery
    Connection = FDConnection1
    SQL.Strings = (
      'select * from pessoas')
    Left = 120
    Top = 216
    object QPessoasid: TFDAutoIncField
      FieldName = 'id'
      Origin = 'id'
      ProviderFlags = [pfInWhere, pfInKey]
      ReadOnly = False
    end
    object QPessoasCNPJCPF: TWideStringField
      FieldName = 'CNPJCPF'
      Origin = 'CNPJCPF'
      Size = 14
    end
    object QPessoasIE: TWideMemoField
      FieldName = 'IE'
      Origin = 'IE'
      BlobType = ftWideMemo
    end
    object QPessoasxNome: TWideStringField
      FieldName = 'xNome'
      Origin = 'xNome'
      Size = 80
    end
    object QPessoasemail: TWideMemoField
      FieldName = 'email'
      Origin = 'email'
      BlobType = ftWideMemo
    end
    object QPessoasfone: TWideStringField
      FieldName = 'fone'
      Origin = 'fone'
      Size = 15
    end
    object QPessoasCEP: TWideStringField
      FieldName = 'CEP'
      Origin = 'CEP'
      Size = 9
    end
    object QPessoasxLgr: TWideStringField
      FieldName = 'xLgr'
      Origin = 'xLgr'
      Size = 60
    end
    object QPessoasnro: TWideStringField
      FieldName = 'nro'
      Origin = 'nro'
    end
    object QPessoasxCpl: TWideStringField
      FieldName = 'xCpl'
      Origin = 'xCpl'
    end
    object QPessoasxBairro: TWideStringField
      FieldName = 'xBairro'
      Origin = 'xBairro'
      Size = 40
    end
    object QPessoascMun: TIntegerField
      FieldName = 'cMun'
      Origin = 'cMun'
    end
    object QPessoasxMun: TWideStringField
      FieldName = 'xMun'
      Origin = 'xMun'
      Size = 40
    end
    object QPessoasUF: TWideStringField
      FieldName = 'UF'
      Origin = 'UF'
      Size = 2
    end
  end
  object QNFeDetalhes: TFDQuery
    Connection = FDConnection1
    SQL.Strings = (
      'select '
      'nfe.id, '
      'nfe.id_destinatario,'
      'nfe.serie,'
      'nfe.numero,'
      'nfe.chave,'
      'nfe.xml_arquivo,'
      'Destinatario.xNome as DestinatarioNome,'
      'Destinatario.email as DestinatarioEmail'
      'from nfe'
      
        'join pessoas as Destinatario on nfe.id_destinatario = Destinatar' +
        'io.id ')
    Left = 224
    Top = 152
    object QNFeDetalhesid: TFDAutoIncField
      FieldName = 'id'
      Origin = 'id'
      ProviderFlags = [pfInWhere, pfInKey]
      ReadOnly = False
    end
    object QNFeDetalhesid_destinatario: TIntegerField
      FieldName = 'id_destinatario'
      Origin = 'id_destinatario'
    end
    object QNFeDetalhesserie: TIntegerField
      FieldName = 'serie'
      Origin = 'serie'
    end
    object QNFeDetalhesnumero: TIntegerField
      FieldName = 'numero'
      Origin = 'numero'
    end
    object QNFeDetalheschave: TWideStringField
      FieldName = 'chave'
      Origin = 'chave'
      Size = 44
    end
    object QNFeDetalhesxml_arquivo: TWideStringField
      FieldName = 'xml_arquivo'
      Origin = 'xml_arquivo'
      Size = 100
    end
    object QNFeDetalhesDestinatarioNome: TWideStringField
      AutoGenerateValue = arDefault
      FieldName = 'DestinatarioNome'
      Origin = 'xNome'
      ProviderFlags = []
      ReadOnly = True
      Size = 80
    end
    object QNFeDetalhesDestinatarioEmail: TWideMemoField
      AutoGenerateValue = arDefault
      FieldName = 'DestinatarioEmail'
      Origin = 'email'
      ProviderFlags = []
      ReadOnly = True
      BlobType = ftWideMemo
    end
  end
end

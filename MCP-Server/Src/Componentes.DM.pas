unit Componentes.DM;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  System.StrUtils,
  System.Math,
  ACBrDFeConfiguracoes,
  ACBrDFeSSL,
  ACBrDFeOpenSSL,
  ACBrDFeUtil,
  ACBrUtil.FilesIO,
  ACBrNFeNotasFiscais,
  ACBrNFeConfiguracoes,
  blcksock,
  pcnConversao,
  pcnConversaoNFe,
  ACBrMail,
  ACBrDFeReport,
  ACBrDFeDANFeReport,
  ACBrNFeDANFEClass,
  ACBrNFeDANFeRLClass,
  ACBrBase,
  ACBrDFe,
  ACBrNFe,
  Emitente;

type
  TComponentesDM = class(TDataModule)
    ACBrNFe1: TACBrNFe;
    ACBrNFeDANFeRL1: TACBrNFeDANFeRL;
    ACBrMail1: TACBrMail;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure ConfigurarComponentes;
    function GetFileNameConfiguracoesIni: string;
    procedure ConfigurarEmail(const AIniFile: TIniFile);
  public

  end;

var
  ComponentesDM: TComponentesDM;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TComponentesDM.DataModuleCreate(Sender: TObject);
begin
  Self.ConfigurarComponentes;
end;

function TComponentesDM.GetFileNameConfiguracoesIni: string;
begin
  Result := '..\..\Configuracoes\Configuracoes.ini';
end;

procedure TComponentesDM.ConfigurarComponentes;
var
  IniFile: String;
  Ini: TIniFile;
  LOk: Boolean;
begin
  IniFile := Self.GetFileNameConfiguracoesIni; //ChangeFileExt(ParamStr(0), '.ini');

  Ini := TIniFile.Create(IniFile);
  try
    ACBrNFe1.Configuracoes.Certificados.URLPFX := Ini.ReadString( 'Certificado', 'URL', '');
    ACBrNFe1.Configuracoes.Certificados.ArquivoPFX := Ini.ReadString( 'Certificado', 'Caminho', '');
    ACBrNFe1.Configuracoes.Certificados.Senha := AnsiString(Ini.ReadString( 'Certificado', 'Senha',  ''));
    ACBrNFe1.Configuracoes.Certificados.NumeroSerie := Ini.ReadString( 'Certificado', 'NumSerie', '');

    ACBrNFe1.SSL.DescarregarCertificado;

    ACBrNFe1.Configuracoes.Geral.SSLLib := TSSLLib(Ini.ReadInteger('Certificado', 'SSLLib',     4));
    ACBrNFe1.Configuracoes.Geral.SSLCryptLib   := TSSLCryptLib(Ini.ReadInteger('Certificado', 'CryptLib',   0));
    ACBrNFe1.Configuracoes.Geral.SSLHttpLib    := TSSLHttpLib(Ini.ReadInteger('Certificado', 'HttpLib',    0));
    ACBrNFe1.Configuracoes.Geral.SSLXmlSignLib := TSSLXmlSignLib(Ini.ReadInteger('Certificado', 'XmlSignLib', 0));
    ACBrNFe1.Configuracoes.Geral.Salvar := Ini.ReadBool('Geral', 'Salvar',         True);
    ACBrNFe1.Configuracoes.Geral.FormaEmissao     := TpcnTipoEmissao(Ini.ReadInteger('Geral', 'FormaEmissao',     0));
    ACBrNFe1.Configuracoes.Geral.ModeloDF         := TpcnModeloDF(Ini.ReadInteger('Geral', 'ModeloDF',         0));
    ACBrNFe1.Configuracoes.Geral.VersaoDF         := TpcnVersaoDF(Ini.ReadInteger('Geral', 'VersaoDF',       3));
    ACBrNFe1.Configuracoes.Geral.IdCSC            := Ini.ReadString( 'Geral', 'IdToken',        '');
    ACBrNFe1.Configuracoes.Geral.CSC              := Ini.ReadString( 'Geral', 'Token',          '');
    ACBrNFe1.Configuracoes.Geral.VersaoQRCode     := TpcnVersaoQrCode(Ini.ReadInteger('Geral', 'VersaoQRCode',   2));
    ACBrNFe1.Configuracoes.Geral.ExibirErroSchema := Ini.ReadBool(   'Geral', 'ExibirErroSchema', True);
    ACBrNFe1.Configuracoes.Geral.FormatoAlerta       := Ini.ReadString( 'Geral', 'FormatoAlerta',    'TAG:%TAGNIVEL% ID:%ID%/%TAG%(%DESCRICAO%) - %MSG%.');
    ACBrNFe1.Configuracoes.Geral.RetirarAcentos := Ini.ReadBool(   'Geral', 'RetirarAcentos', True);

    ACBrNFe1.SSL.SSLType := TSSLType(Ini.ReadInteger('WebService', 'SSLType', 5));
    ACBrNFe1.Configuracoes.WebServices.SSLType := TSSLType(Ini.ReadInteger('WebService', 'SSLType', 5));
    ACBrNFe1.Configuracoes.WebServices.UF := Ini.ReadString('WebService', 'UF', 'SP');
    ACBrNFe1.Configuracoes.WebServices.Ambiente := taHomologacao; //StrToTpAmb(LOk, IntToStr(Ini.ReadInteger('WebService', 'Ambiente',   0)+1));
    ACBrNFe1.Configuracoes.WebServices.Visualizar := Ini.ReadBool('WebService', 'Visualizar', False);
    ACBrNFe1.Configuracoes.WebServices.Salvar := Ini.ReadBool('WebService', 'SalvarSOAP', False);
    ACBrNFe1.Configuracoes.WebServices.AjustaAguardaConsultaRet := Ini.ReadBool('WebService', 'AjustarAut', False);
    ACBrNFe1.Configuracoes.WebServices.Tentativas := StrToIntDef(Ini.ReadString( 'WebService', 'Tentativas', '5'), 5);
    var LIntervalo := Ini.ReadString( 'WebService', 'Intervalo',  '0');
    if not LIntervalo.Trim.IsEmpty then
      ACBrNFe1.Configuracoes.WebServices.IntervaloTentativas := ifThen(StrToInt(LIntervalo) < 1000, StrToInt(LIntervalo) * 1000, StrToInt(LIntervalo));
    ACBrNFe1.Configuracoes.WebServices.TimeOut        := Ini.ReadInteger('WebService', 'TimeOut',    5000);
    ACBrNFe1.Configuracoes.WebServices.ProxyHost  := Ini.ReadString('Proxy', 'Host',  '');
    ACBrNFe1.Configuracoes.WebServices.ProxyPort := Ini.ReadString('Proxy', 'Porta', '');
    ACBrNFe1.Configuracoes.WebServices.ProxyUser  := Ini.ReadString('Proxy', 'User',  '');
    ACBrNFe1.Configuracoes.WebServices.ProxyPass := Ini.ReadString('Proxy', 'Pass',  '');

    ACBrNFe1.Configuracoes.Arquivos.PathSchemas := Ini.ReadString( 'Geral', 'PathSchemas', PathWithDelim('..\..\Schemas\NFe'));
    ACBrNFe1.Configuracoes.Arquivos.Salvar       := Ini.ReadBool(  'Arquivos', 'Salvar',           false);
    ACBrNFe1.Configuracoes.Arquivos.SepararPorMes      := Ini.ReadBool(  'Arquivos', 'PastaMensal',      false);
    ACBrNFe1.Configuracoes.Arquivos.AdicionarLiteral  := Ini.ReadBool(  'Arquivos', 'AddLiteral',       false);
    ACBrNFe1.Configuracoes.Arquivos.EmissaoPathNFe   := Ini.ReadBool(  'Arquivos', 'EmissaoPathNFe',   false);
    ACBrNFe1.Configuracoes.Arquivos.SalvarEvento  := Ini.ReadBool(  'Arquivos', 'SalvarPathEvento', false);
    ACBrNFe1.Configuracoes.Arquivos.SepararPorCNPJ   := Ini.ReadBool(  'Arquivos', 'SepararPorCNPJ',   false);
    ACBrNFe1.Configuracoes.Arquivos.SepararPorModelo := Ini.ReadBool(  'Arquivos', 'SepararPorModelo', false);
    ACBrNFe1.Configuracoes.Arquivos.PathNFe          := Ini.ReadString('Arquivos', 'PathNFe',          '');
    ACBrNFe1.Configuracoes.Arquivos.PathInu             := Ini.ReadString('Arquivos', 'PathInu',          '');
    ACBrNFe1.Configuracoes.Arquivos.PathEvento          := Ini.ReadString('Arquivos', 'PathEvento',       '');

    // IdCSRT e CSRT do Responsável Técnico, no momento só a SEFAZ-PR esta exigindo
    ACBrNFe1.Configuracoes.RespTec.idCSRT := StrToIntDef(Ini.ReadString('RespTecnico', 'IdCSRT', ''), 0);
    ACBrNFe1.Configuracoes.RespTec.CSRT := Ini.ReadString('RespTecnico', 'CSRT', '');

    ACBrNFe1.DANFE.TipoDANFE := StrToTpImp(LOk, IntToStr(Ini.ReadInteger('DANFE', 'Tipo',  0) + 1));
    if ACBrNFe1.DANFE <> nil then
    begin
      ACBrNFe1.DANFE.Logo    := Ini.ReadString( 'DANFE', 'LogoMarca', '');
      ACBrNFe1.DANFE.PathPDF := Ini.ReadString('Arquivos', 'PathPDF', '');
      ACBrNFe1.DANFE.MargemDireita  := 7;
      ACBrNFe1.DANFE.MargemEsquerda := 7;
      ACBrNFe1.DANFE.MargemSuperior := 5;
      ACBrNFe1.DANFE.MargemInferior := 5;
    end;

    var LEmitente :=  TEmitente.GetInstance;
    LEmitente.CNPJ := Ini.ReadString('Emitente', 'CNPJ',        '');
    LEmitente.IE := Ini.ReadString('Emitente', 'IE',          '');
    LEmitente.RazaoSocial := Ini.ReadString('Emitente', 'RazaoSocial', '');
    LEmitente.Fantasia := Ini.ReadString('Emitente', 'Fantasia',    '');
    LEmitente.Fone := Ini.ReadString('Emitente', 'Fone',        '');
    LEmitente.CEP := Ini.ReadString('Emitente', 'CEP',         '');
    LEmitente.Logradouro := Ini.ReadString('Emitente', 'Logradouro',  '');
    LEmitente.Numero := Ini.ReadString('Emitente', 'Numero',      '');
    LEmitente.Complemento := Ini.ReadString('Emitente', 'Complemento', '');
    LEmitente.Bairro := Ini.ReadString('Emitente', 'Bairro',      '');
    LEmitente.CodCidade := Ini.ReadString('Emitente', 'CodCidade',   '');
    LEmitente.Cidade := Ini.ReadString('Emitente', 'Cidade',      '');
    LEmitente.UF := Ini.ReadString('Emitente', 'UF',          '');
    LEmitente.CRT := Ini.ReadInteger('Emitente', 'CRT', 2);

    Self.ConfigurarEmail(Ini);
  finally
    Ini.Free;
  end;
end;

procedure TComponentesDM.ConfigurarEmail(const AIniFile: TIniFile);
begin
  ACBrMail1.Host := AIniFile.ReadString('Email', 'Host', '');
  ACBrMail1.Port := AIniFile.ReadString('Email', 'Port', '');
  ACBrMail1.Username := AIniFile.ReadString('Email', 'User', '');
  ACBrMail1.Password := AIniFile.ReadString('Email', 'Pass', '');
  ACBrMail1.From := AIniFile.ReadString('Email', 'FromEmail', '');
  ACBrMail1.SetSSL := AIniFile.ReadBool('Email', 'SSL', False);
  ACBrMail1.SetTLS := AIniFile.ReadBool('Email', 'TLS', False);
  ACBrMail1.ReadingConfirmation := False; // Pede confirmacao de leitura do email
  ACBrMail1.UseThread := False;  // Aguarda Envio do Email(nao usa thread)
  ACBrMail1.FromName := 'Code4Delphi - Console';
end;

end.

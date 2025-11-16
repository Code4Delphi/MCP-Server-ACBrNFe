unit PreencherNFe;

interface

uses
  System.SysUtils,
  ACBrNFe,
  ACBrBase,
  ACBrDFe,
  ACBrUtil.Base,
  ACBrUtil.FilesIO,
  ACBrUtil.DateTime,
  ACBrUtil.Strings,
  ACBrUtil.XMLHTML,
  ACBrNFe.Classes,
  ACBrDFe.Conversao,
  ACBrDFeUtil,
  ACBrNFeNotasFiscais,
  ACBrNFeConfiguracoes,
  pcnConversao,
  pcnConversaoNFe,
  Componentes.DM,
  Emitente,
  InfRespTec,
  Destinatario;

type
  TPreencherNFe = class
  private
    FACBrNFe: TACBrNFe;
    FEmitente: TEmitente;
    FInfRespTec: TInfRespTec;
    FNumero: Integer;
    FGerarCamposReformaTributaria: Boolean;
    FDestinatario: TDestinatario;
    procedure Preencher;
  public
    constructor Create;
    procedure Processar;

    property Numero: Integer read FNumero write FNumero;
    property Destinatario: TDestinatario read FDestinatario write FDestinatario;
    property GerarCamposReformaTributaria: Boolean read FGerarCamposReformaTributaria write FGerarCamposReformaTributaria;
  end;

implementation

constructor TPreencherNFe.Create;
begin
  FACBrNFe := ComponentesDM.ACBrNFe1;
  FEmitente := TEmitente.GetInstance;
  FInfRespTec := TInfRespTec.GetInstance;
  FGerarCamposReformaTributaria := False;
end;

procedure TPreencherNFe.Processar;
begin
  try
    FACBrNFe.NotasFiscais.Clear;

    Self.Preencher;

    FACBrNFe.NotasFiscais.GerarNFe;
    FACBrNFe.Enviar('1', False, True);
  except
    on E: Exception do
    begin
      Writeln('Falha ao enviar nota. Mensagem: ' + E.Message);
      raise;
    end;
  end;
end;

procedure TPreencherNFe.Preencher;
var
  Ok: Boolean;
  NotaF: NotaFiscal;
  Produto: TDetCollectionItem;
  Duplicata: TDupCollectionItem;
  ObsComplementar: TobsContCollectionItem;
  ObsFisco: TobsFiscoCollectionItem;
  InfoPgto: TpagCollectionItem;
begin
  NotaF := FACBrNFe.NotasFiscais.Add;
  NotaF.NFe.Ide.natOp     := 'VENDA PRODUCAO DO ESTAB.';
  NotaF.NFe.Ide.indPag    := ipVista;
  NotaF.NFe.Ide.modelo    := 55;
  NotaF.NFe.Ide.serie     := 1;
  NotaF.NFe.Ide.nNF       := FNumero;
  NotaF.NFe.Ide.cNF       := GerarCodigoDFe(NotaF.NFe.Ide.nNF);
  NotaF.NFe.Ide.dEmi      := Date;
  NotaF.NFe.Ide.dSaiEnt   := Date;
  NotaF.NFe.Ide.hSaiEnt   := Now;

  NotaF.NFe.Ide.idDest := TpcnDestinoOperacao.doInterestadual;

  if FGerarCamposReformaTributaria then
    NotaF.NFe.Ide.dPrevEntrega := Date + 10;

  NotaF.NFe.Ide.tpNF      := tnSaida;
  NotaF.NFe.Ide.tpEmis    := FACBrNFe.Configuracoes.Geral.FormaEmissao; //TpcnTipoEmissao
  NotaF.NFe.Ide.tpAmb     := taHomologacao; //FACBrNFe.Configuracoes.WebServices.Ambiente;
  NotaF.NFe.Ide.verProc   := '1.0.0.0'; //Versão do seu sistema
  NotaF.NFe.Ide.cUF       := UFtoCUF(FEmitente.UF);
  NotaF.NFe.Ide.cMunFG    := StrToIntDef(FEmitente.CodCidade, 0);
  NotaF.NFe.Ide.finNFe    := fnNormal;
  if  Assigned(FACBrNFe.DANFE ) then
    NotaF.NFe.Ide.tpImp := FACBrNFe.DANFE.TipoDANFE;

  NotaF.NFe.Ide.indIntermed := iiSemOperacao;

  // Reforma Tributaria
  if FGerarCamposReformaTributaria then
  begin
    NotaF.NFe.Ide.cMunFGIBS := StrToIntDef(FEmitente.CodCidade, 0);
    NotaF.NFe.Ide.tpNFDebito := tdNenhum;
    NotaF.NFe.Ide.tpNFCredito := tcNenhum;
    NotaF.NFe.Ide.gCompraGov.tpEnteGov := tcgEstados;
    NotaF.NFe.Ide.gCompraGov.pRedutor := 5;
    NotaF.NFe.Ide.gCompraGov.tpOperGov := togFornecimento;
  end;

  //RESPONSAVEL TECNICO
  NotaF.NFe.infRespTec.CNPJ := FInfRespTec.CNPJ;
  NotaF.NFe.infRespTec.xContato := FInfRespTec.xContato;
  NotaF.NFe.infRespTec.email := FInfRespTec.Email;
  NotaF.NFe.infRespTec.fone := FInfRespTec.Fone;

  //EMITENTE
  NotaF.NFe.Emit.CNPJCPF           := FEmitente.CNPJ;
  NotaF.NFe.Emit.IE                := FEmitente.IE;
  NotaF.NFe.Emit.xNome             := FEmitente.RazaoSocial;
  NotaF.NFe.Emit.xFant             := FEmitente.Fantasia;
  NotaF.NFe.Emit.EnderEmit.fone    := FEmitente.Fone;
  NotaF.NFe.Emit.EnderEmit.CEP     := StrToIntDef(FEmitente.CEP, 86870000);
  NotaF.NFe.Emit.EnderEmit.xLgr    := FEmitente.Logradouro;
  NotaF.NFe.Emit.EnderEmit.nro     := FEmitente.Numero;
  NotaF.NFe.Emit.EnderEmit.xCpl    := FEmitente.Complemento;
  NotaF.NFe.Emit.EnderEmit.xBairro := FEmitente.Bairro;
  NotaF.NFe.Emit.EnderEmit.cMun    := StrToIntDef(FEmitente.CodCidade, 0);
  NotaF.NFe.Emit.EnderEmit.xMun    := FEmitente.Cidade;
  NotaF.NFe.Emit.EnderEmit.UF      := FEmitente.UF;
  NotaF.NFe.Emit.enderEmit.cPais   := 1058;
  NotaF.NFe.Emit.enderEmit.xPais   := 'BRASIL';
  NotaF.NFe.Emit.IEST              := '';
  NotaF.NFe.Emit.IM                := '2648800'; // Preencher no caso de existir serviços na nota
  NotaF.NFe.Emit.CNAE              := '6201500'; // Verifique na cidade do emissor da NFe se é permitido
  NotaF.NFe.Emit.CRT  := StrToCRT(Ok, IntToStr(FEmitente.CRT + 1));

  //DESTINATARIO
  NotaF.NFe.Dest.CNPJCPF           := FDestinatario.CNPJCPF;
  NotaF.NFe.Dest.IE                := FDestinatario.IE;
  NotaF.NFe.Dest.ISUF              := '';
  NotaF.NFe.Dest.xNome             := FDestinatario.RazaoSocial;
  NotaF.NFe.Dest.EnderDest.Fone    := FDestinatario.Fone;
  NotaF.NFe.Dest.EnderDest.CEP     := StrToIntDef(FDestinatario.CEP, 0);
  NotaF.NFe.Dest.EnderDest.xLgr    := FDestinatario.Logradouro;
  NotaF.NFe.Dest.EnderDest.nro     := FDestinatario.Numero;
  NotaF.NFe.Dest.EnderDest.xCpl    := FDestinatario.Complemento;
  NotaF.NFe.Dest.EnderDest.xBairro := FDestinatario.Bairro;
  NotaF.NFe.Dest.EnderDest.cMun    := FDestinatario.CodCidade;
  NotaF.NFe.Dest.EnderDest.xMun    := FDestinatario.Cidade;
  NotaF.NFe.Dest.EnderDest.UF      := FDestinatario.UF;
  NotaF.NFe.Dest.EnderDest.cPais   := 1058;
  NotaF.NFe.Dest.EnderDest.xPais   := 'BRASIL';

  //PRODUTOS
  Produto := NotaF.NFe.Det.New;
  Produto.Prod.nItem    := 1; // Número sequencial, para cada item deve ser incrementado
  Produto.Prod.cProd    := '123456';
  Produto.Prod.cEAN     := '7896523206646';
  Produto.Prod.xProd    := 'Camisa Polo ACBr';
  Produto.Prod.NCM      := '61051000';
  if FGerarCamposReformaTributaria then
    Produto.Prod.tpCredPresIBSZFM := tcpSemCredito;
  Produto.Prod.EXTIPI   := '';
  Produto.Prod.CFOP     := '6101'; //'5101';
  Produto.Prod.uCom     := 'UN';
  Produto.Prod.qCom     := 1;
  Produto.Prod.vUnCom   := 100;
  Produto.Prod.vProd    := 100;

  Produto.Prod.cEANTrib  := '7896523206646';
  Produto.Prod.uTrib     := 'UN';
  Produto.Prod.qTrib     := 1;
  Produto.Prod.vUnTrib   := 100;

  Produto.Prod.vOutro    := 0;
  Produto.Prod.vFrete    := 0;
  Produto.Prod.vSeg      := 0;
  Produto.Prod.vDesc     := 0;
  Produto.infAdProd := 'Informacao Adicional do Produto';
  Produto.Prod.cBarra := 'ABC123456';
  Produto.Prod.cBarraTrib := 'ABC123456';

  with Produto.Imposto do
  begin
    vTotTrib := 0;

    with ICMS do
    begin
      orig := oeNacional;
      if NotaF.NFe.Emit.CRT in [crtSimplesExcessoReceita, crtRegimeNormal] then
      begin
        CST := cst20;
        modBC := dbiMargemValorAgregado;
        pRedBC := 0;
        vBC := 100;
        pICMS := 18;
        vICMS := 18;
        vICMSDeson := 8;
        motDesICMS := mdiOutros;
        indDeduzDeson := tieSim;
      end
      else
      begin
        CSOSN   := csosn101;
        modBC   := dbiValorOperacao;
        pCredSN := 5;
        vCredICMSSN := 100 * pCredSN / 100;
        vBC     := 0;
        pICMS   := 0;
        vICMS   := 0;
        modBCST := dbisListaNeutra;
        pMVAST  := 0;
        pRedBCST:= 0;
        vBCST   := 0;
        pICMSST := 0;
        vICMSST := 0;
      end;

      vBCFCPST := 100;
      pFCPST := 2;
      vFCPST := 2;
      vBCSTRet := 0;
      pST := 0;
      vICMSSubstituto := 0;
      vICMSSTRet := 0;
      vBCFCPSTRet := 0;
      pFCPSTRet := 0;
      vFCPSTRet := 0;
      pRedBCEfet := 0;
      vBCEfet := 0;
      pICMSEfet := 0;
      vICMSEfet := 0;
      vICMSSTDeson := 0;
      motDesICMSST := mdiOutros;
      pFCPDif := 0;
      vFCPDif := 0;
      vFCPEfet := 0;
    end;
  end;

  if NotaF.NFe.Emit.CRT in [crtSimplesExcessoReceita, crtRegimeNormal] then
  begin
    NotaF.NFe.Total.ICMSTot.vBC := 100;
    NotaF.NFe.Total.ICMSTot.vICMS := 18;
  end
  else
  begin
    NotaF.NFe.Total.ICMSTot.vBC := 0;
    NotaF.NFe.Total.ICMSTot.vICMS := 0;
  end;

  NotaF.NFe.Total.ICMSTot.vBCST   := 0;
  NotaF.NFe.Total.ICMSTot.vST     := 0;
  NotaF.NFe.Total.ICMSTot.vProd   := 100;
  NotaF.NFe.Total.ICMSTot.vFrete  := 0;
  NotaF.NFe.Total.ICMSTot.vSeg    := 0;
  NotaF.NFe.Total.ICMSTot.vDesc   := 0;
  NotaF.NFe.Total.ICMSTot.vII     := 0;
  NotaF.NFe.Total.ICMSTot.vIPI    := 0;
  NotaF.NFe.Total.ICMSTot.vPIS    := 0;
  NotaF.NFe.Total.ICMSTot.vCOFINS := 0;
  NotaF.NFe.Total.ICMSTot.vOutro  := 0;
  NotaF.NFe.Total.ICMSTot.vNF     := 100;
  NotaF.NFe.Total.ICMSTot.vTotTrib := 0;

  NotaF.NFe.Cobr.Fat.nFat  := '1001'; // 'Numero da Fatura'
  NotaF.NFe.Cobr.Fat.vOrig := 100;
  NotaF.NFe.Cobr.Fat.vDesc := 0;
  NotaF.NFe.Cobr.Fat.vLiq  := 100;

  Duplicata := NotaF.NFe.Cobr.Dup.New;
  Duplicata.nDup  := '001';
  Duplicata.dVenc := now+10;
  Duplicata.vDup  := 50;

  Duplicata := NotaF.NFe.Cobr.Dup.New;
  Duplicata.nDup  := '002';
  Duplicata.dVenc := now+20;
  Duplicata.vDup  := 50;

  NotaF.NFe.InfAdic.infCpl     :=  '';
  NotaF.NFe.InfAdic.infAdFisco :=  '';

  ObsComplementar := NotaF.NFe.InfAdic.obsCont.New;
  ObsComplementar.xCampo := 'ObsCont';
  ObsComplementar.xTexto := 'Texto';

  ObsFisco := NotaF.NFe.InfAdic.obsFisco.New;
  ObsFisco.xCampo := 'ObsFisco';
  ObsFisco.xTexto := 'Texto';

  // YA. Informações de pagamento
  InfoPgto := NotaF.NFe.pag.New;
  InfoPgto.indPag := ipVista;
  InfoPgto.tPag   := fpDinheiro;
  InfoPgto.vPag   := 25; //100
end;

end.

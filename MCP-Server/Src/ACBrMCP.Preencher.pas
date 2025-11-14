unit ACBrMCP.Preencher;

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
  ACBrMCP.Destinatario;

type
  TACBrMCPPreencher = class
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

constructor TACBrMCPPreencher.Create;
begin
  FACBrNFe := ComponentesDM.ACBrNFe1;
  FEmitente := TEmitente.GetInstance;
  FInfRespTec := TInfRespTec.GetInstance;
  FGerarCamposReformaTributaria := False;
end;

procedure TACBrMCPPreencher.Processar;
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

procedure TACBrMCPPreencher.Preencher;
var
  Ok: Boolean;
  NotaF: NotaFiscal;
  Produto: TDetCollectionItem;
  Volume: TVolCollectionItem;
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

  // Reforma Tributária
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

//  NotaF.NFe.Ide.dhCont := date;
//  NotaF.NFe.Ide.xJust  := 'Justificativa Contingencia';

  {
    valores aceitos pelo campo:
    iiSemOperacao, iiOperacaoSemIntermediador, iiOperacaoComIntermediador
  }
  // Indicador de intermediador/marketplace
  NotaF.NFe.Ide.indIntermed := iiSemOperacao;

  NotaF.NFe.infRespTec.CNPJ := FInfRespTec.CNPJ;
  NotaF.NFe.infRespTec.xContato := FInfRespTec.xContato;
  NotaF.NFe.infRespTec.email := FInfRespTec.Email;
  NotaF.NFe.infRespTec.fone := FInfRespTec.Fone;

  // Reforma Tributária
  if FGerarCamposReformaTributaria then
  begin
    NotaF.NFe.Ide.cMunFGIBS := StrToIntDef(FEmitente.CodCidade, 0);

    NotaF.NFe.Ide.tpNFDebito := tdNenhum;
    NotaF.NFe.Ide.tpNFCredito := tcNenhum;

    NotaF.NFe.Ide.gCompraGov.tpEnteGov := tcgEstados;
    NotaF.NFe.Ide.gCompraGov.pRedutor := 5;
    NotaF.NFe.Ide.gCompraGov.tpOperGov := togFornecimento;

//    Informado para abater as parcelas de antecipação de pagamento, conforme Art. 10. § 4º
//    refNFe: Referência uma NF-e (modelo 55) emitida anteriormente, referente a pagamento antecipado

    with NotaF.NFe.Ide.gPagAntecipado.New do
      refNFe := '12345678901234567890123456789012345678901234';

    with NotaF.NFe.Ide.gPagAntecipado.New do
      refNFe := '12345678901234567890123456789012345678904567';
  end;

  //Para NFe referenciada use os campos abaixo
  (*
  Referenciada := NotaF.NFe.Ide.NFref.Add;
  Referenciada.refNFe       := ''; //NFe Eletronica

  Referenciada.RefNF.cUF    := 0;  // |
  Referenciada.RefNF.AAMM   := ''; // |
  Referenciada.RefNF.CNPJ   := ''; // |
  Referenciada.RefNF.modelo := 1;  // |- NFe Modelo 1/1A
  Referenciada.RefNF.serie  := 1;  // |
  Referenciada.RefNF.nNF    := 0;  // |

  Referenciada.RefNFP.cUF     := 0;  // |
  Referenciada.RefNFP.AAMM    := ''; // |
  Referenciada.RefNFP.CNPJCPF := ''; // |
  Referenciada.RefNFP.IE      := ''; // |- NF produtor Rural
  Referenciada.RefNFP.modelo  := ''; // |
  Referenciada.RefNFP.serie   := 1;  // |
  Referenciada.RefNFP.nNF     := 0;  // |

  Referenciada.RefECF.modelo  := ECFModRef2B; // |
  Referenciada.RefECF.nECF    := '';          // |- Cupom Fiscal
  Referenciada.RefECF.nCOO    := '';          // |
  *)
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
                                                 // a inclusão de serviços na NFe

  // esta sendo somando 1 uma vez que o ItemIndex inicia do zero e devemos
  // passar os valores 1, 2 ou 3
  // (1-crtSimplesNacional, 2-crtSimplesExcessoReceita, 3-crtRegimeNormal)
  NotaF.NFe.Emit.CRT  := StrToCRT(Ok, IntToStr(FEmitente.CRT + 1));

//Para NFe Avulsa preencha os campos abaixo

  NotaF.NFe.Avulsa.CNPJ    := '';
  NotaF.NFe.Avulsa.xOrgao  := '';
  NotaF.NFe.Avulsa.matr    := '';
  NotaF.NFe.Avulsa.xAgente := '';
  NotaF.NFe.Avulsa.fone    := '';
  NotaF.NFe.Avulsa.UF      := '';
  NotaF.NFe.Avulsa.nDAR    := '';
  NotaF.NFe.Avulsa.dEmi    := now;
  NotaF.NFe.Avulsa.vDAR    := 0;
  NotaF.NFe.Avulsa.repEmi  := '';
  NotaF.NFe.Avulsa.dPag    := now;

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

//Use os campos abaixo para informar o endereço de retirada quando for diferente do Remetente/Destinatário

  NotaF.NFe.Retirada.CNPJCPF := '';
  NotaF.NFe.Retirada.xLgr    := '';
  NotaF.NFe.Retirada.nro     := '';
  NotaF.NFe.Retirada.xCpl    := '';
  NotaF.NFe.Retirada.xBairro := '';
  NotaF.NFe.Retirada.cMun    := 0;
  NotaF.NFe.Retirada.xMun    := '';
  NotaF.NFe.Retirada.UF      := '';

//Use os campos abaixo para informar o endereço de entrega quando for diferente do Remetente/Destinatário

  NotaF.NFe.Entrega.CNPJCPF := '';
  NotaF.NFe.Entrega.xLgr    := '';
  NotaF.NFe.Entrega.nro     := '';
  NotaF.NFe.Entrega.xCpl    := '';
  NotaF.NFe.Entrega.xBairro := '';
  NotaF.NFe.Entrega.cMun    := 0;
  NotaF.NFe.Entrega.xMun    := '';
  NotaF.NFe.Entrega.UF      := '';

//Adicionando Produtos
  Produto := NotaF.NFe.Det.New;
  Produto.Prod.nItem    := 1; // Número sequencial, para cada item deve ser incrementado
  Produto.Prod.cProd    := '123456';
  Produto.Prod.cEAN     := '7896523206646';
  Produto.Prod.xProd    := 'Camisa Polo ACBr';
  Produto.Prod.NCM      := '61051000';

  // Reforma Tributária
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

  //Produto.Prod.CEST := '1111111';

  Produto.infAdProd := 'Informacao Adicional do Produto';

  {
    abaixo os campos incluidos no layout a partir da NT 2020/005
  }
  // Opcional - Preencher com o Código de Barras próprio ou de terceiros que seja diferente do padrão GTIN
  // por exemplo: código de barras de catálogo, partnumber, etc
  Produto.Prod.cBarra := 'ABC123456';
  // Opcional - Preencher com o Código de Barras próprio ou de terceiros que seja diferente do padrão GTIN
  //  correspondente àquele da menor unidade comercializável identificado por Código de Barras
  // por exemplo: código de barras de catálogo, partnumber, etc
  Produto.Prod.cBarraTrib := 'ABC123456';

  // Declaração de Importação. Pode ser adicionada várias através do comando Prod.DI.Add
  (*
  DI := Produto.Prod.DI.Add;
  DI.nDi         := '';
  DI.dDi         := now;
  DI.xLocDesemb  := '';
  DI.UFDesemb    := '';
  DI.dDesemb     := now;
  {
    tvMaritima, tvFluvial, tvLacustre, tvAerea, tvPostal, tvFerroviaria, tvRodoviaria,

    abaixo os novos valores incluidos a partir da NT 2020/005

    tvConduto, tvMeiosProprios, tvEntradaSaidaFicta, tvCourier, tvEmMaos, tvPorReboque
  }
  DI.tpViaTransp := tvRodoviaria;
  DI.vAFRMM := 0;
  {
    tiContaPropria, tiContaOrdem, tiEncomenda
  }
  DI.tpIntermedio := tiContaPropria;
  DI.CNPJ := '';
  DI.UFTerceiro := '';
  DI.cExportador := '';

  Adicao := DI.adi.Add;
  Adicao.nAdicao     := 1;
  Adicao.nSeqAdi     := 1;
  Adicao.cFabricante := '';
  Adicao.vDescDI     := 0;
  Adicao.nDraw       := '';
  *)

//Campos para venda de veículos novos

  Produto.Prod.veicProd.tpOP    := toVendaConcessionaria;
  Produto.Prod.veicProd.chassi  := '';
  Produto.Prod.veicProd.cCor    := '';
  Produto.Prod.veicProd.xCor    := '';
  Produto.Prod.veicProd.pot     := '';
  Produto.Prod.veicProd.Cilin   := '';
  Produto.Prod.veicProd.pesoL   := '';
  Produto.Prod.veicProd.pesoB   := '';
  Produto.Prod.veicProd.nSerie  := '';
  Produto.Prod.veicProd.tpComb  := '';
  Produto.Prod.veicProd.nMotor  := '';
  Produto.Prod.veicProd.CMT     := '';
  Produto.Prod.veicProd.dist    := '';
  Produto.Prod.veicProd.anoMod  := 0;
  Produto.Prod.veicProd.anoFab  := 0;
  Produto.Prod.veicProd.tpPint  := '';
  Produto.Prod.veicProd.tpVeic  := 0;
  Produto.Prod.veicProd.espVeic := 0;
  Produto.Prod.veicProd.VIN     := '';
  Produto.Prod.veicProd.condVeic := cvAcabado;
  Produto.Prod.veicProd.cMod    := '';

// Campos de Rastreabilidade do produto
  {
  O grupo <rastro> permiti a rastreabilidade de qualquer produto sujeito a
  regulações sanitárias, casos de recolhimento/recall, além de defensivos agrícolas,
  produtos veterinários, odontológicos, medicamentos, bebidas, águas envasadas,
  embalagens, etc., a partir da indicação de informações de número de lote,
  data de fabricação/produção, data de validade, etc.
  Obrigatório o preenchimento deste grupo no caso de medicamentos e
  produtos farmacêuticos.
  }

  // Ocorrências: 0 - 500
  (*
  Rastro := Produto.Prod.rastro.Add;

  Rastro.nLote  := '17H8F5';
  Rastro.qLote  := 1;
  Rastro.dFab   := StrToDate('01/08/2017');
  Rastro.dVal   := StrToDate('01/08/2019');
  Rastro.cAgreg := ''; // Código de Agregação (opcional) de 1 até 20 dígitos
  *)

//Campos específicos para venda de medicamentos

  // Ocorrências: 1 - 500 ==> 1 - 1 (4.00)
  (*
  Medicamento := Produto.Prod.med.Add;

  Medicamento.cProdANVISA := '1256802470029';
  Medicamento.vPMC        := 100.00; // Preço máximo consumidor
  *)

//Campos específicos para venda de armamento
  (*
  Arma := Produto.Prod.arma.Add;
  Arma.nSerie := 0;
  Arma.tpArma := taUsoPermitido;
  Arma.nCano  := 0;
  Arma.descr  := '';
  *)

//Campos específicos para agropecuario / defensivo
// Devemos gerar somente o grupo defensivo ou o grupo guiaTransito
(*
  Defensivo := Agropecuario.defensivo.Add;
  Defensivo.nReceituario := '123';
  Defensivo.CPFRespTec := '12345678901';
*)

//Campos específicos para agropecuario / guiaTransito
(*
  Agropecuario.guiaTransito.tpGuia := tpgGuiaFlorestal;
  Agropecuario.guiaTransito.UFGuia := 'SP';
  Agropecuario.guiaTransito.serieGuia := '1';
  Agropecuario.guiaTransito.nGuia := '1';
*)

//Campos específicos para venda de combustível(distribuidoras)

  Produto.Prod.comb.cProdANP := 0;
  Produto.Prod.comb.CODIF    := '';
  Produto.Prod.comb.qTemp    := 0;
  Produto.Prod.comb.UFcons   := '';

  Produto.Prod.comb.CIDE.qBCprod   := 0;
  Produto.Prod.comb.CIDE.vAliqProd := 0;
  Produto.Prod.comb.CIDE.vCIDE     := 0;

  Produto.Prod.comb.ICMS.vBCICMS   := 0;
  Produto.Prod.comb.ICMS.vICMS     := 0;
  Produto.Prod.comb.ICMS.vBCICMSST := 0;
  Produto.Prod.comb.ICMS.vICMSST   := 0;

  Produto.Prod.comb.ICMSInter.vBCICMSSTDest := 0;
  Produto.Prod.comb.ICMSInter.vICMSSTDest   := 0;

  Produto.Prod.comb.ICMSCons.vBCICMSSTCons := 0;
  Produto.Prod.comb.ICMSCons.vICMSSTCons   := 0;
  Produto.Prod.comb.ICMSCons.UFcons        := '';

  // Reforma Tributária
  if FGerarCamposReformaTributaria then
  begin
    // Indicador de fornecimento de bem móvel usado
    Produto.Prod.indBemMovelUsado := tieNenhum;

    // Valor total do Item, correspondente à sua participação no total da nota.
    // A soma dos itens deverá corresponder ao total da nota.
    Produto.vItem := 100;
    // Referenciamento de item de outro Documento Fiscal Eletrônico - DF-e
    Produto.DFeReferenciado.chaveAcesso := '';
    Produto.DFeReferenciado.nItem := 1;
  end;

  with Produto.Imposto do
  begin
    // lei da transparencia nos impostos
    vTotTrib := 0;

    with ICMS do
    begin
      // caso o CRT seja:
      // 1=Simples Nacional
      // Os valores aceitos para CSOSN são:
      // csosn101, csosn102, csosn103, csosn201, csosn202, csosn203,
      // csosn300, csosn400, csosn500,csosn900

      // 2=Simples Nacional, excesso sublimite de receita bruta;
      // ou 3=Regime Normal.
      // Os valores aceitos para CST são:
      // cst00, cst10, cst20, cst30, cst40, cst41, cst45, cst50, cst51,
      // cst60, cst70, cst80, cst81, cst90, cstPart10, cstPart90,
      // cstRep41, cstVazio, cstICMSOutraUF, cstICMSSN, cstRep60

      // (consulte o contador do seu cliente para saber qual deve ser utilizado)
      // Pode variar de um produto para outro.

      orig := oeNacional;

      //Grupo de Tributação do ICMS Monofásico sobre combustíveis.
      (*
      CST       := cst02;
      qBCMono   := 100;
      adRemICMS := 10;
      vICMSMono := 10;
      *)
      //Grupo de Tributação do ICMS Monofásico sobre combustíveis.
      (*
      CST          := cst15;
      qBCMono      := 100;
      adRemICMS    := 10;
      vICMSMono    := 10;
      qBCMonoReten := 100;
      adRemICMSReten := 10;
      vICMSMonoReten := 10;
      pRedAdRem      := 10;
      motRedAdRem    := TmotRedAdRem.motTranspColetivo;
      *)
      //Grupo de Tributação do ICMS Monofásico sobre combustíveis.
      (*
      CST           := cst53;
      qBCMono       := 100;
      adRemICMS     := 10;
      vICMSMonoOp   := 10;
      pDif          := 10;
      vICMSMonoDif  := 1;
      vICMSMono     := 10;
      *)
      //Grupo de Tributação do ICMS Monofásico sobre combustíveis.
      (*
      CST           := cst61;
      qBCMonoRet    := 100;
      adRemICMSRet  := 10;
      vICMSMonoRet  := 10;
      *)

      if NotaF.NFe.Emit.CRT in [crtSimplesExcessoReceita, crtRegimeNormal] then
      begin
      {
        CST     := cst00;
        modBC   := dbiPrecoTabelado;
        vBC     := 100;
        pICMS   := 18;
        vICMS   := 18;
        modBCST := dbisMargemValorAgregado;
        pMVAST  := 0;
        pRedBCST:= 0;
        vBCST   := 0;
        pICMSST := 0;
        vICMSST := 0;
        pRedBC  := 0;
      }
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

      {
        abaixo os campos incluidos no layout a partir da NT 2020/005
      }
      // Informar apenas nos motivos de desoneração documentados abaixo
      vICMSSTDeson := 0;
      {
        o campo abaixo só aceita os valores:
        mdiProdutorAgropecuario, mdiOutros, mdiOrgaoFomento
        Campo será preenchido quando o campo anterior estiver preenchido.
      }
      motDesICMSST := mdiOutros;

      // Percentual do diferimento do ICMS relativo ao Fundo de Combate à Pobreza (FCP).
      // No caso de diferimento total, informar o percentual de diferimento "100"
      pFCPDif := 0;
      // Valor do ICMS relativo ao Fundo de Combate à Pobreza (FCP) diferido
      vFCPDif := 0;
      // Valor do ICMS relativo ao Fundo de Combate à Pobreza (FCP) realmente devido.
      vFCPEfet := 0;
    end;

    with ICMSUFDest do
    begin
      // partilha do ICMS e fundo de probreza
      vBCUFDest      := 0.00;
      pFCPUFDest     := 0.00;
      pICMSUFDest    := 0.00;
      pICMSInter     := 0.00;
      pICMSInterPart := 0.00;
      vFCPUFDest     := 0.00;
      vICMSUFDest    := 0.00;
      vICMSUFRemet   := 0.00;
    end;

    (*
    // IPI, se hpouver...
    with IPI do
    begin
      CST      := ipi99;
      clEnq    := '999';
      CNPJProd := '';
      cSelo    := '';
      qSelo    := 0;
      cEnq     := '';

      vBC    := 100;
      qUnid  := 0;
      vUnid  := 0;
      pIPI   := 5;
      vIPI   := 5;
    end;
    *)

    with II do
    begin
      II.vBc      := 0;
      II.vDespAdu := 0;
      II.vII      := 0;
      II.vIOF     := 0;
    end;

    with PIS do
    begin
      CST  := pis99;
      vBC  := 0;
      pPIS := 0;
      vPIS := 0;

      qBCProd   := 0;
      vAliqProd := 0;
      vPIS      := 0;
    end;

    with PISST do
    begin
      vBc       := 0;
      pPis      := 0;
      qBCProd   := 0;
      vAliqProd := 0;
      vPIS      := 0;
      {
        abaixo o campo incluido no layout a partir da NT 2020/005
      }
      {
        valores aceitos pelo campo:
        ispNenhum, ispPISSTNaoCompoe, ispPISSTCompoe
      }
      // Indica se o valor do PISST compõe o valor total da NF-e
      IndSomaPISST :=  ispNenhum;
    end;

    with COFINS do
    begin
      CST     := cof99;
      vBC     := 0;
      pCOFINS := 0;
      vCOFINS := 0;
      qBCProd   := 0;
      vAliqProd := 0;
    end;

    with COFINSST do
    begin
      vBC       := 0;
      pCOFINS   := 0;
      qBCProd   := 0;
      vAliqProd := 0;
      vCOFINS   := 0;
      {
        abaixo o campo incluido no layout a partir da NT 2020/005
      }
      {
        valores aceitos pelo campo:
        iscNenhum, iscCOFINSSTNaoCompoe, iscCOFINSSTCompoe
      }
      // Indica se o valor da COFINS ST compõe o valor total da NF-e
      indSomaCOFINSST :=  iscNenhum;
    end;

    // Reforma Tributária
    if FGerarCamposReformaTributaria then
    begin
      //  Informações do tributo: Imposto Seletivo
      ISel.CSTIS := cstis000;
      ISel.cClassTribIS := '000001';

      ISel.vBCIS := 100;
      ISel.pIS := 5;
      ISel.pISEspec := 5;
      ISel.uTrib := 'UNIDAD';
      ISel.qTrib := 10;
      ISel.vIS := 100;

      {
        Utilize os CST (cst000, cst200, cst220, cst510 e cst550) e os cClassTrib
        correspondentes para gerar o grupo IBSCBS
        Utilize o CST cst620 e os cClassTrib correspondentes para gerar o grupo
        IBSCBSMono
        Utilize o CST cst800 e os cClassTrib correspondentes para gerar o grupo
        gTransfCred
        Utilize o CST cst810 e os cClassTrib correspondentes para gerar o grupo
        gCredPresIBSZFM
      }

      //  Informações do tributo: IBS / CBS
      IBSCBS.CST := cst811;
      IBSCBS.cClassTrib := '000001';
      IBSCBS.indDoacao := tieSim;

      IBSCBS.gIBSCBS.vBC := 100;

      IBSCBS.gIBSCBS.gIBSUF.pIBSUF := 5;
      IBSCBS.gIBSCBS.gIBSUF.vIBSUF := 100;

      IBSCBS.gIBSCBS.gIBSUF.gDif.pDif := 5;
      IBSCBS.gIBSCBS.gIBSUF.gDif.vDif := 100;

      IBSCBS.gIBSCBS.gIBSUF.gDevTrib.vDevTrib := 100;

      IBSCBS.gIBSCBS.gIBSUF.gRed.pRedAliq := 5;
      IBSCBS.gIBSCBS.gIBSUF.gRed.pAliqEfet := 5;

      IBSCBS.gIBSCBS.gIBSMun.pIBSMun := 5;
      IBSCBS.gIBSCBS.gIBSMun.vIBSMun := 100;

      IBSCBS.gIBSCBS.gIBSMun.gDif.pDif := 5;
      IBSCBS.gIBSCBS.gIBSMun.gDif.vDif := 100;

      IBSCBS.gIBSCBS.gIBSMun.gDevTrib.vDevTrib := 100;

      IBSCBS.gIBSCBS.gIBSMun.gRed.pRedAliq := 5;
      IBSCBS.gIBSCBS.gIBSMun.gRed.pAliqEfet := 5;

      // vIBS = vIBSUF + vIBSMun
      IBSCBS.gIBSCBS.vIBS := 100;

      IBSCBS.gIBSCBS.gCBS.pCBS := 5;
      IBSCBS.gIBSCBS.gCBS.vCBS := 100;

      IBSCBS.gIBSCBS.gCBS.gDif.pDif := 5;
      IBSCBS.gIBSCBS.gCBS.gDif.vDif := 100;

      IBSCBS.gIBSCBS.gCBS.gDevTrib.vDevTrib := 100;

      IBSCBS.gIBSCBS.gCBS.gRed.pRedAliq := 5;
      IBSCBS.gIBSCBS.gCBS.gRed.pAliqEfet := 5;

      IBSCBS.gIBSCBS.gTribRegular.CSTReg := cst000;
      IBSCBS.gIBSCBS.gTribRegular.cClassTribReg := '000001';
      IBSCBS.gIBSCBS.gTribRegular.pAliqEfetRegIBSUF := 5;
      IBSCBS.gIBSCBS.gTribRegular.vTribRegIBSUF := 50;
      IBSCBS.gIBSCBS.gTribRegular.pAliqEfetRegIBSMun := 5;
      IBSCBS.gIBSCBS.gTribRegular.vTribRegIBSMun := 50;
      IBSCBS.gIBSCBS.gTribRegular.pAliqEfetRegCBS := 5;
      IBSCBS.gIBSCBS.gTribRegular.vTribRegCBS := 50;

      // Tipo Tributação Compra Governamental
      IBSCBS.gIBSCBS.gTribCompraGov.pAliqIBSUF := 5;
      IBSCBS.gIBSCBS.gTribCompraGov.vTribIBSUF := 50;
      IBSCBS.gIBSCBS.gTribCompraGov.pAliqIBSMun := 5;
      IBSCBS.gIBSCBS.gTribCompraGov.vTribIBSMun := 50;
      IBSCBS.gIBSCBS.gTribCompraGov.pAliqCBS := 5;
      IBSCBS.gIBSCBS.gTribCompraGov.vTribCBS := 50;

      //  Informações do tributo: IBS / CBS em operações com imposto monofásico
      IBSCBS.gIBSCBSMono.gMonoPadrao.qBCMono := 1;
      IBSCBS.gIBSCBSMono.gMonoPadrao.adRemIBS := 5;
      IBSCBS.gIBSCBSMono.gMonoPadrao.adRemCBS := 5;
      IBSCBS.gIBSCBSMono.gMonoPadrao.vIBSMono := 100;
      IBSCBS.gIBSCBSMono.gMonoPadrao.vCBSMono := 100;

      IBSCBS.gIBSCBSMono.gMonoReten.qBCMonoReten := 1;
      IBSCBS.gIBSCBSMono.gMonoReten.adRemIBSReten := 5;
      IBSCBS.gIBSCBSMono.gMonoReten.vIBSMonoReten := 100;
      IBSCBS.gIBSCBSMono.gMonoReten.vCBSMonoReten := 100;

      IBSCBS.gIBSCBSMono.gMonoRet.qBCMonoRet := 1;
      IBSCBS.gIBSCBSMono.gMonoRet.adRemIBSRet := 5;
      IBSCBS.gIBSCBSMono.gMonoRet.vIBSMonoRet := 100;
      IBSCBS.gIBSCBSMono.gMonoRet.vCBSMonoRet := 100;

      IBSCBS.gIBSCBSMono.gMonoDif.pDifIBS := 5;
      IBSCBS.gIBSCBSMono.gMonoDif.vIBSMonoDif := 100;
      IBSCBS.gIBSCBSMono.gMonoDif.pDifCBS := 5;
      IBSCBS.gIBSCBSMono.gMonoDif.vCBSMonoDif := 100;

      IBSCBS.gIBSCBSMono.vTotIBSMonoItem := 100;
      IBSCBS.gIBSCBSMono.vTotCBSMonoItem := 100;

      //  Informações da Transferencia de Crédito
      IBSCBS.gTransfCred.vIBS := 100;
      IBSCBS.gTransfCred.vCBS := 100;

      //  Informações Ajuste de Competência
      IBSCBS.gAjusteCompet.competApur := Date;
      IBSCBS.gAjusteCompet.vIBS := 100;
      IBSCBS.gAjusteCompet.vCBS := 100;

      //  Informações Estorno de Crédito
      IBSCBS.gEstornoCred.vIBSEstCred := 100;
      IBSCBS.gEstornoCred.vCBSEstCred := 100;

      //  Informações do Crédito Presumido Operacional
      IBSCBS.gCredPresOper.cCredPres := cpNenhum;
      IBSCBS.gCredPresOper.vBCCredPres := 100;
      IBSCBS.gCredPresOper.gIBSCredPres.pCredPres := 5;
      IBSCBS.gCredPresOper.gIBSCredPres.vCredPres := 100;
      IBSCBS.gCredPresOper.gIBSCredPres.vCredPresCondSus := 0;
      IBSCBS.gCredPresOper.gCBSCredPres.pCredPres := 5;
      IBSCBS.gCredPresOper.gCBSCredPres.vCredPres := 100;
      IBSCBS.gCredPresOper.gCBSCredPres.vCredPresCondSus := 0;

      //  Informações do Crédito Presumido IBS ZFM
      // tcpNenhum, tcpSemCredito, tcpBensConsumoFinal, tcpBensCapital,
      // tcpBensIntermediarios, tcpBensInformaticaOutros
      IBSCBS.gCredPresIBSZFM.competApur := Date;
      IBSCBS.gCredPresIBSZFM.tpCredPresIBSZFM := tcpBensInformaticaOutros;
      IBSCBS.gCredPresIBSZFM.vCredPresIBSZFM := 100;
    end;
  end;

  //Adicionando Serviços
  (*
  Servico := NotaF.Nfe.Det.Add;
  Servico.Prod.nItem    := 1; // Número sequencial, para cada item deve ser incrementado
  Servico.Prod.cProd    := '123457';
  Servico.Prod.cEAN     := '';
  Servico.Prod.xProd    := 'Descrição do Serviço';
  Servico.Prod.NCM      := '99';
  Servico.Prod.EXTIPI   := '';
  Servico.Prod.CFOP     := '5933';
  Servico.Prod.uCom     := 'UN';
  Servico.Prod.qCom     := 1;
  Servico.Prod.vUnCom   := 100;
  Servico.Prod.vProd    := 100;

  Servico.Prod.cEANTrib  := '';
  Servico.Prod.uTrib     := 'UN';
  Servico.Prod.qTrib     := 1;
  Servico.Prod.vUnTrib   := 100;

  Servico.Prod.vFrete    := 0;
  Servico.Prod.vSeg      := 0;
  Servico.Prod.vDesc     := 0;

  Servico.infAdProd      := 'Informação Adicional do Serviço';

  //Grupo para serviços
  Servico.Imposto.ISSQN
  Servico.Imposto.cSitTrib  := ISSQNcSitTribNORMAL;
  Servico.Imposto.vBC       := 100;
  Servico.Imposto.vAliq     := 2;
  Servico.Imposto.vISSQN    := 2;
  Servico.Imposto.cMunFG    := 3554003;
  // Preencha este campo usando a tabela disponível
  // em http://www.planalto.gov.br/Ccivil_03/LEIS/LCP/Lcp116.htm
  Servico.Imposto.cListServ := '1402';

  NotaF.NFe.Total.ISSQNtot.vServ   := 100;
  NotaF.NFe.Total.ISSQNTot.vBC     := 100;
  NotaF.NFe.Total.ISSQNTot.vISS    := 2;
  NotaF.NFe.Total.ISSQNTot.vPIS    := 0;
  NotaF.NFe.Total.ISSQNTot.vCOFINS := 0;

*)

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

  // lei da transparencia de impostos
  NotaF.NFe.Total.ICMSTot.vTotTrib := 0;

  // partilha do icms e fundo de probreza
  NotaF.NFe.Total.ICMSTot.vFCPUFDest   := 0.00;
  NotaF.NFe.Total.ICMSTot.vICMSUFDest  := 0.00;
  NotaF.NFe.Total.ICMSTot.vICMSUFRemet := 0.00;

  NotaF.NFe.Total.ICMSTot.vFCPST     := 0;
  NotaF.NFe.Total.ICMSTot.vFCPSTRet  := 0;

  NotaF.NFe.Total.retTrib.vRetPIS    := 0;
  NotaF.NFe.Total.retTrib.vRetCOFINS := 0;
  NotaF.NFe.Total.retTrib.vRetCSLL   := 0;
  NotaF.NFe.Total.retTrib.vBCIRRF    := 0;
  NotaF.NFe.Total.retTrib.vIRRF      := 0;
  NotaF.NFe.Total.retTrib.vBCRetPrev := 0;
  NotaF.NFe.Total.retTrib.vRetPrev   := 0;

  // Reforma Tributária
  if FGerarCamposReformaTributaria then
  begin
    NotaF.NFe.Total.ISTot.vIS := 100;

    NotaF.NFe.Total.IBSCBSTot.vBCIBSCBS := 100;

    NotaF.NFe.Total.IBSCBSTot.gIBS.vIBS := 100;
    NotaF.NFe.Total.IBSCBSTot.gIBS.vCredPres := 100;
    NotaF.NFe.Total.IBSCBSTot.gIBS.vCredPresCondSus := 100;

    NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSUFTot.vDif := 100;
    NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSUFTot.vDevTrib := 100;
    NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSUFTot.vIBSUF := 100;

    NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSMunTot.vDif := 100;
    NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSMunTot.vDevTrib := 100;
    NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSMunTot.vIBSMun := 100;

    NotaF.NFe.Total.IBSCBSTot.gCBS.vDif := 100;
    NotaF.NFe.Total.IBSCBSTot.gCBS.vDevTrib := 100;
    NotaF.NFe.Total.IBSCBSTot.gCBS.vCBS := 100;
    NotaF.NFe.Total.IBSCBSTot.gCBS.vCredPres := 100;
    NotaF.NFe.Total.IBSCBSTot.gCBS.vCredPresCondSus := 100;

    NotaF.NFe.Total.IBSCBSTot.gMono.vIBSMono := 100;
    NotaF.NFe.Total.IBSCBSTot.gMono.vCBSMono := 100;
    NotaF.NFe.Total.IBSCBSTot.gMono.vIBSMonoReten := 100;
    NotaF.NFe.Total.IBSCBSTot.gMono.vCBSMonoReten := 100;
    NotaF.NFe.Total.IBSCBSTot.gMono.vIBSMonoRet := 100;
    NotaF.NFe.Total.IBSCBSTot.gMono.vCBSMonoRet := 100;

    NotaF.NFe.Total.IBSCBSTot.gEstornoCred.vIBSEstCred := 100;
    NotaF.NFe.Total.IBSCBSTot.gEstornoCred.vCBSEstCred := 100;

    // Valor total da NF-e com IBS / CBS / IS
    NotaF.NFe.Total.vNFTot := 100;
  end;

  NotaF.NFe.Transp.modFrete := mfContaEmitente;
  NotaF.NFe.Transp.Transporta.CNPJCPF  := '';
  NotaF.NFe.Transp.Transporta.xNome    := '';
  NotaF.NFe.Transp.Transporta.IE       := '';
  NotaF.NFe.Transp.Transporta.xEnder   := '';
  NotaF.NFe.Transp.Transporta.xMun     := '';
  NotaF.NFe.Transp.Transporta.UF       := '';

  NotaF.NFe.Transp.retTransp.vServ    := 0;
  NotaF.NFe.Transp.retTransp.vBCRet   := 0;
  NotaF.NFe.Transp.retTransp.pICMSRet := 0;
  NotaF.NFe.Transp.retTransp.vICMSRet := 0;
  NotaF.NFe.Transp.retTransp.CFOP     := '';
  NotaF.NFe.Transp.retTransp.cMunFG   := 0;

  Volume := NotaF.NFe.Transp.Vol.New;
  Volume.qVol  := 1;
  Volume.esp   := 'Especie';
  Volume.marca := 'Marca';
  Volume.nVol  := 'Numero';
  Volume.pesoL := 100;
  Volume.pesoB := 110;

  //Lacres do volume. Pode ser adicionado vários
  (*
  Lacre := Volume.Lacres.Add;
  Lacre.nLacre := '';
  *)

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

    // O grupo infIntermed só deve ser gerado nos casos de operação não presencial
    // pela internet em site de terceiros (Intermediadores).
//  NotaF.NFe.infIntermed.CNPJ := '';
//  NotaF.NFe.infIntermed.idCadIntTran := '';

  NotaF.NFe.InfAdic.infCpl     :=  '';
  NotaF.NFe.InfAdic.infAdFisco :=  '';

  ObsComplementar := NotaF.NFe.InfAdic.obsCont.New;
  ObsComplementar.xCampo := 'ObsCont';
  ObsComplementar.xTexto := 'Texto';

  ObsFisco := NotaF.NFe.InfAdic.obsFisco.New;
  ObsFisco.xCampo := 'ObsFisco';
  ObsFisco.xTexto := 'Texto';

//Processo referenciado
  (*
  ProcReferenciado := NotaF.Nfe.InfAdic.procRef.Add;
  ProcReferenciado.nProc := '';
  ProcReferenciado.indProc := ipSEFAZ;
  *)

  NotaF.NFe.exporta.UFembarq   := '';
  NotaF.NFe.exporta.xLocEmbarq := '';

  NotaF.NFe.compra.xNEmp := '';
  NotaF.NFe.compra.xPed  := '';
  NotaF.NFe.compra.xCont := '';

// YA. Informações de pagamento

  InfoPgto := NotaF.NFe.pag.New;
  InfoPgto.indPag := ipVista;
  InfoPgto.tPag   := fpDinheiro;
  InfoPgto.vPag   := 25; //100

// Exemplo de pagamento integrado.

  InfoPgto := NotaF.NFe.pag.New;
  InfoPgto.indPag := ipVista;
  InfoPgto.tPag   := fpCartaoCredito;

  {
    abaixo o campo incluido no layout a partir da NT 2020/006
  }
  {
    se tPag for fpOutro devemos incluir o campo xPag
  InfoPgto.xPag := 'Caderneta';
  }
  InfoPgto.vPag   := 75;
  InfoPgto.tpIntegra := tiPagIntegrado;
  InfoPgto.CNPJ      := '05481336000137';
  InfoPgto.tBand     := bcVisa;
  InfoPgto.cAut      := '1234567890123456';

// YA09 Troco
// Regra opcional: Informar se valor dos pagamentos maior que valor da nota.
// Regra obrigatória: Se informado, Não pode diferir de "(+) vPag (id:YA03) (-) vNF (id:W16)"
//  NotaF.NFe.pag.vTroco := 75;

  {
    abaixo o campo incluido no layout a partir da NT 2020/006
  }
  // CNPJ do Intermediador da Transação (agenciador, plataforma de delivery,
  // marketplace e similar) de serviços e de negócios.
  NotaF.NFe.infIntermed.CNPJ := '';
  // Nome do usuário ou identificação do perfil do vendedor no site do intermediador
  // (agenciador, plataforma de delivery, marketplace e similar) de serviços e de
  // negócios.
  NotaF.NFe.infIntermed.idCadIntTran := '';
end;

end.

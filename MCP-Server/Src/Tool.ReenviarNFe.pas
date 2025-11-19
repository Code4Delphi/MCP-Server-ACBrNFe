unit Tool.ReenviarNFe;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Rtti,
  System.Generics.Collections,
  TMS.MCP.Server,
  TMS.MCP.Tools,
  TMS.MCP.Helpers,
  Database.Dm,
  Componentes.DM;

type
  TToolReenviarNFe = class
  private
    FMCPServer: TTMSMCPServer;
    FDm: TDatabaseDm;
    procedure AddToolReenviarNFe;
    function ReenviarNFe(const Args: array of TValue): TValue;
    procedure EnviarNFePorEmail;
  public
    constructor Create(const AMCPServer: TTMSMCPServer);
    destructor Destroy; override;
    procedure Processar;
  end;

implementation

constructor TToolReenviarNFe.Create(const AMCPServer: TTMSMCPServer);
begin
  FMCPServer := AMCPServer;
  FDm := TDatabaseDm.Create(nil);
end;

destructor TToolReenviarNFe.Destroy;
begin
  FDm.Free;
  inherited;
end;

procedure TToolReenviarNFe.Processar;
begin
  Self.AddToolReenviarNFe;
end;

procedure TToolReenviarNFe.AddToolReenviarNFe;
const
  C_NOME_TOOL = 'ReenviarNFe';
var
  LTool: TTMSMCPTool;
  LProp: TTMSMCPToolProperty;
begin
  FMCPServer.Tools.RegisterTool(C_NOME_TOOL, 'Reenvia a NFe da chave informada', Self.ReenviarNFe);

  LTool := FMCPServer.Tools.FindByName(C_NOME_TOOL);
  LProp := LTool.Properties.Add;
  LProp.Name := 'ChaveDaNFe';
  LProp.Description := 'Chave da NFe a ser reenviada';
  LProp.PropertyType := TTMSMCPToolPropertyType.ptString;
  LProp.Required := True;
end;

function TToolReenviarNFe.ReenviarNFe(const Args: array of TValue): TValue;
var
  LChave: string;
begin
  ComponentesDM.ACBrNFe1.NotasFiscais.Clear;

  if Length(Args) <= 0 then
  begin
    Result := TValue.From<string>('Chave da NFe não informado');
    Exit;
  end;

  LChave := Args[0].AsString.Trim;
  if LChave.Length <> 44 then
  begin
    Result := TValue.From<string>('Informe uma chave válida para reenvio da NFe');
    Exit;
  end;

  if not FDm.QNFeDetalhesGet(LChave) then
  begin
    Result := TValue.From<string>('Não foi encontrado uma NFe com esta chave na base de dados');
    Exit;
  end;

  var LCaminhoArquivo := ComponentesDM.ACBrNFe1.Configuracoes.Arquivos.PathSalvar + FDm.QNFeDetalhesxml_arquivo.AsString;
  Writeln('Caminho XML: ' + LCaminhoArquivo);
  ComponentesDM.ACBrNFe1.NotasFiscais.LoadFromFile(LCaminhoArquivo);

  Self.EnviarNFePorEmail;

  Result := TValue.From<string>('Processo finalizado. Nota reenviada para: ' + FDm.QNFeDetalhesDestinatarioEmail.AsString);
end;

procedure TToolReenviarNFe.EnviarNFePorEmail;
begin
  var LMsg := TStringList.Create;
  try
    LMsg.Add('Nota fiscal REENVIADA.');
    LMsg.Add('Numero: ' + ComponentesDM.ACBrNFe1.NotasFiscais.Items[0].NFe.Ide.nNF.ToString);
    LMsg.Add('Destinatario: ' + FDm.QNFeDetalhesDestinatarioNome.AsString);
    LMsg.Add('');
    LMsg.Add('Atenciosamente, Cesar Cardoso');
    LMsg.Add('Data e hora: ' + DateTimeToStr(Now));

    var LEnviaPDF := False;
    ComponentesDM.ACBrNFe1.NotasFiscais.Items[0].EnviarEmail(FDm.QNFeDetalhesDestinatarioEmail.AsString,
      'REENVIADO pelo MCP ACBr NFe. n.: ' + ComponentesDM.ACBrNFe1.NotasFiscais.Items[0].NFe.Ide.nNF.ToString,
      LMsg, LEnviaPDF, nil, nil);
  finally
    LMsg.Free;
  end;
end;

end.

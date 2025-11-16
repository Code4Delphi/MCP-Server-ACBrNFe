unit ACBrMCP.Server;

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
  TMS.MCP.Transport.StreamableHTTP,
  PreencherNFe,
  Componentes.DM,
  SalvarNFeBD,
  Destinatario;

type
  TServer = class
  private
    FMCPServer: TTMSMCPServer;
    FHTTPTransport: TTMSMCPStreamableHTTPTransport;
    FMsgRetorno: string;
    procedure OnServerLog(Sender: TObject; const LogMessage: string);
    function GerarNFe(const Args: array of TValue): TValue;
    procedure EnviarNFePorEmail(const ADestinatario: TDestinatario);
    procedure GravarNFeNoBanco;
    procedure AddLog(const AMsg: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetupServer;
    procedure Run;
  end;

implementation

const
  HTTP_PORT = 8080;
  HTTP_END_POINT = '/acbr';

constructor TServer.Create;
begin
  FMCPServer := TTMSMCPServer.Create(nil);
  FMCPServer.ServerName := 'ACBrNFe-MCPServer';
  FMCPServer.ServerVersion := '2.0.0';
  FMCPServer.OnLog := OnServerLog;

  //CREATE HTTP TRANSPORT WITH CUSTOM ENDPOINT
  FHTTPTransport := TTMSMCPStreamableHTTPTransport.Create(nil, HTTP_PORT, HTTP_END_POINT);
  FMCPServer.Transport := FHTTPTransport;

  FMsgRetorno := '';
end;

destructor TServer.Destroy;
begin
  FHTTPTransport.Free;
  FMCPServer.Free;
  inherited;
end;

procedure TServer.OnServerLog(Sender: TObject; const LogMessage: string);
begin
  WriteLn(Format('[SERVER] [%s] %s', [DateTimeToStr(Now) ,LogMessage]));
end;

procedure TServer.Run;
begin
  FMCPServer.Start;
  WriteLn('Server running');
  WriteLn('Port: ' + FHTTPTransport.Port.ToString);
  WriteLn('Endpoint: ' + FHTTPTransport.MCPEndpoint);
  WriteLn(Format('http://localhost:%d%s ', [FHTTPTransport.Port, FHTTPTransport.MCPEndpoint]));
  WriteLn('Press Enter to stop...');
  ReadLn;
end;

procedure TServer.SetupServer;
var
  LTool: TTMSMCPTool;
  LProp: TTMSMCPToolProperty;
begin
  FMCPServer.Tools.RegisterTool('GerarNFe', 'Gera uma NF-e com o número e o destinatário informado', Self.GerarNFe);

  LTool := FMCPServer.Tools.FindByName('GerarNFe');
  LProp := LTool.Properties.Add;
  LProp.Name := 'NumeroParaNFe';
  LProp.Description := 'Número para geração da NFe';
  LProp.PropertyType := TTMSMCPToolPropertyType.ptInteger;
  LProp.Required := True;

  LTool := FMCPServer.Tools.FindByName('GerarNFe');
  LProp := LTool.Properties.Add;
  LProp.Name := 'NomeDoDestinatario';
  LProp.Description := 'Nome do destinatario';
  LProp.PropertyType := TTMSMCPToolPropertyType.ptString;
  LProp.Required := True;
end;

function TServer.GerarNFe(const Args: array of TValue): TValue;
var
  LNumero: Integer;
  LNomeDestinatario: string;
  LDestinatario: TDestinatario;
begin
  FMsgRetorno := '';

  if Length(Args) <= 0 then
  begin
    Result := TValue.From<string>('Número para NFe não informado');
    Exit;
  end;

  LNumero := Args[0].AsInteger;
  if LNumero <= 0 then
  begin
    Result := TValue.From<string>('Informe um número válido para emissão da NFe');
    Exit;
  end;

  LNomeDestinatario := Args[1].AsString;
  if LNomeDestinatario.Trim.IsEmpty then
  begin
    Result := TValue.From<string>('Informe o nome do destinatário para emissão da NFe');
    Exit;
  end;

  LDestinatario := TDestinatario.Create;
  try
    if not LDestinatario.GetDadosDoBanco(LNomeDestinatario) then
    begin
      Self.AddLog(LDestinatario.MsgRetorno);
      Result := TValue.From<string>(FMsgRetorno.Trim);
      Exit;
    end;

    var LEnviar := TPreencherNFe.Create;
    try
      LEnviar.Numero := LNumero;
      LEnviar.Destinatario := LDestinatario;
      LEnviar.Processar;
      Self.AddLog('- Nota enviada chave: ' + ComponentesDM.ACBrNFe1.NotasFiscais.Items[0].NFe.procNFe.chNFe);
    finally
      LEnviar.Free;
    end;

    try
      Self.GravarNFeNoBanco;
    except
      on E: Exception do
        Self.AddLog('- Não foi possível gravar os dados no banco de dados. Mensagem; ' + E.Message);
    end;

    try
      Self.EnviarNFePorEmail(LDestinatario);
    except
      on E: Exception do
        Self.AddLog('- Não foi possível enviar o e-mail da nota gerada. Mensagem; ' + E.Message);
    end;

    Result := TValue.From<string>('Processo finalizado. '+ sLineBreak + FMsgRetorno.Trim);
  finally
    LDestinatario.Free;
  end;
end;

procedure TServer.AddLog(const AMsg: string);
begin
  FMsgRetorno := FMsgRetorno + AMsg;
  WriteLn(AMsg);
end;

procedure TServer.GravarNFeNoBanco;
var
  LSalvar: TSalvarNFeBD;
begin
  LSalvar := TSalvarNFeBD.Create;
  try
    LSalvar.GravarNFeNoBanco;
  finally
    LSalvar.Free;
  end;
end;

procedure TServer.EnviarNFePorEmail(const ADestinatario: TDestinatario);
begin
  var LMsg := TStringList.Create;
  try
    LMsg.Add('Nota fiscal emitida ');
    LMsg.Add('Numero: ' + ComponentesDM.ACBrNFe1.NotasFiscais.Items[0].NFe.Ide.nNF.ToString);
    LMsg.Add('Destinatario: ' + ADestinatario.RazaoSocial);
    LMsg.Add('');
    LMsg.Add('Atenciosamente, Cesar Cardoso');
    LMsg.Add('Data e hora: ' + DateTimeToStr(Now));

    var LEnviaPDF := False;
    ComponentesDM.ACBrNFe1.NotasFiscais.Items[0].EnviarEmail(ADestinatario.Email,
      'Enviado pelo MCP ACBr. NFe n.: ' + ComponentesDM.ACBrNFe1.NotasFiscais.Items[0].NFe.Ide.nNF.ToString,
      LMsg, LEnviaPDF, nil, nil);
  finally
    LMsg.Free;
  end;
end;

end.

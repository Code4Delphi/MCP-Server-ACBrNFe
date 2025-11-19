unit Tool.GerarNFe;

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
  Componentes.DM,
  Destinatario,
  PreencherNFe,
  SalvarNFeBD;

type
  TToolGerarNFe = class
  private
    FMCPServer: TTMSMCPServer;
    FMsgRetorno: string;
    procedure AddToolGerarNFe;
    procedure EnviarNFePorEmail(const ADestinatario: TDestinatario);
    function GerarNFe(const Args: array of TValue): TValue;
    procedure GravarNFeNoBanco(const ADestinatario: TDestinatario);
    procedure AddLog(const AMsg: string);
  public
    constructor Create(const AMCPServer: TTMSMCPServer);
    procedure Processar;
  end;

implementation

constructor TToolGerarNFe.Create(const AMCPServer: TTMSMCPServer);
begin
  FMCPServer := AMCPServer;
  FMsgRetorno := '';
end;

procedure TToolGerarNFe.Processar;
begin
  Self.AddToolGerarNFe;
end;

procedure TToolGerarNFe.AddLog(const AMsg: string);
begin
  FMsgRetorno := FMsgRetorno + AMsg;
  WriteLn(AMsg);
end;

procedure TToolGerarNFe.AddToolGerarNFe;
const
  C_NOME_TOOL = 'GerarNFe';
var
  LTool: TTMSMCPTool;
  LProp: TTMSMCPToolProperty;
begin
  FMCPServer.Tools.RegisterTool(C_NOME_TOOL, 'Gera uma NF-e com o número e o destinatário informado', Self.GerarNFe);

  LTool := FMCPServer.Tools.FindByName(C_NOME_TOOL);
  LProp := LTool.Properties.Add;
  LProp.Name := 'NumeroParaNFe';
  LProp.Description := 'Número para geração da NFe';
  LProp.PropertyType := TTMSMCPToolPropertyType.ptInteger;
  LProp.Required := True;

  LTool := FMCPServer.Tools.FindByName(C_NOME_TOOL);
  LProp := LTool.Properties.Add;
  LProp.Name := 'NomeDoDestinatario';
  LProp.Description := 'Nome do destinatario';
  LProp.PropertyType := TTMSMCPToolPropertyType.ptString;
  LProp.Required := True;
end;

function TToolGerarNFe.GerarNFe(const Args: array of TValue): TValue;
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
      Self.GravarNFeNoBanco(LDestinatario);
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

procedure TToolGerarNFe.EnviarNFePorEmail(const ADestinatario: TDestinatario);
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

procedure TToolGerarNFe.GravarNFeNoBanco(const ADestinatario: TDestinatario);
var
  LSalvar: TSalvarNFeBD;
begin
  LSalvar := TSalvarNFeBD.Create;
  try
    LSalvar.GravarNFeNoBanco(ADestinatario);
  finally
    LSalvar.Free;
  end;
end;

end.

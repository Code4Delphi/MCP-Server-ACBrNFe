unit MCP.Server.DM;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.Generics.Collections,
  Forms,
  TMS.MCP.Transport,
  TMS.MCP.Transport.StreamableHTTP,
  TMS.MCP.CustomComponent,
  TMS.MCP.Server;

type
  TMCPServerDM = class(TDataModule)
    TMSMCPServer1: TTMSMCPServer;
    TMSMCPStreamableHTTPTransport1: TTMSMCPStreamableHTTPTransport;
    procedure TMSMCPServer1Log(Sender: TObject; const LogMessage: string);
    function TMSMCPServer1Tools0Execute(const Args: array of TValue): TValue;
    function TMSMCPServer1Tools1Execute(const Args: array of TValue): TValue;
  private
    FOnLog: TProc<string>;
    procedure AddLog(const ALog: string);
  public
    procedure Start;
    property OnLog: TProc<string> read FOnLog write FOnLog;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  Main.View;

{$R *.dfm}

procedure TMCPServerDM.TMSMCPServer1Log(Sender: TObject; const LogMessage: string);
begin
  Self.AddLog(Format('[%s] %s', [DateTimeToStr(Now), LogMessage]));
end;

procedure TMCPServerDM.AddLog(const ALog: string);
begin
  if Assigned(FOnLog) then
    FOnLog(ALog);
end;

procedure TMCPServerDM.Start;
begin
  TMSMCPServer1.Start;
  Self.AddLog('Server running');
  Self.AddLog('Name: ' + TMSMCPServer1.ServerName);
  Self.AddLog('Port: ' + TMSMCPStreamableHTTPTransport1.Port.ToString);
  Self.AddLog('Endpoint: ' + TMSMCPStreamableHTTPTransport1.MCPEndpoint);
end;

function TMCPServerDM.TMSMCPServer1Tools0Execute(const Args: array of TValue): TValue;
begin
  Result := TValue.From<string>('Pong');
end;

function TMCPServerDM.TMSMCPServer1Tools1Execute(const Args: array of TValue): TValue;
var
  LNumero: Integer;
begin
  if Length(Args) <= 0 then
  begin
    Result := TValue.From<string>('Número para NFe não informado');
    Exit;
  end;

  LNumero := Args[0].AsInteger;
  if LNumero <= 0 then
  begin
    Result := TValue.From<string>('Informe um núemro válido para emissão da NFe');
    Exit;
  end;

  MainView.CriarEEnviarNFe(LNumero);

  Result := TValue.From<string>('Nota gerada com sucesso');
  Application.ProcessMessages;
end;

end.

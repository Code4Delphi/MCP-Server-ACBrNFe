unit ACBrMCP.Server;

interface

uses
  System.SysUtils,
  System.Classes,

  TMS.MCP.Server,
  TMS.MCP.Tools,
  TMS.MCP.Helpers,
  TMS.MCP.Transport.StreamableHTTP,
  Tool.GerarNFe;

type
  TServer = class
  private
    FMCPServer: TTMSMCPServer;
    FHTTPTransport: TTMSMCPStreamableHTTPTransport;
    FToolGerarNFe: TToolGerarNFe;
    procedure OnServerLog(Sender: TObject; const LogMessage: string);
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

  FToolGerarNFe := TToolGerarNFe.Create(FMCPServer);
end;

destructor TServer.Destroy;
begin
  FToolGerarNFe.Free;
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
begin
  FToolGerarNFe.Processar;
end;

end.

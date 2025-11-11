program ACBrNFe_MCP;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  ACBrMCP.Server in 'Src\ACBrMCP.Server.pas',
  Componentes.DM in 'Src\Componentes.DM.pas' {ComponentesDM: TDataModule},
  Emitente in 'Src\Emitente.pas',
  ACBrMCP.Preencher in 'Src\ACBrMCP.Preencher.pas',
  Database.Dm in 'Src\Database.Dm.pas' {DatabaseDm: TDataModule},
  ACBrMCP.Salvar in 'Src\ACBrMCP.Salvar.pas',
  ACBrMCP.Destinatario in 'Src\ACBrMCP.Destinatario.pas';

var
  ServerMCP: TServer;
begin
  try
    ComponentesDM := TComponentesDM.Create(nil);
    ServerMCP := TServer.Create;
    try
      ServerMCP.SetupServer;
      ServerMCP.Run;
      //ServerMCP.ProcessarEnvioNFe(321);
    finally
      ServerMCP.Free;
      ComponentesDM.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('Error: ' + E.Message);
      ReadLn;
      ExitCode := 1;
    end;
  end;
end.
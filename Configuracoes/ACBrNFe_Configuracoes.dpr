program ACBrNFe_Configuracoes;

uses
  Forms,
  Main.View in 'Src\Main.View.pas' {MainView},
  SelecionarCertificados.View in 'Src\SelecionarCertificados.View.pas' {SelecionarCertificadosView},
  Status.View in 'Src\Status.View.pas' {StatusView},
  MCP.Server.DM in 'Src\MCP.Server.DM.pas' {MCPServerDM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainView, MainView);
  Application.CreateForm(TSelecionarCertificadosView, SelecionarCertificadosView);
  Application.CreateForm(TStatusView, StatusView);
  Application.Run;
end.

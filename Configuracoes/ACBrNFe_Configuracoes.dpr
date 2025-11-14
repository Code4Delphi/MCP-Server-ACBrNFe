program ACBrNFe_Configuracoes;

uses
  Forms,
  Main.View in 'Src\Main.View.pas' {MainView},
  SelecionarCertificados.View in 'Src\SelecionarCertificados.View.pas' {SelecionarCertificadosView};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Config MCP ACBrNFe';
  Application.CreateForm(TMainView, MainView);
  Application.CreateForm(TSelecionarCertificadosView, SelecionarCertificadosView);
  Application.Run;
end.

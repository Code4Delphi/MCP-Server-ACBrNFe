unit ACBrMCP.Salvar;

interface

uses
  System.SysUtils,
  ACBrNFe,
  ACBrBase,
  ACBrDFe,
  Componentes.DM,
  Database.Dm;

type
  TACBrMCPSalvar = class
  private
    FDm: TDatabaseDm;
    FACBrNFe: TACBrNFe;
  public
    constructor Create;
    destructor Destroy; override;
    procedure GravarNFeNoBanco;
  end;

implementation

constructor TACBrMCPSalvar.Create;
begin
  FACBrNFe := ComponentesDM.ACBrNFe1;
  FDm := TDatabaseDm.Create(nil);
end;

destructor TACBrMCPSalvar.Destroy;
begin
  FDm.Free;
  inherited;
end;

procedure TACBrMCPSalvar.GravarNFeNoBanco;
begin
  FDm.QNFeGet('');
  FDm.QNFe.Append;

  FDm.QNFechave.AsString := FACBrNFe.NotasFiscais.Items[0].NFe.procNFe.chNFe;
  FDm.QNFexml_arquivo.AsString := ExtractFileName(FACBrNFe.NotasFiscais.Items[0].NomeArq);
  FDm.QNFe.Post;
end;

end.

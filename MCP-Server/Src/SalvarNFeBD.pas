unit SalvarNFeBD;

interface

uses
  System.SysUtils,
  ACBrNFe,
  ACBrBase,
  ACBrDFe,
  Componentes.DM,
  Database.Dm,
  Destinatario;

type
  TSalvarNFeBD = class
  private
    FDm: TDatabaseDm;
    FACBrNFe: TACBrNFe;
  public
    constructor Create;
    destructor Destroy; override;
    procedure GravarNFeNoBanco(const ADestinatario: TDestinatario);
  end;

implementation

constructor TSalvarNFeBD.Create;
begin
  FACBrNFe := ComponentesDM.ACBrNFe1;
  FDm := TDatabaseDm.Create(nil);
end;

destructor TSalvarNFeBD.Destroy;
begin
  FDm.Free;
  inherited;
end;

procedure TSalvarNFeBD.GravarNFeNoBanco(const ADestinatario: TDestinatario);
begin
  FDm.QNFeGet('');
  FDm.QNFe.Append;
  FDm.QNFeid_destinatario.AsInteger := ADestinatario.Id;
  FDm.QNFeserie.AsInteger := FACBrNFe.NotasFiscais.Items[0].NFe.Ide.serie;
  FDm.QNFenumero.AsInteger := FACBrNFe.NotasFiscais.Items[0].NFe.Ide.nNF;
  FDm.QNFechave.AsString := FACBrNFe.NotasFiscais.Items[0].NFe.procNFe.chNFe;
  FDm.QNFexml_arquivo.AsString := ExtractFileName(FACBrNFe.NotasFiscais.Items[0].NomeArq);
  FDm.QNFe.Post;
end;

end.

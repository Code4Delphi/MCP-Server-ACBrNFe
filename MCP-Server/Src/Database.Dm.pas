unit Database.Dm;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.ConsoleUI.Wait,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Comp.DataSet;

type
  TDatabaseDm = class(TDataModule)
    FDConnection1: TFDConnection;
    QNFe: TFDQuery;
    QNFeid: TFDAutoIncField;
    QNFechave: TWideStringField;
    QNFexml_arquivo: TWideStringField;
    QPessoas: TFDQuery;
    QPessoasid: TFDAutoIncField;
    QPessoasCNPJCPF: TWideStringField;
    QPessoasIE: TWideMemoField;
    QPessoasxNome: TWideStringField;
    QPessoasfone: TWideStringField;
    QPessoasCEP: TWideStringField;
    QPessoasxLgr: TWideStringField;
    QPessoasnro: TWideStringField;
    QPessoasxCpl: TWideStringField;
    QPessoasxBairro: TWideStringField;
    QPessoascMun: TIntegerField;
    QPessoasxMun: TWideStringField;
    QPessoasUF: TWideStringField;
    QNFeserie: TIntegerField;
    QNFenumero: TIntegerField;
    QPessoasemail: TWideMemoField;
    QNFeDetalhes: TFDQuery;
    QNFeDetalhesid: TFDAutoIncField;
    QNFeDetalhesid_destinatario: TIntegerField;
    QNFeDetalhesserie: TIntegerField;
    QNFeDetalhesnumero: TIntegerField;
    QNFeDetalheschave: TWideStringField;
    QNFeDetalhesxml_arquivo: TWideStringField;
    QNFeDetalhesDestinatarioEmail: TWideMemoField;
    QNFeDetalhesDestinatarioNome: TWideStringField;
    QNFeid_destinatario: TIntegerField;
    procedure DataModuleCreate(Sender: TObject);
  private
    FSqlPessoas: string;
    FSqlQNFe: string;
    FSqlQNFeDetalhes: string;
  public
    function QPessoasGet(const AIdPessoa: Integer): Boolean; overload;
    function QPessoasGet(const ANomePessoa: string): Boolean; overload;
    function QNFeGet(const AChaveNFe: string): Boolean;
    function QNFeDetalhesGet(const AChaveNFe: string): Boolean;
  end;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TDatabaseDm.DataModuleCreate(Sender: TObject);
begin
  FDConnection1.Connected := False;
  FDConnection1.Params.Database := '..\..\BD\dados_acbr.db';

  FSqlPessoas := QPessoas.SQL.Text;
  FSqlQNFe := QNFe.SQL.Text;
  FSqlQNFeDetalhes := QNFeDetalhes.SQL.Text;
end;

function TDatabaseDm.QPessoasGet(const AIdPessoa: Integer): Boolean;
begin
  QPessoas.Close;
  QPessoas.SQL.Text := FSqlPessoas;
  QPessoas.SQL.Add('where pessoas.id = :Id');
  QPessoas.ParamByName('Id').AsInteger := AIdPessoa;
  QPessoas.Open;

  Result := not QPessoas.IsEmpty;
end;

function TDatabaseDm.QPessoasGet(const ANomePessoa: string): Boolean;
begin
  QPessoas.Close;
  QPessoas.SQL.Text := FSqlPessoas;
  QPessoas.SQL.Add('where pessoas.xNome like :Nome');
  QPessoas.SQL.Add('limit 1');
  QPessoas.ParamByName('Nome').AsString := '%' + ANomePessoa + '%';
  QPessoas.Open;

  Result := not QPessoas.IsEmpty;
end;

function TDatabaseDm.QNFeGet(const AChaveNFe: string): Boolean;
begin
  QNFe.Close;
  QNFe.SQL.Text := FSqlQNFe;
  QNFe.SQL.Add('where nfe.chave = :Chave');
  QNFe.ParamByName('Chave').AsString := AChaveNFe;
  QNFe.Open;

  Result := not QNFe.IsEmpty;
end;

function TDatabaseDm.QNFeDetalhesGet(const AChaveNFe: string): Boolean;
begin
  QNFeDetalhes.Close;
  QNFeDetalhes.SQL.Text := FSqlQNFeDetalhes;
  QNFeDetalhes.SQL.Add('where nfe.chave = :Chave');
  QNFeDetalhes.ParamByName('Chave').AsString := AChaveNFe;
  QNFeDetalhes.Open;

  Result := not QNFeDetalhes.IsEmpty;
end;

end.

unit ACBrMCP.Destinatario;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  Database.Dm;

type
  TDestinatario = class
  private
    FDm: TDatabaseDm;
    FId: Integer;
    FCNPJCPF: string;
    FIE: string;
    FRazaoSocial: string;
    FFantasia: string;
    FFone: string;
    FCEP: string;
    FLogradouro: string;
    FNumero: string;
    FComplemento: string;
    FBairro: string;
    FCodCidade: Integer;
    FCidade: string;
    FUF: string;
    FMsgRetorno: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function GetDadosDoBanco(const ANomeDestinatario: string): Boolean;

    property Id: Integer read FId write FId;
    property CNPJCPF: string read FCNPJCPF write FCNPJCPF;
    property IE: string read FIE write FIE;
    property RazaoSocial: string read FRazaoSocial write FRazaoSocial;
    property Fantasia: string read FFantasia write FFantasia;
    property Fone: string read FFone write FFone;
    property CEP: string read FCEP write FCEP;
    property Logradouro: string read FLogradouro write FLogradouro;
    property Numero: string read FNumero write FNumero;
    property Complemento: string read FComplemento write FComplemento;
    property Bairro: string read FBairro write FBairro;
    property CodCidade: Integer read FCodCidade write FCodCidade;
    property Cidade: string read FCidade write FCidade;
    property UF: string read FUF write FUF;
    property MsgRetorno: string read FMsgRetorno;
  end;

implementation

constructor TDestinatario.Create;
begin
  FDm := TDatabaseDm.Create(nil);
  Self.Clear;
end;

destructor TDestinatario.Destroy;
begin
  FDm.Free;
  inherited;
end;

procedure TDestinatario.Clear;
begin
  FId := 0;
  FCNPJCPF := '';
  FIE := '';
  FRazaoSocial := '';
  FFantasia := '';
  FFone := '';
  FCEP := '';
  FLogradouro := '';
  FNumero := '';
  FComplemento := '';
  FBairro := '';
  FCodCidade := 0;
  FCidade := '';
  FUF := '';
  FMsgRetorno := '';
end;

function TDestinatario.GetDadosDoBanco(const ANomeDestinatario: string): Boolean;
begin
  Self.Clear;
  Result := False;

  if not FDm.QPessoasGet(ANomeDestinatario) then
  begin
    FMsgRetorno := 'Destinatário com o nome '+ ANomeDestinatario +' não encontrado na base de dados';
    Exit;
  end;

  FId := FDm.QPessoasid.AsInteger;
  FCNPJCPF := FDm.QPessoasCNPJCPF.AsString;
  FIE := FDm.QPessoasIE.AsString;
  FRazaoSocial := FDm.QPessoasxNome.AsString;
  FFantasia := FDm.QPessoasxNome.AsString;
  FFone := FDm.QPessoasfone.AsString;
  FCEP := FDm.QPessoasCEP.AsString;
  FLogradouro := FDm.QPessoasxLgr.AsString;
  FNumero := FDm.QPessoasnro.AsString;
  FComplemento := FDm.QPessoasxCpl.AsString;
  FBairro := FDm.QPessoasxBairro.AsString;
  FCodCidade := FDm.QPessoascMun.AsInteger;
  FCidade := FDm.QPessoasxMun.AsString;
  FUF := FDm.QPessoasUF.AsString;
  FDm.QPessoas.Close;
  Result := True;
end;

end.

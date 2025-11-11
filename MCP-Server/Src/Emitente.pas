unit Emitente;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles;

type
  TEmitente = class
  private
    FCNPJ: string;
    FIE: string;
    FRazaoSocial: string;
    FFantasia: string;
    FFone: string;
    FCEP: string;
    FLogradouro: string;
    FNumero: string;
    FComplemento: string;
    FBairro: string;
    FCodCidade: string;
    FCidade: string;
    FUF: string;
    FCRT: Integer;
  public
    constructor Create;
    procedure Clear;
    class function GetInstance: TEmitente;

    property CNPJ: string read FCNPJ write FCNPJ;
    property IE: string read FIE write FIE;
    property RazaoSocial: string read FRazaoSocial write FRazaoSocial;
    property Fantasia: string read FFantasia write FFantasia;
    property Fone: string read FFone write FFone;
    property CEP: string read FCEP write FCEP;
    property Logradouro: string read FLogradouro write FLogradouro;
    property Numero: string read FNumero write FNumero;
    property Complemento: string read FComplemento write FComplemento;
    property Bairro: string read FBairro write FBairro;
    property CodCidade: string read FCodCidade write FCodCidade;
    property Cidade: string read FCidade write FCidade;
    property UF: string read FUF write FUF;
    property CRT: Integer read FCRT write FCRT;
  end;

implementation

var
  Instance: TEmitente;

class function TEmitente.GetInstance: TEmitente;
begin
  Result := Instance;
end;

constructor TEmitente.Create;
begin
  Self.Clear;
end;

procedure TEmitente.Clear;
begin
  FCNPJ := '';
  FIE := '';
  FRazaoSocial := '';
  FFantasia := '';
  FFone := '';
  FCEP := '';
  FLogradouro := '';
  FNumero := '';
  FComplemento := '';
  FBairro := '';
  FCodCidade := '';
  FCidade := '';
  FUF := '';
  FCRT := 0;
end;

initialization
  Instance := TEmitente.Create;

finalization
  FreeAndNil(Instance);

end.

unit InfRespTec;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles;

type
  TInfRespTec = class
  private
    FCNPJ: string;
    FxContato: string;
    FEmail: string;
    FFone: string;
  public
    constructor Create;
    procedure Clear;
    class function GetInstance: TInfRespTec;

    property CNPJ: string read FCNPJ write FCNPJ;
    property xContato: string read FxContato write FxContato;
    property Email: string read FEmail write FEmail;
    property Fone: string read FFone write FFone;
  end;

implementation

var
  Instance: TInfRespTec;

class function TInfRespTec.GetInstance: TInfRespTec;
begin
  Result := Instance;
end;

constructor TInfRespTec.Create;
begin
  Self.Clear;
end;

procedure TInfRespTec.Clear;
begin
  FCNPJ := '';
  FxContato := '';
  FEmail := '';
  FFone := '';
end;

initialization
  Instance := TInfRespTec.Create;

finalization
  FreeAndNil(Instance);

end.

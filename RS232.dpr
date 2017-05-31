program RS232;

uses
  Forms,
  RS232_U in 'RS232_U.pas' {fPrincipal};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfPrincipal, fPrincipal);
  Application.Run;
end.

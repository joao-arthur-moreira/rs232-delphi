unit RS232_U;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TfPrincipal = class(TForm)
    Panel1: TPanel;
    btAbrir: TButton;
    btFechar: TButton;
    Panel2: TPanel;
    edEnviar: TEdit;
    btEnviar: TButton;
    Panel3: TPanel;
    Memo1: TMemo;
    Panel4: TPanel;
    edConfig: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    edPorta: TEdit;
    Timer1: TTimer;
    btnLerPorta: TButton;
    edtLeitura: TEdit;
    procedure btAbrirClick(Sender: TObject);
    procedure btFecharClick(Sender: TObject);
    procedure btEnviarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnLerPortaClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fPrincipal: TfPrincipal;
  hComm: THandle;
  bRead: array[0..255] of byte;
  iRet: LongBool;
  bAberta: Boolean;

implementation
{
Objetivo: Abrir comunicação com a porta serial
Paramentros:
 NomePorta  =COM1,COM2,etc
 ConfigPorta=2400,o,7,1 ou 9600,n,8,2 etc
Retorno:
 True ou false
}
Function OpenComm(NomePorta, ConfigPorta: String):Boolean;
var BarDCB: DCB;
    LastError: Cardinal;
    CTimeOut: COMMTIMEOUTS;
begin
   hComm:=CreateFile(PChar(NomePorta),GENERIC_READ+GENERIC_WRITE,
                                0, //not shared
                                nil, //no security
                                OPEN_EXISTING,
                                FILE_ATTRIBUTE_NORMAL, //+FILE_FLAG_OVERLAPPED
                                0{template} );
    If hComm = INVALID_HANDLE_VALUE Then begin
        ShowMessage('Porta Serial ' + NomePorta + ' não disponível. configure os paramentros da porta serial');
        Result:=False;
        Exit;
    End;
//  Configurar os Time Outs para a Porta
    CtimeOut.ReadIntervalTimeout:=20;
    CtimeOut.ReadTotalTimeoutConstant:=1;
    CtimeOut.ReadTotalTimeoutMultiplier:=1;
    CtimeOut.WriteTotalTimeoutConstant:=20;
    CtimeOut.WriteTotalTimeoutMultiplier:=1;
    iRet:=SetCommTimeouts(hComm, CTimeOut);
    If Ord(iRet)= -1 Then begin
        LastError:=GetLastError();
        ShowMessage('Não é permitido configurar os Timeouts para esta porta ' + NomePorta + ' Erro: ' + Inttostr(LastError));
        CloseHandle(hComm);
        Result:=False;
        Exit;
    End;
    iRet:=BuildCommDCB(PChar(NomePorta+':'+ConfigPorta), BarDCB);
    If Ord(iRet)=-1 Then begin
        LastError:= GetLastError();
        ShowMessage('Não é permitido montar os parametros da Porta' + ConfigPorta + ' Erro: ' + Inttostr(LastError));
        CloseHandle(hComm);
        Result:=False;
        Exit;
    End;
    iRet:=SetCommState(hComm, BarDCB);
    If Ord(iRet)= -1 Then begin
        LastError:= GetLastError();
        ShowMessage('Não é permitido configurar os parametros da Porta' + ConfigPorta + ' Erro: ' + Inttostr(LastError));
        CloseHandle(hComm);
        Result:=False;
        Exit;
    End;
    Result:=True;
End;
{
Objetivo: Fechar comunicação com a porta serial
Retorno:
 True ou false
}
Function CloseComm:Boolean;
begin
  Result:=CloseHandle(hComm);
End;
{
Objetivo: Limpar Buffer de Leitura e Escrita
}
Procedure FlushComm;
begin
  FlushFileBuffers(hComm);
End;
{
Objetivo: Limpar dados recebidos na porta serial
}
Procedure ClearReadComm;
begin
  PurgeComm(hComm,PURGE_RXCLEAR);
End;
{
Objetivo: Limpar dados enviados para porta serial
}
Procedure ClearSendComm;
begin
  PurgeComm(hComm,PURGE_TXCLEAR);
End;
{
Objetivo: Ler dados na Porta serial
Retorno:
 String
}
Function ReadComm:String;
var BytesLidos: DWord;
    i: Integer;
    ReadStr: String;
begin
  iRet:=ReadFile(hComm, bRead[0], 255, BytesLidos, nil);
  if ord(iRet)=-1 then exit;
  ReadStr:='';
//IF bytesLidos > 0 then ShowMessage(inttostr(BytesLidos));
  If BytesLidos > 0 Then
    For I:=0 To BytesLidos - 1  do
      ReadStr:=ReadStr + chr(bRead[i])
  Else
     FlushComm;
  Result:=ReadStr;
End;
{
Objetivo: Enviar dados para a porta serial
Paramentros:
 sComando = 'WBFHOSY'
 comando para configurar o leitor em 2400,o,7,1
 Modelo TL800 da empresa Tecsimi
Retorno:
 True ou false
}
Function SendComm(sComando: String):Integer;
var BytesEnviados: DWORD;
begin
  iRet:=WriteFile(hComm,PCHAR(sComando)[0],Length(sComando), BytesEnviados, nil);
  FlushComm;
  if iRet then Result:=BytesEnviados else Result:=-1;
End;
{FIM DAS FUNÇÕES DO WINDOWS}
{$R *.DFM}

procedure TfPrincipal.btAbrirClick(Sender: TObject);
begin
//Abrir a porta e habilitar/desabilitar botões e Timer.
  bAberta:=OpenComm(edPorta.Text,edConfig.Text);
  btAbrir.Enabled:=not bAberta;
  btFechar.Enabled:=bAberta;
  //Timer1.Enabled:=bAberta;
  Memo1.Lines.Clear;
  //Memo1.Lines.Add('PASSE O DOCUMENTO NO LEITOR..');
end;

procedure TfPrincipal.btFecharClick(Sender: TObject);
begin
//Fechar a porta e habilitar/desabilitar botões e Timer.
  bAberta:=CloseComm;
  Timer1.Enabled:=not bAberta;
  btAbrir.Enabled:=bAberta;
  btFechar.Enabled:=not bAberta;
end;

procedure TfPrincipal.btnLerPortaClick(Sender: TObject);
var
  cStr: String;
  sPeso,sTara: String;
begin
  cStr:=ReadComm;
  if Length(cStr)>0 then
  begin
    Memo1.Lines.Add(cStr);

    Memo1.Lines.Add('Peso: '+ Trim(Copy(cStr,35,7)));
    Memo1.Lines.Add('Tara: '+ Trim(Copy(cStr,55,7)));

    sPeso := Trim(Copy(cStr,35,7));
    sTara := Trim(Copy(cStr,55,7));

    sPeso := StringReplace(sPeso,'.',',',[rfReplaceAll]);
    sTara := StringReplace(sTara,'.',',',[rfReplaceAll]);

    edtLeitura.Text := sPeso+'|'+sTara;
  end;
end;

procedure TfPrincipal.btEnviarClick(Sender: TObject);
var
  cStr: String;
begin
//Enviar comando para a porta serial
  if not bAberta then
  begin
    ShowMessage('PORTA SERIAL ESTA FECHADA !');
    exit;
  end;
  SendComm(edEnviar.Text);

  cStr:=ReadComm;
  if Length(cStr)>0 then Memo1.Lines.Add(cStr);
end;

procedure TfPrincipal.FormCreate(Sender: TObject);
begin
  btFechar.Enabled:=False;
end;

{Timer usado para executar a função de leitura da porta}
procedure TfPrincipal.Timer1Timer(Sender: TObject);
var cStr: String;
begin
  if not bAberta then
  begin
    ShowMessage('PORTA SERIAL ESTA FECHADA!');
    exit;
  end;
  cStr:=ReadComm;
  if Length(cStr)>0 then
    Memo1.Lines.Add(cStr);
end;

procedure TfPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if bAberta then CloseComm;
end;

end.

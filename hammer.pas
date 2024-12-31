program LoadTester;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, IdHTTP, IdGlobal, IdSSLOpenSSL, IdException, SyncObjs, DateUtils, Math,
  StrUtils, JSON;

type
  TLoadTestThread = class(TThread)
  private
    FURL: string;
    FMethod: string;
    FHeaders: TStringList;
    FData: string;
    FTimeout: Integer;
    FRetries: Integer;
    FResponseTime: TDateTime;
    FResponseCode: Integer;
    FSuccess: Boolean;
    FLock: TCriticalSection;
    FLog: TextFile;
    FResults: TJSONArray;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean; const AURL, AMethod: string;
      AHeaders: TStringList; AData: string; ATimeout, ARetries: Integer; ALock: TCriticalSection;
      ALog: TextFile; AResults: TJSONArray);
    destructor Destroy; override;
  end;

var
  ver_major, ver_minor, patch: Byte;
  bots: Integer;
  url, method: string;
  headers: TStringList;
  data: string;
  timeout, retries: Integer;
  rateLimit: Double;
  logFile: TextFile;
  lock: TCriticalSection;
  responseTimes: array of Double;
  responseCodes: array of Integer;
  startTime, endTime: TDateTime;
  totalRequests, successfulRequests: Integer;
  resultsArray: TJSONArray;
  portScan: Boolean;
  fingerprint: Boolean;
  target_ip: string;
  start_port, end_port: Integer;
  fingerprint_url: string;

procedure TLoadTestThread.Execute;
var
  http: TIdHTTP;
  proxy: TIdConnectThroughHTTP;
  retryCount: Integer;
  startTime, endTime: TDateTime;
  resultObj: TJSONObject;
begin
  FSuccess := False;
  retryCount := 0;
  while (retryCount <= FRetries) and not Terminated do
  begin
    http := TIdHTTP.Create(nil);
    proxy := TIdConnectThroughHTTP.Create(nil);
    try
      http.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(http);
      http.HandleRedirects := True;
      http.MaxAuthRetries := 3;
      http.Request.CustomHeaders.Assign(FHeaders);
      http.ReadTimeout := FTimeout;
      http.ConnectTimeout := FTimeout;
      http.IOHandler.ReadTimeout := FTimeout;
      http.IOHandler.ConnectTimeout := FTimeout;

      if FHeaders.Values['Proxy'] <> '' then
      begin
        proxy.Host := FHeaders.Values['Proxy'];
        proxy.Port := StrToIntDef(FHeaders.Values['ProxyPort'], 8080);
        http.IOHandler := proxy;
      end;

      startTime := Now;
      try
        case FMethod of
          'GET': FResponseCode := http.Get(FURL).ResponseCode;
          'POST': FResponseCode := http.Post(FURL, TStringStream.Create(FData)).ResponseCode;
          'PUT': FResponseCode := http.Put(FURL, TStringStream.Create(FData)).ResponseCode;
          'DELETE': FResponseCode := http.Delete(FURL).ResponseCode;
        end;
        FSuccess := True;
      except
        on E: Exception do
        begin
          FLock.Enter;
          try
            Writeln(logFile, Format('Error: %s at %s', [E.Message, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
          finally
            FLock.Leave;
          end;
          Inc(retryCount);
        end;
      end;
      endTime := Now;
      FResponseTime := MilliSecondsBetween(endTime, startTime) / MSecsPerSec;

      FLock.Enter;
      try
        Writeln(logFile, Format('Response Code: %d, Time: %.3f sec, at %s', [FResponseCode, FResponseTime, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
        SetLength(responseTimes, Length(responseTimes) + 1);
        responseTimes[High(responseTimes)] := FResponseTime;
        SetLength(responseCodes, Length(responseCodes) + 1);
        responseCodes[High(responseCodes)] := FResponseCode;
        Inc(totalRequests);
        if FSuccess then
          Inc(successfulRequests);

        resultObj := TJSONObject.Create;
        try
          resultObj.AddPair('ResponseCode', TJSONNumber.Create(FResponseCode));
          resultObj.AddPair('ResponseTime', TJSONNumber.Create(FResponseTime));
          FResults.AddElement(resultObj);
        except
          resultObj.Free;
          raise;
        end;
      finally
        FLock.Leave;
      end;
    finally
      http.Free;
      proxy.Free;
    end;
  end;
end;

constructor TLoadTestThread.Create(CreateSuspended: Boolean; const AURL, AMethod: string;
  AHeaders: TStringList; AData: string; ATimeout, ARetries: Integer; ALock: TCriticalSection;
  ALog: TextFile; AResults: TJSONArray);
begin
  inherited Create(CreateSuspended);
  FURL := AURL;
  FMethod := AMethod;
  FHeaders := TStringList.Create;
  FHeaders.Assign(AHeaders);
  FData := AData;
  FTimeout := ATimeout;
  FRetries := ARetries;
  FLock := ALock;
  FLog := ALog;
  FResults := AResults;
end;

destructor TLoadTestThread.Destroy;
begin
  FHeaders.Free;
  inherited Destroy;
end;

procedure ParseCommandLine;
var
  i: Integer;
  param: string;
begin
  portScan := False;
  fingerprint := False;
  for i := 1 to ParamCount do
  begin
    param := ParamStr(i);
    if param.StartsWith('--') or param.StartsWith('-') then
    begin
      if param.StartsWith('--url=') or param.StartsWith('-u=') then
        url := Copy(param, Pos('=', param) + 1, Length(param))
      else if param.StartsWith('--bots=') or param.StartsWith('-b=') then
        bots := StrToIntDef(Copy(param, Pos('=', param) + 1, Length(param)), 0)
      else if param.StartsWith('--timeout=') or param.StartsWith('-t=') then
        timeout := StrToIntDef(Copy(param, Pos('=', param) + 1, Length(param)), 10000)
      else if param.StartsWith('--version') or param.StartsWith('-v') then
      begin
        Writeln(Format('ROSASINESUS v%d.%d.%d', [ver_major, ver_minor, patch]));
        Halt;
      end
      else if param.StartsWith('--help') or param.StartsWith('-h') then
      begin
        Writeln('Usage:');
        Writeln('  ./loadtester --url=<URL> --bots=<bots> [--timeout=<timeout>] [--version] [--help]');
        Writeln('  ./loadtester --port-scan --target-ip=<IP> --start-port=<start> --end-port=<end>');
        Writeln('  ./loadtester --fingerprint --fingerprint-url=<URL>');
        Writeln('Flags:');
        Writeln('  --url, -u: The target URL for testing.');
        Writeln('  --bots, -b: The number of concurrent bots for the attack.');
        Writeln('  --timeout, -t: Timeout for each request in milliseconds (optional, default is 10000 ms).');
        Writeln('  --version, -v: Prints the version and exits.');
        Writeln('  --help, -h: Prints this usage message.');
        Writeln('  --port-scan, -p: Enable port scanning.');
        Writeln('  --target-ip, -i: Target IP address for port scanning.');
        Writeln('  --start-port, -s: Starting port for scanning.');
        Writeln('  --end-port, -e: Ending port for scanning.');
        Writeln('  --fingerprint, -f: Enable web server fingerprinting.');
        Writeln('  --fingerprint-url, -fu: URL for web server fingerprinting.');
        Halt;
      end
      else if param.StartsWith('--port-scan') or param.StartsWith('-p') then
        portScan := True
      else if param.StartsWith('--target-ip=') or param.StartsWith('-i=') then
        target_ip := Copy(param, Pos('=', param) + 1, Length(param))
      else if param.StartsWith('--start-port=') or param.StartsWith('-s=') then
        start_port := StrToIntDef(Copy(param, Pos('=', param) + 1, Length(param)), 1)
      else if param.StartsWith('--end-port=') or param.StartsWith('-e=') then
        end_port := StrToIntDef(Copy(param, Pos('=', param) + 1, Length(param)), 1024)
      else if param.StartsWith('--fingerprint') or param.StartsWith('-f') then
        fingerprint := True
      else if param.StartsWith('--fingerprint-url=') or param.StartsWith('-fu=') then
        fingerprint_url := Copy(param, Pos('=', param) + 1, Length(param));
    end;
  end;

  if portScan and fingerprint then
  begin
    Writeln('Error: --port-scan and --fingerprint cannot be used together.');
    Halt;
  end;

  if portScan then
  begin
    if target_ip = '' then
    begin
      Writeln('Error: --target-ip is required for port scanning.');
      Halt;
    end;
    if start_port = 0 then
    begin
      Writeln('Error: --start-port is required for port scanning.');
      Halt;
    end;
    if end_port = 0 then
    begin
      Writeln('Error: --end-port is required for port scanning.');
      Halt;
    end;
  end;

  if fingerprint then
  begin
    if fingerprint_url = '' then
    begin
      Writeln('Error: --fingerprint-url is required for web server fingerprinting.');
      Halt;
    end;
  end;

  if not portScan and not fingerprint and (url = '' or bots = 0) then
  begin
    Writeln('Error: --url and --bots are required for load testing.');
    Halt;
  end;
end;

procedure display_real_time_metrics;
var
  currentRequests, currentSuccessfulRequests: Integer;
  currentResponseTime: Double;
begin
  while totalRequests < bots do
  begin
    lock.Enter;
    try
      currentRequests := totalRequests;
      currentSuccessfulRequests := successfulRequests;
      if Length(responseTimes) > 0 then
        currentResponseTime := responseTimes[High(responseTimes)]
      else
        currentResponseTime := 0;
    finally
      lock.Leave;
    end;
    Writeln(Format('Requests Sent: %d, Successful: %d, Last Response Time: %.3f sec', [currentRequests, currentSuccessfulRequests, currentResponseTime]));
    Sleep(1000); // Update every second
  end;
end;

procedure simulate_traffic_profile(profile: string; bots: Integer; const url, method: string; headers: TStringList; const data: string;
  timeout, retries: Integer; rateLimit: Double; results: TJSONArray);
begin
  case LowerCase(profile) of
    'spike':
      begin
        // Simulate a spike in traffic
        bots := bots * 10; // Increase bots for spike
        run_tests(bots, url, method, headers, data, timeout, retries, rateLimit, results);
        bots := bots div 10; // Reset bots to original
      end;
    'wave':
      begin
        // Simulate a wave of traffic
        for var i := 1 to 5 do
        begin
          run_tests(bots div 5, url, method, headers, data, timeout, retries, rateLimit, results);
          Sleep(2000); // Wait for 2 seconds between waves
        end;
      end;
    'sustained':
      begin
        // Simulate sustained traffic
        run_tests(bots, url, method, headers, data, timeout, retries, rateLimit, results);
      end;
    else
      Writeln('Unknown traffic profile, using sustained traffic by default.');
      run_tests(bots, url, method, headers, data, timeout, retries, rateLimit, results);
  end;
end;

procedure run_tests(bots: Integer; const url, method: string; headers: TStringList; const data: string;
  timeout, retries: Integer; rateLimit: Double; results: TJSONArray);
var
  threads: array of TLoadTestThread;
  i: Integer;
  interval: Double;
begin
  interval := 1 / rateLimit;
  SetLength(threads, bots);
  lock := TCriticalSection.Create;
  for i := 0 to bots - 1 do
  begin
    threads[i] := TLoadTestThread.Create(True, url, method, headers, data, timeout, retries, lock, logFile, results);
    threads[i].FreeOnTerminate := True;
    threads[i].Resume;
    Sleep(Round(interval * 1000)); // Sleep to control rate limit
  end;

  // Wait for all threads to complete
  for i := 0 to bots - 1 do
  begin
    while threads[i] <> nil do
    begin
      Sleep(100);
      Threads[i].WaitFor;
    end;
  end;
  lock.Free;
end;

procedure log_results(results: TJSONArray);
var
  totalResponseTime: Double;
  minResponseTime, maxResponseTime, avgResponseTime: Double;
    jsonFile: TextFile;
  jsonStr: string;
begin
  totalResponseTime := 0;
  minResponseTime := MaxDouble;
  maxResponseTime := 0;

  for var responseTime in responseTimes do
  begin
    totalResponseTime := totalResponseTime + responseTime;
    if responseTime < minResponseTime then
      minResponseTime := responseTime;
    if responseTime > maxResponseTime then
      maxResponseTime := responseTime;
  end;

  if Length(responseTimes) > 0 then
    avgResponseTime := totalResponseTime / Length(responseTimes)
  else
    avgResponseTime := 0;

  Writeln(logFile, '------------------- Results -------------------');
  Writeln(logFile, Format('Total Requests: %d', [totalRequests]));
  Writeln(logFile, Format('Successful Requests: %d', [successfulRequests]));
  Writeln(logFile, Format('Average Response Time: %.3f sec', [avgResponseTime]));
  Writeln(logFile, Format('Minimum Response Time: %.3f sec', [minResponseTime]));
  Writeln(logFile, Format('Maximum Response Time: %.3f sec', [maxResponseTime]));
  Writeln(logFile, '-------------------------------------------');

  // Save results to JSON file
  AssignFile(jsonFile, 'load_test_results.json');
  Rewrite(jsonFile);

  jsonStr := results.ToString;
  Writeln(jsonFile, jsonStr);

  CloseFile(jsonFile);
end;

// Function to scan a single port
procedure scan_port(target_ip: string; port: Integer);
var
  client: TIdTCPClient;
  open: Boolean;
begin
  client := TIdTCPClient.Create(nil);
  try
    client.Host := target_ip;
    client.Port := port;
    client.ConnectTimeout := 1000; // 1 second timeout
    try
      client.Connect;
      open := True;
    except
      on E: Exception do
        open := False;
    end;
    if open then
      Writeln(Format('Port %d is OPEN', [port]))
    else
      Writeln(Format('Port %d is CLOSED or FILTERED', [port]));
  finally
    client.Free;
  end;
end;

// Function to scan a range of ports
procedure scan_ports(target_ip: string; start_port, end_port: Integer);
var
  port: Integer;
begin
  for port := start_port to end_port do
    scan_port(target_ip, port);
end;

// Function to fingerprint web server
procedure fingerprint_web_server(url: string);
var
  http: TIdHTTP;
  response: IIdHTTPResponse;
  serverHeader: string;
begin
  http := TIdHTTP.Create(nil);
  try
    http.HandleRedirects := True;
    http.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(http);
    try
      response := http.Head(url);
      serverHeader := response.Server;
      if serverHeader <> '' then
        Writeln(Format('Web Server: %s', [serverHeader]))
      else
        Writeln('Web Server: Unknown');
    except
      on E: Exception do
        Writeln(Format('Error fingerprinting web server: %s', [E.Message]));
    end;
  finally
    http.Free;
  end;
end;

begin
  ver_major := 1;
  ver_minor := 1;
  patch := 0;
  Writeln('ROSASINESUS');
  Writeln(Format('ver %d.%d.%d', [ver_major, ver_minor, patch]));
  Writeln('Load Tester - DDOS Simulator for your own website');

  AssignFile(logFile, 'load_test.log');
  Rewrite(logFile);

  ParseCommandLine;

  headers := TStringList.Create;
  try
    method := 'GET'; // Default method
    data := '';
    timeout := 10000; // Default timeout in milliseconds
    retries := 3; // Default retries
    rateLimit := 1.0; // Default rate limit (1 request per second)

    if portScan then
    begin
      Writeln(Format('Scanning %s from port %d to %d...', [target_ip, start_port, end_port]));
      scan_ports(target_ip, start_port, end_port);
    end
    else if fingerprint then
    begin
      Writeln(Format('Fingerprinting web server at %s...', [fingerprint_url]));
      fingerprint_web_server(fingerprint_url);
    end
    else
    begin
      startTime := Now;

      resultsArray := TJSONArray.Create;
      try
        display_real_time_metrics;
        simulate_traffic_profile('sustained', bots, url, method, headers, data, timeout, retries, rateLimit, resultsArray);
        endTime := Now;

        log_results(resultsArray);
      finally
        resultsArray.Free;
      end;

      Writeln(Format('Test completed in %.3f sec', [MilliSecondsBetween(endTime, startTime) / MSecsPerSec]));
    end;
  finally
    headers.Free;
  end;

  CloseFile(logFile);
end.

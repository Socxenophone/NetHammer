unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, SyncObjs, DateUtils, Math,
  StrUtils, IdHTTP, IdGlobal, IdSSLOpenSSL, IdException, IdComponent, IdTCPConnection,
  IdTCPClient, IdBaseComponent, IdExceptionCore, IdIntercept, IdInterceptBase, IdInterceptRetry,
  IdInterceptThrottle, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdIOHandlerWriteBuffer,
  IdIOHandlerReadBuffer, IdIOHandlerBuffer, IdIOHandlerStream, IdIOHandlerMemory, IdIOHandlerFile,
  IdIOHandlerNamedPipe, IdIOHandlerSocketOpenSSL, IdIOHandlerSSLIOHandler, IdIOHandlerSSLIOHandlerSocket,
  IdIOHandlerSSLIOHandlerSocketOpenSSL, IdIOHandlerSSLIOHandlerSocketOpenSSLBase, IdIOHandlerSSLIOHandlerSocketOpenSSLVCL,
  IdIOHandlerSSLIOHandlerSocketOpenSSLVCLBase, IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImpl,
  IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplBase, IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSL,
  IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLBase, IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImpl,
  IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplBase, IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSL,
  IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSLBase, IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSLImpl,
  IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSLImplBase, IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSLImplSSL,
  IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSLImplSSLBase, IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSLImplSSLImpl,
  IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSLImplSSLImplBase, IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSLImplSSLImplSSL,
  IdIOHandlerSSLIOHandlerSocketOpenSSLVCLImplSSLImplSSLImplSSLImplSSLBase, JSON, Sockets;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Memo1: TMemo;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
    FLock: TCriticalSection;
    FResponseTimes: array of Double;
    FResponseCodes: array of Integer;
    FTotalRequests, FSuccessfulRequests: Integer;
    FResultsArray: TJSONArray;
    FLogFile: TextFile;
    procedure DisplayRealTimeMetrics;
    procedure SimulateTrafficProfile(Profile: string);
    procedure RunTests(Bots: Integer; const URL, Method: string; Headers: TStringList; const Data: string;
      Timeout, Retries: Integer; RateLimit: Double; Results: TJSONArray);
    procedure LogResults(Results: TJSONArray);
    procedure ScanPort(TargetIP: string; Port: Integer);
    procedure ScanPorts(TargetIP: string; StartPort, EndPort: Integer);
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  URL, Method, Data: string;
  Headers: TStringList;
  Bots, Timeout, Retries: Integer;
  RateLimit: Double;
begin
  URL := Edit1.Text;
  Bots := StrToIntDef(Edit2.Text, 0);
  Timeout := StrToIntDef(Edit3.Text, 10000);
  Retries := 3;
  RateLimit := 1.0;
  Method := ComboBox1.Text;
  Data := '';
  Headers := TStringList.Create;
  try
    AssignFile(FLogFile, 'load_test.log');
    Rewrite(FLogFile);

    FLock := TCriticalSection.Create;
    FTotalRequests := 0;
    FSuccessfulRequests := 0;
    SetLength(FResponseTimes, 0);
    SetLength(FResponseCodes, 0);
    FResultsArray := TJSONArray.Create;

    try
      DisplayRealTimeMetrics;
      SimulateTrafficProfile('sustained');
      LogResults(FResultsArray);
    finally
      FResultsArray.Free;
      CloseFile(FLogFile);
      FLock.Free;
    end;

  finally
    Headers.Free;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  TargetIP: string;
  StartPort, EndPort: Integer;
begin
  TargetIP := Edit4.Text;
  StartPort := StrToIntDef(Edit5.Text, 1);
  EndPort := StrToIntDef(Edit6.Text, 1024);

  Memo1.Lines.Add(Format('Scanning %s from port %d to %d...', [TargetIP, StartPort, EndPort]));
  ScanPorts(TargetIP, StartPort, EndPort);
end;

procedure TForm1.DisplayRealTimeMetrics;
var
  CurrentRequests, CurrentSuccessfulRequests: Integer;
  CurrentResponseTime: Double;
begin
  while FTotalRequests < StrToIntDef(Edit2.Text, 0) do
  begin
    FLock.Enter;
    try
      CurrentRequests := FTotalRequests;
      CurrentSuccessfulRequests := FSuccessfulRequests;
      if Length(FResponseTimes) > 0 then
        CurrentResponseTime := FResponseTimes[High(FResponseTimes)]
      else
        CurrentResponseTime := 0;
    finally
      FLock.Leave;
    end;
    Memo1.Lines.Add(Format('Requests Sent: %d, Successful: %d, Last Response Time: %.3f sec',
      [CurrentRequests, CurrentSuccessfulRequests, CurrentResponseTime]));
    Sleep(1000); // Update every second
  end;
end;

procedure TForm1.SimulateTrafficProfile(Profile: string);
var
  Bots: Integer;
  URL, Method: string;
  Headers: TStringList;
  Data: string;
  Timeout, Retries: Integer;
  RateLimit: Double;
begin
  Bots := StrToIntDef(Edit2.Text, 0);
  URL := Edit1.Text;
  Method := ComboBox1.Text;
  Headers := TStringList.Create;
  Data := '';
  Timeout := StrToIntDef(Edit3.Text, 10000);
  Retries := 3;
  RateLimit := 1.0;
  try
    case LowerCase(Profile) of
      'spike':
        begin
          // Simulate a spike in traffic
          Bots := Bots * 10; // Increase bots for spike
          RunTests(Bots, URL, Method, Headers, Data, Timeout, Retries, RateLimit, FResultsArray);
          Bots := Bots div 10; // Reset bots to original
        end;
      'wave':
        begin
          // Simulate a wave of traffic
          for var i := 1 to 5 do
          begin
            RunTests(Bots div 5, URL, Method, Headers, Data, Timeout, Retries, RateLimit, FResultsArray);
            Sleep(2000); // Wait for 2 seconds between waves
          end;
        end;
      'sustained':
        begin
          // Simulate sustained traffic
          RunTests(Bots, URL, Method, Headers, Data, Timeout, Retries, RateLimit, FResultsArray);
        end;
      else
        Memo1.Lines.Add('Unknown traffic profile, using sustained traffic by default.');
        RunTests(Bots, URL, Method, Headers, Data, Timeout, Retries, RateLimit, FResultsArray);
    end;
  finally
    Headers.Free;
  end;
end;

procedure TForm1.RunTests(Bots: Integer; const URL, Method: string; Headers: TStringList; const Data: string;
  Timeout, Retries: Integer; RateLimit: Double; Results: TJSONArray);
var
  Threads: array of TLoadTestThread;
  i: Integer;
  Interval: Double;
begin
  Interval := 1 / RateLimit;
  SetLength(Threads, Bots);
  for i := 0 to Bots - 1 do
  begin
    Threads[i] := TLoadTestThread.Create(True, URL, Method, Headers, Data, Timeout, Retries, FLock, FLogFile, Results);
    Threads[i].FreeOnTerminate := True;
    Threads[i].Resume;
    Sleep(Round(Interval * 1000)); // Sleep to control rate limit
  end;

  // Wait for all threads to complete
  for i := 0 to Bots - 1 do
  begin
    while Threads[i] <> nil do
    begin
      Sleep(100);
      Threads[i].WaitFor;
    end;
  end;
end;

procedure TForm1.LogResults(Results: TJSONArray);
var
  TotalResponseTime: Double;
  MinResponseTime, MaxResponseTime, AvgResponseTime: Double;
  JsonFile: TextFile;
  JsonStr: string;
begin
  TotalResponseTime := 0;
  MinResponseTime := MaxDouble;
  MaxResponseTime := 0;

  for var ResponseTime in FResponseTimes do
  begin
    TotalResponseTime := TotalResponseTime + ResponseTime;
    if ResponseTime < MinResponseTime then
      MinResponseTime := ResponseTime;
    if ResponseTime > MaxResponseTime then
      MaxResponseTime := ResponseTime;
  end;

  AvgResponseTime := TotalResponseTime / Length(FResponseTimes);

  Memo1.Lines.Add('------------------- Results -------------------');
  Memo1.Lines.Add(Format('Total Requests: %d', [FTotalRequests]));
  Memo1.Lines.Add(Format('Successful Requests: %d', [FSuccessfulRequests]));
  Memo1.Lines.Add(Format('Average Response Time: %.3f sec', [AvgResponseTime]));
  Memo1.Lines.Add(Format('Minimum Response Time: %.3f sec', [MinResponseTime]));
  Memo1.Lines.Add(Format('Maximum Response Time: %.3f sec', [MaxResponseTime]));
    Memo1.Lines.Add('-------------------------------------------');

  // Save results to JSON file
  AssignFile(JsonFile, 'load_test_results.json');
  Rewrite(JsonFile);

  JsonStr := Results.ToString;
  Writeln(JsonFile, JsonStr);

  CloseFile(JsonFile);
end;

procedure TForm1.ScanPort(TargetIP: string; Port: Integer);
var
  Socket: TSocket;
  SockAddr: TSockAddr;
  Result: Integer;
  Timeout: TTimeVal;
begin
  Socket := fpSocket(AF_INET, SOCK_STREAM, 0);
  if Socket = -1 then
  begin
    Memo1.Lines.Add(Format('Failed to create socket for port %d', [Port]));
    Exit;
  end;

  SockAddr.sin_family := AF_INET;
  SockAddr.sin_port := htons(Port);
  SockAddr.sin_addr.s_addr := inet_addr(PChar(TargetIP));

  Timeout.tv_sec := 1; // 1 second timeout
  Timeout.tv_usec := 0;

  fpSetLinger(Socket, False, 0);
  fpSetSockOpt(Socket, SOL_SOCKET, SO_RCVTIMEO, @Timeout, SizeOf(Timeout));
  fpSetSockOpt(Socket, SOL_SOCKET, SO_SNDTIMEO, @Timeout, SizeOf(Timeout));

  Result := fpConnect(Socket, @SockAddr, SizeOf(SockAddr));
  if Result = 0 then
    Memo1.Lines.Add(Format('Port %d is OPEN', [Port]))
  else
    Memo1.Lines.Add(Format('Port %d is CLOSED or FILTERED', [Port]));

  fpCloseSocket(Socket);
end;

procedure TForm1.ScanPorts(TargetIP: string; StartPort, EndPort: Integer);
var
  Port: Integer;
begin
  for Port := StartPort to EndPort do
  begin
    ScanPort(TargetIP, Port);
    Sleep(10); // Add a small delay to avoid overwhelming the target
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ComboBox1.Items.Add('GET');
  ComboBox1.Items.Add('POST');
  ComboBox1.Items.Add('PUT');
  ComboBox1.Items.Add('DELETE');
  ComboBox1.ItemIndex := 0; // Default to GET
end;

{ TLoadTestThread }

procedure TLoadTestThread.Execute;
var
  Http: TIdHTTP;
  Proxy: TIdConnectThroughHTTP;
  RetryCount: Integer;
  StartTime, EndTime: TDateTime;
  ResultObj: TJSONObject;
begin
  FSuccess := False;
  RetryCount := 0;
  while (RetryCount <= FRetries) and not Terminated do
  begin
    Http := TIdHTTP.Create(nil);
    Proxy := TIdConnectThroughHTTP.Create(nil);
    try
      Http.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(Http);
      Http.HandleRedirects := True;
      Http.MaxAuthRetries := 3;
      Http.Request.CustomHeaders.Assign(FHeaders);
      Http.ReadTimeout := FTimeout;
      Http.ConnectTimeout := FTimeout;
      Http.IOHandler.ReadTimeout := FTimeout;
      Http.IOHandler.ConnectTimeout := FTimeout;

      if FHeaders.Values['Proxy'] <> '' then
      begin
        Proxy.Host := FHeaders.Values['Proxy'];
        Proxy.Port := StrToIntDef(FHeaders.Values['ProxyPort'], 8080);
        Http.IOHandler := Proxy;
      end;

      StartTime := Now;
      try
        case FMethod of
          'GET': FResponseCode := Http.Get(FURL).ResponseCode;
          'POST': FResponseCode := Http.Post(FURL, TStringStream.Create(FData)).ResponseCode;
          'PUT': FResponseCode := Http.Put(FURL, TStringStream.Create(FData)).ResponseCode;
          'DELETE': FResponseCode := Http.Delete(FURL).ResponseCode;
        end;
        FSuccess := True;
      except
        on E: Exception do
        begin
          FLock.Enter;
          try
            Writeln(FLog, Format('Error: %s at %s', [E.Message, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
            Memo1.Lines.Add(Format('Error: %s at %s', [E.Message, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
          finally
            FLock.Leave;
          end;
          Inc(RetryCount);
        end;
      end;
      EndTime := Now;
      FResponseTime := MilliSecondsBetween(EndTime, StartTime) / MSecsPerSec;

      FLock.Enter;
      try
        Writeln(FLog, Format('Response Code: %d, Time: %.3f sec, at %s', [FResponseCode, FResponseTime, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
        Memo1.Lines.Add(Format('Response Code: %d, Time: %.3f sec, at %s', [FResponseCode, FResponseTime, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
        SetLength(FResponseTimes, Length(FResponseTimes) + 1);
        FResponseTimes[High(FResponseTimes)] := FResponseTime;
        SetLength(FResponseCodes, Length(FResponseCodes) + 1);
        FResponseCodes[High(FResponseCodes)] := FResponseCode;
        Inc(FTotalRequests);
        if FSuccess then
          Inc(FSuccessfulRequests);

        ResultObj := TJSONObject.Create;
        try
          ResultObj.AddPair('ResponseCode', TJSONNumber.Create(FResponseCode));
          ResultObj.AddPair('ResponseTime', TJSONNumber.Create(FResponseTime));
          FResults.AddElement(ResultObj);
        except
          ResultObj.Free;
          raise;
        end;
      finally
        FLock.Leave;
      end;
    finally
      Http.Free;
      Proxy.Free;
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

end.

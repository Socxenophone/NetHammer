program PortScanner;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, Sockets, BaseUnix, Unix, Crt;

const
  TIMEOUT_SECONDS = 1; // Timeout in seconds

// Function to create a socket
function CreateSocket: TSocket;
begin
  Result := fpSocket(AF_INET, SOCK_STREAM, 0);
  if Result = -1 then
  begin
    Writeln('Error creating socket');
    Halt;
  end;
end;

// Function to set a timeout on the socket
procedure SetTimeout(Socket: TSocket; Timeout: Integer);
var
  TimeVal: TTimeVal;
begin
  TimeVal.tv_sec := Timeout;
  TimeVal.tv_usec := 0;
  if fpSetSockOpt(Socket, SOL_SOCKET, SO_RCVTIMEO, @TimeVal, SizeOf(TimeVal)) = -1 then
  begin
    Writeln('Error setting socket timeout');
    Halt;
  end;
end;

// Function to scan a single port
procedure ScanPort(const TargetIP: string; Port: Integer);
var
  Socket: TSocket;
  ServerAddr: TSockAddrIn;
  Result: Integer;
begin
  Socket := CreateSocket;
  try
    FillChar(ServerAddr, SizeOf(ServerAddr), 0);
    ServerAddr.sin_family := AF_INET;
    ServerAddr.sin_port := htons(Port);
    ServerAddr.sin_addr.s_addr := inet_addr(PChar(TargetIP));

    SetTimeout(Socket, TIMEOUT_SECONDS);

    Result := fpConnect(Socket, @ServerAddr, SizeOf(ServerAddr));
    if Result = 0 then
    begin
      Writeln(Format('Port %d is OPEN', [Port]));
    end
    else
    begin
      Writeln(Format('Port %d is CLOSED or FILTERED', [Port]));
    end;
  finally
    fpCloseSocket(Socket);
  end;
end;

// Function to scan a range of ports
procedure ScanPorts(const TargetIP: string; StartPort, EndPort: Integer);
var
  Port: Integer;
begin
  for Port := StartPort to EndPort do
  begin
    ScanPort(TargetIP, Port);
  end;
end;

// Main function
procedure Main;
var
  TargetIP: string;
  StartPort, EndPort: Integer;
begin
  Write('Enter target IP address: ');
  ReadLn(TargetIP);
  Write('Enter starting port: ');
  ReadLn(StartPort);
  Write('Enter ending port: ');
  ReadLn(EndPort);

  Writeln(Format('Scanning %s from port %d to %d...', [TargetIP, StartPort, EndPort]));
  ScanPorts(TargetIP, StartPort, EndPort);
end;

begin
  Main;
end.

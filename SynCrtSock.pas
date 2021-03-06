/// classes implementing HTTP/1.1 client and server protocol
// - this unit is a part of the freeware Synopse mORMot framework,
// licensed under a MPL/GPL/LGPL tri-license; version 1.18
unit SynCrtSock;

{
    This file is part of Synopse framework.

    Synopse framework. Copyright (C) 2014 Arnaud Bouchez
      Synopse Informatique - http://synopse.info

  *** BEGIN LICENSE BLOCK *****
  Version: MPL 1.1/GPL 2.0/LGPL 2.1

  The contents of this file are subject to the Mozilla Public License Version
  1.1 (the "License"); you may not use this file except in compliance with
  the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
  for the specific language governing rights and limitations under the License.

  The Original Code is Synopse mORMot framework.

  The Initial Developer of the Original Code is Arnaud Bouchez.

  Portions created by the Initial Developer are Copyright (C) 2014
  the Initial Developer. All Rights Reserved.

  Contributor(s):
  - pavel (mpv)
  
  Alternatively, the contents of this file may be used under the terms of
  either the GNU General Public License Version 2 or later (the "GPL"), or
  the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
  in which case the provisions of the GPL or the LGPL are applicable instead
  of those above. If you wish to allow use of your version of this file only
  under the terms of either the GPL or the LGPL, and not to allow others to
  use your version of this file under the terms of the MPL, indicate your
  decision by deleting the provisions above and replace them with the notice
  and other provisions required by the GPL or the LGPL. If you do not delete
  the provisions above, a recipient may use your version of this file under
  the terms of any one of the MPL, the GPL or the LGPL.

  ***** END LICENSE BLOCK *****


   TCP/IP and HTTP/1.1 Client and Server
  ***************************************

  Initial version: 2009 May, by Arnaud Bouchez

  Version 1.4 - February 8, 2010
  - whole Synopse SQLite3 database framework released under the GNU Lesser
    General Public License version 3, instead of generic "Public Domain"
  - fix a bug happening when multiple HTTP connections were opened and
    closed in the same program

  Version 1.5 - March 1, 2010
  - new generic unix implementation, using libc sockets, in SynLibcSock.pas

  Version 1.9
  - avoid some GPF during client deconnection when the server shut down
  - rewrite HTTP Server handle request loop keep alive timing
  - HTTP Server now use a Thread Pool to speed up multi-connections: this
    speed up a lot HTTP/1.0 requests, by creating a Thread only if
    necessary

  Version 1.9.2
  - deleted deprecated DOS related code (formerly used with DWPL Dos Extender)
  - a dedicated thread is now used if the incoming HTTP request has
    POSTed a body content of more than 16 KB (to avoid Deny Of Service, and
    preserve the Thread Pool to only real small processes)
  - new CROnly parameter for TCrtSocket.SockRecvLn, to handle #13 as
    line delimiter: by default, #10 or #13#10 are line delimiters
    (as for normal Window/Linux text files)

  Version 1.12
  - added connection check and exception handling in
    THttpServerSocket.GetRequest, which now is a function returning a boolean
  - added DOS / TCP SYN Flood detection if THttpServerSocket.GetRequest
    spent more than 2 seconds to get header from HTTP Client

  Version 1.13
  - code modifications to compile with Delphi 5 compiler
  - new THttpApiServer class, using fast http.sys kernel-mode server
    for better performance and less resource usage
  - DOS / TCP SYN Flood detection time enhanced to 5 seconds
  - fixed HTTP client stream layout (to be more RFC compliant)
  - new generic compression handling mechanism: can handle gzip, deflate
    or custom synlz / synlzo algorithms via THttpSocketCompress functions
  - new THttpServerGeneric.Request virtual abstract method prototype
  - new TWinINet class, using WinINet API (very slow, do not use)
  - new TWinHTTP class, using WinHTTP API (faster than THttpClientSocket):
    this is the class to be used

  Version 1.15
  - unit now tested with Delphi XE2 (32 Bit)
  - fixed issue in HTTP_RESPONSE.SetHeaders()

  Version 1.16
  - fixed issue in case of wrong void parameter e.g. in THttpApiServer.AddUrl
  - circumvent some bugs of Delphi XE2 background compiler (main compiler is OK)
  - added 'RemoteIP: 127.0.0.1' to the retrieved HTTP headers
  - major speed up of THttpApiServer for Windows Vista and up, by processing
    huge content in chunks: upload of 100Mb file take 25 sec before and 6 sec
    after changes, according to feedback by MPV - ticket 711247b998
  - new THttpServerGeneric.OnHttpThreadTerminate event, available to clean-up
    any process in the thread context, when it is terminated (to call e.g.
    TSQLDBConnectionPropertiesThreadSafe.EndCurrentThread in order to call
    CoUnInitialize from thread in which CoInitialize was initialy made) - see
    http://synopse.info/fossil/tktview?name=213544b2f5

  Version 1.17
  - replaced TSockData string type to the generic RawByteString type (and
    the default AnsiString for non-Unicode version of Delphi)
  - added optional aProxyName, aProxyByPass parameters to TWinHttpAPI /
    TWinInet and TWinHTTP constructors
  - added THttpServerGeneric.OnHttpThreadStart property, and associated
    TNotifyThreadEvent event prototype
  - handle 'Range: bytes=***-***' request in THttpApiServer

  Version 1.18
  - introducing THttpServerRequest class for HTTP server context
  - http.sys kernel-mode server now handles HTTP API 2.0 (available since
    Windows Vista / Server 2008), or fall back to HTTP API 1.0 (for Windows XP
    or Server 2003) - thanks pavel for the feedback and initial patch!
  - deep code refactoring of thread process, especially for TSynThreadPool as
    used by THttpServer: introducing TNotifiedThread and TSynThreadPoolSubThread;
    as a result, it fixes OnHttpThreadStart and OnHttpThreadTerminate to be
    triggered from every thread, as expected
  - converted any AnsiString type into a more neutral RawByteString (this is
    correct for URIs or port numbers, and avoid any dependency to SynCommons)
  - added TCrtSocket.TCPNoDelay/SendTimeout/ReceiveTimeout/KeepAlive properties
  - added THttpApiServer.RemoveUrl() method
  - added THttpApiServer.HTTPQueueLength property (for HTTP API 2.0 only)
  - added THttpApiServer.MaxBandwidth and THttpApiServer.MaxConnections
    properties (for HTTP API 2.0 only) - thanks mpv for the proposal!
  - added THttpApiServer.ServerSessionID and UrlGroupID read-only properties
  - let HTTP_RESPONSE.AddCustomHeader() recognize all known headers
  - THttpApiServer won't try to send an error message when connection is broken
  - added error check for HttpSendHttpResponse() API call
  - added EWinHTTP exception, raised when TWinHttp client fails to connect
  - added aTimeOut optional parameter to TCrtSocket.Open() constructor
  - added function HtmlEncode()
  - some code cleaning about 64 bit compilation (including [540628f498])
  - refactored HTTP_DATA_CHUNK record definition into HTTP_DATA_CHUNK_* records
    to circumvent XE3 alignemnt issue
  - WinSock-based THttpServer will avoid creating a thread per connection,
    when the maximum of 64 threads is reached in the pool, with an exception
    of kept-alife or huge body requets (avoiding DoS attacks by limiting the
    total number of created threads)
  - let WinSock-based THttpServer.Process() handle HTTP_RESP_STATICFILE
  - force disable range checking and other compiler options for this unit
  - included more detailed information to HTTP client User-Agent header
  - added SendTimeout and ReceiveTimeout optional parameters to TWinHttpAPI
    constructors - feature request [bfe485b678]
  - added optional aCompressMinSize parameter to RegisterCompress() methods
  - added TWinHttpAPI.Get/Post/Put/Delete() class functions for easy remote
    resource retrieval using either WinHTTP or WinINet APIs
  - added TURI structure, ready to parse a supplied HTTP URI
  - added 'ConnectionID: 1234578' to the HTTP headers - request [0636eeec54]
  - fixed TCrtSocket.BytesIn and TCrtSocket.BytesOut properties
  - fixed ticket [82df275784] TWinHttpAPI with responses without Content-Length
  - fixed ticket [f0749956af] TWinINet does not work with HTTPS servers
  - fixed ticket [842a5ae15a] THttpApiServer.Execute/SendError message
  - fixed ticket [f2ae4022a4] EWinINet error handling
  - fixed ticket [73da2c17b1] about Accept-Encoding header in THttpApiServer
  - fixed ticket [cbcbb3b2fc] about PtrInt definition
  - fixed ticket [91f8f3ec6f] about error retrieving unknown headers
  - fixed ticket [f79ff5714b] about potential finalization issues as .bpl in IDE
  - fixed ticket [2d53fc43e3] about unneeded port 80
  - fixed ticket [11b327bd77] about TCrtSocket not working with Delphi 2009+
  - fixed ticket [0f6ecdaf55] for better compatibility with HTTP/1.1 cache
  - fixed ticket [814f6bd65a] about missing OnHttpThreadStart in CreateClone
  - fixed ticket [51a9c086f3] about THttpApiServer.SetHTTPQueueLength()
  - fixed potential Access Violation error at THttpServerResp shutdown
  - removed several compilation hints when assertions are set to off
  - added aRegisterURI optional parameter to THttpApiServer.AddUrl() method
  - made exception error messages more explicit (tuned per module)
  - fixed several issues when releasing THttpApiServer and THttpServer instances
  - allow to use any Unicode content for SendEmail() - also includes
    SendEmailSubject() function, for feature request [0a5fdf9129]  

}

{$I Synopse.inc} // define HASINLINE USETYPEINFO CPU32 CPU64 OWNNORMTOUPPER

interface

{ $define DEBUG2}
{ $define DEBUG23}

{$ifdef MSWINDOWS}
  /// define this to publish TWinINet / TWinHttp / TWinHttpAPI classes
  {$define USEWININET}
  // define this to use TSynThreadPool for faster multi-connection on THttpServer
  // with Thread Pool: 3394 requests / second (each request received 4 KB of data)
  // without the Pool: 140/s in the IDE (i.e. one core), 2637/s on a dual core
  {$define USETHREADPOOL}
{$else}
  {$undef USEWININET}    // WinINet / WinHTTP / HttpAPI expect a Windows system
  {$undef USETHREADPOOL} // our IOCP patternis Windows-specific
{$endif}

{$ifdef DEBUG2}
{.$define DEBUG}
{$endif}

uses
{$ifdef MSWINDOWS}
  Windows,
  SynWinSock,
  {$ifdef USEWININET}
    WinInet,
  {$endif}
{$else}
  {$undef USEWININET}
  {$ifdef CONDITIONALEXPRESSIONS}
    Types,
  {$endif}
  LibC,
{$endif}
{$ifndef LVCL}
  Contnrs,
{$endif}
  SysUtils,
  Classes;

const
  /// the current version number of the freeware Synopse framework
  // - match the value defined in SynCommons.pas
  SYNOPSE_FRAMEWORK_VERSION = '1.18'{$ifdef LVCL}+' LVCL'{$endif};

  /// the full text of the current Synopse mORMot framework version
  XPOWEREDPROGRAM = 'Synopse mORMot '+SYNOPSE_FRAMEWORK_VERSION;

  /// used by THttpApiServer.Request for http.sys to send a static file
  // - the OutCustomHeader should contain the proper 'Content-type: ....'
  // corresponding to the file (e.g. by calling GetMimeContentType() function
  // from SynCommons supplyings the file name)
  // - should match HTML_CONTENT_STATICFILE constant defined in mORMot.pas unit
  HTTP_RESP_STATICFILE = '!STATICFILE';

  /// TWinHttpAPI timeout default value for DNS resolution
  // - leaving to 0 will let system default value be used
  HTTP_DEFAULT_RESOLVETIMEOUT = 0;
  /// TWinHttpAPI timeout default value for remote connection
  // - default is 60 seconds
  HTTP_DEFAULT_CONNECTTIMEOUT = 60000;
  /// TWinHttpAPI timeout default value for data sending
  // - default is 30 seconds
  // - you can override this value by setting the corresponding parameter in
  // TWinHttpAPI.Create() constructor
  HTTP_DEFAULT_SENDTIMEOUT = 30000;
  /// TWinHttpAPI timeout default value for data receiving
  // - default is 30 seconds
  // - you can override this value by setting the corresponding parameter in
  // TWinHttpAPI.Create() constructor
  HTTP_DEFAULT_RECEIVETIMEOUT = 30000;

type
{$ifdef UNICODE}
  /// define the fastest Unicode string type of the compiler
  SynUnicode = UnicodeString;
{$else}
  /// define the fastest Unicode string type of the compiler
  SynUnicode = WideString;
  /// define RawByteString, as it does exist in Delphi 2009 and up
  // - to be used for byte storage into an AnsiString
  RawByteString = AnsiString;
{$endif}

{$ifndef CONDITIONALEXPRESSIONS}
  // not defined in Delphi 5 or older
  PPointer = ^Pointer;
  TTextLineBreakStyle = (tlbsLF, tlbsCRLF);
  UTF8String = AnsiString;
  UTF8Encode = AnsiString;
{$endif}

{$ifndef FPC}
  /// FPC 64 compatibility integer type
  {$ifdef UNICODE}
  PtrInt = NativeInt;
  PtrUInt = NativeUInt;
  {$else}
  PtrInt = integer;
  PtrUInt = cardinal;
  {$endif}
  /// FPC 64 compatibility pointer type
  PPtrInt = ^PtrInt;
  PPtrUInt = ^PtrUInt;
{$endif}

  /// exception thrown by the classes of this unit
  ECrtSocket = class(Exception)
  public
    constructor Create(const Msg: string); overload;
    constructor Create(const Msg: string; Error: integer); overload;
  end;

  TCrtSocketClass = class of TCrtSocket;

  /// the available available network transport layer
  // - either TCP/IP, UDP/IP or Unix sockets
  TCrtSocketLayer = (cslTCP, cslUDP, cslUNIX);

  /// Fast low-level Socket implementation
  // - direct access to the OS (Windows, Linux) network layer
  // - use Open constructor to create a client to be connected to a server
  // - use Bind constructor to initialize a server
  // - use direct access to low level Windows or Linux network layer
  // - use SockIn and SockOut (after CreateSock*) to read or write data
  //  as with standard Delphi text files (see SendEmail implementation)
  // - if app is multi-threaded, use faster SockSend() instead of SockOut^
  //  for direct write access to the socket; but SockIn^ is much faster than
  // SockRecv() thanks to its internal buffer, even on multi-threaded app
  // (at least under Windows, it may be up to 10 times faster)
  // - but you can decide whatever to use none, one or both SockIn/SockOut
  // - our classes are much faster than the Indy or Synapse implementation
  TCrtSocket = class
  protected
    /// raise an ECrtSocket exception on error (called by Open/Bind constructors)
    procedure OpenBind(const aServer, aPort: RawByteString; doBind: boolean;
      aSock: integer=-1; aLayer: TCrtSocketLayer=cslTCP);
    procedure SetInt32OptionByIndex(OptName, OptVal: integer);
  public
    /// initialized after Open() with socket
    Sock: TSocket;
    /// initialized after Open() with Server name
    Server: RawByteString;
    /// initialized after Open() with port number
    Port: RawByteString;
    /// after CreateSockIn, use Readln(SockIn,s) to read a line from the opened socket
    SockIn: ^TextFile;
    /// after CreateSockOut, use Writeln(SockOut,s) to send a line to the opened socket
    SockOut: ^TextFile;
    /// if higher than 0, read loop will wait for incoming data till
    // TimeOut milliseconds (default value is 10000) - used also in SockSend()
    TimeOut: cardinal;
    /// total bytes received
    BytesIn,
    /// total bytes sent
    BytesOut: Int64;
    /// common initialization of all constructors
    // - do not call directly, but use Open / Bind constructors instead
    constructor Create(aTimeOut: cardinal=10000); reintroduce; virtual;
    /// connect to aServer:aPort
    constructor Open(const aServer, aPort: RawByteString; aLayer: TCrtSocketLayer=cslTCP;
      aTimeOut: cardinal=10000);
    /// bind to aPort
    constructor Bind(const aPort: RawByteString; aLayer: TCrtSocketLayer=cslTCP);
    /// initialize SockIn for receiving with read[ln](SockIn^,...)
    // - data is buffered, filled as the data is available
    // - read(char) or readln() is indeed very fast
    // - multithread applications would also use this SockIn pseudo-text file
    // - by default, expect CR+LF as line feed (i.e. the HTTP way)
    procedure CreateSockIn(LineBreak: TTextLineBreakStyle=tlbsCRLF);
    /// initialize SockOut for sending with write[ln](SockOut^,....)
    // - data is sent (flushed) after each writeln() - it's a compiler feature
    // - use rather SockSend() + SockSendFlush to send headers at once e.g.
    // since writeln(SockOut^,..) flush buffer each time
    procedure CreateSockOut;
    /// close the opened socket, and corresponding SockIn/SockOut
    destructor Destroy; override;
    /// read Length bytes from SockIn buffer + Sock if necessary
    // - if SockIn is available, it first gets data from SockIn^.Buffer,
    // then directly receive data from socket
    // - can be used also without SockIn: it will call directly SockRecv() in such case
    function SockInRead(Content: PAnsiChar; Length: integer): integer;
    /// check the connection status of the socket
    function SockConnected: boolean;
    /// simulate writeln() with direct use of Send(Sock, ..)
    // - useful on multi-treaded environnement (as in THttpServer.Process)
    // - no temp buffer is used
    // - handle RawByteString, ShortString, Char, Integer parameters
    // - raise ECrtSocket exception on socket error
    procedure SockSend(const Values: array of const); overload;
    /// simulate writeln() with a single line
    procedure SockSend(const Line: RawByteString=''); overload;
    /// flush all pending data to be sent
    procedure SockSendFlush;
    /// fill the Buffer with Length bytes
    // - use TimeOut milliseconds wait for incoming data
    // - bypass the SockIn^ buffers
    // - raise ECrtSocket exception on socket error
    procedure SockRecv(Buffer: pointer; Length: integer);
    /// returns the socket input stream as a string
    function SockReceiveString: RawByteString;
    /// fill the Buffer with Length bytes
    // - use TimeOut milliseconds wait for incoming data
    // - bypass the SockIn^ buffers
    // - return false on any error, true on success
    function TrySockRecv(Buffer: pointer; Length: integer): boolean;
    /// call readln(SockIn^,Line) or simulate it with direct use of Recv(Sock, ..)
    // - char are read one by one
    // - use TimeOut milliseconds wait for incoming data
    // - raise ECrtSocket exception on socket error
    // - by default, will handle #10 or #13#10 as line delimiter (as normal text
    // files), but you can delimit lines using #13 if CROnly is TRUE
    procedure SockRecvLn(out Line: RawByteString; CROnly: boolean=false); overload;
    /// call readln(SockIn^) or simulate it with direct use of Recv(Sock, ..)
    // - char are read one by one
    // - use TimeOut milliseconds wait for incoming data
    // - raise ECrtSocket exception on socket error
    // - line content is ignored
    procedure SockRecvLn; overload;
    /// append P^ data into SndBuf (used by SockSend(), e.g.)
    // - call SockSendFlush to send it through the network via SndLow()
    procedure Snd(P: pointer; Len: integer);
    /// direct send data through network
    // - raise a ECrtSocket exception on any error
    // - bypass the SndBuf or SockOut^ buffers
    procedure SndLow(P: pointer; Len: integer);
    /// direct send data through network
    // - return false on any error, true on success
    // - bypass the SndBuf or SockOut^ buffers
    function TrySndLow(P: pointer; Len: integer): boolean;
    /// direct send data through network
    // - raise a ECrtSocket exception on any error
    // - bypass the SndBuf or SockOut^ buffers
    // - raw Data is sent directly to OS: no CR/CRLF is appened to the block
    procedure Write(const Data: RawByteString);
    /// set the TCP_NODELAY option for the connection
    // - 1 (true) will disable the Nagle buffering algorithm; it should only be
    // set for applications that send frequent small bursts of information
    // without getting an immediate response, where timely delivery of data
    // is required - so it expects buffering before calling Write() or *SndLow()
    // - see http://www.unixguide.net/network/socketfaq/2.16.shtml
    property TCPNoDelay: Integer index TCP_NODELAY write SetInt32OptionByIndex;
    /// set the SO_SNDTIMEO option for the connection
    // - i.e. the timeout, in milliseconds, for blocking send calls
    // - see http://msdn.microsoft.com/en-us/library/windows/desktop/ms740476
    property SendTimeout: Integer index SO_SNDTIMEO write SetInt32OptionByIndex;
    /// set the SO_RCVTIMEO option for the connection
    // - i.e. the timeout, in milliseconds, for blocking receive calls
    // - see http://msdn.microsoft.com/en-us/library/windows/desktop/ms740476
    property ReceiveTimeout: Integer index SO_RCVTIMEO write SetInt32OptionByIndex;
    /// set the SO_KEEPALIVE option for the connection
    // - 1 (true) will enable keep-alive packets for the connection
    // - see http://msdn.microsoft.com/en-us/library/windows/desktop/ee470551
    property KeepAlive: Integer index SO_KEEPALIVE write SetInt32OptionByIndex;
  private
    SockInEof: boolean;
    /// updated by every Snd()
    SndBuf: RawByteString;
    SndBufLen: integer;
    /// close and shutdown the connection (called from Destroy)
    procedure Close;
  end;

  /// event used to compress or uncompress some data during HTTP protocol
  // - should always return the protocol name for ACCEPT-ENCODING: header
  // e.g. 'gzip' or 'deflate' for standard HTTP format, but you can add
  // your own (like 'synlzo' or 'synlz')
  // - the data is compressed (if Compress=TRUE) or uncompressed (if
  // Compress=FALSE) in the Data variable (i.e. it is modified in-place)
  // - to be used with THttpSocket.RegisterCompress method
  // - type is a generic AnsiString, which should be in practice a
  // RawByteString or a RawByteString 
  THttpSocketCompress = function(var Data: RawByteString; Compress: boolean): RawByteString;

  /// used to maintain a list of known compression algorithms
  THttpSocketCompressRec = record
    /// the compression name, as in ACCEPT-ENCODING: header (gzip,deflate,synlz)
    Name: RawByteString;
    /// the function handling compression and decompression
    Func: THttpSocketCompress;
    /// the size in bytes after which compress will take place
    // - will be 1024 e.g. for 'zip' or 'deflate'
    // - could be 0 e.g. when encrypting the content, meaning "always compress" 
    CompressMinSize: integer;
  end;

  /// list of known compression algorithms
  THttpSocketCompressRecDynArray = array of THttpSocketCompressRec;

  /// identify some items in a list of known compression algorithms
  THttpSocketCompressSet = set of 0..31;

  /// parent of THttpClientSocket and THttpServerSocket classes
  // - contain properties for implementing the HTTP/1.1 protocol using WinSock
  // - handle chunking of body content
  // - can optionaly compress and uncompress on the fly the data, with
  // standard gzip/deflate or custom (synlzo/synlz) protocols
  THttpSocket = class(TCrtSocket)
  protected
    /// true if the TRANSFER-ENCODING: CHUNKED was set in headers
    Chunked: boolean;
    /// to call GetBody only once
    fBodyRetrieved: boolean;
    /// used by RegisterCompress method
    fCompress: THttpSocketCompressRecDynArray;
    /// set by RegisterCompress method
    fCompressAcceptEncoding: RawByteString;
    /// GetHeader set index of protocol in fCompress[], from ACCEPT-ENCODING: 
    fCompressHeader: THttpSocketCompressSet;
    /// same as HeaderValue('Content-Encoding'), but retrieved during Request
    // and mapped into the fCompress[] array
    fContentCompress: integer;
    /// retrieve the HTTP headers into Headers[] and fill most properties below
    procedure GetHeader;
    /// retrieve the HTTP body (after uncompression if necessary) into Content
    procedure GetBody;
    /// compress the data, adding corresponding headers via SockSend()
    // - always add a 'Content-Length: ' header entry (even if length=0)
    // - e.g. 'Content-Encoding: synlz' header if compressed using synlz
    // - and if Data is not '', will add 'Content-Type: ' header
    procedure CompressDataAndWriteHeaders(const OutContentType: RawByteString;
      var OutContent: RawByteString);
  public
    /// TCP/IP prefix to mask HTTP protocol
    // - if not set, will create full HTTP/1.0 or HTTP/1.1 compliant content
    // - in order to make the TCP/IP stream not HTTP compliant, you can specify
    // a prefix which will be put before the first header line: in this case,
    // the TCP/IP stream won't be recognized as HTTP, and will be ignored by
    // most AntiVirus programs, and increase security - but you won't be able
    // to use an Internet Browser nor AJAX application for remote access any more
    TCPPrefix: RawByteString;
    /// will contain the first header line:
    // - 'GET /path HTTP/1.1' for a GET request with THttpServer, e.g.
    // - 'HTTP/1.0 200 OK' for a GET response after Get() e.g.
    Command: RawByteString;
    /// will contain the header lines after a Request - use HeaderValue() to get one
    Headers: array of RawByteString;
    /// will contain the data retrieved from the server, after the Request
    Content: RawByteString;
    /// same as HeaderValue('Content-Length'), but retrieved during Request
    // - is overridden with real Content length during HTTP body retrieval
    ContentLength: integer;
    /// same as HeaderValue('Content-Type'), but retrieved during Request
    ContentType: RawByteString;
    /// same as HeaderValue('Connection')='close', but retrieved during Request
    ConnectionClose: boolean;
    /// add an header entry, returning the just entered entry index in Headers[]
    function HeaderAdd(const aValue: RawByteString): integer;
    /// set all Header values at once, from CRLF delimited text
    procedure HeaderSetText(const aText: RawByteString);
    /// get all Header values at once, as CRLF delimited text
    function HeaderGetText: RawByteString; virtual;
    /// HeaderValue('Content-Type')='text/html', e.g.
    function HeaderValue(aName: RawByteString): RawByteString;
    /// will register a compression algorithm
    // - used e.g. to compress on the fly the data, with standard gzip/deflate
    // or custom (synlzo/synlz) protocols
    // - returns true on success, false if this function or this
    // ACCEPT-ENCODING: header was already registered
    // - you can specify a minimal size (in bytes) before which the content won't
    // be compressed (1024 by default, corresponding to a MTU of 1500 bytes)
    // - the first registered algorithm will be the prefered one for compression
    function RegisterCompress(aFunction: THttpSocketCompress;
      aCompressMinSize: integer=1024): boolean;
  end;

  THttpServer = class;

  /// WinSock-based HTTP/1.1 server class used by THttpServer Threads
  THttpServerSocket = class(THttpSocket)
  private
  public
    /// contains the method ('GET','POST'.. e.g.) after GetRequest()
    Method: RawByteString;
    /// contains the URL ('/' e.g.) after GetRequest()
    URL: RawByteString;
    /// true if the client is HTTP/1.1 and 'Connection: Close' is not set
    // (default HTTP/1.1 behavior is keep alive, unless 'Connection: Close'
    // is specified, cf. RFC 2068 page 108: "HTTP/1.1 applications that do not
    // support persistent connections MUST include the "close" connection option
    // in every message")
    KeepAliveClient: boolean;
    /// create the socket according to a server
    // - will register the THttpSocketCompress functions from the server
    constructor Create(aServer: THttpServer); reintroduce;
    /// main object function called after aClientSock := Accept + Create:
    // - get initialize the socket with the supplied accepted socket
    // - caller will then use the GetRequest method below to
    // get the request
    procedure InitRequest(aClientSock: TSocket);
    /// main object function called after aClientSock := Accept + Create:
    // - get Command, Method, URL, Headers and Body (if withBody is TRUE)
    // - get sent data in Content (if ContentLength<>0)
    // - return false if the socket was not connected any more, or if
    // any exception occured during the process
    function GetRequest(withBody: boolean=true): boolean;
    /// get all Header values at once, as CRLF delimited text
    // - this overridden version will add the 'RemoteIP: 1.2.3.4' header
    function HeaderGetText: RawByteString; override;
  end;

  /// WinSock-based REST and HTTP/1.1 compatible client class
  // - this component is HTTP/1.1 compatible, according to RFC 2068 document
  // - the REST commands (GET/POST/PUT/DELETE) are directly available
  // - open connection with the server with inherited Open(server,port) function
  // - if KeepAlive>0, the connection is not broken: a further request (within
  // KeepAlive milliseconds) will use the existing connection if available,
  // or recreate a new one if the former is outdated or reset by server
  // (will retry only once); this is faster, uses less resources (especialy
  // under Windows), and is the recommended way to implement a HTTP/1.1 server
  // - on any error (timeout, connection closed) will retry once to get the value
  // - don't forget to use Free procedure when you are finished
  THttpClientSocket = class(THttpSocket)
  public
    /// by default, the client is identified as IE 5.5, which is very
    // friendly welcome by most servers :(
    // - you can specify a custom value here
    UserAgent: RawByteString;

    /// common initialization of all constructors
    // - this overridden method will set the UserAgent with some default value
    constructor Create(aTimeOut: cardinal=10000); override;

    /// after an Open(server,port), return 200 if OK, http status error otherwise - get
    // the page data in Content
    function Get(const url: RawByteString; KeepAlive: cardinal=0; const header: RawByteString=''): integer;
    /// after an Open(server,port), return 200 if OK, http status error otherwise - only
    // header is read from server: Content is always '', but Headers are set
    function Head(const url: RawByteString; KeepAlive: cardinal=0; const header: RawByteString=''): integer;
    /// after an Open(server,port), return 200,201,204 if OK, http status error otherwise
    function Post(const url, Data, DataType: RawByteString; KeepAlive: cardinal=0;
      const header: RawByteString=''): integer;
    /// after an Open(server,port), return 200,201,204 if OK, http status error otherwise
    function Put(const url, Data, DataType: RawByteString; KeepAlive: cardinal=0;
      const header: RawByteString=''): integer;
    /// after an Open(server,port), return 200,202,204 if OK, http status error otherwise
    function Delete(const url: RawByteString; KeepAlive: cardinal=0; const header: RawByteString=''): integer;

    /// low-level HTTP/1.1 request
    // - call by all REST methods above
    // - after an Open(server,port), return 200,202,204 if OK, http status error otherwise
    // - retry is false by caller, and will be recursively called with true to retry once
    function Request(const url, method: RawByteString; KeepAlive: cardinal;
      const header, Data, DataType: RawByteString; retry: boolean): integer;
  end;

  {$ifndef LVCL}
  /// event prototype used e.g. by THttpServerGeneric.OnHttpThreadStart
  TNotifyThreadEvent = procedure(Sender: TThread) of object;
  {$endif}

  /// a simple TThread with a notification flag
  // - used e.g. by THttpServerGeneric.NotifyThreadStart()
  TNotifiedThread = class(TThread)
  protected
    fNotified: TObject;
    {$ifndef LVCL}
    fOnTerminate: TNotifyThreadEvent;
    procedure DoTerminate; override;
    {$endif}
  end;

{$ifdef USETHREADPOOL}
  TSynThreadPoolTHttpServer = class;
{$endif}

  /// HTTP response Thread as used by THttpServer WinSock-based class
  // - Execute procedure get the request and calculate the answer
  // - you don't have to overload the protected THttpServerResp Execute method:
  // override THttpServer.Request() function or, if you need a lower-level access
  // (change the protocol, e.g.) THttpServer.Process() method itself
  THttpServerResp = class(TNotifiedThread)
  protected
    fServer: THttpServer;
    fServerSock: THttpServerSocket;
    {$ifdef USETHREADPOOL}
    fThreadPool: TSynThreadPoolTHttpServer;
    {$endif}
    fClientSock: TSocket;
    /// main thread loop: read request from socket, send back answer
    procedure Execute; override;
  public
    /// initialize the response thread for the corresponding incoming socket
    // - this version will get the request directly from an incoming socket
    constructor Create(aSock: TSocket; aServer: THttpServer); overload;
    /// initialize the response thread for the corresponding incoming socket
    // - this version will handle KeepAlive, for such an incoming request
    constructor Create(aServerSock: THttpServerSocket; aServer: THttpServer
      {$ifdef USETHREADPOOL}; aThreadPool: TSynThreadPoolTHttpServer{$endif}); overload;
  end;

{$ifdef USETHREADPOOL}

  TSynThreadPool = class;

  /// defines the sub-threads used by TSynThreadPool
  TSynThreadPoolSubThread = class(TNotifiedThread)
  protected
    fOwner: TSynThreadPool;
  public
    /// initialize the thread
    constructor Create(Owner: TSynThreadPool);
    /// will loop for any pending IOCP commands, and execute fOwner.Task()
    procedure Execute; override;
  end;

  /// a simple Thread Pool, used for fast handling HTTP requests
  // - will handle multi-connection with less overhead than creating a thread
  // for each incoming request
  // - this Thread Pool is implemented over I/O Completion Ports, which is a faster
  // method than keeping a TThread list, and resume them on request: I/O completion
  // just has the thread running while there is pending tasks, with no pause/resume
  TSynThreadPool = class
  protected
    FRequestQueue: THandle;
    FThread: TObjectList; // of TSynThreadPoolSubThread
    FThreadID: array[0..63] of THandle;
    FGeneratedThreadCount: integer;
    FOnHttpThreadTerminate: TNotifyThreadEvent;
    /// process to be executed after notification
    procedure Task(aCaller: TSynThreadPoolSubThread; aContext: Pointer); virtual; abstract;
  public
    /// initialize a thread pool with the supplied number of threads
    // - abstract Task() virtual method will be called by one of the threads 
    // - up to 64 threads can be associated to a Thread Pool
    constructor Create(NumberOfThreads: Integer=32); 
    /// shut down the Thread pool, releasing all associated threads
    destructor Destroy; override;
  end;

  /// a simple Thread Pool, used for fast handling HTTP requests of a THttpServer
  // - will create a THttpServerResp response thread, if the incoming request
  // is identified as HTTP/1.1 keep alive
  TSynThreadPoolTHttpServer = class(TSynThreadPool)
  protected
    fServer: THttpServer;
    procedure Task(aCaller: TSynThreadPoolSubThread; aContext: Pointer); override;
  public
    /// initialize a thread pool with the supplied number of threads
    // - Task() overridden method processs the HTTP request set by Push()
    // - up to 64 threads can be associated to a Thread Pool
    constructor Create(Server: THttpServer; NumberOfThreads: Integer=32); reintroduce;
    /// add an incoming HTTP request to the Thread Pool
    function Push(aClientSock: TSocket): Boolean;
  end;
  
{$endif USETHREADPOOL}

{$M+} // to have existing RTTI for published properties
  THttpServerGeneric = class;
{$M-}

  /// a generic input/output structure used for HTTP server requests
  // - URL/Method/InHeaders/InContent properties are input parameters
  // - OutContent/OutContentType/OutCustomHeader are output parameters
  // - OutCustomHeader will handle Content-Type/Location
  // - if OutContentType is HTTP_RESP_STATICFILE (i.e. '!STATICFILE', defined
  // as STATICFILE_CONTENT_TYPE in mORMot.pas), then OutContent is the UTF-8
  // file name of a file which must be sent to the client via http.sys (much
  // faster than manual buffering/sending)
  THttpServerRequest = class
  protected
    fURL, fMethod, fInHeaders, fInContent, fInContentType: RawByteString;
    fOutContent, fOutContentType, fOutCustomHeaders: RawByteString;
    fServer: THttpServerGeneric;
    fCallingThread: TNotifiedThread;
  public
    /// initialize the context, associated to a HTTP server instance
    constructor Create(aServer: THttpServerGeneric; aCallingThread: TNotifiedThread);
    /// prepare an incoming request
    // - will set input parameters URL/Method/InHeaders/InContent/InContentType
    // - will reset output parameters
    procedure Prepare(const aURL, aMethod, aInHeaders, aInContent, aInContentType: RawByteString);
    /// input parameter containing the caller URI
    property URL: RawByteString read fURL;
    /// input parameter containing the caller method (GET/POST...)
    property Method: RawByteString read fMethod;
    /// input parameter containing the caller message headers
    property InHeaders: RawByteString read fInHeaders;
    /// input parameter containing the caller message body
    // - e.g. some GET/POST/PUT JSON data can be specified here
    property InContent: RawByteString read fInContent;
    // input parameter defining the caller message body content type
    property InContentType: RawByteString read fInContentType;
    /// output parameter to be set to the response message body
    property OutContent: RawByteString read fOutContent write fOutContent ;
    /// output parameter to define the reponse message body content type
    property OutContentType: RawByteString read fOutContentType write fOutContentType;
    /// output parameter to be sent back as the response message header
    property OutCustomHeaders: RawByteString read fOutCustomHeaders write fOutCustomHeaders;
    /// the associated server instance
    property Server: THttpServerGeneric read fServer;
    /// the thread instance which called this execution context
    property CallingThread: TNotifiedThread read fCallingThread;
  end;

  /// event handler used by THttpServerGeneric.OnRequest property
  // - Ctxt defines both input and output parameters
  // - result of the function is the HTTP error code (200 if OK, e.g.)
  // - OutCustomHeader will handle Content-Type/Location
  // - if OutContentType is HTTP_RESP_STATICFILE (i.e. '!STATICFILE' aka
  // STATICFILE_CONTENT_TYPE in mORMot.pas), then OutContent is the UTF-8 file
  // name of a file which must be sent to the client via http.sys (much faster
  // than manual buffering/sending) and  the OutCustomHeader should
  // contain the proper 'Content-type: ....'
  TOnHttpServerRequest = function(Ctxt: THttpServerRequest): cardinal of object;

{$M+} // to have existing RTTI for published properties
  /// generic HTTP server
  THttpServerGeneric = class(TNotifiedThread)
  protected
    /// optional event handler for the virtual Request method
    fOnRequest: TOnHttpServerRequest;
    /// list of all registered compression algorithms
    fCompress: THttpSocketCompressRecDynArray;
    /// set by RegisterCompress method
    fCompressAcceptEncoding: RawByteString;
    fOnHttpThreadStart: TNotifyThreadEvent;
    function GetAPIVersion: string; virtual; abstract;
    procedure NotifyThreadStart(Sender: TNotifiedThread);
  public
    /// override this function to customize your http server
    // - InURL/InMethod/InContent properties are input parameters
    // - OutContent/OutContentType/OutCustomHeader are output parameters
    // - result of the function is the HTTP error code (200 if OK, e.g.)
    // - OutCustomHeader will handle Content-Type/Location
    // - if OutContentType is HTTP_RESP_STATICFILE (i.e. '!STATICFILE' or
    // STATICFILE_CONTENT_TYPE defined in mORMot.pas), then OutContent is the
    // UTF-8 file name of a file which must be sent to the client via http.sys
    // (much faster than manual buffering/sending) and  the OutCustomHeader should
    // contain the proper 'Content-type: ....'
    // - default implementation is to call the OnRequest event (if existing)
    // - warning: this process must be thread-safe (can be called by several
    // threads simultaneously)
    function Request(Ctxt: THttpServerRequest): cardinal; virtual;
    /// will register a compression algorithm
    // - used e.g. to compress on the fly the data, with standard gzip/deflate
    // or custom (synlzo/synlz) protocols
    // - you can specify a minimal size (in bytes) before which the content won't
    // be compressed (1024 by default, corresponding to a MTU of 1500 bytes)
    // - the first registered algorithm will be the prefered one for compression
    procedure RegisterCompress(aFunction: THttpSocketCompress;
      aCompressMinSize: integer=1024); virtual;
    /// event handler called by the default implementation of the
    // virtual Request method
    // - warning: this process must be thread-safe (can be called by several
    // threads simultaneously)
    property OnRequest: TOnHttpServerRequest read fOnRequest write fOnRequest;
    /// event handler called when the Thread is just initiated
    // - called in the thread context at first place in THttpServerGeneric.Execute
    property OnHttpThreadStart: TNotifyThreadEvent
      read fOnHttpThreadStart write fOnHttpThreadStart;
    /// event handler called when the Thread is terminating, in the thread context
    // - the TThread.OnTerminate event will be called within a Synchronize()
    // wrapper, so it won't fit our purpose
    // - to be used e.g. to call CoUnInitialize from thread in which CoInitialize
    // was made, for instance via a method defined as such:
    // ! procedure TMyServer.OnHttpThreadTerminate(Sender: TObject);
    // ! begin // TSQLDBConnectionPropertiesThreadSafe
    // !   fMyConnectionProps.EndCurrentThread;
    // ! end;
    property OnHttpThreadTerminate: TNotifyThreadEvent read fOnTerminate write fOnTerminate;
  published
    /// returns the API version used by the inherited implementation
    property APIVersion: string read GetAPIVersion;
  end;

  ULONGLONG = Int64;
  HTTP_OPAQUE_ID = ULONGLONG;
  HTTP_URL_GROUP_ID = HTTP_OPAQUE_ID;
  HTTP_SERVER_SESSION_ID = HTTP_OPAQUE_ID;

  {/ HTTP server using fast http.sys kernel-mode server
   - The HTTP Server API enables applications to communicate over HTTP without
   using Microsoft Internet Information Server (IIS). Applications can register
   to receive HTTP requests for particular URLs, receive HTTP requests, and send
   HTTP responses. The HTTP Server API includes SSL support so that applications
   can exchange data over secure HTTP connections without IIS. It is also
   designed to work with I/O completion ports.
   - The HTTP Server API is supported on Windows Server 2003 operating systems
   and on Windows XP with Service Pack 2 (SP2). Be aware that Microsoft IIS 5
   running on Windows XP with SP2 is not able to share port 80 with other HTTP
   applications running simultaneously. }
  THttpApiServer = class(THttpServerGeneric)
  protected
    /// the internal request queue
		fReqQueue: THandle;
    /// contain list of THttpApiServer cloned instances
    fClones: TObjectList;
    // if fClones=nil, fOwner contains the main THttpApiServer instance
    fOwner: THttpApiServer;
    /// list of all registered URL
    fRegisteredUnicodeUrl: array of SynUnicode;
    fServerSessionID: HTTP_SERVER_SESSION_ID;
    fUrlGroupID: HTTP_URL_GROUP_ID;
    function GetRegisteredUrl: SynUnicode;
    function GetCloned: boolean;
    function GetHTTPQueueLength: Cardinal;
    procedure SetHTTPQueueLength(aValue: Cardinal);
    function GetMaxBandwidth: Cardinal;
    procedure SetMaxBandwidth(aValue: Cardinal);
    function GetMaxConnections: Cardinal;
    procedure SetMaxConnections(aValue: Cardinal);
    function GetAPIVersion: string; override;
    /// server main loop - don't change directly
    // - will call the Request public virtual method with the appropriate
    // parameters to retrive the content
    procedure Execute; override;
    /// create a clone
    constructor CreateClone(From: THttpApiServer);
  public
    /// initialize the HTTP Service
    // - will raise an exception if http.sys is not available (e.g. before
    // Windows XP SP2) or if the request queue creation failed
    // - if you override this contructor, put the AddUrl() methods within,
    // and you can set CreateSuspended to TRUE
    // - if you will call AddUrl() methods later, set CreateSuspended to FALSE,
    // then call explicitely the Resume method, after all AddUrl() calls, in
    // order to start the server
    constructor Create(CreateSuspended: Boolean);
    /// release all associated memory and handles
    destructor Destroy; override;
    /// will clone this thread into multiple other threads
    // - could speed up the process on multi-core CPU
    // - will work only if the OnProcess property was set (this is the case
    // e.g. in TSQLHttpServer.Create() constructor)
    // - maximum value is 256 - higher should not be worth it
    procedure Clone(ChildThreadCount: integer);
    /// register the URLs to Listen On
    // - e.g. AddUrl('root','888')
    // - aDomainName could be either a fully qualified case-insensitive domain
    // name, an IPv4 or IPv6 literal string, or a wildcard ('+' will bound
    // to all domain names for the specified port, '*' will accept the request
    // when no other listening hostnames match the request for that port)
    // - return 0 (NO_ERROR) on success, an error code if failed: under Vista
    // and Seven, you could have ERROR_ACCESS_DENIED if the process is not
    // running with enough rights (by default, UAC requires administrator rights
    // for adding an URL to http.sys registration list) - solution is to call
    // the THttpApiServer.AddUrlAuthorize class method during program setup
    // - if this method is not used within an overridden constructor, default
    // Create must have be called with CreateSuspended = TRUE and then call the
    // Resume method after all Url have been added
    // - if aRegisterURI is TRUE, the URI will be registered (need adminitrator
    // rights) - default is FALSE, as defined by Windows security policy
    function AddUrl(const aRoot, aPort: RawByteString; Https: boolean=false;
      const aDomainName: RawByteString='*'; aRegisterURI: boolean=false): integer;
    /// un-register the URLs to Listen On
    // - this method expect the same parameters as specified to AddUrl()
    // - return 0 (NO_ERROR) on success, an error code if failed (e.g.
    // -1 if the corresponding parameters do not match any previous AddUrl)
    function RemoveUrl(const aRoot, aPort: RawByteString; Https: boolean=false;
      const aDomainName: RawByteString='*'): integer;
    /// will authorize a specified URL prefix
    // - will allow to call AddUrl() later for any user on the computer
    // - if aRoot is left '', it will authorize any root for this port
    // - must be called with Administrator rights: this class function is to be
    // used in a Setup program for instance, especially under Vista or Seven,
    // to reserve the Url for the server
    // - add a new record to the http.sys URL reservation store
    // - return '' on success, an error message otherwise
    // - will first delete any matching rule for this URL prefix
    // - if OnlyDelete is true, will delete but won't add the new authorization;
    // in this case, any error message at deletion will be returned
    class function AddUrlAuthorize(const aRoot, aPort: RawByteString; Https: boolean=false;
      const aDomainName: RawByteString='*'; OnlyDelete: boolean=false): string;
    /// will register a compression algorithm
    // - overridden method which will handle any cloned instances
    procedure RegisterCompress(aFunction: THttpSocketCompress;
      aCompressMinSize: integer=1024); override;
    /// access to the internal THttpApiServer list cloned by this main instance
    // - as created by Clone() method
    property Clones: TObjectList read fClones;
    /// read-only access to the low-level Session ID of this server instance
    property ServerSessionID: HTTP_SERVER_SESSION_ID read fServerSessionID;
    /// read-only access to the low-level URI Group ID of this server instance
    property UrlGroupID: HTTP_URL_GROUP_ID read fUrlGroupID;
  published
    /// TRUE if this instance is in fact a cloned instance for the thread pool
    property Cloned: boolean read GetCloned;
    /// return the list of registered URL on this server instance
    property RegisteredUrl: SynUnicode read GetRegisteredUrl;
    /// HTTP.sys requers/responce queue length (via HTTP API 2.0)
    // - default value if 1000, which sounds fine for most use cases
    // - increase this value in case of many 503 HTTP answers or if many
    // "QueueFull" messages appear in HTTP.sys log files (normaly in
    // C:\Windows\System32\LogFiles\HTTPERR\httperr*.log) - may appear with
    // thousands of concurrent clients accessing at once the same server
  	// - see @http://msdn.microsoft.com/en-us/library/windows/desktop/aa364501
    // - will return 0 if the system does not support HTTP API 2.0 (i.e.
    // under Windows XP or Server 2003)
    // - this method will also handle any cloned instances, so you can write e.g.
    // ! if aSQLHttpServer.HttpServer.InheritsFrom(THttpApiServer) then
    // !   THttpApiServer(aSQLHttpServer.HttpServer).HTTPQueueLength := 5000;
    property HTTPQueueLength: Cardinal read GetHTTPQueueLength write SetHTTPQueueLength;
    /// the maximum allowed bandwidth rate in bytes per second (via HTTP API 2.0)
    // - Setting this value to 0 allows an unlimited bandwidth
    // - by default Windows not limit bandwidth (actually limited to 4 Gbit/sec).
    // - will return 0 if the system does not support HTTP API 2.0 (i.e.
    // under Windows XP or Server 2003)
    property MaxBandwidth: Cardinal read GetMaxBandwidth write SetMaxBandwidth;
    /// the maximum number of HTTP connections allowed (via HTTP API 2.0)
    // - Setting this value to 0 allows an unlimited number of connections
    // - by default Windows not limit number of allowed connections
    // - will return 0 if the system does not support HTTP API 2.0 (i.e.
    // under Windows XP or Server 2003)
    property MaxConnections: Cardinal read GetMaxConnections write SetMaxConnections;
  end;

  /// main HTTP server Thread using the standard Sockets library (e.g. WinSock)
  // - bind to a port and listen to incoming requests
  // - assign this requests to THttpServerResp threads
  // - it implements a HTTP/1.1 compatible server, according to RFC 2068 specifications
  // - if the client is also HTTP/1.1 compatible, KeepAlive connection is handled:
  //  multiple requests will use the existing connection and thread;
  //  this is faster and uses less resources, especialy under Windows
  // - a Thread Pool is used internaly to speed up HTTP/1.0 connections
  // - it will trigger the Windows firewall popup UAC window at first run
  // - don't forget to use Free procedure when you are finished
  THttpServer = class(THttpServerGeneric)
  protected
    /// used to protect Process() call
    fProcessCS: TRTLCriticalSection;
{$ifdef USETHREADPOOL}
    /// the associated Thread Pool
    fThreadPool: TSynThreadPoolTHttpServer;
    fThreadPoolContentionCount: cardinal;
    fThreadPoolContentionAbortCount: cardinal;
{$endif}
    fInternalHttpServerRespList: TList;
    // this overridden version will return e.g. 'Winsock 2.514'
    function GetAPIVersion: string; override;
    /// server main loop - don't change directly
    procedure Execute; override;
    /// this method is called on every new client connection, i.e. every time
    // a THttpServerResp thread is created with a new incoming socket
    procedure OnConnect; virtual;
    /// this method is called on every client disconnection to update stats
    procedure OnDisconnect; virtual;
    /// override this function in order to low-level process the request;
    // default process is to get headers, and call public function Request
    procedure Process(ClientSock: THttpServerSocket; aCallingThread: TNotifiedThread); virtual;
  public
    /// contains the main server Socket
    // - it's a raw TCrtSocket, which only need a socket to be bound, listening
    // and accept incoming request
    // - THttpServerSocket are created on the fly for every request, then
    // a THttpServerResp thread is created for handling this THttpServerSocket
    Sock: TCrtSocket;
    /// will contain the total number of connection to the server
    // - it's the global count since the server started
    ServerConnectionCount: cardinal;
    /// time, in milliseconds, for the HTTP.1/1 connections to be kept alive;
    // default is 3000 ms
    ServerKeepAliveTimeOut: cardinal;
    /// TCP/IP prefix to mask HTTP protocol
    // - if not set, will create full HTTP/1.0 or HTTP/1.1 compliant content
    // - in order to make the TCP/IP stream not HTTP compliant, you can specify
    // a prefix which will be put before the first header line: in this case,
    // the TCP/IP stream won't be recognized as HTTP, and will be ignored by
    // most AntiVirus programs, and increase security - but you won't be able
    // to use an Internet Browser nor AJAX application for remote access any more
    TCPPrefix: RawByteString;

    /// create a Server Thread, binded and listening on a port
    // - this constructor will raise a EHttpServer exception if binding failed
    // - you can specify a number of threads to be initialized to handle
    // incoming connections (default is 32, which may be sufficient for most
    // cases, maximum is 64)
    constructor Create(const aPort: RawByteString
      {$ifdef USETHREADPOOL}; ServerThreadPoolCount: integer=32{$endif});
    /// release all memory and handlers
    destructor Destroy; override;
  published
    {$ifdef USETHREADPOOL}
    /// number of times there was no availibility in the internal thread pool
    // to handle an incoming request
    // - this won't make any error, but just delay for 20 ms and try again
    property ThreadPoolContentionCount: cardinal read fThreadPoolContentionCount;
    /// number of times there an incoming request is rejected due to overload
    // - this is an error after 30 seconds of not any process availability
    property ThreadPoolContentionAbortCount: cardinal read fThreadPoolContentionAbortCount;
    {$endif}
  end;
{$M-}

  /// structure used to parse an URI into its components
  // - ready to be supplied e.g. to a TWinHttpAPI sub-class
  // - used e.g. by class function TWinHttpAPI.Get()
  TURI = {$ifdef UNICODE}record{$else}object{$endif}
    /// if the server is accessible via http:// or https://
    Https: boolean;
    /// the server name
    // - e.g. 'www.somewebsite.com'
    Server: RawByteString;
    /// the server port
    // - e.g. '80'
    Port: RawByteString;
    /// the resource address
    // - e.g. '/category/name/10?param=1'
    Address: RawByteString;
    /// fill the members from a supplied URI
    function From(aURI: RawByteString): boolean;
  end;

{$ifdef USEWININET}
  {/ a class to handle HTTP/1.1 request using either WinINet, either WinHTTP API
    - has a common behavior as THttpClientSocket()
    - this abstract class will be implemented e.g. with TWinINet or TWinHttp }
  TWinHttpAPI = class
  protected
    fServer: RawByteString;
    fProxyName: RawByteString;
    fProxyByPass: RawByteString;
    fPort: cardinal;
    fHttps: boolean;
    fKeepAlive: cardinal;
    /// used by RegisterCompress method
    fCompress: THttpSocketCompressRecDynArray;
    /// set by RegisterCompress method
    fCompressAcceptEncoding: RawByteString;
    /// set index of protocol in fCompress[], from ACCEPT-ENCODING: header
    fCompressHeader: THttpSocketCompressSet;
    /// used for internal connection
    fSession, fConnection, fRequest: HINTERNET;
    procedure InternalConnect(SendTimeout,ReceiveTimeout: DWORD); virtual; abstract;
    procedure InternalRequest(const method, aURL: RawByteString); virtual; abstract;
    procedure InternalCloseRequest; virtual; abstract;
    procedure InternalAddHeader(const hdr: RawByteString); virtual; abstract;
    procedure InternalSendRequest(const aData: RawByteString); virtual; abstract;
    function InternalGetInfo(Info: DWORD): RawByteString; virtual; abstract;
    function InternalGetInfo32(Info: DWORD): DWORD; virtual; abstract;
    function InternalReadData(var Data: RawByteString; Read: integer): cardinal; virtual; abstract;
    class function InternalREST(const url,method,data,header: RawByteString): RawByteString;
  public
    /// connect to http://aServer:aPort or https://aServer:aPort
    // - optional aProxyName may contain the name of the proxy server to use,
    // and aProxyByPass an optional semicolon delimited list of host names or
    // IP addresses, or both, that should not be routed through the proxy
    // - you can customize the default client timeouts by setting appropriate
    // SendTimeout and ReceiveTimeout parameters (in ms) - note that after
    // creation of this instance, the connection is tied to the initial
    // parameters, so we won't publish any properties to change those
    // initial values once created
    constructor Create(const aServer, aPort: RawByteString; aHttps: boolean;
      const aProxyName: RawByteString=''; const aProxyByPass: RawByteString='';
      SendTimeout: DWORD=HTTP_DEFAULT_SENDTIMEOUT;
      ReceiveTimeout: DWORD=HTTP_DEFAULT_RECEIVETIMEOUT);

    /// low-level HTTP/1.1 request
    // - after an Create(server,port), return 200,202,204 if OK,
    // http status error otherwise
    function Request(const url, method: RawByteString; KeepAlive: cardinal;
      const InHeader, InData, InDataType: RawByteString;
      out OutHeader, OutData: RawByteString): integer; virtual;

    /// wrapper method to retrieve a resource via an HTTP GET
    // - will parse the supplied URI to check for the http protocol (HTTP/HTTPS),
    // server name and port, and resource name
    // - it will internally create a TWinHttpAPI inherited instance: do not use
    // TWinHttpAPI.Get() but either TWinHTTP.Get() or TWinINet.Get() methods
    class function Get(const aURI: RawByteString;
      const aHeader: RawByteString=''): RawByteString;
    /// wrapper method to create a resource via an HTTP POST
    // - will parse the supplied URI to check for the http protocol (HTTP/HTTPS),
    // server name and port, and resource name
    // - the supplied aData content is POSTed to the server, with an optional
    // aHeader content
    // - it will internally create a TWinHttpAPI inherited instance: do not use
    // TWinHttpAPI.Post() but either TWinHTTP.Post() or TWinINet.Post() methods
    class function Post(const aURI, aData: RawByteString;
      const aHeader: RawByteString=''): RawByteString;
    /// wrapper method to update a resource via an HTTP PUT
    // - will parse the supplied URI to check for the http protocol (HTTP/HTTPS),
    // server name and port, and resource name
    // - the supplied aData content is PUT to the server, with an optional
    // aHeader content
    // - it will internally create a TWinHttpAPI inherited instance: do not use
    // TWinHttpAPI.Put() but either TWinHTTP.Put() or TWinINet.Put() methods
    class function Put(const aURI, aData: RawByteString;
      const aHeader: RawByteString=''): RawByteString;
    /// wrapper method to delete a resource via an HTTP DELETE
    // - will parse the supplied URI to check for the http protocol (HTTP/HTTPS),
    // server name and port, and resource name
    // - it will internally create a TWinHttpAPI inherited instance: do not use
    // TWinHttpAPI.Delete() but either TWinHTTP.Delete() or TWinINet.Delete()
    class function Delete(const aURI: RawByteString;
      const aHeader: RawByteString=''): RawByteString;

    /// will register a compression algorithm
    // - used e.g. to compress on the fly the data, with standard gzip/deflate
    // or custom (synlzo/synlz) protocols
    // - returns true on success, false if this function or this
    // ACCEPT-ENCODING: header was already registered
    // - you can specify a minimal size (in bytes) before which the content won't
    // be compressed (1024 by default, corresponding to a MTU of 1500 bytes)
    // - the first registered algorithm will be the prefered one for compression
    function RegisterCompress(aFunction: THttpSocketCompress;
      aCompressMinSize: integer=1024): boolean;
    /// the remote server host name, as stated specified to the class constructor
    property Server: RawByteString read fServer;
    /// the remote server port number, as specified to the class constructor
    property Port: cardinal read fPort;
    /// if the remote server uses HTTPS, as specified to the class constructor
    property Https: boolean read fHttps;
    /// the remote server optional proxy, as specified to the class constructor
    property ProxyName: RawByteString read fProxyName;
    /// the remote server optional proxy by-pass list, as specified to the class
    // constructor
    property ProxyByPass: RawByteString read fProxyByPass;
  end;

  {/ a class to handle HTTP/1.1 request using the WinINet API
   - has a common behavior as THttpClientSocket()
   - The Microsoft Windows Internet (WinINet) application programming interface
     (API) enables applications to access standard Internet protocols, such as
     FTP and HTTP/HTTPS.
   - by design, the WinINet API should not be used from a service
   - note: WinINet is MUCH slower than THttpClientSocket: do not use this, only
     if you find some performance improvements on some networks }
  TWinINet = class(TWinHttpAPI)
  protected
    // those internal methods will raise an EWinINet exception on error
    procedure InternalConnect(SendTimeout,ReceiveTimeout: DWORD); override;
    procedure InternalRequest(const method, aURL: RawByteString); override;
    procedure InternalCloseRequest; override;
    procedure InternalAddHeader(const hdr: RawByteString); override;
    procedure InternalSendRequest(const aData: RawByteString); override;
    function InternalGetInfo(Info: DWORD): RawByteString; override;
    function InternalGetInfo32(Info: DWORD): DWORD; override;
    function InternalReadData(var Data: RawByteString; Read: integer): cardinal; override;
  public
    /// relase the connection
    destructor Destroy; override;
  end;

  /// WinINet exception type
  EWinINet = class(Exception)
  protected
    fCode: DWORD;
  public
    /// create a WinINet exception, with the error message as text
    constructor Create;
    /// associated Error Code, as retrieved from API
    property ErrorCode: DWORD read fCode;
  end;

  {/ a class to handle HTTP/1.1 request using the WinHTTP API
   - has a common behavior as THttpClientSocket() but seems to be faster
     over a network and is able to retrieve the current proxy settings
     (if available) and handle secure https connection - so it seems to be the
     class to use in your client programs
   - WinHTTP does not share any proxy settings with Internet Explorer.
     The WinHTTP proxy configuration is set by either
     proxycfg.exe on Windows XP and Windows Server 2003 or earlier, either
     netsh.exe on Windows Vista and Windows Server 2008 or later; for instance,
     you can run "proxycfg -u" or "netsh winhttp import proxy source=ie" to use
     the current user's proxy settings for Internet Explorer (under 64 bit
     Vista/Seven, to configure applications using the 32 bit WinHttp settings,
     call netsh or proxycfg bits from %SystemRoot%\SysWOW64 folder explicitely)
   - Microsoft Windows HTTP Services (WinHTTP) is targeted at middle-tier and
     back-end server applications that require access to an HTTP client stack }
  TWinHTTP = class(TWinHttpAPI)
  private
  protected
    // those internal methods will raise an EOSError exception on error
    procedure InternalConnect(SendTimeout,ReceiveTimeout: DWORD); override;
    procedure InternalRequest(const method, aURL: RawByteString); override;
    procedure InternalCloseRequest; override;
    procedure InternalAddHeader(const hdr: RawByteString); override;
    procedure InternalSendRequest(const aData: RawByteString); override;
    function InternalGetInfo(Info: DWORD): RawByteString; override;
    function InternalGetInfo32(Info: DWORD): DWORD; override;
    function InternalReadData(var Data: RawByteString; Read: integer): cardinal; override;
  public
    /// relase the connection
    destructor Destroy; override;
  end;

  /// type of a TWinHttpAPI class
  TWinHttpAPIClass = class of TWinHttpAPI;

  /// WinHTTP exception type
  EWinHTTP = class(Exception);

{$endif}


/// create a TCrtSocket, returning nil on error
// (useful to easily catch socket error exception ECrtSocket)
function Open(const aServer, aPort: RawByteString): TCrtSocket;

/// create a THttpClientSocket, returning nil on error
// (useful to easily catch socket error exception ECrtSocket)
function OpenHttp(const aServer, aPort: RawByteString): THttpClientSocket;

/// retrieve the content of a web page, using the HTTP/1.1 protocol and GET method
// - this method will use a low-level THttpClientSock socket: if you want
// something able to use your computer proxy, take a look at TWinINet.Get()
function HttpGet(const server, port: RawByteString; const url: RawByteString): RawByteString;

/// send some data to a remote web server, using the HTTP/1.1 protocol and POST method
function HttpPost(const server, port: RawByteString; const url, Data, DataType: RawByteString): boolean;

/// send an email using the SMTP protocol
// - retry true on success
// - the Subject is expected to be in plain 7 bit ASCII, so you could use
// SendEmailSubject() to encode it as Unicode, if needed
// - you can optionally set the encoding charset to be used for the Text body
function SendEmail(const Server, From, CSVDest, Subject, Text: RawByteString;
  const Headers: RawByteString=''; const User: RawByteString=''; const Pass: RawByteString='';
  const Port: RawByteString='25'; const TextCharSet: RawByteString = 'ISO-8859-1'): boolean;

/// convert a supplied subject text into an Unicode encoding
// - will convert the text into UTF-8 and append '=?UTF-8?B?'
// - for pre-Unicode versions of Delphi, Text is expected to be already UTF-8
// encoded - since Delphi 2010, it will be converted from UnicodeString
function SendEmailSubject(const Text: string): RawByteString;

/// retrieve the HTTP reason text from a code
// - e.g. StatusCodeToReason(200)='OK'
function StatusCodeToReason(Code: integer): RawByteString;

/// retrieve the IP adress from a computer name
function ResolveName(const Name: RawByteString): RawByteString;

/// Base64 encoding of a string
function Base64Encode(const s: RawByteString): RawByteString;

/// Base64 decoding of a string
function Base64Decode(const s: RawByteString): RawByteString;

/// escaping of HTML codes like < > & "
function HtmlEncode(const s: RawByteString): RawByteString;

{$ifdef Win32}
/// remotly get the MAC address of a computer, from its IP Address
// - only works under Win2K and later
// - return the MAC address as a 12 hexa chars ('0050C204C80A' e.g.)
function GetRemoteMacAddress(const IP: RawByteString): RawByteString;
{$endif}


implementation

{ ************ some shared helper functions and classes }

function StatusCodeToReason(Code: integer): RawByteString;
begin
  case Code of
    100: result := 'Continue';
    200: result := 'OK';
    201: result := 'Created';
    202: result := 'Accepted';
    203: result := 'Non-Authoritative Information';
    204: result := 'No Content';
    300: result := 'Multiple Choices';
    301: result := 'Moved Permanently';
    302: result := 'Found';
    303: result := 'See Other';
    304: result := 'Not Modified';
    307: result := 'Temporary Redirect';
    400: result := 'Bad Request';
    401: result := 'Unauthorized';
    403: result := 'Forbidden';
    404: result := 'Not Found';
    405: result := 'Method Not Allowed';
    406: result := 'Not Acceptable';
    500: result := 'Internal Server Error';
    503: result := 'Service Unavailable';
    else str(Code,result);
  end;
end;

function Hex2Dec(c: AnsiChar): byte;
begin
  case c of
  'A'..'Z': result := Ord(c) - (Ord('A') - 10);
  'a'..'z': result := Ord(c) - (Ord('a') - 10);
  '0'..'9': result := Ord(c) - Ord('0');
  else result := 255;
  end;
end;

// Base64 string encoding
function Base64Encode(const s: RawByteString): RawByteString;
procedure Encode(rp, sp: PAnsiChar; len: integer);
const
  b64: array[0..63] of AnsiChar =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var i: integer;
    c: cardinal;
begin
  for i := 1 to len div 3 do begin
    c := ord(sp[0]) shl 16 + ord(sp[1]) shl 8 + ord(sp[2]);
    rp[0] := b64[(c shr 18) and $3f];
    rp[1] := b64[(c shr 12) and $3f];
    rp[2] := b64[(c shr 6) and $3f];
    rp[3] := b64[c and $3f];
    inc(rp,4);
    inc(sp,3);
  end;
  case len mod 3 of
    1: begin
      c := ord(sp[0]) shl 16;
      rp[0] := b64[(c shr 18) and $3f];
      rp[1] := b64[(c shr 12) and $3f];
      rp[2] := '=';
      rp[3] := '=';
    end;
    2: begin
      c := ord(sp[0]) shl 16 + ord(sp[1]) shl 8;
      rp[0] := b64[(c shr 18) and $3f];
      rp[1] := b64[(c shr 12) and $3f];
      rp[2] := b64[(c shr 6) and $3f];
      rp[3] := '=';
    end;
  end;
end;
var len: integer;
begin
  result:='';
  len := length(s);
  if len = 0 then exit;
  SetLength(result, ((len + 2) div 3) * 4);
  Encode(pointer(result),pointer(s),len);
end;

function Base64Decode(const s: RawByteString): RawByteString;
var i, j, len: integer;
    sp, rp: PAnsiChar;
    c, ch: integer;
begin
  result:= '';
  len := length(s);
  if (len = 0) or (len mod 4 <> 0) then
    exit;
  len := len shr 2;
  SetLength(result, len * 3); 
  sp := pointer(s); 
  rp := pointer(result);
  for i := 1 to len do begin 
    c := 0; 
    j := 0; 
    while true do begin
      ch := ord(sp[j]);
      case chr(ch) of
        'A'..'Z': c := c or (ch - ord('A'));
        'a'..'z': c := c or (ch - (ord('a')-26));
        '0'..'9': c := c or (ch - (ord('0')-52));
        '+': c := c or 62;
        '/': c := c or 63;
        else
        if j=3 then begin
          rp[0] := AnsiChar(c shr 16);
          rp[1] := AnsiChar(c shr 8);
          SetLength(result, len*3-1);
          exit;
        end else begin
          rp[0] := AnsiChar(c shr 10);
          SetLength(result, len*3-2);
          exit;
        end;
      end;
      if j=3 then break;
      inc(j);
      c := c shl 6;
    end;
    rp[2] := AnsiChar(c);
    c := c shr 8;
    rp[1] := AnsiChar(c);
    c := c shr 8;
    rp[0] := AnsiChar(c);
    inc(rp,3);
    inc(sp,4);
  end;  
end;

function HtmlEncode(const s: RawByteString): RawByteString;
var i: integer;
begin // not very fast, but working
  result := '';
  for i := 1 to length(s) do
    case s[i] of
      '<': result := result+'&lt;';
      '>': result := result+'&gt;';
      '&': result := result+'&amp;';
      '"': result := result+'&quot;';
      else result := result+s[i];
    end;
end;

const
  CRLF: array[0..1] of AnsiChar = (#13,#10);

function StrLen(S: PAnsiChar): integer;
begin
  result := 0;
  if S<>nil then
  while true do
    if S[0]<>#0 then
    if S[1]<>#0 then
    if S[2]<>#0 then
    if S[3]<>#0 then begin
      inc(S,4);
      inc(result,4);
    end else begin
      inc(result,3);
      exit;
    end else begin
      inc(result,2);
      exit;
    end else begin
      inc(result);
      exit;
    end else
      exit;
end;

function IdemPChar(p, up: pAnsiChar): boolean;
// if the beginning of p^ is same as up^ (ignore case - up^ must be already Upper)
var c: AnsiChar;
begin
  result := false;
  if (p=nil) or (up=nil) then
    exit;
  while up^<>#0 do begin
    c := p^;
    if up^<>c then
      if c in ['a'..'z'] then begin
        dec(c,32);
        if up^<>c then
          exit;
      end else exit;
    inc(up);
    inc(p);
  end;
  result := true;
end;

function IdemPCharArray(p: PAnsiChar; const upArray: array of PAnsiChar): integer;
var W: word;
begin
  if p<>nil then begin
    w := ord(p[0])+ord(p[1])shl 8;
    if p[0] in ['a'..'z'] then
      dec(w,32);
    if p[1] in ['a'..'z'] then
      dec(w,32 shl 8);
    for result := 0 to high(upArray) do
      if (PWord(upArray[result])^=w) and IdemPChar(p+2,upArray[result]+2) then
        exit;
  end;
  result := -1;
end;

function GetNextItem(var P: PAnsiChar; Sep: AnsiChar = ','): RawByteString;
// return next CSV string in P, nil if no more
var S: PAnsiChar;
begin
  if P=nil then
    result := '' else begin
    S := P;
    while (S^<>#0) and (S^<>Sep) do
      inc(S);
    SetString(result,P,S-P);
    if S^<>#0 then
     P := S+1 else
     P := nil;
  end;
end;

function GetNextItemUInt64(var P: PAnsiChar): Int64;
var c: PtrUInt;
begin
  if P=nil then begin
    result := 0;
    exit;
  end;
  result := byte(P^)-48;  // caller ensured that P^ in ['0'..'9']
  inc(P);
  repeat
    c := byte(P^)-48;
    if c>9 then
      break else
      result := result*10+c;
    inc(P);
  until false;
end; // P^ will point to the first non digit char

function GetNextLine(var P: PAnsiChar): RawByteString;
var S: PAnsiChar;
begin
  if P=nil then
    result := '' else begin
    S := P;
    while S^>=' ' do
      inc(S);
    SetString(result,P,S-P);
    while (S^<>#0) and (S^<' ') do inc(S); // ignore e.g. #13 or #10
    if S^<>#0 then
      P := S else
      P := nil;
  end;
end;

function PosChar(Str: PAnsiChar; Chr: AnsiChar): PAnsiChar;
begin
  result := Str;
  while result^<>Chr do begin
    if result^=#0 then begin
      result := nil;
      exit;
    end;
    Inc(result);
  end;
end;

{$ifdef UNICODE}
// rewrite some functions to avoid unattempted ansi<->unicode conversion

function Trim(const S: RawByteString): RawByteString;
{$ifdef PUREPASCAL}
var I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I<=L) and (S[I]<=' ') do Inc(I);
  if I>L then
    Result := '' else
  if (I=1) and (S[L]>' ') then
    Result := S else begin
    while S[L]<=' ' do Dec(L);
    Result := Copy(S, I, L-I+1);
  end;
end;
{$else}
asm  // fast implementation by John O'Harrow
  test eax,eax                   {S = nil?}
  xchg eax,edx
  jz   System.@LStrClr           {Yes, Return Empty String}
  mov  ecx,[edx-4]               {Length(S)}
  cmp  byte ptr [edx],' '        {S[1] <= ' '?}
  jbe  @@TrimLeft                {Yes, Trim Leading Spaces}
  cmp  byte ptr [edx+ecx-1],' '  {S[Length(S)] <= ' '?}
  jbe  @@TrimRight               {Yes, Trim Trailing Spaces}
  jmp  System.@LStrLAsg          {No, Result := S (which occurs most time)}
@@TrimLeft:                      {Strip Leading Whitespace}
  dec  ecx
  jle  System.@LStrClr           {All Whitespace}
  inc  edx
  cmp  byte ptr [edx],' '
  jbe  @@TrimLeft
@@CheckDone:
  cmp  byte ptr [edx+ecx-1],' '
{$ifdef UNICODE}
  jbe  @@TrimRight
  push 65535 // RawByteString code page for Delphi 2009 and up
  call  System.@LStrFromPCharLen // we need a call, not a direct jmp
  ret
{$else}
  ja   System.@LStrFromPCharLen
{$endif}
@@TrimRight:                     {Strip Trailing Whitespace}
  dec  ecx
  jmp  @@CheckDone
end;
{$endif}

function UpperCase(const S: RawByteString): RawByteString;
procedure Upper(Source, Dest: PAnsiChar; L: cardinal);
var Ch: AnsiChar; // this sub-call is shorter and faster than 1 plain proc
begin
  repeat
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then
      dec(Ch, 32);
    Dest^ := Ch;
    dec(L);
    inc(Source);
    inc(Dest);
  until L=0;
end;
var L: cardinal;
begin
  result := '';
  L := Length(S);
  if L=0 then
    exit;
  SetLength(result, L);
  Upper(pointer(S),pointer(result),L);
end;

{$endif}

function GetCardinal(P: PAnsiChar): cardinal; overload;
var c: cardinal;
begin
  if P=nil then begin
    result := 0;
    exit;
  end;
  if P^=' ' then repeat inc(P) until P^<>' ';
  c := byte(P^)-48;
  if c>9 then
    result := 0 else begin
    result := c;
    inc(P);
    repeat
      c := byte(P^)-48;
      if c>9 then
        break else
        result := result*10+c;
      inc(P);
    until false;
  end;
end;

function GetCardinal(P,PEnd: PAnsiChar): cardinal; overload;
var c: cardinal;
begin
  result := 0;
  if (P=nil) or (P>=PEnd) then
    exit;
  if P^=' ' then repeat
    inc(P);
    if P=PEnd then exit;
  until P^<>' ';
  c := byte(P^)-48;
  if c>9 then
    exit;
  result := c;
  inc(P);
  while P<PEnd do begin
    c := byte(P^)-48;
    if c>9 then
      break else
      result := result*10+c;
    inc(P);
  end;
end;

function PCharToHex32(p: PAnsiChar): cardinal;
var v0,v1: byte;
begin
  result := 0;
  if p<>nil then begin
    while p^=' ' do inc(p);
    repeat
      v0 := Hex2Dec(p[0]);
      if v0=255 then break; // not in '0'..'9','a'..'f'
      v1 := Hex2Dec(p[1]);
      inc(p);
      if v1=255 then begin
        result := (result shl 4)+v0; // only one char left
        break;
      end;
      v0 := v0 shl 4;
      result := result shl 8;
      inc(v0,v1);
      inc(p);
      inc(result,v0);
    until false;
  end;
end;

{$ifndef CONDITIONALEXPRESSIONS}
function Utf8ToAnsi(const UTF8: RawByteString): RawByteString;
begin
  result := UTF8; // no conversion
end;
{$endif}

const
  ENGLISH_LANGID = $0409;
  // see http://msdn.microsoft.com/en-us/library/windows/desktop/aa383770
  ERROR_WINHTTP_CANNOT_CONNECT = 12029;
  ERROR_WINHTTP_TIMEOUT = 12002;
  ERROR_WINHTTP_INVALID_SERVER_RESPONSE = 12152;


function SysErrorMessagePerModule(Code: DWORD; ModuleName: PChar): string;
var tmpLen: DWORD;
    err: PChar;
begin
  if Code=NO_ERROR then begin
    result := '';
    exit;
  end;
  tmpLen := FormatMessage(
    FORMAT_MESSAGE_FROM_HMODULE or FORMAT_MESSAGE_ALLOCATE_BUFFER,
    pointer(GetModuleHandle(ModuleName)),Code,ENGLISH_LANGID,@err,0,nil);
  try
    while (tmpLen>0) and (ord(err[tmpLen-1]) in [0..32,ord('.')]) do
      dec(tmpLen);
    SetString(result,err,tmpLen);
  finally
    LocalFree(HLOCAL(err));
  end;
  if result='' then begin
    result := SysErrorMessage(Code);
    if result='' then
      if Code=ERROR_WINHTTP_CANNOT_CONNECT then
        result := 'cannot connect' else
      if Code=ERROR_WINHTTP_TIMEOUT then
        result := 'timeout' else
      if Code=ERROR_WINHTTP_INVALID_SERVER_RESPONSE then
        result := 'invalid server response' else
        result := IntToHex(Code,8);
  end;
end;

procedure RaiseLastModuleError(ModuleName: PChar; ModuleException: ExceptClass);
var LastError: Integer;
    Error: Exception;
begin
  LastError := GetLastError;
  if LastError<>NO_ERROR then
    Error := ModuleException.CreateFmt('%s error %d (%s)',
      [ModuleName,LastError,SysErrorMessagePerModule(LastError,ModuleName)]) else
    Error := ModuleException.CreateFmt('Undefined %s error',[ModuleName]);
  raise Error;
end;

const
  HexChars: array[0..15] of AnsiChar = '0123456789ABCDEF';

procedure BinToHexDisplay(Bin: PByte; BinBytes: integer; var result: shortstring);
var j: cardinal;
begin
  result[0] := AnsiChar(BinBytes*2);
  for j := BinBytes-1 downto 0 do begin
    result[j*2+1] := HexChars[Bin^ shr 4];
    result[j*2+2] := HexChars[Bin^ and $F];
    inc(Bin);
  end;
end;

function BinToHexDisplayW(Bin: PByte; BinBytes: integer): RawByteString;
var j: cardinal;
    P: PAnsiChar;
begin
  SetString(Result,nil,BinBytes*4+1);
  P := pointer(Result);
  for j := BinBytes-1 downto 0 do begin
    P[j*4] := HexChars[Bin^ shr 4];
    P[j*4+1] := #0;
    P[j*4+2] := HexChars[Bin^ and $F];
    P[j*4+3] := #0;
    inc(Bin);
  end;
  P[BinBytes*4] := #0;
end;

function Ansi7ToUnicode(const Ansi: RawByteString): RawByteString;
var n, i: integer;
begin  // fast ANSI 7 bit conversion
  if Ansi='' then
    result := '' else begin
    n := length(Ansi);
    SetLength(result,n*2+1);
    for i := 0 to n do // to n = including last #0
      PWordArray(pointer(result))^[i] := PByteArray(pointer(Ansi))^[i];
  end;
end;

function DefaultUserAgent(Instance: TObject): RawByteString;
const
  DEFAULT_AGENT = 'Mozilla/4.0 (compatible; MSIE 5.5; Windows; Synopse mORMot '+
    SYNOPSE_FRAMEWORK_VERSION+' ';
begin
  result := DEFAULT_AGENT+RawByteString(Instance.ClassName)+')';
end;

/// decode 'CONTENT-ENCODING: ' parameter from registered compression list
function ComputeContentEncoding(const Compress: THttpSocketCompressRecDynArray;
  P: PAnsiChar): THttpSocketCompressSet;
var i: integer;
    aName: RawByteString;
    Beg: PAnsiChar;
begin
  integer(result) := 0;
  if P<>nil then
    repeat
      while P^ in [' ',','] do inc(P);
      Beg := P; // 'gzip;q=1.0, deflate' -> aName='gzip' then 'deflate'
      while not (P^ in [';',',',#0]) do inc(P);
      SetString(aName,Beg,P-Beg);
      for i := 0 to high(Compress) do
        if aName=Compress[i].Name then
          include(result,i);
      while not (P^ in [',',#0]) do inc(P);
    until P^=#0;
end;

function RegisterCompressFunc(var Compress: THttpSocketCompressRecDynArray;
  aFunction: THttpSocketCompress; var aAcceptEncoding: RawByteString;
  aCompressMinSize: integer): RawByteString;
var i, n: integer;
    dummy, aName: RawByteString;
begin
  result := '';
  if @aFunction=nil then
    exit;
  n := length(Compress);
  aName := aFunction(dummy,true);
  for i := 0 to n-1 do
    with Compress[i] do
      if Name=aName then begin // already set
        if @Func=@aFunction then // update min. compress size value
          CompressMinSize := aCompressMinSize;
        exit;
      end;
  if n=sizeof(integer)*8 then
    exit; // fCompressHeader is 0..31 (casted as integer)
  SetLength(Compress,n+1);
  with Compress[n] do begin
    Name := aName;
    {$ifdef FPC}
    Func := aFunction;
    {$else}
    @Func := @aFunction;
    {$endif}
    CompressMinSize := aCompressMinSize;
  end;
  if aAcceptEncoding='' then
    aAcceptEncoding := 'Accept-Encoding: '+aName else
    aAcceptEncoding := aAcceptEncoding+','+aName;
  result := aName;
end;

function CompressDataAndGetHeaders(Accepted: THttpSocketCompressSet;
  var Handled: THttpSocketCompressRecDynArray; const OutContentType: RawByteString;
  var OutContent: RawByteString): RawByteString;
var i, OutContentLen: integer;
    OutContentIsText: boolean;
    OutContentTypeP: PAnsiChar absolute OutContentType;
begin
  if (integer(Accepted)<>0) and (OutContentType<>'') and (Handled<>nil) then begin
    OutContentLen := length(OutContent);
    OutContentIsText := IdemPChar(OutContentTypeP,'TEXT/') or
                      ((IdemPChar(OutContentTypeP,'APPLICATION/') and
                                (IdemPChar(OutContentTypeP+12,'JSON') or
                                 IdemPChar(OutContentTypeP+12,'XML'))));
    for i := 0 to high(Handled) do
    if i in Accepted then
    with Handled[i] do
    if (CompressMinSize=0) or // 0 here means "always" (e.g. for encryption)
       (OutContentIsText and (OutContentLen>=CompressMinSize)) then begin
      // compression of the OutContent + update header
      result := Func(OutContent,true);
      exit; // first in fCompress[] is prefered
    end;
  end;
  result := '';
end;

{$ifdef Win32}
function GetRemoteMacAddress(const IP: RawByteString): RawByteString;
// implements http://msdn.microsoft.com/en-us/library/aa366358
type
  TSendARP = function(DestIp: DWORD; srcIP: DWORD; pMacAddr: pointer; PhyAddrLen: Pointer): DWORD; stdcall;
var dwRemoteIP: DWORD;
    PhyAddrLen: Longword;
    pMacAddr: array [0..7] of byte;
    I: integer;
    P: PAnsiChar;
    SendARPLibHandle: THandle;
    SendARP: TSendARP;
begin
  result := '';
  SendARPLibHandle := LoadLibrary('iphlpapi.dll');
  if SendARPLibHandle<>0 then
  try
    SendARP := TSendARP(GetProcAddress(SendARPLibHandle,'SendARP'));
    if @SendARP=nil then
      exit; // we are not under 2K or later
    dwremoteIP := inet_addr(pointer(IP));
    if dwremoteIP<>0 then begin
      PhyAddrLen := 8;
      if SendARP(dwremoteIP, 0, @pMacAddr, @PhyAddrLen)=NO_ERROR then begin
        if PhyAddrLen=6 then begin
          SetLength(result,12);
          P := pointer(result);
          for i := 0 to 5 do begin
            P[0] := HexChars[pMacAddr[i] shr 4];
            P[1] := HexChars[pMacAddr[i] and $F];
            inc(P,2);
          end;
        end;
      end;
    end;
  finally
    FreeLibrary(SendARPLibHandle);
  end;
end;
{$endif}


const
  XPOWEREDNAME = 'X-Powered-By';
  XPOWEREDVALUE = XPOWEREDPROGRAM+' http://synopse.info';


{ THttpServerRequest }

constructor THttpServerRequest.Create(aServer: THttpServerGeneric; aCallingThread: TNotifiedThread);
begin
  inherited Create;
  fServer := aServer;
  fCallingThread := aCallingThread;
end;

procedure THttpServerRequest.Prepare(const aURL, aMethod, aInHeaders, aInContent, aInContentType: RawByteString);
begin
  fURL := aURL;
  fMethod := aMethod;
  fInHeaders := aInHeaders;
  fInContent := aInContent;
  fInContentType := aInContentType;
  fOutContent := '';
  fOutContentType := '';
  fOutCustomHeaders := '';
end;


{ THttpServerGeneric }

procedure THttpServerGeneric.RegisterCompress(aFunction: THttpSocketCompress;
  aCompressMinSize: integer=1024);
begin
  RegisterCompressFunc(fCompress,aFunction,fCompressAcceptEncoding,aCompressMinSize);
end;

function THttpServerGeneric.Request(Ctxt: THttpServerRequest): cardinal;
begin
  NotifyThreadStart(Ctxt.CallingThread);
  if Assigned(OnRequest) then
    result := OnRequest(Ctxt) else
    result := 404; // 404 NOT FOUND
end;

procedure THttpServerGeneric.NotifyThreadStart(Sender: TNotifiedThread);
begin
  if Sender=nil then
    raise ECrtSocket.Create('NotifyThreadStart(nil)');
  if Assigned(fOnHttpThreadStart) and not Assigned(Sender.fNotified) then begin
    fOnHttpThreadStart(Sender);
    Sender.fNotified := self;
  end;
end;


{ TURI }

const
  DEFAULT_PORT: array[boolean] of RawByteString = ('80','443');

function TURI.From(aURI: RawByteString): boolean;
var P: PAnsiChar;
begin
  Https := false;
  Finalize(self);
  result := false;
  aURI := Trim(aURI);
  if aURI='' then
    exit;
  P := pointer(aURI);
  if IdemPChar(P,'HTTP://') then
    inc(P,7) else
  if IdemPChar(P,'HTTPS://') then begin
    inc(P,8);
    Https := true;
  end;
  if PosChar(P,':')<>nil then begin
    Server := GetNextItem(P,':');
    Port := GetNextItem(P,'/');
  end else begin
    Server := GetNextItem(P,'/');
    Port := DEFAULT_PORT[Https];
  end;
  Address := P;
  if Server<>'' then
    result := true;
end;


{ ************ WinSock API access - TCrtSocket and THttp*Socket }

function ResolveName(const Name: RawByteString): RawByteString;
var l: TStringList;
begin
  l := TStringList.Create;
  try
    // use AF_INET+PF_INET instead of AF_UNSPEC+PF_UNSPEC: IP6 is buggy!
    ResolveNameToIP(Name, AF_INET, PF_INET, SOCK_STREAM, l);
    if l.Count=0 then
      result := Name else
      result := RawByteString(l[0]);
  finally
    l.Free;
  end;
end;

function CallServer(const Server, Port: RawByteString; doBind: boolean;
   aLayer: TCrtSocketLayer): TSocket;
var Sin: TVarSin;
    IP: RawByteString;
    li: TLinger;
    SOCK_TYPE, IPPROTO: integer;
{$ifdef LINUX}
    serveraddr: sockaddr;
{$endif}
begin
  result := -1;
  case aLayer of
    cslTCP: begin
      SOCK_TYPE := SOCK_STREAM;
      IPPROTO := IPPROTO_TCP;
    end;
    cslUDP: begin
      SOCK_TYPE := SOCK_DGRAM;
      IPPROTO := IPPROTO_UDP;
    end;
    cslUNIX: begin
{$ifndef LINUX}
      exit; // not handled under Win32
{$else} // special version for UNIX sockets
      result := socket(AF_UNIX,SOCK_STREAM,0);
      if result<0 then
        exit;
      if doBind then begin
        fillchar(serveraddr,sizeof(serveraddr),0);
http://publib.boulder.ibm.com/infocenter/iseries/v5r3/index.jsp?topic=/rzab6/rzab6uafunix.htm
        serveraddr.
        if (bind(result,@serveraddr,sizeof(serveraddr))<0) or
           (listen(result,SOMAXCONN)<0) then begin
          close(sd);
          result := -1;
        end;
      end;
      exit;
{$endif}
    end;
    else exit; // make this stupid compiler happy
  end;
  IP := ResolveName(Server);
  // use AF_INET+PF_INET instead of AF_UNSPEC+PF_UNSPEC: IP6 is buggy!
  if SetVarSin(Sin, IP, Port, AF_INET, PF_INET, SOCK_TYPE, true)<>0 then
    exit;
  result := Socket(integer(Sin.AddressFamily), SOCK_TYPE, IPPROTO);
  if result=-1 then
    exit;
  if doBind then begin
    // Socket should remain open for 5 seconds after a closesocket() call
    li.l_onoff := Ord(true);
    li.l_linger := 5;
    SetSockOpt(result, SOL_SOCKET, SO_LINGER, @li, SizeOf(li));
    // bind and listen to this port
    if (Bind(result, Sin)<>0) or
       ((aLayer<>cslUDP) and (Listen(result, SOMAXCONN)<>0)) then begin
      CloseSocket(result);
      result := -1;
    end;
  end else
  if Connect(result,Sin)<>0 then begin
     CloseSocket(result);
     result := -1;
  end;
end;

function OutputSock(var F: TTextRec): integer;
var Index, Size: integer;
    Sock: TCRTSocket;
begin
  if F.BufPos<>0 then begin
    result := -1; // on socket error -> raise ioresult error
    Sock := TCrtSocket(F.Handle);
    if (Sock=nil) or (Sock.Sock=-1) then
      exit; // file closed
    Index := 0;
    repeat
      Size := Send(Sock.Sock, @F.BufPtr[Index], F.BufPos, 0);
      if Size<=0 then
        exit;
      inc(Sock.BytesOut, Size);
      dec(F.BufPos,Size);
      inc(Index,Size);
    until F.BufPos=0;
  end;
  result := 0; // no error
end;

function InputSock(var F: TTextRec): Integer;
// SockIn pseudo text file fill its internal buffer only with available data
// -> no unwanted wait time is added
// -> very optimized use for readln() in HTTP stream
var Size: integer;
    Sock: TCRTSocket;
begin
  F.BufEnd := 0;
  F.BufPos := 0;
  result := -1; // on socket error -> raise ioresult error
  Sock := TCrtSocket(F.Handle);
  if (Sock=nil) or (Sock.Sock=-1) then
    exit; // file closed = no socket -> error
  if Sock.TimeOut<>0 then begin // will wait for pending data?
    IOCtlSocket(Sock.Sock, FIONREAD, Size); // get exact count
    if (Size<=0) or (Size>integer(F.BufSize)) then
      Size := F.BufSize;
  end else
    Size := F.BufSize;
  Size := Recv(Sock.Sock, F.BufPtr, Size, 0);
  // Recv() may return Size=0 if no data is pending, but no TCP/IP error
  if Size>=0 then begin
    F.BufEnd := Size;
    inc(Sock.BytesIn, Size);
    result := 0; // no error
  end else begin
    Sock.SockInEof := true; // error -> mark end of SockIn
    result := -WSAGetLastError();
    // result <0 will update ioresult and raise an exception if {$I+}
  end;
end;

function CloseSock(var F: TTextRec): integer;
var Sock: TCRTSocket;
begin
  Sock := TCrtSocket(F.Handle);
  if Sock<>nil then
    Sock.Close;
  F.Handle := 0; // Sock := nil
  Result := 0;
end;

function OpenSock(var F: TTextRec): integer;
begin
  F.BufPos := 0;
  F.BufEnd := 0;
  if F.Mode=fmInput then begin // ReadLn
    F.InOutFunc := @InputSock;
    F.FlushFunc := nil;
  end else begin               // WriteLn
    F.Mode := fmOutput;
    F.InOutFunc := @OutputSock;
    F.FlushFunc := @OutputSock;
  end;
  F.CloseFunc := @CloseSock;
  Result := 0;
end;


{ TCrtSocket }

constructor TCrtSocket.Bind(const aPort: RawByteString; aLayer: TCrtSocketLayer=cslTCP);
begin
  Create(5000); // default bind timeout is 5 seconds
  OpenBind('0.0.0.0',aPort,true,-1,aLayer); // raise an ECrtSocket exception on error
end;

constructor TCrtSocket.Open(const aServer, aPort: RawByteString; aLayer: TCrtSocketLayer;
  aTimeOut: cardinal);
begin
  Create(aTimeOut); // default read timeout is 10 seconds
  OpenBind(aServer,aPort,false,-1,aLayer); // raise an ECrtSocket exception on error
end;

procedure TCrtSocket.Close;
begin
  if (SockIn<>nil) or (SockOut<>nil) then begin
    ioresult; // reset ioresult value if SockIn/SockOut were used
    if SockIn<>nil then begin
      TTextRec(SockIn^).BufPos := 0;  // reset input buffer
      TTextRec(SockIn^).BufEnd := 0;
    end;
    if SockOut<>nil then begin
      TTextRec(SockOut^).BufPos := 0; // reset output buffer
      TTextRec(SockOut^).BufEnd := 0;
    end;
  end;
  if Sock=-1 then
    exit; // no opened connection to close
  Shutdown(Sock,1);
  CloseSocket(Sock);
  Sock := -1; // don't change Server or Port, since may try to reconnect
end;

constructor TCrtSocket.Create(aTimeOut: cardinal);
begin
  TimeOut := aTimeOut;
end;

procedure TCrtSocket.SetInt32OptionByIndex(OptName, OptVal: integer);
begin
  if (self=nil) or (Sock<=0) then
    raise ECrtSocket.CreateFmt('Unexpected SetOption(%d,%d)',[OptName,OptVal]);
  if SetSockOpt(Sock,SOL_SOCKET,OptName,PAnsiChar(@OptVal),sizeof(OptVal))<>0 then
    raise ECrtSocket.CreateFmt('Error %d for SetOption(%d,%d)',
      [WSAGetLastError,OptName,OptVal]);
end;
  
procedure TCrtSocket.OpenBind(const aServer, aPort: RawByteString;
  doBind: boolean; aSock: integer=-1; aLayer: TCrtSocketLayer=cslTCP);
const BINDTXT: array[boolean] of string = ('open','bind');
begin
  if aPort='' then
    Port := '80' else // default port is 80 (HTTP)
    Port := aPort;
  if aSock<0 then
    Sock := CallServer(aServer,Port,doBind,aLayer) else // OPEN or BIND
    Sock := aSock; // ACCEPT mode -> socket is already created by caller
  if Sock=-1 then
    raise ECrtSocket.CreateFmt('Socket %s creation error on %s:%s (%d)',
      [BINDTXT[doBind],aServer,Port,WSAGetLastError]);
  Server := aServer;
  if (aSock<0) and (TimeOut>0) then begin // set timeout in OPEN/BIND modes
    ReceiveTimeout := TimeOut;
    SendTimeout := TimeOut;
  end;
end;

procedure TCrtSocket.SockSend(const Values: array of const);
var i: integer;
    tmp: shortstring;
begin
  for i := 0 to high(Values) do
  with Values[i] do
  case VType of
    vtString:     Snd(@VString^[1], pByte(VString)^);
    vtAnsiString: Snd(VAnsiString, length(RawByteString(VAnsiString)));
{$ifdef UNICODE}
    vtUnicodeString: begin
      tmp := shortstring(UnicodeString(VUnicodeString)); // convert into ansi (max length 255)
      Snd(@tmp[1],length(tmp));
    end;
{$endif}
    vtPChar:      Snd(VPChar, StrLen(VPChar));
    vtChar:       Snd(@VChar, 1);
    vtWideChar:   Snd(@VWideChar,1); // only ansi part of the character
    vtInteger:    begin
      Str(VInteger,tmp);
      Snd(@tmp[1],length(tmp));
    end;
  end;
  Snd(@CRLF, 2);
end;

procedure TCrtSocket.SockSend(const Line: RawByteString);
begin
  if Line<>'' then
    Snd(pointer(Line),length(Line));
  Snd(@CRLF, 2);
end;

procedure TCrtSocket.SockSendFlush;
begin
  if SndBufLen=0 then
    exit;
  SndLow(pointer(SndBuf), SndBufLen);
  SndBufLen := 0;
end;

procedure TCrtSocket.SndLow(P: pointer; Len: integer);
begin
  if not TrySndLow(P,Len) then
    raise ECrtSocket.Create('SndLow');
end;

function TCrtSocket.TrySndLow(P: pointer; Len: integer): boolean;
var SentLen: integer;
begin
  result := false;
  if (self=nil) or (Len<0) or (P=nil) then
    exit;
  repeat
    SentLen := Send(Sock, P, Len, 0);
    if SentLen<0 then
      exit;
    dec(Len,SentLen);
    inc(BytesOut,SentLen);
    if Len<=0 then break;
    inc(PtrUInt(P),SentLen);
  until false;
  result := true;
end;

procedure TCrtSocket.Write(const Data: RawByteString);
begin
  SndLow(pointer(Data),length(Data));
end;

function TCrtSocket.SockInRead(Content: PAnsiChar; Length: integer): integer;
// read Length bytes from SockIn^ buffer + Sock if necessary
begin
  // get data from SockIn buffer, if any (faster than ReadChar)
  if SockIn<>nil then
    with TTextRec(SockIn^) do begin
      result := BufEnd-BufPos;
      if result>0 then begin
        if result>Length then
          result := Length;
        move(BufPtr[BufPos],Content^,result);
        inc(BufPos,result);
        inc(Content,result);
        dec(Length,result);
      end;
    end else
      result := 0;
  // direct receiving of the triming bytes from socket
  if Length>0 then begin
    SockRecv(Content,Length);
    inc(result,Length);
  end;
end;

destructor TCrtSocket.Destroy;
begin
  Close;
  if SockIn<>nil then
    Freemem(SockIn);
  if SockOut<>nil then
    Freemem(SockOut);
  inherited;
end;

procedure TCrtSocket.Snd(P: pointer; Len: integer);
begin
  if Len<=0 then
    exit;
  if PByte(SndBuf)=nil then
    if Len<2048 then // 2048 is about FASTMM4 small block size
      SetLength(SndBuf,2048) else
      SetLength(SndBuf,Len) else
    if Len+SndBufLen>pInteger(PAnsiChar(pointer(SndBuf))-4)^ then
      SetLength(SndBuf,pInteger(PAnsiChar(pointer(SndBuf))-4)^+Len+2048);
  move(P^,PAnsiChar(pointer(SndBuf))[SndBufLen],Len);
  inc(SndBufLen,Len);
end;

const
  SOCKBUFSIZE = 1024; // big enough for headers (content will be read directly)

procedure TCrtSocket.CreateSockIn(LineBreak: TTextLineBreakStyle);
begin
  if (Self=nil) or (SockIn<>nil) then
    exit; // initialization already occured
  GetMem(SockIn,sizeof(TTextRec)+SOCKBUFSIZE);
  fillchar(SockIn^,sizeof(TTextRec),0);
  with TTextRec(SockIn^) do begin
    Handle := PtrInt(self);
    Mode := fmClosed;
    BufSize := SOCKBUFSIZE;
    BufPtr := pointer(PAnsiChar(SockIn)+sizeof(TTextRec)); // ignore Buffer[] (Delphi 2009+)
    OpenFunc := @OpenSock;
  end;
{$ifdef CONDITIONALEXPRESSIONS}
  SetLineBreakStyle(SockIn^,LineBreak); // http does break lines with #13#10
{$endif}
  Reset(SockIn^);
end;

procedure TCrtSocket.CreateSockOut;
begin
  if SockOut<>nil then
    exit; // initialization already occured
  GetMem(SockOut,sizeof(TTextRec)+SOCKBUFSIZE);
  fillchar(SockOut^,sizeof(TTextRec),0);
  with TTextRec(SockOut^) do begin
    Handle := PtrInt(self);
    Mode := fmClosed;
    BufSize := SOCKBUFSIZE;
    BufPtr := pointer(PAnsiChar(SockIn)+sizeof(TTextRec)); // ignore Buffer[] (Delphi 2009+)
    OpenFunc := @OpenSock;
  end;
{$ifdef CONDITIONALEXPRESSIONS}
  SetLineBreakStyle(SockOut^,tlbsCRLF);
{$endif}
  Rewrite(SockOut^);
end;

procedure TCrtSocket.SockRecv(Buffer: pointer; Length: integer);
begin
  if not TrySockRecv(Buffer,Length) then
    raise ECrtSocket.Create('SockRecv');
end;

function TCrtSocket.TrySockRecv(Buffer: pointer; Length: integer): boolean;
var Size: PtrInt;
begin
  result := false;
  if self=nil then
    exit;
  if (Buffer<>nil) and (Length>0) then
    repeat
      Size := Recv(Sock, Buffer, Length, 0);
      if Size<=0 then
        exit;
      inc(BytesIn, Size);
      dec(Length,Size);
      inc(PByte(Buffer),Size);
    until Length=0;
  result := true;
end;

procedure TCrtSocket.SockRecvLn(out Line: RawByteString; CROnly: boolean=false);
procedure RecvLn(var Line: RawByteString);
var P: PAnsiChar;
    LP, L: PtrInt;
    tmp: array[0..1023] of AnsiChar; // avoid ReallocMem() every char
begin
  P := @tmp;
  Line := '';
  repeat
    SockRecv(P,1); // this is very slow under Windows -> use SockIn^ instead
    if P^<>#13 then // at least NCSA 1.3 does send a #10 only -> ignore #13
      if P^=#10 then begin
        if Line='' then // get line
          SetString(Line,tmp,P-tmp) else begin
          LP := P-tmp; // append to already read chars
          L := length(Line);
          Setlength(Line,L+LP);
          move(tmp,(PAnsiChar(pointer(Line))+L)^,LP);
        end;
        exit;
      end else
      if P=@tmp[1023] then begin // tmp[] buffer full?
        L := length(Line); // -> append to already read chars
        Setlength(Line,L+1024);
        move(tmp,(PAnsiChar(pointer(Line))+L)^,1024);
        P := tmp;
      end else
        inc(P);
  until false;
end;
var c: AnsiChar;
   Error: integer;
begin
  if CROnly then begin // slow but accurate version which expect #13 as line end
    // SockIn^ expect either #10, either #13#10 -> a dedicated version is needed
    repeat
      SockRecv(@c,1); // this is slow but works
      if c in [#0,#13] then
        exit; // end of line
      Line := Line+c; // will do the work anyway
    until false;
  end else
  if SockIn<>nil then begin
    {$I-}
    readln(SockIn^,Line); // example: HTTP/1.0 200 OK
    Error := ioresult;
    if Error<>0 then
      raise ECrtSocket.Create('SockRecvLn',Error);
    {$I+}
  end else
    RecvLn(Line); // slow under Windows -> use SockIn^ instead
end;

procedure TCrtSocket.SockRecvLn;
var c: AnsiChar;
    Error: integer;
begin
  if SockIn<>nil then begin
    {$I-}
    readln(SockIn^);
    Error := ioresult;
    if Error<>0 then
      raise ECrtSocket.Create('SockRecvLn',Error);
    {$I+}
  end else
    repeat
      SockRecv(@c,1);
    until c=#10;
end;

function TCrtSocket.SockConnected: boolean;
var Sin: TVarSin;
begin
  result := GetPeerName(Sock,Sin)=0;
end;

function TCrtSocket.SockReceiveString: RawByteString;
var Size, L, Read: integer;
begin
  result := '';
  if self=nil then
    exit;
  L := 0;
  repeat
    Sleep(0);
    if IOCtlSocket(Sock, FIONREAD, Size)<>0 then // get exact count
      exit;
    if Size=0 then // connection broken
      if result='' then begin // wait till something
        Sleep(10); // 10 ms delay in infinite loop
        continue;
      end else
        break;
    SetLength(result,L+Size); // append to result
    Read := recv(Sock,PAnsiChar(pointer(result))+L,Size,0);
    inc(L,Read);
    if Read<Size then
      SetLength(result,L); // e.g. Read=0 may happen
  until false;
end;


{ THttpClientSocket }

constructor THttpClientSocket.Create(aTimeOut: cardinal);
begin
  inherited Create(aTimeOut);
  UserAgent := DefaultUserAgent(self);
end;

function THttpClientSocket.Delete(const url: RawByteString; KeepAlive: cardinal;
  const header: RawByteString): integer;
begin
  result := Request(url,'DELETE',KeepAlive,header,'','',false);
end;

function THttpClientSocket.Get(const url: RawByteString; KeepAlive: cardinal=0; const header: RawByteString=''): integer;
begin
  result := Request(url,'GET',KeepAlive,header,'','',false);
end;

function THttpClientSocket.Head(const url: RawByteString; KeepAlive: cardinal;
  const header: RawByteString): integer;
begin
  result := Request(url,'HEAD',KeepAlive,header,'','',false);
end;

function THttpClientSocket.Post(const url, Data, DataType: RawByteString; KeepAlive: cardinal;
  const header: RawByteString): integer;
begin
  result := Request(url,'POST',KeepAlive,header,Data,DataType,false);
end;

function THttpClientSocket.Put(const url, Data, DataType: RawByteString;
  KeepAlive: cardinal; const header: RawByteString): integer;
begin
  result := Request(url,'PUT',KeepAlive,header,Data,DataType,false);
end;

function THttpClientSocket.Request(const url, method: RawByteString;
  KeepAlive: cardinal; const Header, Data, DataType: RawByteString; retry: boolean): integer;
procedure DoRetry(Error: integer);
begin
  if retry then // retry once -> return error if already retried
    result := Error else begin
    Close; // close this connection
    try
      OpenBind(Server,Port,false); // then retry this request with a new socket
      result := Request(url,method,KeepAlive,Header,Data,DataType,true);
    except
      on Exception do
        result := Error;
    end;
  end;
end;
var P: PAnsiChar;
    aURL, aData: RawByteString;
begin
  if SockIn=nil then // done once
    CreateSockIn; // use SockIn by default if not already initialized: 2x faster
  Content := '';
  {$ifdef DEBUG2}system.write(#13#10,method,' ',url);
  if Retry then system.Write(' RETRY');{$endif}
  if Sock=-1 then
    DoRetry(404) else // socket closed (e.g. KeepAlive=0) -> reconnect
  try
  try
{$ifdef DEBUG23}system.write(' Send');{$endif}
    // send request - we use SockSend because writeln() is calling flush()
    // -> all header will be sent at once
    if TCPPrefix<>'' then
      SockSend(TCPPrefix);
    if (url='') or (url[1]<>'/') then
      aURL := '/'+url else // need valid url according to the HTTP/1.1 RFC
      aURL := url;
{$ifdef DEBUGAPI}  writeln('? ',method,' ',aurl); {$endif}
    if Port='80' then
      SockSend([method, ' ', aURL, ' HTTP/1.1'#13#10+
        'Host: ', Server, #13#10'Accept: */*']) else
      SockSend([method, ' ', aURL, ' HTTP/1.1'#13#10+
        'Host: ', Server, ':', Port, #13#10'Accept: */*']);
    SockSend(['User-Agent: ',UserAgent]);
    aData := Data; // need var for Data to be eventually compressed
    CompressDataAndWriteHeaders(DataType,aData);
    if KeepAlive>0 then
      SockSend(['Keep-Alive: ',KeepAlive,#13#10'Connection: Keep-Alive']) else
      SockSend('Connection: Close');
    if header<>'' then
      SockSend(header);
    if fCompressAcceptEncoding<>'' then
      SockSend(fCompressAcceptEncoding);
    SockSend; // send CRLF
    {$ifdef DEBUG23} SndBuf[SndBufLen+1] := #0;
      system.Writeln(#13#10'HeaderOut ',PAnsiChar(SndBuf));{$endif}
    SockSendFlush; // flush all pending data (i.e. headers) to network
    if aData<>'' then // for POST and PUT methods: content to be sent
      SndLow(pointer(aData),length(aData)); // no CRLF at the end of data
{$ifdef DEBUG23}system.write('OK ');{$endif}
    // get headers
    SockRecvLn(Command); // will raise ECrtSocket on any error
    if TCPPrefix<>'' then
      if Command<>TCPPrefix then begin
        result :=  505;
        exit;
      end else
      SockRecvLn(Command);
{$ifdef DEBUG23}system.write(Command);{$endif}
    P := pointer(Command);
    if IdemPChar(P,'HTTP/1.') then begin
      result := GetCardinal(P+9); // get http numeric status code
      if result=0 then begin
        result :=  505;
        exit;
      end;
      while result=100 do begin
        repeat // 100 CONTINUE will just be ignored client side
          SockRecvLn(Command);
          P := pointer(Command);
        until IdemPChar(P,'HTTP/1.');  // ignore up to next command
        result := GetCardinal(P+9);
      end;
      if P[7]='0' then
        KeepAlive := 0; // HTTP/1.0 -> force connection close
    end else begin // error on reading answer
      DoRetry(505); // 505=wrong format
      exit;
    end;
    GetHeader; // read all other headers
{$ifdef DEBUG23}system.write('OK Body');{$endif}
    if not IdemPChar(pointer(method),'HEAD') then
      GetBody; // get content if necessary (not HEAD method)
{$ifdef DEBUGAPI}writeln('? ',Command,' ContentLength=',length(Content));
    if result<>200 then writeln('? ',Content,#13#10,HeaderGetText); {$endif}
  except
    on Exception do
      DoRetry(404);
  end;
  finally
    if KeepAlive=0 then
      Close;
  end;
end;

function Open(const aServer, aPort: RawByteString): TCrtSocket;
begin
  try
    result := TCrtSocket.Open(aServer,aPort);
  except
    on ECrtSocket do
      result := nil;
  end;
end;

function OpenHttp(const aServer, aPort: RawByteString): THttpClientSocket;
begin
  try
    result := THttpClientSocket.Open(aServer,aPort);
  except
    on ECrtSocket do
      result := nil;
  end;
end;

function HttpGet(const server, port: RawByteString; const url: RawByteString): RawByteString;
var Http: THttpClientSocket;
begin
  result := '';
  Http := OpenHttp(server,port);
  if Http<>nil then
  try
    if Http.Get(url)=200 then
      result := Http.Content;
  finally
    Http.Free;
  end;
end;

function HttpPost(const server, port: RawByteString; const url, Data, DataType: RawByteString): boolean;
var Http: THttpClientSocket;
begin
  result := false;
  Http := OpenHttp(server,port);
  if Http<>nil then
  try
    result := Http.Post(url,Data,DataType) in [200,201,204];
  finally
    Http.Free;
  end;
end;

function SendEmail(const Server, From, CSVDest, Subject, Text, Headers,
  User, Pass, Port, TextCharSet: RawByteString): boolean;
var TCP: TCrtSocket;
procedure Expect(const Answer: RawByteString);
var Res: RawByteString;
begin
  repeat
    readln(TCP.SockIn^,Res);
  until (Length(Res)<4)or(Res[4]<>'-');
  if not IdemPChar(pointer(Res),pointer(Answer)) then
    raise Exception.Create(string(Res));
end;
procedure Exec(const Command, Answer: RawByteString);
begin
  writeln(TCP.SockOut^,Command);
  Expect(Answer)
end;
var P: PAnsiChar;
    rec, ToList: RawByteString;
begin
  result := false;
  P := pointer(CSVDest);
  if P=nil then exit;
  TCP := Open(Server, Port);
  if TCP<>nil then
  try
    TCP.CreateSockIn; // we use SockIn and SockOut here
    TCP.CreateSockOut;
    Expect('220');
    if (User<>'') and (Pass<>'') then begin
      Exec('EHLO '+Server,'25');
      Exec('AUTH LOGIN','334');
      Exec(Base64Encode(User),'334');
      Exec(Base64Encode(Pass),'235');
    end else
      Exec('HELO '+Server,'25');
    writeln(TCP.SockOut^,'MAIL FROM:<',From,'>'); Expect('250');
    ToList := 'To: ';
    repeat
      rec := trim(GetNextItem(P));
      if rec='' then continue;
      if pos(RawByteString('<'),rec)=0 then
        rec := '<'+rec+'>';
      Exec('RCPT TO:'+rec,'25');
      ToList := ToList+rec+', ';
    until P=nil;
    Exec('DATA','354');
    writeln(TCP.SockOut^,'Subject: ',Subject,#13#10,
      ToList,#13#10'Content-Type: text/plain; charset=',TextCharSet,
      #13#10'Content-Transfer-Encoding: 8bit'#13#10,
      Headers,#13#10#13#10,Text);
    Exec('.','25');
    writeln(TCP.SockOut^,'QUIT');
    result := true;
  finally
    TCP.Free;
  end;
end;

function SendEmailSubject(const Text: string): RawByteString;
var utf8: UTF8String;
begin
  utf8 := UTF8String(Text);
  result := '=?UTF-8?B?'+Base64Encode(utf8);
end;


var
  WsaDataOnce: TWSADATA;

{ THttpServer }

constructor THttpServer.Create(const aPort: RawByteString
      {$ifdef USETHREADPOOL}; ServerThreadPoolCount: integer=32{$endif});
var aSock: TCrtSocket;
begin
  InitializeCriticalSection(fProcessCS);
  aSock := TCrtSocket.Bind(aPort); // BIND + LISTEN
  inherited Create(false);
  Sock := aSock;
  ServerKeepAliveTimeOut := 3000; // HTTP.1/1 KeepAlive is 3 seconds by default
  fInternalHttpServerRespList := TList.Create;
{$ifdef USETHREADPOOL}
  fThreadPool := TSynThreadPoolTHttpServer.Create(self,ServerThreadPoolCount);
{$endif}
end;

function THttpServer.GetAPIVersion: string;
begin
  result := Format('%s.%d',[WsaDataOnce.szDescription,WsaDataOnce.wVersion]);
end;

destructor THttpServer.Destroy;
var StartTick, StopTick: Cardinal;
begin
  Terminate; // set Terminated := true for THttpServerResp.Execute
  StartTick := GetTickCount;
  StopTick := StartTick+20000;
  EnterCriticalSection(fProcessCS);
  if fInternalHttpServerRespList<>nil then begin
    repeat // wait for all THttpServerResp.Execute to be finished
      if fInternalHttpServerRespList.Count=0 then
        break;
      LeaveCriticalSection(fProcessCS);
      sleep(100);
      EnterCriticalSection(fProcessCS);
    until (GetTickCount>StopTick) or (GetTickCount<StartTick);
    FreeAndNil(fInternalHttpServerRespList);
  end;
  LeaveCriticalSection(fProcessCS);
{$ifdef USETHREADPOOL}
  FreeAndNil(fThreadPool); // release all associated threads and I/O completion
{$endif}
{$ifdef LINUX}
  pthread_detach(ThreadID); // manualy do it here
{$endif}
  FreeAndNil(Sock);
  inherited Destroy;         // direct Thread abort, no wait till ended
  DeleteCriticalSection(fProcessCS);
end;

{.$define MONOTHREAD}
// define this not to create a thread at every connection (not recommended)

procedure THttpServer.Execute;
var ClientSock: TSocket;
    Sin: TVarSin;
{$ifdef MONOTHREAD}
    ClientCrtSock: THttpServerSocket;
{$endif}
{$ifdef USETHREADPOOL}
    i: integer;
{$endif}
label abort;
begin
  // main server process loop
  if Sock.Sock>0 then
    while not Terminated do begin
      ClientSock := Accept(Sock.Sock,Sin);
      if Terminated or (Sock=nil) then begin
abort:  Shutdown(ClientSock,1);
        CloseSocket(ClientSock);
        break; // don't accept input if server is down
      end;
      OnConnect;
{$ifdef MONOTHREAD}
      ClientCrtSock := THttpServerSocket.Create(self);
      try
        ClientCrtSock.InitRequest(ClientSock);
        if ClientCrtSock.GetRequest then
          Process(ClientCrtSock);
        OnDisconnect;
        Shutdown(ClientSock,1);
        CloseSocket(ClientSock)
      finally
        ClientCrtSock.Free;
      end;
{$else}
{$ifdef USETHREADPOOL}
      if not fThreadPool.Push(ClientSock) then begin
        for i := 1 to 1500 do begin
          inc(fThreadPoolContentionCount);
          sleep(20); // wait a little until a thread gets free
          if fThreadPool.Push(ClientSock) then
            Break;
        end;
        inc(fThreadPoolContentionAbortCount);
        goto Abort; // 1500*20 = 30 seconds timeout
      end;
{$else} // default implementation creates one thread for each incoming socket
        THttpServerResp.Create(ClientSock, self);
{$endif}
{$endif}
      end;
end;

procedure THttpServer.OnConnect;
begin
  inc(ServerConnectionCount);
end;

procedure THttpServer.OnDisconnect;
begin
  // nothing to do by default
end;

procedure THttpServer.Process(ClientSock: THttpServerSocket; aCallingThread: TNotifiedThread);
var Context: THttpServerRequest;
    P: PAnsiChar;
    Code: cardinal;
    s: RawByteString;
    FileToSend: TFileStream;
begin
  if (ClientSock=nil) or (ClientSock.Headers=nil) then
    // we didn't get the request = socket read error
    exit; // -> send will probably fail -> nothing to send back
  if Terminated then
    exit;
  Context := THttpServerRequest.Create(self,aCallingThread);
  try
    // calc answer
    with ClientSock do begin
      Context.Prepare(URL,Method,HeaderGetText,Content,ContentType);
      Code := Request(Context);
    end;
    if Terminated then
      exit;
    // handle case of direct sending of static file (as with http.sys)
    if (Context.OutContent<>'') and (Context.OutContentType=HTTP_RESP_STATICFILE) then
      try
        FileToSend := TFileStream.Create(
          {$ifdef UNICODE}UTF8ToUnicodeString{$else}Utf8ToAnsi{$endif}(Context.OutContent),
          fmOpenRead or fmShareDenyNone);
        try
          SetString(Context.fOutContent,nil,FileToSend.Size);
          FileToSend.Read(Pointer(Context.fOutContent)^,length(Context.fOutContent));
          Context.OutContentType := ''; // 'Content-type: ...' in OutCustomHeader
       finally
          FileToSend.Free;
        end;
      except
        on Exception do begin
         Code := 404;
         Context.OutContent := '';
        end;
      end;
    // send response (multi-thread OK) at once
    if (Code<200) or (ClientSock.Headers=nil) then
      Code := 404;
    if not(Code in [200,201]) and (Context.OutContent='') then begin
      Context.OutCustomHeaders := '';
      Context.OutContentType := 'text/html'; // create message to display
      ContexT.OutContent := RawByteString(format('<body>%s Server Error %d<hr>%s<br>',
        [ClassName,Code,StatusCodeToReason(Code)]));
    end;
    // 1. send HTTP status command
    if ClientSock.TCPPrefix<>'' then
      ClientSock.SockSend(ClientSock.TCPPrefix);
    if ClientSock.KeepAliveClient then
      ClientSock.SockSend(['HTTP/1.1 ',Code,' OK']) else
      ClientSock.SockSend(['HTTP/1.0 ',Code,' OK']);
    // 2. send headers
    // 2.1. custom headers from Request() method
    P := pointer(Context.fOutCustomHeaders);
    while P<>nil do begin
      s := GetNextLine(P);
      if s<>'' then begin // no void line (means headers ending)
        ClientSock.SockSend(s);
        if IdemPChar(pointer(s),'CONTENT-ENCODING:') then
          integer(ClientSock.fCompressHeader) := 0; // custom encoding: don't compress
      end;
    end;
    // 2.2. generic headers
    ClientSock.SockSend([XPOWEREDNAME+': '+XPOWEREDVALUE+#13#10'Server: ',ClassName]);
    ClientSock.CompressDataAndWriteHeaders(Context.OutContentType,Context.fOutContent);
    if ClientSock.KeepAliveClient then begin
      if ClientSock.fCompressAcceptEncoding<>'' then
        ClientSock.SockSend(ClientSock.fCompressAcceptEncoding);
      ClientSock.SockSend('Connection: Keep-Alive'#13#10); // #13#10 -> end headers
    end else
      ClientSock.SockSend; // headers must end with a void line
    ClientSock.SockSendFlush; // flush all pending data (i.e. headers) to network
    // 3. sent HTTP body content (if any)
    if Context.OutContent<>'' then
      // direct send to socket (no CRLF at the end of data)
      ClientSock.SndLow(pointer(Context.OutContent),length(Context.OutContent));
  finally
    if Sock<>nil then begin // add transfert stats to main socket
      EnterCriticalSection(fProcessCS);
      inc(Sock.BytesIn,ClientSock.BytesIn);
      inc(Sock.BytesOut,ClientSock.BytesOut);
      LeaveCriticalSection(fProcessCS);
      ClientSock.BytesIn := 0;
      ClientSock.BytesOut := 0;
    end;
    Context.Free;
  end;
end;


{ TNotifiedThread }

{$ifndef LVCL}
procedure TNotifiedThread.DoTerminate;
begin
  if Assigned(fNotified) and Assigned(fOnTerminate) then begin
    fOnTerminate(self);
    fNotified := nil;
  end;
  inherited DoTerminate;
end;  
{$endif}


{ THttpServerResp }

constructor THttpServerResp.Create(aSock: TSocket; aServer: THttpServer);
begin
  Create(THttpServerSocket.Create(aServer),aServer{$ifdef USETHREADPOOL},nil{$endif});
  fClientSock := aSock;
end;

constructor THttpServerResp.Create(aServerSock: THttpServerSocket;
  aServer: THttpServer{$ifdef USETHREADPOOL}; aThreadPool: TSynThreadPoolTHttpServer{$endif});
begin
  inherited Create(false);
  FreeOnTerminate := true;
  fServer := aServer;
  fServerSock := aServerSock;
  {$ifdef USETHREADPOOL}
  fThreadPool := aThreadPool;
  {$endif}
  fOnTerminate := fServer.fOnTerminate;
  EnterCriticalSection(fServer.fProcessCS);
  try
    fServer.fInternalHttpServerRespList.Add(self);
  finally
    LeaveCriticalSection(fServer.fProcessCS);
  end;
end;

procedure THttpServerResp.Execute;
procedure HandleRequestsProcess;
var c: char;
    StartTick, StopTick, Tick: cardinal;
    Size, nSleep: integer;
begin
  {$ifdef USETHREADPOOL}
  if fThreadPool<>nil then
    InterlockedIncrement(fThreadPool.FGeneratedThreadCount);
  {$endif}
  try
    nSleep := 0;
    repeat
      StartTick := GetTickCount;
      StopTick := StartTick+fServer.ServerKeepAliveTimeOut;
      repeat // within this loop, break=wait for next command, exit=quit
        if (fServer=nil) or fServer.Terminated or (fServerSock=nil) then
          exit; // server is down -> close connection
        Size := Recv(fServerSock.Sock,@c,1,MSG_PEEK);
        // Recv() may return Size=0 if no data is pending, but no TCP/IP error
        if (fServer=nil) or fServer.Terminated then
          exit; // server is down -> disconnect the client
        if Size<0 then
          exit; // socket error -> disconnect the client
        if Size=0 then begin
          // no data available -> wait for keep alive timeout
          inc(nSleep);
          if nSleep<150 then
            sleep(0) else
          if nSleep<160 then
            sleep(1) else
          if nSleep<200 then
            sleep(2) else
            sleep(10);
        end else begin
          // get request and headers
          nSleep := 0;
          if not fServerSock.GetRequest(True) then
            // fServerSock connection was down or headers are not correct
            exit;
          // calc answer and send response
          fServer.Process(fServerSock,self);
          // keep connection only if necessary
          if fServerSock.KeepAliveClient then
            break else
            exit;
        end;
        Tick := GetTickCount;
        if Tick<StartTick then // time wrap after continuous run for 49.7 days
          break; // reset Ticks count + retry
        if Tick>StopTick then
          exit; // reached time out -> close connection
       until false;
    until false;
  except
    on E: Exception do
      ; // any exception will silently disconnect the client
  end;
  {$ifdef USETHREADPOOL}
  if fThreadPool<>nil then
    InterlockedDecrement(fThreadPool.FGeneratedThreadCount);
  {$endif}
end;
var aSock: TSocket;
    i: integer;
begin
  try
    try
      if fClientSock<>0 then begin
        // direct call from incoming socket
        aSock := fClientSock;
        fClientSock := 0; // mark no need to Shutdown and close fClientSock
        fServerSock.InitRequest(aSock); // now fClientSock is in fServerSock
        if fServer<>nil then
          HandleRequestsProcess;
      end else begin
        // call from TSynThreadPoolTHttpServer -> handle first request
        if not fServerSock.fBodyRetrieved then
          fServerSock.GetBody;
        fServer.Process(fServerSock,self);
        if (fServer<>nil) and fServerSock.KeepAliveClient then
          HandleRequestsProcess; // process further kept alive requests
      end;
    finally
      try
        assert(fServer<>nil);
        if fServer<>nil then
        try
          EnterCriticalSection(fServer.fProcessCS);
          fServer.OnDisconnect;
          if (fServer.fInternalHttpServerRespList<>nil) then begin
            i := fServer.fInternalHttpServerRespList.IndexOf(self);
            if i>=0 then
              fServer.fInternalHttpServerRespList.Delete(i);
          end;
        finally
          LeaveCriticalSection(fServer.fProcessCS);
          fServer := nil;
        end;
      finally
        FreeAndNil(fServerSock);
        if fClientSock<>0 then begin
          // if Destroy happens before fServerSock.GetRequest() in Execute below
          Shutdown(fClientSock,1);
          CloseSocket(fClientSock);
        end;
      end;
    end;
  except
    on Exception do
      ; // just ignore unexpected exceptions here, especially during clean-up
  end;
end;


{ THttpSocket }

procedure THttpSocket.GetBody;
var Line: RawByteString; // 32 bits chunk length in hexa
    LinePChar: array[0..31] of AnsiChar;
    Len, LContent, Error: integer;
begin
  fBodyRetrieved := true;
{$ifdef DEBUG23}system.writeln('GetBody ContentLength=',ContentLength);{$endif}
  Content := '';
  {$I-}
  // direct read bytes, as indicated by Content-Length or Chunked
  if Chunked then begin // we ignore the Length
    LContent := 0; // current read position in Content
    repeat
      if SockIn<>nil then begin
        readln(SockIn^,LinePChar);      // use of a static PChar is faster
        Error := ioresult;
        if Error<>0 then
          raise ECrtSocket.Create('GetBody1',Error);
        Len := PCharToHex32(LinePChar); // get chunk length in hexa
      end else begin
        SockRecvLn(Line);
        Len := PCharToHex32(pointer(Line)); // get chunk length in hexa
      end;
      if Len=0 then begin // ignore next line (normaly void)
        SockRecvLn;
        break;
      end;
      SetLength(Content,LContent+Len); // reserve memory space for this chunk
      SockInRead(pointer(PAnsiChar(pointer(Content))+LContent),Len) ; // append chunk data
      inc(LContent,Len);
      SockRecvLn; // ignore next #13#10
    until false;
  end else
  if ContentLength>0 then begin
    SetLength(Content,ContentLength); // not chuncked: direct read
    SockInRead(pointer(Content),ContentLength); // works with SockIn=nil or not
  end else
  if ContentLength<0 then begin // ContentLength=-1 if no Content-Length
    // no Content-Length nor Chunked header -> read until eof()
    if SockIn<>nil then 
      while not eof(SockIn^) do begin
        readln(SockIn^,Line);
        if Content='' then
          Content := Line else
          Content := Content+#13#10+Line;
      end;
    ContentLength := length(Content); // update Content-Length
    exit;
  end;
  // optionaly uncompress content
  if cardinal(fContentCompress)<cardinal(length(fCompress)) then
    if fCompress[fContentCompress].Func(Content,false)='' then
      // invalid content
      raise ECrtSocket.CreateFmt('%s uncompress',[fCompress[fContentCompress].Name]);
  ContentLength := length(Content); // update Content-Length
  if SockIn<>nil then begin
    Error := ioresult;
    if Error<>0 then
      raise ECrtSocket.Create('GetBody2',Error);
  end;
  {$I+}
end;

procedure THttpSocket.GetHeader;
var s: RawByteString;
    i, n: integer;
    P: PAnsiChar;
begin
  fBodyRetrieved := false;
  ContentType := '';
  ContentLength := -1;
  fContentCompress := -1;
  ConnectionClose := false;
  Chunked := false;
  n := 0;
  repeat
    SockRecvLn(s);
    if s='' then
      break; // headers end with a void line
    if length(Headers)<=n then
      SetLength(Headers,n+10);
    Headers[n] := s;
    inc(n);
    {$ifdef DEBUG23}system.Writeln(ClassName,'.HeaderIn ',s);{$endif}
    P := pointer(s);
    if IdemPChar(P,'CONTENT-LENGTH:') then
      ContentLength := GetCardinal(pointer(PAnsiChar(pointer(s))+16)) else
    if IdemPChar(P,'CONTENT-TYPE:') then
      ContentType := trim(copy(s,14,128)) else
    if IdemPChar(P,'TRANSFER-ENCODING: CHUNKED') then
      Chunked := true else
    if IdemPChar(P,'CONNECTION: CLOSE') then
      ConnectionClose := true else
    if fCompress<>nil then
      if IdemPChar(P,'ACCEPT-ENCODING:') then
        fCompressHeader := ComputeContentEncoding(fCompress,P+16) else
      if IdemPChar(P,'CONTENT-ENCODING: ') then begin
        i := 18;
        while s[i+1]=' ' do inc(i);
        delete(s,1,i);
        for i := 0 to high(fCompress) do
          if fCompress[i].Name=s then begin
            fContentCompress := i;
            break;
          end;
      end;
  until false;
  SetLength(Headers,n);
end;

function THttpSocket.HeaderAdd(const aValue: RawByteString): integer;
begin
  result := length(Headers);
  SetLength(Headers,result+1);
  Headers[result] := aValue;
end;

procedure THttpSocket.HeaderSetText(const aText: RawByteString);
var P, PDeb: PAnsiChar;
    n: integer;
begin
  P := pointer(aText);
  n := 0;
  if P<>nil then
    repeat
      PDeb := P;
      while P^>#13 do inc(P);
      if PDeb<>P then begin // add any not void line
        if length(Headers)<=n then
          SetLength(Headers,n+10);
        SetString(Headers[n],PDeb,P-PDeb);
        inc(n);
      end;
      while (P^=#13) or (P^=#10) do inc(P);
    until P^=#0;
  SetLength(Headers,n);
end;

function THttpSocket.HeaderGetText: RawByteString;
var i,L,n: integer;
    V: PtrInt;
    P: PAnsiChar;
begin
  // much faster than for i := 0 to Count-1 do result := result+Headers[i]+#13#10;
  result := '';
  n := length(Headers);
  if n=0 then
    exit;
  L := n*2; // #13#10 size
  dec(n);
  for i := 0 to n do
    if pointer(Headers[i])<>nil then
      inc(L,PInteger(PAnsiChar(pointer(Headers[i]))-4)^); // fast add length(List[i])
  SetLength(result,L);
  P := pointer(result);
  for i := 0 to n do begin
    V := PtrInt(PAnsiChar(Headers[i]));
    if V<>0 then begin
      L := PInteger(V-4)^;  // L := length(List[i])
      move(pointer(V)^,P^,L);
      inc(P,L);
    end;
    PWord(P)^ := 13+10 shl 8;
    inc(P,2);
  end;
end;

function THttpSocket.HeaderValue(aName: RawByteString): RawByteString;
var i: integer;
begin
  if Headers<>nil then begin
    aName := UpperCase(aName)+':';
    for i := 0 to high(Headers) do
      if IdemPChar(pointer(Headers[i]),pointer(aName)) then begin
        result := trim(copy(Headers[i],length(aName)+1,maxInt));
        exit;
      end;
  end;
  result := '';
end;

function THttpSocket.RegisterCompress(aFunction: THttpSocketCompress;
  aCompressMinSize: integer): boolean;
begin
  result := RegisterCompressFunc(fCompress,aFunction,fCompressAcceptEncoding,aCompressMinSize)<>'';
end;

procedure THttpSocket.CompressDataAndWriteHeaders(const OutContentType: RawByteString;
  var OutContent: RawByteString);
var OutContentEncoding: RawByteString;
begin
  if integer(fCompressHeader)<>0 then begin
    OutContentEncoding := CompressDataAndGetHeaders(fCompressHeader,fCompress,
      OutContentType,OutContent);
    if OutContentEncoding<>'' then
        SockSend(['Content-Encoding: ',OutContentEncoding]);
  end;
  SockSend(['Content-Length: ',length(OutContent)]); // needed even 0
  if (OutContent<>'') and (OutContentType<>'') then
    SockSend(['Content-Type: ',OutContentType]);
end;

procedure GetSinIPFromCache(const Sin: TVarSin; var result: RawByteString);
begin
  if (Sin.AddressFamily=AF_INET6) and SockWship6Api then
    result := GetSinIP(Sin) else
  if Sin.AddressFamily=AF_INET then
    result := RawByteString(Format('%d.%d.%d.%d',[
      Sin.sin_addr.S_bytes[0],Sin.sin_addr.S_bytes[1],
      Sin.sin_addr.S_bytes[2],Sin.sin_addr.S_bytes[3]])) else
    result := '';
end;


{ THttpServerSocket }

procedure THttpServerSocket.InitRequest(aClientSock: TSocket);
var li: TLinger;
begin
  CreateSockIn; // use SockIn by default if not already initialized: 2x faster
  OpenBind('','',false,aClientSock); // open aClientSock for reading
  // Socket should remain open for 5 seconds after a closesocket() call
  li.l_onoff := Ord(true);
  li.l_linger := 5;
  SetSockOpt(aClientSock, SOL_SOCKET, SO_LINGER, @li, SizeOf(li));
end;

function THttpServerSocket.HeaderGetText: RawByteString;
var Name: TVarSin;
    IP: RawByteString;
    ConnectionID: shortstring;
begin
  BinToHexDisplay(@Sock,4,ConnectionID);
  result := inherited HeaderGetText+'ConnectionID: '+ConnectionID+#13#10;
  if GetSockName(Sock,Name)<>0 then
    exit;
  GetSinIPFromCache(Name,IP);
  if IP<>'' then
    result := result+'RemoteIP: '+IP+#13#10;
end;

function THttpServerSocket.GetRequest(withBody: boolean=true): boolean;
var P: PAnsiChar;
    StartTix, EndTix: cardinal;
begin
  try
    StartTix := GetTickCount;
    // 1st line is command: 'GET /path HTTP/1.1' e.g.
    SockRecvLn(Command);
    if TCPPrefix<>'' then
      if TCPPrefix<>Command then begin
        result := false;
        exit
      end else
      SockRecvLn(Command);
    P := pointer(Command);
    Method := GetNextItem(P,' '); // 'GET'
    URL := GetNextItem(P,' ');    // '/path'
    KeepAliveClient := IdemPChar(P,'HTTP/1.1');
    Content := '';
    // get headers and content
    GetHeader;
    if ConnectionClose then
      KeepAliveClient := false;
    if (ContentLength<0) and KeepAliveClient then
      ContentLength := 0; // HTTP/1.1 and no content length -> no eof
    EndTix := GetTickCount;
    result := EndTix<StartTix+5000; // 5 sec for header -> DOS / TCP SYN Flood
    // if time wrap after 49.7 days -> EndTix<StartTix -> always accepted
    if result and withBody then
      GetBody;
  except
    on E: Exception do
      result := false; // mark error
  end;
end;

constructor THttpServerSocket.Create(aServer: THttpServer);
begin
  inherited Create(5000);
  if aServer<>nil then begin
    fCompress := aServer.fCompress;
    fCompressAcceptEncoding := aServer.fCompressAcceptEncoding;
    TCPPrefix := aServer.TCPPrefix;
  end;
end;


{ ECrtSocket }

constructor ECrtSocket.Create(const Msg: string);
begin
  Create(Msg,WSAGetLastError());
end;

constructor ECrtSocket.Create(const Msg: string; Error: integer);
begin
  Error := abs(Error);
  inherited CreateFmt('%s %d (%s)',[Msg,Error,SysErrorMessage(Error)]);
end;


{$ifdef USETHREADPOOL}

{ TSynThreadPool }

const
  // Posted to the completion port when shutting down
  SHUTDOWN_FLAG = POverlapped(-1);

constructor TSynThreadPool.Create(NumberOfThreads: Integer);
var i: integer;
    Thread: TSynThreadPoolSubThread;
begin
  if NumberOfThreads=0 then
    NumberOfThreads := 1 else
  if cardinal(NumberOfThreads)>cardinal(length(FThreadID)) then
    NumberOfThreads := length(FThreadID); // maximum count for WaitForMultipleObjects()
  // Create IO completion port to queue the HTTP requests
  FRequestQueue := CreateIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, NumberOfThreads);
  if FRequestQueue=INVALID_HANDLE_VALUE then begin
    FRequestQueue := 0;
    exit;
  end;
  // Now create the worker threads
  FThread := TObjectList.Create;
  for i := 0 to NumberOfThreads-1 do begin
    Thread := TSynThreadPoolSubThread.Create(Self);
    FThread.Add(Thread);
    FThreadID[i] := Thread.ThreadID;
  end;
  FGeneratedThreadCount := NumberOfThreads;
end;

destructor TSynThreadPool.Destroy;
var i: integer;
begin
  if FRequestQueue<>0 then begin
    // Tell the threads we're shutting down
    for i := 1 to fThread.Count do
      PostQueuedCompletionStatus(FRequestQueue, 0, 0, SHUTDOWN_FLAG);
    // Wait for threads to finish, with 30 seconds TimeOut
    WaitForMultipleObjects(FThread.Count,@FThreadID,True,30000);
    // Close the request queue handle
    CloseHandle(FRequestQueue);
    FRequestQueue := 0;
  end;
  FreeAndNil(fThread);
end;

{ TSynThreadPoolSubThread }

const
  // if HTTP body length is bigger than 1 MB, creates a dedicated THttpServerResp 
  THREADPOOL_BIGBODYSIZE = 1024*1024;

  // kept-alive or big HTTP requests will create a dedicated THttpServerResp
  // - each thread reserves 2 MB of memory so it may break the server
  // - keep the value to a decent number, to let resources be constrained
  THREADPOOL_MAXCREATEDTHREADS = 100;

constructor TSynThreadPoolSubThread.Create(Owner: TSynThreadPool);
begin
  fOwner := Owner;
  fOnTerminate := Owner.FOnHttpThreadTerminate;
  inherited Create(false);
end;

function GetQueuedCompletionStatus(CompletionPort: THandle;
  var lpNumberOfBytesTransferred: pointer; var lpCompletionKey: PtrUInt;
  var lpOverlapped: POverlapped; dwMilliseconds: DWORD): BOOL; stdcall;
  external kernel32; // redefine with an unique signature for all Delphi/FPC

procedure TSynThreadPoolSubThread.Execute;
var Context: pointer;
    Key: PtrUInt;
    Overlapped: POverlapped;
begin
  if fOwner<>nil then
  while GetQueuedCompletionStatus(fOwner.FRequestQueue,Context,Key,OverLapped,INFINITE) do
  try
    if OverLapped=SHUTDOWN_FLAG then
      break; // exit thread
    if Context<>nil then
      fOwner.Task(Self,Context);
  except
    on Exception do
      ; // we should handle all exceptions in this loop
  end;
end;


{ TSynThreadPoolTHttpServer }

constructor TSynThreadPoolTHttpServer.Create(Server: THttpServer; NumberOfThreads: Integer=32);
begin
  inherited Create(NumberOfThreads);
  fServer := Server;
end;

function TSynThreadPoolTHttpServer.Push(aClientSock: TSocket): boolean;
begin
  result := false;
  if (Self=nil) or (FRequestQueue=0) then
    exit;
  result := PostQueuedCompletionStatus(FRequestQueue,PtrUInt(aClientSock),0,nil);
end;

procedure TSynThreadPoolTHttpServer.Task(aCaller: TSynThreadPoolSubThread; aContext: Pointer);
var ServerSock: THttpServerSocket;
begin
  ServerSock := THttpServerSocket.Create(fServer);
  try
    ServerSock.InitRequest(TSocket(aContext));
    // get Header of incoming request
    if ServerSock.GetRequest(false) then
      // connection and header seem valid -> process request further
      if (FGeneratedThreadCount<THREADPOOL_MAXCREATEDTHREADS) and
         (ServerSock.KeepAliveClient or
          (ServerSock.ContentLength>THREADPOOL_BIGBODYSIZE)) then begin
        // HTTP/1.1 Keep Alive -> process in background thread
        // or posted data > 1 MB -> get Body in background thread
        THttpServerResp.Create(ServerSock,fServer,self);
        ServerSock := nil; // THttpServerResp will do ServerSock.Free
      end else begin
        // no Keep Alive = multi-connection -> process in the Thread Pool
        ServerSock.GetBody; // we need to get it now
        fServer.Process(ServerSock,aCaller);
        fServer.OnDisconnect;
        // no Shutdown here: will be done client-side
      end;
  finally
    FreeAndNil(ServerSock);
  end;
end; 

{$endif USETHREADPOOL}


{ ************  http.sys / HTTP API low-level direct access }

{$MINENUMSIZE 4}
{$A+}

type
  // HTTP version used
  HTTP_VERSION = packed record
    MajorVersion: word;
    MinorVersion: word;
  end;

  // the req* values identify Request Headers, and resp* Response Headers
  THttpHeader = (
    reqCacheControl,
    reqConnection,
    reqDate,
    reqKeepAlive,
    reqPragma,
    reqTrailer,
    reqTransferEncoding,
    reqUpgrade,
    reqVia,
    reqWarning,
    reqAllow,
    reqContentLength,
    reqContentType,
    reqContentEncoding,
    reqContentLanguage,
    reqContentLocation,
    reqContentMd5,
    reqContentRange,
    reqExpires,
    reqLastModified,
    reqAccept,
    reqAcceptCharset,
    reqAcceptEncoding,
    reqAcceptLanguage,
    reqAuthorization,
    reqCookie,
    reqExpect,
    reqFrom,
    reqHost,
    reqIfMatch,
    reqIfModifiedSince,
    reqIfNoneMatch,
    reqIfRange,
    reqIfUnmodifiedSince,
    reqMaxForwards,
    reqProxyAuthorization,
    reqReferer,
    reqRange,
    reqTe,
    reqTranslate,
    reqUserAgent
{$ifndef CONDITIONALEXPRESSIONS}
   );
const // Delphi 5 does not support values overlapping for enums
  respAcceptRanges = THttpHeader(20);
  respAge = THttpHeader(21);
  respEtag = THttpHeader(22);
  respLocation = THttpHeader(23);
  respProxyAuthenticate = THttpHeader(24);
  respRetryAfter = THttpHeader(25);
  respServer = THttpHeader(26);
  respSetCookie = THttpHeader(27);
  respVary = THttpHeader(28);
  respWwwAuthenticate = THttpHeader(29);
type
{$else}  ,
    respAcceptRanges = 20,
    respAge,
    respEtag,
    respLocation,
    respProxyAuthenticate,
    respRetryAfter,
    respServer,
    respSetCookie,
    respVary,
    respWwwAuthenticate);
{$endif}

  THttpVerb = (
    hvUnparsed,
    hvUnknown,
    hvInvalid,
    hvOPTIONS,
    hvGET,
    hvHEAD,
    hvPOST,
    hvPUT,
    hvDELETE,
    hvTRACE,
    hvCONNECT,
    hvTRACK,  // used by Microsoft Cluster Server for a non-logged trace
    hvMOVE,
    hvCOPY,
    hvPROPFIND,
    hvPROPPATCH,
    hvMKCOL,
    hvLOCK,
    hvUNLOCK,
    hvSEARCH,
    hvMaximum );

  THttpChunkType = (
    hctFromMemory,
    hctFromFileHandle,
    hctFromFragmentCache);

  THttpServiceConfigID = (
    hscIPListenList,
    hscSSLCertInfo,
    hscUrlAclInfo,      
    hscMax);
  THttpServiceConfigQueryType = (
    hscQueryExact,
    hscQueryNext,
    hscQueryMax);

  HTTP_URL_CONTEXT = HTTP_OPAQUE_ID;
  HTTP_REQUEST_ID = HTTP_OPAQUE_ID;
  HTTP_CONNECTION_ID = HTTP_OPAQUE_ID;
  HTTP_RAW_CONNECTION_ID = HTTP_OPAQUE_ID;

  // Pointers overlap and point into pFullUrl. nil if not present.
  HTTP_COOKED_URL = record
    FullUrlLength: word;     // in bytes not including the #0
    HostLength: word;        // in bytes not including the #0
    AbsPathLength: word;     // in bytes not including the #0
    QueryStringLength: word; // in bytes not including the #0
    pFullUrl: PWideChar;     // points to "http://hostname:port/abs/.../path?query"
    pHost: PWideChar;        // points to the first char in the hostname
    pAbsPath: PWideChar;     // Points to the 3rd '/' char
    pQueryString: PWideChar; // Points to the 1st '?' char or #0
  end;

  HTTP_TRANSPORT_ADDRESS = record
    pRemoteAddress: PSOCKADDR;
    pLocalAddress: PSOCKADDR;
  end;

  HTTP_UNKNOWN_HEADER = record
    NameLength: word;          // in bytes not including the #0
    RawValueLength: word;      // in bytes not including the n#0
    pName: PAnsiChar;          // The header name (minus the ':' character)
    pRawValue: PAnsiChar;      // The header value
  end;
  PHTTP_UNKNOWN_HEADER = ^HTTP_UNKNOWN_HEADER;
  HTTP_UNKNOWN_HEADERs = array of HTTP_UNKNOWN_HEADER;

  HTTP_KNOWN_HEADER = record
    RawValueLength: word;     // in bytes not including the #0
    pRawValue: PAnsiChar;
  end;
  PHTTP_KNOWN_HEADER = ^HTTP_KNOWN_HEADER;

  HTTP_RESPONSE_HEADERS = record
    // number of entries in the unknown HTTP headers array
    UnknownHeaderCount: word;
    // array of unknown HTTP headers
    pUnknownHeaders: pointer;
    // Reserved, must be 0
    TrailerCount: word;
    // Reserved, must be nil
    pTrailers: pointer;
    // Known headers
    KnownHeaders: array[low(THttpHeader)..respWwwAuthenticate] of HTTP_KNOWN_HEADER;
  end;

  HTTP_REQUEST_HEADERS = record
    // number of entries in the unknown HTTP headers array
    UnknownHeaderCount: word;
    // array of unknown HTTP headers
    pUnknownHeaders: PHTTP_UNKNOWN_HEADER;
    // Reserved, must be 0
    TrailerCount: word;
    // Reserved, must be nil
    pTrailers: pointer;
    // Known headers
    KnownHeaders: array[low(THttpHeader)..reqUserAgent] of HTTP_KNOWN_HEADER;
  end;

  HTTP_BYTE_RANGE = record
    StartingOffset: ULARGE_INTEGER;
    Length: ULARGE_INTEGER;
  end;

  // we use 3 distinct HTTP_DATA_CHUNK_* records since variable records
  // alignment is buggy/non compatible under Delphi XE3
  HTTP_DATA_CHUNK_INMEMORY = record
    DataChunkType: THttpChunkType; // always hctFromMemory
    Reserved1: ULONG;
    pBuffer: pointer;
    BufferLength: ULONG;
    Reserved2: ULONG;
    Reserved3: ULONG;
  end;
  PHTTP_DATA_CHUNK_INMEMORY = ^HTTP_DATA_CHUNK_INMEMORY;
  HTTP_DATA_CHUNK_FILEHANDLE = record
    DataChunkType: THttpChunkType; // always hctFromFileHandle
    ByteRange: HTTP_BYTE_RANGE;
    FileHandle: THandle;
  end;
  HTTP_DATA_CHUNK_FRAGMENTCACHE = record
    DataChunkType: THttpChunkType; // always hctFromFragmentCache
    FragmentNameLength: word;      // in bytes not including the #0
    pFragmentName: PWideChar;
  end;

  HTTP_SSL_CLIENT_CERT_INFO = record
    CertFlags: ULONG;
    CertEncodedSize: ULONG;
    pCertEncoded: PUCHAR;
    Token: THandle;
    CertDeniedByMapper: boolean;
  end;
  PHTTP_SSL_CLIENT_CERT_INFO = ^HTTP_SSL_CLIENT_CERT_INFO;

  HTTP_SSL_INFO = record
    ServerCertKeySize: word;
    ConnectionKeySize: word;
    ServerCertIssuerSize: ULONG;
    ServerCertSubjectSize: ULONG;
    pServerCertIssuer: PAnsiChar;
    pServerCertSubject: PAnsiChar;
    pClientCertInfo: PHTTP_SSL_CLIENT_CERT_INFO;
    SslClientCertNegotiated: ULONG;
  end;
  PHTTP_SSL_INFO = ^HTTP_SSL_INFO;

  HTTP_SERVICE_CONFIG_URLACL_KEY = record
    pUrlPrefix: PWideChar;
  end;
  HTTP_SERVICE_CONFIG_URLACL_PARAM = record
    pStringSecurityDescriptor: PWideChar;
  end;
  HTTP_SERVICE_CONFIG_URLACL_SET = record
    KeyDesc: HTTP_SERVICE_CONFIG_URLACL_KEY;
    ParamDesc: HTTP_SERVICE_CONFIG_URLACL_PARAM;
  end;
  HTTP_SERVICE_CONFIG_URLACL_QUERY = record
    QueryDesc: THttpServiceConfigQueryType;
    KeyDesc: HTTP_SERVICE_CONFIG_URLACL_KEY;
    dwToken: DWORD;
  end;

  HTTP_REQUEST_INFO_TYPE = (
    HttpRequestInfoTypeAuth
    );

  HTTP_AUTH_STATUS = (
    HttpAuthStatusSuccess,
    HttpAuthStatusNotAuthenticated,
    HttpAuthStatusFailure
    );

  HTTP_REQUEST_AUTH_TYPE = (
    HttpRequestAuthTypeNone,
    HttpRequestAuthTypeBasic,
    HttpRequestAuthTypeDigest,
    HttpRequestAuthTypeNTLM,
    HttpRequestAuthTypeNegotiate,
    HttpRequestAuthTypeKerberos
    );

  SECURITY_STATUS = ULONG;

  HTTP_REQUEST_AUTH_INFO = record
    AuthStatus: HTTP_AUTH_STATUS;
    SecStatus: SECURITY_STATUS;
    Flags: ULONG;
    AuthType: HTTP_REQUEST_AUTH_TYPE;
    AccessToken: THandle;
    ContextAttributes: ULONG;
    PackedContextLength: ULONG;
    PackedContextType: ULONG;
    PackedContext: pointer;
    MutualAuthDataLength: ULONG;
    pMutualAuthData: PCHAR;
  end;
  PHTTP_REQUEST_AUTH_INFO = ^HTTP_REQUEST_AUTH_INFO;

  HTTP_REQUEST_INFO = record
    InfoType: HTTP_REQUEST_INFO_TYPE;
    InfoLength: ULONG;
    pInfo: pointer;
  end;
  PHTTP_REQUEST_INFO = ^HTTP_REQUEST_INFO;

  /// structure used to handle data associated with a specific request
  HTTP_REQUEST = record
    // either 0 (Only Header), either HTTP_RECEIVE_REQUEST_FLAG_COPY_BODY
    Flags: cardinal;
    // An identifier for the connection on which the request was received
    ConnectionId: HTTP_CONNECTION_ID;
    // A value used to identify the request when calling
    // HttpReceiveRequestEntityBody, HttpSendHttpResponse, and/or
    // HttpSendResponseEntityBody
    RequestId: HTTP_REQUEST_ID;
    // The context associated with the URL prefix
    UrlContext: HTTP_URL_CONTEXT;
    // The HTTP version number
    Version: HTTP_VERSION;
    // An HTTP verb associated with this request
    Verb: THttpVerb;
    // The length of the verb string if the Verb field is hvUnknown
    // (in bytes not including the last #0)
    UnknownVerbLength: word;
    // The length of the raw (uncooked) URL (in bytes not including the last #0)
    RawUrlLength: word;
     // Pointer to the verb string if the Verb field is hvUnknown
    pUnknownVerb: PAnsiChar;
    // Pointer to the raw (uncooked) URL
    pRawUrl: PAnsiChar;
    // The canonicalized Unicode URL
    CookedUrl: HTTP_COOKED_URL;
    // Local and remote transport addresses for the connection
    Address: HTTP_TRANSPORT_ADDRESS;
    // The request headers.
    Headers: HTTP_REQUEST_HEADERS;
    // The total number of bytes received from network for this request
    BytesReceived: ULONGLONG;
    EntityChunkCount: word;
    pEntityChunks: pointer;
    RawConnectionId: HTTP_RAW_CONNECTION_ID;
    // SSL connection information
    pSslInfo: PHTTP_SSL_INFO;
    xxxPadding: DWORD;
    RequestInfoCount: word;
    pRequestInfo: PHTTP_REQUEST_INFO;
  end;
  PHTTP_REQUEST = ^HTTP_REQUEST;

  HTTP_RESPONSE_INFO_TYPE = (
    HttpResponseInfoTypeMultipleKnownHeaders,
    HttpResponseInfoTypeAuthenticationProperty,
    HttpResponseInfoTypeQosProperty,
    HttpResponseInfoTypeChannelBind
    );

  HTTP_RESPONSE_INFO = record
    Typ: HTTP_RESPONSE_INFO_TYPE;
    Length: ULONG;
    pInfo: Pointer;
  end;
  PHTTP_RESPONSE_INFO = ^HTTP_RESPONSE_INFO;

  /// structure as expected by HttpSendHttpResponse() API
  HTTP_RESPONSE = object
  public
    Flags: cardinal;
    // The raw HTTP protocol version number
    Version: HTTP_VERSION;
    // The HTTP status code (e.g., 200)
    StatusCode: word;
    // in bytes not including the '\0'
    ReasonLength: word;
    // The HTTP reason (e.g., "OK"). This MUST not contain non-ASCII characters
    // (i.e., all chars must be in range 0x20-0x7E).
    pReason: PAnsiChar;
    // The response headers
    Headers: HTTP_RESPONSE_HEADERS;
    // number of elements in pEntityChunks[] array
    EntityChunkCount: word;
    // pEntityChunks points to an array of EntityChunkCount HTTP_DATA_CHUNK_*
    pEntityChunks: pointer;
    // contains the number of HTTP API 2.0 extended information
    ResponseInfoCount: word;
    // map the HTTP API 2.0 extended information
    pResponseInfo: PHTTP_RESPONSE_INFO;
    // will set both StatusCode and Reason
    // - OutStatus is a temporary variable which will be field with the
    // corresponding text
    procedure SetStatus(code: integer; var OutStatus: RawByteString);
    // will set the content of the reponse, and ContentType header
    procedure SetContent(var DataChunk: HTTP_DATA_CHUNK_INMEMORY;
      const Content: RawByteString; const ContentType: RawByteString='text/html');
    /// will set all header values from lines
    // - Content-Type/Content-Encoding/Location will be set in KnownHeaders[]
    // - all other headers will be set in temp UnknownHeaders[]
    procedure SetHeaders(P: PAnsiChar; var UnknownHeaders: HTTP_UNKNOWN_HEADERs);
    /// add one header value to the internal headers
    // - SetHeaders() method should have been called before to initialize the
    // internal UnknownHeaders[] array
    function AddCustomHeader(P: PAnsiChar; var UnknownHeaders: HTTP_UNKNOWN_HEADERs): PAnsiChar;
  end;
  PHTTP_RESPONSE = ^HTTP_RESPONSE;

  HTTP_PROPERTY_FLAGS = ULONG;

  HTTP_ENABLED_STATE = (
    HttpEnabledStateActive,
    HttpEnabledStateInactive
    );
  PHTTP_ENABLED_STATE = ^HTTP_ENABLED_STATE;

  HTTP_STATE_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    State: HTTP_ENABLED_STATE;
  end;
  PHTTP_STATE_INFO = ^HTTP_STATE_INFO;

  THTTP_503_RESPONSE_VERBOSITY = (
    Http503ResponseVerbosityBasic,
    Http503ResponseVerbosityLimited,
    Http503ResponseVerbosityFull
    );
  PHTTP_503_RESPONSE_VERBOSITY = ^ THTTP_503_RESPONSE_VERBOSITY;

  HTTP_QOS_SETTING_TYPE = (
    HttpQosSettingTypeBandwidth,
    HttpQosSettingTypeConnectionLimit,
    HttpQosSettingTypeFlowRate // Windows Server 2008 R2 and Windows 7 only.
    );
  PHTTP_QOS_SETTING_TYPE = ^HTTP_QOS_SETTING_TYPE;

  HTTP_QOS_SETTING_INFO = record
    QosType: HTTP_QOS_SETTING_TYPE;
    QosSetting: Pointer;
  end;
  PHTTP_QOS_SETTING_INFO = ^HTTP_QOS_SETTING_INFO;

  HTTP_CONNECTION_LIMIT_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    MaxConnections: ULONG;
  end;
  PHTTP_CONNECTION_LIMIT_INFO = ^HTTP_CONNECTION_LIMIT_INFO;

  HTTP_BANDWIDTH_LIMIT_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    MaxBandwidth: ULONG;
  end;
  PHTTP_BANDWIDTH_LIMIT_INFO = ^HTTP_BANDWIDTH_LIMIT_INFO;

  HTTP_FLOWRATE_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    MaxBandwidth: ULONG;
    MaxPeakBandwidth: ULONG;
    BurstSize: ULONG;
  end;
  PHTTP_FLOWRATE_INFO = ^HTTP_FLOWRATE_INFO;

const
   HTTP_MIN_ALLOWED_BANDWIDTH_THROTTLING_RATE {:ULONG} = 1024;
   HTTP_LIMIT_INFINITE {:ULONG} = ULONG(-1);

type
  HTTP_SERVICE_CONFIG_TIMEOUT_KEY = (
    IdleConnectionTimeout,
    HeaderWaitTimeout
    );
  PHTTP_SERVICE_CONFIG_TIMEOUT_KEY = ^HTTP_SERVICE_CONFIG_TIMEOUT_KEY;

  HTTP_SERVICE_CONFIG_TIMEOUT_PARAM = word;
  PHTTP_SERVICE_CONFIG_TIMEOUT_PARAM = ^HTTP_SERVICE_CONFIG_TIMEOUT_PARAM;

  HTTP_SERVICE_CONFIG_TIMEOUT_SET = record
    KeyDesc: HTTP_SERVICE_CONFIG_TIMEOUT_KEY;
    ParamDesc: HTTP_SERVICE_CONFIG_TIMEOUT_PARAM;
  end;
  PHTTP_SERVICE_CONFIG_TIMEOUT_SET = ^HTTP_SERVICE_CONFIG_TIMEOUT_SET;

  HTTP_TIMEOUT_LIMIT_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    EntityBody: word;
    DrainEntityBody: word;
    RequestQueue: word;
    IdleConnection: word;
    HeaderWait: word;
    MinSendRate: word;
  end;
  PHTTP_TIMEOUT_LIMIT_INFO = ^HTTP_TIMEOUT_LIMIT_INFO;

  HTTP_LISTEN_ENDPOINT_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    EnableSharing: BOOLEAN;
  end;
  PHTTP_LISTEN_ENDPOINT_INFO = ^HTTP_LISTEN_ENDPOINT_INFO;

  HTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS = record
    DomainNameLength: word;
    DomainName: PWideChar;
    RealmLength: word;
    Realm: PWideChar;
  end;
  PHTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS = ^HTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS;

  HTTP_SERVER_AUTHENTICATION_BASIC_PARAMS = record
    RealmLength: word;
    Realm: PWideChar;
  end;
  PHTTP_SERVER_AUTHENTICATION_BASIC_PARAMS = ^HTTP_SERVER_AUTHENTICATION_BASIC_PARAMS;

const
  HTTP_AUTH_ENABLE_BASIC        = $00000001;
  HTTP_AUTH_ENABLE_DIGEST       = $00000002;
  HTTP_AUTH_ENABLE_NTLM         = $00000004;
  HTTP_AUTH_ENABLE_NEGOTIATE    = $00000008;
  HTTP_AUTH_ENABLE_KERBEROS     = $00000010;
  HTTP_AUTH_ENABLE_ALL          = $0000001F;

  HTTP_AUTH_EX_FLAG_ENABLE_KERBEROS_CREDENTIAL_CACHING  = $01;
  HTTP_AUTH_EX_FLAG_CAPTURE_CREDENTIAL                  = $02;

type
  HTTP_SERVER_AUTHENTICATION_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    AuthSchemes: ULONG;
    ReceiveMutualAuth: BYTEBOOL;
    ReceiveContextHandle: BYTEBOOL;
    DisableNTLMCredentialCaching: BYTEBOOL;
    ExFlags: BYTE;
    DigestParams: HTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS;
    BasicParams: HTTP_SERVER_AUTHENTICATION_BASIC_PARAMS;
  end;
  PHTTP_SERVER_AUTHENTICATION_INFO = ^HTTP_SERVER_AUTHENTICATION_INFO;


  HTTP_SERVICE_BINDING_TYPE=(
    HttpServiceBindingTypeNone,
    HttpServiceBindingTypeW,
    HttpServiceBindingTypeA
    );

  HTTP_SERVICE_BINDING_BASE = record
    BindingType: HTTP_SERVICE_BINDING_TYPE;
  end;
  PHTTP_SERVICE_BINDING_BASE = ^HTTP_SERVICE_BINDING_BASE;

  HTTP_SERVICE_BINDING_A = record
    Base: HTTP_SERVICE_BINDING_BASE;
    Buffer: PAnsiChar;
    BufferSize: ULONG;
  end;
  PHTTP_SERVICE_BINDING_A = HTTP_SERVICE_BINDING_A;

  HTTP_SERVICE_BINDING_W = record
    Base: HTTP_SERVICE_BINDING_BASE;
    Buffer: PWCHAR;
    BufferSize: ULONG;
  end;
  PHTTP_SERVICE_BINDING_W = ^HTTP_SERVICE_BINDING_W;

  HTTP_AUTHENTICATION_HARDENING_LEVELS = (
    HttpAuthenticationHardeningLegacy,
    HttpAuthenticationHardeningMedium,
    HttpAuthenticationHardeningStrict
  );

const
  HTTP_CHANNEL_BIND_PROXY = $1;
  HTTP_CHANNEL_BIND_PROXY_COHOSTING = $20;

  HTTP_CHANNEL_BIND_NO_SERVICE_NAME_CHECK = $2;
  HTTP_CHANNEL_BIND_DOTLESS_SERVICE = $4;
  HTTP_CHANNEL_BIND_SECURE_CHANNEL_TOKEN = $8;
  HTTP_CHANNEL_BIND_CLIENT_SERVICE = $10;

type
  HTTP_CHANNEL_BIND_INFO = record
    Hardening: HTTP_AUTHENTICATION_HARDENING_LEVELS;
    Flags: ULONG;
    ServiceNames: PHTTP_SERVICE_BINDING_BASE;
    NumberOfServiceNames: ULONG;
  end;
  PHTTP_CHANNEL_BIND_INFO = ^HTTP_CHANNEL_BIND_INFO;

  HTTP_REQUEST_CHANNEL_BIND_STATUS = record
    ServiceName: PHTTP_SERVICE_BINDING_BASE;
    ChannelToken: PUCHAR;
    ChannelTokenSize: ULONG;
    Flags: ULONG;
  end;
  PHTTP_REQUEST_CHANNEL_BIND_STATUS = ^HTTP_REQUEST_CHANNEL_BIND_STATUS;

const
   // Logging option flags. When used in the logging configuration alters
   // some default logging behaviour.

   // HTTP_LOGGING_FLAG_LOCAL_TIME_ROLLOVER - This flag is used to change
   //      the log file rollover to happen by local time based. By default
   //      log file rollovers happen by GMT time.
   HTTP_LOGGING_FLAG_LOCAL_TIME_ROLLOVER = 1;

   // HTTP_LOGGING_FLAG_USE_UTF8_CONVERSION - When set the unicode fields
   //      will be converted to UTF8 multibytes when writting to the log
   //      files. When this flag is not present, the local code page
   //      conversion happens.
   HTTP_LOGGING_FLAG_USE_UTF8_CONVERSION = 2;

   // HTTP_LOGGING_FLAG_LOG_ERRORS_ONLY -
   // HTTP_LOGGING_FLAG_LOG_SUCCESS_ONLY - These two flags are used to
   //      to do selective logging. If neither of them are present both
   //      types of requests will be logged. Only one these flags can be
   //      set at a time. They are mutually exclusive.
   HTTP_LOGGING_FLAG_LOG_ERRORS_ONLY = 4;
   HTTP_LOGGING_FLAG_LOG_SUCCESS_ONLY = 8;

   // The known log fields recognized/supported by HTTPAPI. Following fields
   // are used for W3C logging. Subset of them are also used for error logging
   HTTP_LOG_FIELD_DATE              = $00000001;
   HTTP_LOG_FIELD_TIME              = $00000002;
   HTTP_LOG_FIELD_CLIENT_IP         = $00000004;
   HTTP_LOG_FIELD_USER_NAME         = $00000008;
   HTTP_LOG_FIELD_SITE_NAME         = $00000010;
   HTTP_LOG_FIELD_COMPUTER_NAME     = $00000020;
   HTTP_LOG_FIELD_SERVER_IP         = $00000040;
   HTTP_LOG_FIELD_METHOD            = $00000080;
   HTTP_LOG_FIELD_URI_STEM          = $00000100;
   HTTP_LOG_FIELD_URI_QUERY         = $00000200;
   HTTP_LOG_FIELD_STATUS            = $00000400;
   HTTP_LOG_FIELD_WIN32_STATUS      = $00000800;
   HTTP_LOG_FIELD_BYTES_SENT        = $00001000;
   HTTP_LOG_FIELD_BYTES_RECV        = $00002000;
   HTTP_LOG_FIELD_TIME_TAKEN        = $00004000;
   HTTP_LOG_FIELD_SERVER_PORT       = $00008000;
   HTTP_LOG_FIELD_USER_AGENT        = $00010000;
   HTTP_LOG_FIELD_COOKIE            = $00020000;
   HTTP_LOG_FIELD_REFERER           = $00040000;
   HTTP_LOG_FIELD_VERSION           = $00080000;
   HTTP_LOG_FIELD_HOST              = $00100000;
   HTTP_LOG_FIELD_SUB_STATUS        = $00200000;

   HTTP_ALL_NON_ERROR_LOG_FIELDS = HTTP_LOG_FIELD_SUB_STATUS*2-1;

   // Fields that are used only for error logging
   HTTP_LOG_FIELD_CLIENT_PORT    = $00400000;
   HTTP_LOG_FIELD_URI            = $00800000;
   HTTP_LOG_FIELD_SITE_ID        = $01000000;
   HTTP_LOG_FIELD_REASON         = $02000000;
   HTTP_LOG_FIELD_QUEUE_NAME     = $04000000;

type
  HTTP_LOGGING_TYPE = (
    HttpLoggingTypeW3C,
    HttpLoggingTypeIIS,
    HttpLoggingTypeNCSA,
    HttpLoggingTypeRaw
    );

  HTTP_LOGGING_ROLLOVER_TYPE = (
    HttpLoggingRolloverSize,
    HttpLoggingRolloverDaily,
    HttpLoggingRolloverWeekly,
    HttpLoggingRolloverMonthly,
    HttpLoggingRolloverHourly
    );

  HTTP_LOGGING_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    LoggingFlags: ULONG;
    SoftwareName: PWideChar;
    SoftwareNameLength: word;
    DirectoryNameLength: word;
    DirectoryName: PWideChar;
    Format: HTTP_LOGGING_TYPE;
    Fields: ULONG;
    pExtFields: pointer;
    NumOfExtFields: word;
    MaxRecordSize: word;
    RolloverType: HTTP_LOGGING_ROLLOVER_TYPE;
    RolloverSize: ULONG;
    pSecurityDescriptor: PSECURITY_DESCRIPTOR;
  end;
  PHTTP_LOGGING_INFO = ^HTTP_LOGGING_INFO;

  HTTP_LOG_DATA_TYPE = (
    HttpLogDataTypeFields
    );

  HTTP_LOG_DATA = record
    Typ: HTTP_LOG_DATA_TYPE
  end;
  PHTTP_LOG_DATA = ^HTTP_LOG_DATA;

  HTTP_LOG_FIELDS_DATA = record
    Base: HTTP_LOG_DATA;
    UserNameLength: word;
    UriStemLength: word;
    ClientIpLength: word;
    ServerNameLength: word;
    ServiceNameLength: word;
    ServerIpLength: word;
    MethodLength: word;
    UriQueryLength: word;
    HostLength: word;
    UserAgentLength: word;
    CookieLength: word;
    ReferrerLength: word;
    UserName: PWideChar;
    UriStem: PWideChar;
    ClientIp: PAnsiChar;
    ServerName: PAnsiChar;
    ServiceName: PAnsiChar;
    ServerIp: PAnsiChar;
    Method: PAnsiChar;
    UriQuery: PAnsiChar;
    Host: PAnsiChar;
    UserAgent: PAnsiChar;
    Cookie: PAnsiChar;
    Referrer: PAnsiChar;
    ServerPort: word;
    ProtocolStatus: word;
    Win32Status: ULONG;
    MethodNum: THttpVerb;
    SubStatus: word;
  end;
  PHTTP_LOG_FIELDS_DATA = ^HTTP_LOG_FIELDS_DATA;

  HTTP_BINDING_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    RequestQueueHandle: THandle;
  end;

  HTTP_PROTECTION_LEVEL_TYPE=(
    HttpProtectionLevelUnrestricted,
    HttpProtectionLevelEdgeRestricted,
    HttpProtectionLevelRestricted
    );

  HTTP_PROTECTION_LEVEL_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    Level: HTTP_PROTECTION_LEVEL_TYPE;
  end;
  PHTTP_PROTECTION_LEVEL_INFO = ^HTTP_PROTECTION_LEVEL_INFO;

const
  HTTP_VERSION_UNKNOWN: HTTP_VERSION = (MajorVersion: 0; MinorVersion: 0);
  HTTP_VERSION_0_9: HTTP_VERSION = (MajorVersion: 0; MinorVersion: 9);
  HTTP_VERSION_1_0: HTTP_VERSION = (MajorVersion: 1; MinorVersion: 0);
  HTTP_VERSION_1_1: HTTP_VERSION = (MajorVersion: 1; MinorVersion: 1);
  /// error raised by HTTP API when the client disconnected (e.g. after timeout)
  HTTPAPI_ERROR_NONEXISTENTCONNECTION = 1229;
  // if set, available entity body is copied along with the request headers
  // into pEntityChunks
  HTTP_RECEIVE_REQUEST_FLAG_COPY_BODY = 1;
  // there is more entity body to be read for this request
  HTTP_REQUEST_FLAG_MORE_ENTITY_BODY_EXISTS = 1;
  // initialization for applications that use the HTTP Server API
  HTTP_INITIALIZE_SERVER = 1;
  // initialization for applications that use the HTTP configuration functions
  HTTP_INITIALIZE_CONFIG = 2;
  // see http://msdn.microsoft.com/en-us/library/windows/desktop/aa364496
  HTTP_RECEIVE_REQUEST_ENTITY_BODY_FLAG_FILL_BUFFER = 1;
  // see http://msdn.microsoft.com/en-us/library/windows/desktop/aa364499
  HTTP_SEND_RESPONSE_FLAG_PROCESS_RANGES = 1;
  // flag which can be used by HttpRemoveUrlFromUrlGroup() 
  HTTP_URL_FLAG_REMOVE_ALL = 1;

function RetrieveHeaders(const Request: HTTP_REQUEST): RawByteString;
const
  KNOWNHEADERS: array[reqCacheControl..reqUserAgent] of string[19] = (
    'Cache-Control','Connection','Date','Keep-Alive','Pragma','Trailer',
    'Transfer-Encoding','Upgrade','Via','Warning','Allow','Content-Length',
    'Content-Type','Content-Encoding','Content-Language','Content-Location',
    'Content-MD5','Content-Range','Expires','Last-Modified','Accept',
    'Accept-Charset','Accept-Encoding','Accept-Language','Authorization',
    'Cookie','Expect','From','Host','If-Match','If-Modified-Since',
    'If-None-Match','If-Range','If-Unmodified-Since','Max-Forwards',
    'Proxy-Authorization','Referer','Range','TE','Translate','User-Agent');
  REMOTEIP_HEADERLEN = 10;
  REMOTEIP_HEADER: string[REMOTEIP_HEADERLEN] = 'RemoteIP: ';
  CONNECTIONID_HEADERLEN = 14;
  CONNECTIONID_HEADER: string[CONNECTIONID_HEADERLEN] = 'ConnectionID: ';
var i, L: integer;
    H: THttpHeader;
    P: PHTTP_UNKNOWN_HEADER;
    D: PAnsiChar;
    RemoteIP: RawByteString;
    ConnectionID: ShortString;
begin
  assert(low(KNOWNHEADERS)=low(Request.Headers.KnownHeaders));
  assert(high(KNOWNHEADERS)=high(Request.Headers.KnownHeaders));
  if Request.Address.pRemoteAddress<>nil then
    GetSinIPFromCache(PVarSin(Request.Address.pRemoteAddress)^,RemoteIP);
  BinToHexDisplay(@Request.ConnectionId,8,ConnectionID);
  // compute headers length
  if RemoteIP<>'' then
    L := (REMOTEIP_HEADERLEN+2)+length(RemoteIP) else
    L := 0;
  inc(L,(CONNECTIONID_HEADERLEN+2)+ord(ConnectionID[0]));
  for H := low(KNOWNHEADERS) to high(KNOWNHEADERS) do
    if Request.Headers.KnownHeaders[H].RawValueLength<>0 then
      inc(L,Request.Headers.KnownHeaders[H].RawValueLength+ord(KNOWNHEADERS[H][0])+4);
  P := Request.Headers.pUnknownHeaders;
  if P<>nil then
    for i := 1 to Request.Headers.UnknownHeaderCount do begin
      inc(L,P^.NameLength+P^.RawValueLength+4); // +4 for each ': '+#13#10
      inc(P);
    end;
  // set headers content
  SetString(result,nil,L);
  D := pointer(result);
  for H := low(KNOWNHEADERS) to high(KNOWNHEADERS) do
    if Request.Headers.KnownHeaders[H].RawValueLength<>0 then begin
      move(KNOWNHEADERS[H][1],D^,ord(KNOWNHEADERS[H][0]));
      inc(D,ord(KNOWNHEADERS[H][0]));
      PWord(D)^ := ord(':')+ord(' ')shl 8;
      inc(D,2);
      move(Request.Headers.KnownHeaders[H].pRawValue^,D^,
        Request.Headers.KnownHeaders[H].RawValueLength);
      inc(D,Request.Headers.KnownHeaders[H].RawValueLength);
      PWord(D)^ := 13+10 shl 8;
      inc(D,2);
    end;
  P := Request.Headers.pUnknownHeaders;
  if P<>nil then
    for i := 1 to Request.Headers.UnknownHeaderCount do begin
      move(P^.pName^,D^,P^.NameLength);
      inc(D,P^.NameLength);
      PWord(D)^ := ord(':')+ord(' ')shl 8;
      inc(D,2);
      move(P^.pRawValue^,D^,P^.RawValueLength);
      inc(D,P^.RawValueLength);
      inc(P);
      PWord(D)^ := 13+10 shl 8;
      inc(D,2);
    end;
  if RemoteIP<>'' then begin
    move(REMOTEIP_HEADER[1],D^,REMOTEIP_HEADERLEN);
    inc(D,REMOTEIP_HEADERLEN);
    move(pointer(RemoteIP)^,D^,length(RemoteIP));
    inc(D,length(RemoteIP));
    PWord(D)^ := 13+10 shl 8;
    inc(D,2);
  end;
  move(CONNECTIONID_HEADER[1],D^,CONNECTIONID_HEADERLEN);
  inc(D,CONNECTIONID_HEADERLEN);
  move(ConnectionID[1],D^,ord(ConnectionID[0]));
  inc(D,ord(ConnectionID[0]));
  PWord(D)^ := 13+10 shl 8;
  {$ifopt C+}         
  inc(D,2);
  assert(D-pointer(result)=L);
  {$endif}
end;

type
  HTTP_SERVER_PROPERTY = (
    HttpServerAuthenticationProperty,
    HttpServerLoggingProperty,
    HttpServerQosProperty,
    HttpServerTimeoutsProperty,
    HttpServerQueueLengthProperty,
    HttpServerStateProperty,
    HttpServer503VerbosityProperty,
    HttpServerBindingProperty,
    HttpServerExtendedAuthenticationProperty,
    HttpServerListenEndpointProperty,
    HttpServerChannelBindProperty,
    HttpServerProtectionLevelProperty
    );

  /// direct late-binding access to the HTTP API server 1.0 or 2.0  
  THttpAPI = packed record
    /// access to the httpapi.dll loaded library 
    Module: THandle;
    /// will be either 1.0 or 2.0, depending on the published .dll functions 
    Version: HTTP_VERSION;
    {/ The HttpInitialize function initializes the HTTP Server API driver, starts it,
    if it has not already been started, and allocates data structures for the
    calling application to support response-queue creation and other operations.
    Call this function before calling any other functions in the HTTP Server API. }
    Initialize: function(Version: HTTP_VERSION; Flags: cardinal;
      pReserved: pointer=nil): HRESULT; stdcall;
    {/ The HttpTerminate function cleans up resources used by the HTTP Server API
    to process calls by an application. An application should call HttpTerminate
    once for every time it called HttpInitialize, with matching flag settings. }
    Terminate: function(Flags: cardinal;
      Reserved: integer=0): HRESULT; stdcall;
    {/ The HttpCreateHttpHandle function creates an HTTP request queue for the
    calling application and returns a handle to it. }
    CreateHttpHandle: function(var ReqQueueHandle: THandle;
      Reserved: integer=0): HRESULT; stdcall;
    {/ The HttpAddUrl function registers a given URL so that requests that match
    it are routed to a specified HTTP Server API request queue. An application
    can register multiple URLs to a single request queue using repeated calls to
    HttpAddUrl.
    - a typical url prefix is 'http://+:80/vroot/', 'https://+:80/vroot/' or
      'https://adatum.com:443/secure/database/' - here the '+' is called a
      Strong wildcard, i.e. will match every IP or server name }
    AddUrl: function(ReqQueueHandle: THandle; UrlPrefix: PWideChar;
      Reserved: integer=0): HRESULT; stdcall;
    {/ Unregisters a specified URL, so that requests for it are no longer
      routed to a specified queue. }
    RemoveUrl: function(ReqQueueHandle: THandle; UrlPrefix: PWideChar): HRESULT; stdcall;
    {/ retrieves the next available HTTP request from the specified request queue }
    ReceiveHttpRequest: function(ReqQueueHandle: THandle; RequestId: HTTP_REQUEST_ID;
      Flags: cardinal; var pRequestBuffer: HTTP_REQUEST; RequestBufferLength: ULONG;
      var pBytesReceived: ULONG; pOverlapped: pointer=nil): HRESULT; stdcall;
    {/ sent the response to a specified HTTP request }
    SendHttpResponse: function(ReqQueueHandle: THandle; RequestId: HTTP_REQUEST_ID;
      Flags: integer; var pHttpResponse: HTTP_RESPONSE; pReserved1: pointer;
      var pBytesSent: cardinal; pReserved2: pointer=nil; Reserved3: ULONG=0;
      pOverlapped: pointer=nil; pReserved4: pointer=nil): HRESULT; stdcall;
    {/ receives additional entity body data for a specified HTTP request }
    ReceiveRequestEntityBody: function(ReqQueueHandle: THandle; RequestId: HTTP_REQUEST_ID;
      Flags: ULONG; pBuffer: pointer; BufferLength: cardinal; var pBytesReceived: cardinal;
      pOverlapped: pointer=nil): HRESULT; stdcall;
    {/ set specified data, such as IP addresses or SSL Certificates, from the
      HTTP Server API configuration store}
    SetServiceConfiguration: function(ServiceHandle: THandle;
      ConfigId: THttpServiceConfigID; pConfigInformation: pointer;
      ConfigInformationLength: ULONG; pOverlapped: pointer=nil): HRESULT; stdcall;
    {/ deletes specified data, such as IP addresses or SSL Certificates, from the
      HTTP Server API configuration store}
    DeleteServiceConfiguration: function(ServiceHandle: THandle;
      ConfigId: THttpServiceConfigID; pConfigInformation: pointer;
      ConfigInformationLength: ULONG; pOverlapped: pointer=nil): HRESULT; stdcall;
    /// removes from the HTTP Server API cache associated with a given request
    // queue all response fragments that have a name whose site portion matches
    // a specified UrlPrefix
    FlushResponseCache: function(ReqQueueHandle: THandle; pUrlPrefix: PWideChar; Flags: ULONG;
      pOverlapped: POverlapped): ULONG; stdcall;
    /// cancels a specified request
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    CancelHttpRequest: function(ReqQueueHandle: THandle; RequestId: HTTP_REQUEST_ID;
      pOverlapped: pointer = nil): HRESULT; stdcall;
    /// creates a server session for the specified HTTP API version
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    CreateServerSession: function(Version: HTTP_VERSION;
      var ServerSessionId: HTTP_SERVER_SESSION_ID; Reserved: ULONG = 0): HRESULT; stdcall;
    /// deletes the server session identified by the server session ID
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    CloseServerSession: function(ServerSessionId: HTTP_SERVER_SESSION_ID): HRESULT; stdcall;
    ///  creates a new request queue or opens an existing request queue
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    // - replaces the HTTP version 1.0 CreateHttpHandle() function
    CreateRequestQueue: function(Version: HTTP_VERSION;
      pName: PWideChar; pSecurityAttributes: Pointer;
      Flags: ULONG; var ReqQueueHandle: THandle): HRESULT; stdcall;
    /// sets a new server session property or modifies an existing property
    // on the specified server session
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    SetServerSessionProperty: function(ServerSessionId: HTTP_SERVER_SESSION_ID;
      aProperty: HTTP_SERVER_PROPERTY; pPropertyInformation: Pointer;
      PropertyInformationLength: ULONG): HRESULT; stdcall;
    /// queries a server property on the specified server session
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    QueryServerSessionProperty: function(ServerSessionId: HTTP_SERVER_SESSION_ID;
      aProperty: HTTP_SERVER_PROPERTY; pPropertyInformation: Pointer;
      PropertyInformationLength: ULONG; pReturnLength: PULONG = nil): HRESULT; stdcall;
    /// creates a URL Group under the specified server session
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    CreateUrlGroup: function(ServerSessionId: HTTP_SERVER_SESSION_ID;
      var UrlGroupId: HTTP_URL_GROUP_ID; Reserved: ULONG = 0): HRESULT; stdcall;
    /// closes the URL Group identified by the URL Group ID
    // - this call also removes all of the URLs that are associated with
    // the URL Group
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    CloseUrlGroup: function(UrlGroupId: HTTP_URL_GROUP_ID): HRESULT; stdcall;
    /// adds the specified URL to the URL Group identified by the URL Group ID
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    // - this function replaces the HTTP version 1.0 AddUrl() function
    AddUrlToUrlGroup: function(UrlGroupId: HTTP_URL_GROUP_ID;
      pFullyQualifiedUrl: PWideChar; UrlContext: HTTP_URL_CONTEXT = 0;
      Reserved: ULONG = 0): HRESULT; stdcall;
    /// removes the specified URL from the group identified by the URL Group ID
    // - this function removes one, or all, of the URLs from the group
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    // - it replaces the HTTP version 1.0 RemoveUrl() function
    RemoveUrlFromUrlGroup: function(UrlGroupId: HTTP_URL_GROUP_ID;
      pFullyQualifiedUrl: PWideChar; Flags: ULONG): HRESULT; stdcall;
    /// sets a new property or modifies an existing property on the specified
    // URL Group
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    SetUrlGroupProperty: function(UrlGroupId: HTTP_URL_GROUP_ID;
      aProperty: HTTP_SERVER_PROPERTY; pPropertyInformation: Pointer;
      PropertyInformationLength: ULONG): HRESULT; stdcall;
    /// queries a property on the specified URL Group
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    QueryUrlGroupProperty: function(UrlGroupId: HTTP_URL_GROUP_ID;
      aProperty: HTTP_SERVER_PROPERTY; pPropertyInformation: Pointer;
      PropertyInformationLength: ULONG; pReturnLength: PULONG = nil): HRESULT; stdcall;
    /// sets a new property or modifies an existing property on the request
    // queue identified by the specified handle
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    SetRequestQueueProperty: function(ReqQueueHandle: THandle;
      aProperty: HTTP_SERVER_PROPERTY; pPropertyInformation: Pointer;
      PropertyInformationLength: ULONG; Reserved: ULONG; pReserved: Pointer): HRESULT; stdcall;
    ///  queries a property of the request queue identified by the
    // specified handle
    // - available only for HTTP API 2.0 (since Windows Vista / Server 2008)
    QueryRequestQueueProperty: function(ReqQueueHandle: THandle;
      aProperty: HTTP_SERVER_PROPERTY; pPropertyInformation: Pointer;
      PropertyInformationLength: ULONG; Reserved: ULONG; pReturnLength: PULONG; pReserved: Pointer): HRESULT; stdcall;
  end;

var
  Http: THttpAPI;

type
  THttpAPIs = (hInitialize,hTerminate,hCreateHttpHandle,
    hAddUrl, hRemoveUrl, hReceiveHttpRequest,
    hSendHttpResponse, hReceiveRequestEntityBody,
    hSetServiceConfiguration, hDeleteServiceConfiguration, hFlushResponseCache,
    hCancelHttpRequest,
    hCreateServerSession, hCloseServerSession,
    hCreateRequestQueue,
    hSetServerSessionProperty, hQueryServerSessionProperty,
    hCreateUrlGroup, hCloseUrlGroup,
    hAddUrlToUrlGroup, hRemoveUrlFromUrlGroup,
    hSetUrlGroupProperty, hQueryUrlGroupProperty,
    hSetRequestQueueProperty, hQueryRequestQueueProperty
    );
const
  hHttpApi2First = hCancelHttpRequest;
  
  HttpNames: array[THttpAPIs] of PChar = (
    'HttpInitialize','HttpTerminate','HttpCreateHttpHandle',
    'HttpAddUrl', 'HttpRemoveUrl', 'HttpReceiveHttpRequest',
    'HttpSendHttpResponse', 'HttpReceiveRequestEntityBody',
    'HttpSetServiceConfiguration', 'HttpDeleteServiceConfiguration',
    'HttpFlushResponseCache',
    'HttpCancelHttpRequest',
    'HttpCreateServerSession', 'HttpCloseServerSession',
    'HttpCreateRequestQueue',
    'HttpSetServerSessionProperty', 'HttpQueryServerSessionProperty',
    'HttpCreateUrlGroup', 'HttpCloseUrlGroup',
    'HttpAddUrlToUrlGroup', 'HttpRemoveUrlFromUrlGroup',
    'HttpSetUrlGroupProperty', 'HttpQueryUrlGroupProperty',
    'HttpSetRequestQueueProperty', 'HttpQueryRequestQueueProperty'
    );

function RegURL(aRoot, aPort: RawByteString; Https: boolean;
  aDomainName: RawByteString): SynUnicode;
const Prefix: array[boolean] of RawByteString = ('http://','https://');
begin
  if aPort='' then
    aPort := '80';
  aRoot := trim(aRoot);
  aDomainName := trim(aDomainName);
  if aDomainName='' then begin
    result := '';
    exit;
  end;
  if aRoot<>'' then begin
    if aRoot[1]<>'/' then
      insert('/',aRoot,1);
    if aRoot[length(aRoot)]<>'/' then
      aRoot := aRoot+'/';
  end else
    aRoot := '/'; // allow for instance 'http://*:2869/'
  aRoot := Prefix[Https]+aDomainName+':'+aPort+aRoot;
  result := SynUnicode(aRoot);
end;

const
  HTTPAPI_DLL = 'httpapi.dll';

procedure HttpApiInitialize;
var api: THttpAPIs;
    P: PPointer;
begin
  if Http.Module<>0 then
    exit; // already loaded
  try
    if Http.Module=0 then begin
      Http.Module := LoadLibrary(HTTPAPI_DLL);
      Http.Version.MajorVersion := 2; // API 2.0 if all functions are available
      if Http.Module<=255 then
        raise Exception.CreateFmt('Unable to find %s',[HTTPAPI_DLL]);
      {$ifdef FPC}
      P := @Http.Initialize;
      {$else}
      P := @@Http.Initialize;
      {$endif}
      for api := low(api) to high(api) do begin
        P^ := GetProcAddress(Http.Module,HttpNames[api]);
        if P^=nil then
          if api<hHttpApi2First then
            raise Exception.CreateFmt('Unable to find "%s" in %s',[HttpNames[api],HTTPAPI_DLL]) else
            Http.Version.MajorVersion := 1; // e.g. Windows XP or Server 2003
        inc(P);
      end;
    end;
  except
    on E: Exception do begin
      if Http.Module>255 then begin
        FreeLibrary(Http.Module);
        Http.Module := 0;
      end;
      raise E;
    end;
  end;
end;


{ EHttpApiServer }

type
  EHttpApiServer = class(Exception)
  protected
    fLastError: integer;
    fLastApi: THttpAPIs;
  public
    class procedure RaiseOnError(api: THttpAPIs; Error: integer);
    constructor Create(api: THttpAPIs; Error: integer);
    property LastApi: THttpAPIs read fLastApi;
    property LastError: integer read fLastError;
  end;

class procedure EHttpApiServer.RaiseOnError(api: THttpAPIs; Error: integer);
begin
  if Error<>NO_ERROR then
    raise self.Create(api,Error);
end;

constructor EHttpApiServer.Create(api: THttpAPIs; Error: integer);
begin
  fLastError := Error;
  fLastApi := api;
  inherited CreateFmt('%s failed: %s (%d)',
    [HttpNames[api],SysErrorMessagePerModule(Error,HTTPAPI_DLL),Error])
end;


{ THttpApiServer }

function THttpApiServer.AddUrl(const aRoot, aPort: RawByteString; Https: boolean;
  const aDomainName: RawByteString; aRegisterURI: boolean): integer;
var uri: SynUnicode;
    n: integer;
begin
  result := -1;
  if (Self=nil) or (fReqQueue=0) or (Http.Module=0) then
    exit;
  uri := RegURL(aRoot, aPort, Https, aDomainName);
  if uri='' then
    exit; // invalid parameters
  if aRegisterURI then
    AddUrlAuthorize(aRoot,aPort,Https,aDomainName);
  if Http.Version.MajorVersion>1 then
    result := Http.AddUrlToUrlGroup(fUrlGroupID,pointer(uri)) else
    result := Http.AddUrl(fReqQueue,pointer(uri));
  if result=NO_ERROR then begin
    n := length(fRegisteredUnicodeUrl);
    SetLength(fRegisteredUnicodeUrl,n+1);
    fRegisteredUnicodeUrl[n] := uri;
  end;
end;

function THttpApiServer.RemoveUrl(const aRoot, aPort: RawByteString; Https: boolean;
  const aDomainName: RawByteString): integer;
var uri: SynUnicode;
    i,j,n: integer;
begin
  result := -1;
  if (Self=nil) or (fReqQueue=0) or (Http.Module=0) then
    exit;
  uri := RegURL(aRoot, aPort, Https, aDomainName);
  if uri='' then
    exit; // invalid parameters
  n := High(fRegisteredUnicodeUrl);
  for i := 0 to n do
    if fRegisteredUnicodeUrl[i]=uri then begin
      if Http.Version.MajorVersion>1 then
        result := Http.RemoveUrlFromUrlGroup(fUrlGroupID,pointer(uri),0) else
        result := Http.RemoveUrl(fReqQueue,pointer(uri));
      if result<>0 then
        exit; // shall be handled by caller
      for j := i to n-1 do
        fRegisteredUnicodeUrl[j] := fRegisteredUnicodeUrl[j+1];
      SetLength(fRegisteredUnicodeUrl,n);
      exit;
    end;
end;

class function THttpApiServer.AddUrlAuthorize(const aRoot, aPort: RawByteString;
  Https: boolean; const aDomainName: RawByteString; OnlyDelete: boolean): string;
const
  /// will allow AddUrl() registration to everyone
  // - 'GA' (GENERIC_ALL) to grant all access
  // - 'S-1-1-0'	defines a group that includes all users
  HTTPADDURLSECDESC: PWideChar = 'D:(A;;GA;;;S-1-1-0)';
var prefix: SynUnicode;
    Error: HRESULT;
    Config: HTTP_SERVICE_CONFIG_URLACL_SET;
begin
  try
    HttpApiInitialize;
    prefix := RegURL(aRoot, aPort, Https, aDomainName);
    if prefix='' then
      result := 'Invalid parameters' else begin
      EHttpApiServer.RaiseOnError(hInitialize,Http.Initialize(
        Http.Version,HTTP_INITIALIZE_CONFIG));
      try
        fillchar(Config,sizeof(Config),0);
        Config.KeyDesc.pUrlPrefix := pointer(prefix);
        // first delete any existing information
        Error := Http.DeleteServiceConfiguration(0,hscUrlAclInfo,@Config,Sizeof(Config));
        // then add authorization rule
        if not OnlyDelete then begin
          Config.KeyDesc.pUrlPrefix := pointer(prefix);
          Config.ParamDesc.pStringSecurityDescriptor := HTTPADDURLSECDESC;
          Error := Http.SetServiceConfiguration(0,hscUrlAclInfo,@Config,Sizeof(Config));
        end;
        if (Error<>NO_ERROR) and (Error<>ERROR_ALREADY_EXISTS) then
          raise EHttpApiServer.Create(hSetServiceConfiguration,Error);
        result := ''; // success
      finally
        Http.Terminate(HTTP_INITIALIZE_CONFIG);
      end;
    end;
  except
    on E: Exception do
      result := E.Message;
  end;
end;

procedure THttpApiServer.Clone(ChildThreadCount: integer);
var i: integer;
begin
  if (fReqQueue=0) or not Assigned(OnRequest) or (ChildThreadCount<=0) then
    exit; // nothing to clone (need a queue and a process event)
  if ChildThreadCount>256 then
    ChildThreadCount := 256; // not worth adding
  for i := 1 to ChildThreadCount do
    fClones.Add(THttpApiServer.CreateClone(self));
end;

function THttpApiServer.GetAPIVersion: string;
begin
  result := Format('HTTP API %d.%d',[Http.Version.MajorVersion,Http.Version.MinorVersion]);
end;

constructor THttpApiServer.Create(CreateSuspended: Boolean);
var bindInfo: HTTP_BINDING_INFO;
begin
  inherited Create(true);
  HttpApiInitialize; // will raise an exception in case of failure
  EHttpApiServer.RaiseOnError(hInitialize,
    Http.Initialize(Http.Version,HTTP_INITIALIZE_SERVER));
  if Http.Version.MajorVersion>1 then begin
    EHttpApiServer.RaiseOnError(hCreateServerSession,Http.CreateServerSession(
      Http.Version,fServerSessionID));
    EHttpApiServer.RaiseOnError(hCreateUrlGroup,Http.CreateUrlGroup(
      fServerSessionID,fUrlGroupID));
    EHttpApiServer.RaiseOnError(hCreateRequestQueue,Http.CreateRequestQueue(
      Http.Version,pointer(BinToHexDisplayW(@fServerSessionID,SizeOf(fServerSessionID))),
      nil,0,fReqQueue));
    bindInfo.Flags := 1;
    bindInfo.RequestQueueHandle := FReqQueue;
    EHttpApiServer.RaiseOnError(hSetUrlGroupProperty,Http.SetUrlGroupProperty(
      fUrlGroupID,HttpServerBindingProperty,@bindInfo,SizeOf(bindInfo)));
  end else
    EHttpApiServer.RaiseOnError(hCreateHttpHandle,Http.CreateHttpHandle(fReqQueue));
  fClones := TObjectList.Create;
  if not CreateSuspended then
    Suspended := False;
end;

constructor THttpApiServer.CreateClone(From: THttpApiServer);
begin
  inherited Create(false);
  fOwner := From;
  fReqQueue := From.fReqQueue;
  fOnRequest := From.fOnRequest;
  fCompress := From.fCompress;
  fCompressAcceptEncoding := From.fCompressAcceptEncoding;
  OnHttpThreadStart := From.OnHttpThreadStart;
  OnHttpThreadTerminate := From.OnHttpThreadTerminate;
end;

destructor THttpApiServer.Destroy;
var i: integer;
begin
  if (fClones<>nil) and (Http.Module<>0) then begin  // fClones=nil for clone threads
    if fReqQueue<>0 then begin
      if Http.Version.MajorVersion>1 then begin
       if fUrlGroupID<>0 then begin
         Http.RemoveUrlFromUrlGroup(fUrlGroupID,nil,HTTP_URL_FLAG_REMOVE_ALL);
         Http.CloseUrlGroup(fUrlGroupID);
         fUrlGroupID := 0;
       end;
       CloseHandle(FReqQueue);
       if fServerSessionID<>0 then begin
         Http.CloseServerSession(fServerSessionID);
         fServerSessionID := 0;
       end;
      end else begin
        for i := 0 to high(fRegisteredUnicodeUrl) do
          Http.RemoveUrl(fReqQueue,pointer(fRegisteredUnicodeUrl[i]));
        CloseHandle(fReqQueue); // will break all THttpApiServer.Execute
      end;
      fReqQueue := 0;
      FreeAndNil(fClones);
      Http.Terminate(HTTP_INITIALIZE_SERVER);
    end;
    {$ifdef LVCL}
    Sleep(500); // LVCL TThread does not wait for its completion -> do it now
    {$endif}
  end;
  inherited Destroy;
end;

const
  VERB_TEXT: array[hvOPTIONS..hvSEARCH] of RawByteString = (
    'OPTIONS', 'GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'TRACE',
    'CONNECT', 'TRACK', 'MOVE', 'COPY', 'PROPFIND', 'PROPPATCH',
    'MKCOL', 'LOCK', 'UNLOCK', 'SEARCH');
   
procedure THttpApiServer.Execute;
var Req: PHTTP_REQUEST;
    ReqID: HTTP_REQUEST_ID;
    ReqBuf, RespBuf: RawByteString;
    i: integer;
    flags, bytesRead, bytesSent: cardinal;
    Err: HRESULT;
    InCompressAccept: THttpSocketCompressSet;
    InContentLength, InContentLengthRead: cardinal;
    InContentEncoding, InAcceptEncoding, Range: RawByteString;
    OutContentEncoding, OutStatus: RawByteString;
    Context: THttpServerRequest;
    FileHandle: THandle;
    Resp: PHTTP_RESPONSE;
    BufRead, R: PAnsiChar;
    Heads: HTTP_UNKNOWN_HEADERs;
    RangeStart, RangeLength: Int64;
    DataChunkInMemory: HTTP_DATA_CHUNK_INMEMORY;
    DataChunkFile: HTTP_DATA_CHUNK_FILEHANDLE;

  procedure SendError(StatusCode: cardinal; const ErrorMsg: string; E: Exception=nil);
  var Msg: string;
  begin
    try
      Resp^.SetStatus(StatusCode,OutStatus);
      Msg := format(
        '<html><body style="font-family:verdana;"><h1>Server Error %d: %s</h1><p>',
        [StatusCode,OutStatus]);
      if E<>nil then
        Msg := Msg+string(E.ClassName)+' Exception raised:<br>';
      Resp^.SetContent(DataChunkInMemory,UTF8String(Msg)+HtmlEncode(
        {$ifdef UNICODE}UTF8String{$else}UTF8Encode{$endif}(ErrorMsg))+
        '</p><p><small>'+XPOWEREDVALUE,
        'text/html; charset=utf-8');
      Http.SendHttpResponse(fReqQueue,Req^.RequestId,0,Resp^,nil,bytesSent);
    except
      on Exception do
        ; // ignore any HttpApi level errors here (client may crashed)
    end;
  end;

begin
  // THttpServerGeneric thread preparation: launch any OnHttpThreadStart event
  NotifyThreadStart(self);
  // reserve working buffers
  SetLength(Heads,64);
  SetLength(RespBuf,sizeof(Resp^));
  Resp := pointer(RespBuf);
  SetLength(ReqBuf,16384+sizeof(HTTP_REQUEST)); // space for Req^ + 16 KB of headers
  Req := pointer(ReqBuf);
  Context := THttpServerRequest.Create(self,self);
  try
    // main loop
    ReqID := 0;
    Context.fServer := self;
    repeat
      // retrieve next pending request, and read its headers
      fillchar(Req^,sizeof(HTTP_REQUEST),0);
      Err := Http.ReceiveHttpRequest(fReqQueue,ReqID,0,Req^,length(ReqBuf),bytesRead);
      if Terminated then
        break;
      case Err of
      NO_ERROR:
      try
        // parse method and headers
        Context.fURL := Req^.pRawUrl;
        if Req^.Verb in [low(VERB_TEXT)..high(VERB_TEXT)] then
          Context.fMethod := VERB_TEXT[Req^.Verb] else
          SetString(Context.fMethod,Req^.pUnknownVerb,Req^.UnknownVerbLength);
        with Req^.Headers.KnownHeaders[reqContentType] do
          SetString(Context.fInContentType,pRawValue,RawValueLength);
        with Req^.Headers.KnownHeaders[reqAcceptEncoding] do
          SetString(InAcceptEncoding,pRawValue,RawValueLength);
        InCompressAccept := ComputeContentEncoding(fCompress,pointer(InAcceptEncoding));
        Context.fInHeaders := RetrieveHeaders(Req^);
        // retrieve body
        Context.fInContent := '';
        if HTTP_REQUEST_FLAG_MORE_ENTITY_BODY_EXISTS and Req^.Flags<>0 then begin
          with Req^.Headers.KnownHeaders[reqContentLength] do
            InContentLength := GetCardinal(pRawValue,pRawValue+RawValueLength);
          if InContentLength<>0 then begin
            SetLength(Context.fInContent,InContentLength);
            BufRead := pointer(Context.InContent);
            InContentLengthRead := 0;
            repeat
              BytesRead := 0;
              if Http.Version.MajorVersion>1 then // speed optimization for Vista+
                flags := HTTP_RECEIVE_REQUEST_ENTITY_BODY_FLAG_FILL_BUFFER else
                flags := 0;
              Err := Http.ReceiveRequestEntityBody(fReqQueue,Req^.RequestId,flags,
                BufRead,InContentLength-InContentLengthRead,BytesRead);
              inc(InContentLengthRead,BytesRead);
              if Err=ERROR_HANDLE_EOF then begin
                if InContentLengthRead<InContentLength then
                  SetLength(Context.fInContent,InContentLengthRead);
                Err := NO_ERROR;
                break; // should loop until returns ERROR_HANDLE_EOF
              end;
              if Err<>NO_ERROR then
                break;
              inc(BufRead,BytesRead);
            until InContentLengthRead=InContentLength;
            if Err<>NO_ERROR then begin
              SendError(406,SysErrorMessagePerModule(Err,HTTPAPI_DLL));
              continue;
            end;
            with Req^.Headers.KnownHeaders[reqContentEncoding] do
            if RawValueLength<>0 then begin
              SetString(InContentEncoding,pRawValue,RawValueLength);
              for i := 0 to high(fCompress) do
                if fCompress[i].Name=InContentEncoding then begin
                  fCompress[i].Func(Context.fInContent,false); // uncompress
                  break;
                end;
            end;
          end;
        end;
        try
          // compute response
          Context.OutContent := '';
          Context.OutContentType := '';
          Context.OutCustomHeaders := '';
          fillchar(Resp^,sizeof(Resp^),0);
          Resp^.SetStatus(Request(Context),OutStatus);
          if Terminated then
            exit;
          // send response
          Resp^.Version := Req^.Version;
          Resp^.SetHeaders(pointer(Context.OutCustomHeaders),Heads);
          if fCompressAcceptEncoding<>'' then
            Resp^.AddCustomHeader(pointer(fCompressAcceptEncoding),Heads);
          if Context.OutContentType=HTTP_RESP_STATICFILE then begin
            // response is file -> OutContent is UTF-8 file name to be served
            FileHandle := FileOpen(
              {$ifdef UNICODE}UTF8ToUnicodeString{$else}Utf8ToAnsi{$endif}(Context.OutContent),
              fmOpenRead or fmShareDenyNone);
            if PtrInt(FileHandle)<0 then begin
              SendError(404,SysErrorMessage(GetLastError));
              continue;
            end;
            try // http.sys will serve then close the file from kernel
              DataChunkFile.DataChunkType := hctFromFileHandle;
              DataChunkFile.FileHandle := FileHandle;
              flags := 0;
              DataChunkFile.ByteRange.StartingOffset.QuadPart := 0;
              Int64(DataChunkFile.ByteRange.Length.QuadPart) := -1; // to eof
              with Req^.Headers.KnownHeaders[reqRange] do
                if (RawValueLength>6) and IdemPChar(pRawValue,'BYTES=') and
                   (pRawValue[6] in ['0'..'9']) then begin
                  SetString(Range,pRawValue+6,RawValueLength-6); // need #0 end
                  R := pointer(Range);
                  RangeStart := GetNextItemUInt64(R);
                  if R^='-' then begin
                    inc(R);
                    flags := HTTP_SEND_RESPONSE_FLAG_PROCESS_RANGES;
                    DataChunkFile.ByteRange.StartingOffset := ULARGE_INTEGER(RangeStart);
                    if R^ in ['0'..'9'] then begin
                      RangeLength := GetNextItemUInt64(R)-RangeStart+1;
                      if RangeLength>=0 then // "bytes=0-499" -> start=0, len=500
                        DataChunkFile.ByteRange.Length := ULARGE_INTEGER(RangeLength);
                    end; // "bytes=1000-" -> start=1000, len=-1 (to eof)
                  end;
                end;
              Resp^.EntityChunkCount := 1;
              Resp^.pEntityChunks := @DataChunkFile;
              Http.SendHttpResponse(fReqQueue,Req^.RequestId,flags,Resp^,nil,bytesSent);
            finally
              FileClose(FileHandle);
            end;
          end else begin
            // response is in OutContent -> sent it from memory
            if fCompress<>nil then begin
              with Resp^.Headers.KnownHeaders[reqContentEncoding] do
              if RawValueLength=0 then begin
                // no previous encoding -> try if any compression
                OutContentEncoding := CompressDataAndGetHeaders(InCompressAccept,
                  fCompress,Context.OutContentType,Context.fOutContent);
                pRawValue := pointer(OutContentEncoding);
                RawValueLength := length(OutContentEncoding);
              end;
            end;
            Resp^.SetContent(DataChunkInMemory,Context.OutContent,Context.OutContentType);
            EHttpApiServer.RaiseOnError(hSendHttpResponse,Http.SendHttpResponse(
              fReqQueue,Req^.RequestId,0,Resp^,nil,bytesSent));
          end;
        except
          on E: Exception do
            // handle any exception raised during process: show must go on!
            if not E.InheritsFrom(EHttpApiServer) or // ensure still connected
               (EHttpApiServer(E).LastError<>HTTPAPI_ERROR_NONEXISTENTCONNECTION) then
              SendError(500,E.Message,E);
        end;
      finally    
        ReqId := 0; // reset Request ID to handle the next pending request
      end;
      ERROR_MORE_DATA: begin
        // input buffer was too small to hold the request headers
        // -> increase buffer size and call the API again
        ReqID := Req^.RequestId;
        SetLength(ReqBuf,bytesRead);
        Req := pointer(ReqBuf);
      end;
      ERROR_CONNECTION_INVALID:
        if ReqID=0 then
          break else
          // TCP connection was corrupted by the peer -> ignore + next request
          ReqID := 0;
      else break; // unhandled Err value
      end;
    until Terminated;
  finally
    Context.Free;
  end;
end;

procedure THttpApiServer.RegisterCompress(aFunction: THttpSocketCompress;
  aCompressMinSize: integer=1024);
var i: integer;
begin
  inherited;
  if fClones<>nil then
    for i := 0 to fClones.Count-1 do
      THttpApiServer(fClones.List{$ifdef FPC}^{$endif}[i]).
        RegisterCompress(aFunction,aCompressMinSize);
end;

function THttpApiServer.GetHTTPQueueLength: Cardinal;
var returnLength: ULONG;
begin
  if (Http.Version.MajorVersion<2) or (self=nil) then
    result := 0 else begin
    if fOwner<>nil then
      self := fOwner;
    if fReqQueue=0 then
      result := 0 else
      EHttpApiServer.RaiseOnError(hQueryRequestQueueProperty,
        Http.QueryRequestQueueProperty(fReqQueue,HttpServerQueueLengthProperty,
          @Result, sizeof(Result), 0, @returnLength, nil));
  end;
end;

procedure THttpApiServer.SetHTTPQueueLength(aValue: Cardinal);
begin
  if Http.Version.MajorVersion<2 then
    raise EHttpApiServer.Create(hSetRequestQueueProperty, ERROR_OLD_WIN_VERSION);
  if (self<>nil) and (fReqQueue<>0) then
    EHttpApiServer.RaiseOnError(hSetRequestQueueProperty,
      Http.SetRequestQueueProperty(fReqQueue,HttpServerQueueLengthProperty,
        @aValue, sizeof(aValue), 0, nil));
end;

function THttpApiServer.GetRegisteredUrl: SynUnicode;
var i: integer;
begin
  if fRegisteredUnicodeUrl=nil then
    result := '' else
    result := fRegisteredUnicodeUrl[0];
  for i := 1 to high(fRegisteredUnicodeUrl) do
    result := result+','+fRegisteredUnicodeUrl[i];
end;

function THttpApiServer.GetCloned: boolean;
begin
  result := (fOwner<>nil);
end;

procedure THttpApiServer.SetMaxBandwidth(aValue: Cardinal);
var
   qosInfo: HTTP_QOS_SETTING_INFO;
   limitInfo: HTTP_BANDWIDTH_LIMIT_INFO;
begin
  if Http.Version.MajorVersion<2 then
    raise EHttpApiServer.Create(hSetUrlGroupProperty, ERROR_OLD_WIN_VERSION);
  if (self<>nil) and (fUrlGroupID<>0) then begin
    if AValue = 0 then
      limitInfo.MaxBandwidth := HTTP_LIMIT_INFINITE
    else if AValue < HTTP_MIN_ALLOWED_BANDWIDTH_THROTTLING_RATE then
      limitInfo.MaxBandwidth := HTTP_MIN_ALLOWED_BANDWIDTH_THROTTLING_RATE
    else
      limitInfo.MaxBandwidth := aValue;

    limitInfo.Flags := 1;
    qosInfo.QosType := HttpQosSettingTypeBandwidth;
    qosInfo.QosSetting := @limitInfo;

    EHttpApiServer.RaiseOnError(hSetServerSessionProperty,
      Http.SetServerSessionProperty(fServerSessionID, HttpServerQosProperty,
        @qosInfo, SizeOf(qosInfo)));

    EHttpApiServer.RaiseOnError(hSetUrlGroupProperty,
      Http.SetUrlGroupProperty(fUrlGroupID, HttpServerQosProperty,
        @qosInfo, SizeOf(qosInfo)));
  end;
end;

function THttpApiServer.GetMaxBandwidth: Cardinal;
var qosInfoGet: record
      qosInfo: HTTP_QOS_SETTING_INFO;
      limitInfo: HTTP_BANDWIDTH_LIMIT_INFO;
    end;
begin
  if (Http.Version.MajorVersion<2) or (self=nil) then begin
    result := 0;
    exit;
  end;
  if fOwner<>nil then
    self := fOwner;
  if fUrlGroupID=0 then begin
    result := 0;
    exit;
  end;
  qosInfoGet.qosInfo.QosType := HttpQosSettingTypeBandwidth;
  qosInfoGet.qosInfo.QosSetting := @qosInfoGet.limitInfo;
  EHttpApiServer.RaiseOnError(hQueryUrlGroupProperty,
    Http.QueryUrlGroupProperty(fUrlGroupID, HttpServerQosProperty,
      @qosInfoGet, SizeOf(qosInfoGet)));
  Result := qosInfoGet.limitInfo.MaxBandwidth;
end;

function THttpApiServer.GetMaxConnections: Cardinal;
var qosInfoGet: record
      qosInfo: HTTP_QOS_SETTING_INFO;
      limitInfo: HTTP_CONNECTION_LIMIT_INFO;
    end;
    returnLength: ULONG;
begin
  if (Http.Version.MajorVersion<2) or (self=nil) then begin
    result := 0;
    exit;
  end;
  if fOwner<>nil then
    self := fOwner;
  if fUrlGroupID=0 then begin
    result := 0;
    exit;
  end;
  qosInfoGet.qosInfo.QosType := HttpQosSettingTypeConnectionLimit;
  qosInfoGet.qosInfo.QosSetting := @qosInfoGet.limitInfo;
  EHttpApiServer.RaiseOnError(hQueryUrlGroupProperty,
    Http.QueryUrlGroupProperty(fUrlGroupID, HttpServerQosProperty,
      @qosInfoGet, SizeOf(qosInfoGet), @returnLength));
  Result := qosInfoGet.limitInfo.MaxConnections;
end;

procedure THttpApiServer.SetMaxConnections(aValue: Cardinal);
var qosInfo: HTTP_QOS_SETTING_INFO;
    limitInfo: HTTP_CONNECTION_LIMIT_INFO;
begin
  if Http.Version.MajorVersion<2 then
    raise EHttpApiServer.Create(hSetUrlGroupProperty, ERROR_OLD_WIN_VERSION);
  if (self<>nil) and (fUrlGroupID<>0) then begin
    if AValue = 0 then
      limitInfo.MaxConnections := HTTP_LIMIT_INFINITE else
      limitInfo.MaxConnections := aValue;
    limitInfo.Flags := 1;
    qosInfo.QosType := HttpQosSettingTypeConnectionLimit;
    qosInfo.QosSetting := @limitInfo;
    EHttpApiServer.RaiseOnError(hSetUrlGroupProperty,
      Http.SetUrlGroupProperty(fUrlGroupID, HttpServerQosProperty,
        @qosInfo, SizeOf(qosInfo)));
  end;
end;


{ HTTP_RESPONSE }

procedure HTTP_RESPONSE.SetContent(var DataChunk: HTTP_DATA_CHUNK_INMEMORY;
  const Content, ContentType: RawByteString);
begin
  fillchar(DataChunk,sizeof(DataChunk),0);
  if Content='' then
    exit;
  DataChunk.DataChunkType := hctFromMemory;
  DataChunk.pBuffer := pointer(Content);
  DataChunk.BufferLength := length(Content);
  EntityChunkCount := 1;
  pEntityChunks := @DataChunk;
  Headers.KnownHeaders[reqContentType].RawValueLength := length(ContentType);
  Headers.KnownHeaders[reqContentType].pRawValue := pointer(ContentType);
end;

function HTTP_RESPONSE.AddCustomHeader(P: PAnsiChar; var UnknownHeaders: HTTP_UNKNOWN_HEADERs): PAnsiChar;
const KNOWNHEADERS: array[reqCacheControl..respWwwAuthenticate] of PAnsiChar = (
    'CACHE-CONTROL:','CONNECTION:','DATE:','KEEP-ALIVE:','PRAGMA:','TRAILER:',
    'TRANSFER-ENCODING:','UPGRADE:','VIA:','WARNING:','ALLOW:','CONTENT-LENGTH:',
    'CONTENT-TYPE:','CONTENT-ENCODING:','CONTENT-LANGUAGE:','CONTENT-LOCATION:',
    'CONTENT-MD5:','CONTENT-RANGE:','EXPIRES:','LAST-MODIFIED:',
    'ACCEPT-RANGES:','AGE:','ETAG:','LOCATION:','PROXY-AUTHENTICATE:',
    'RETRY-AFTER:','SERVER:','SET-COOKIE:','VARY:','WWW-AUTHENTICATE:');
var UnknownName: PAnsiChar;
    i: integer;
begin
  i := IdemPCharArray(P,KNOWNHEADERS);
  if i>=0 then
  with Headers.KnownHeaders[THttpHeader(i)] do begin
    while P^<>':' do inc(P);
    inc(P); // jump ':'
    while P^=' ' do inc(P);
    pRawValue := P;
    while P^>=' ' do inc(P);
    RawValueLength := P-pRawValue;
  end else begin
    UnknownName := P;
    while (P^>=' ') and (P^<>':') do inc(P);
    if P^=':' then
      with UnknownHeaders[Headers.UnknownHeaderCount] do begin
        pName := UnknownName;
        NameLength := P-pName;
        repeat inc(P) until P^<>' ';
        pRawValue := P;
        while P^>=' ' do inc(P);
        RawValueLength := P-pRawValue;
        if Headers.UnknownHeaderCount=high(UnknownHeaders) then begin
          SetLength(UnknownHeaders,Headers.UnknownHeaderCount+32);
          Headers.pUnknownHeaders := pointer(UnknownHeaders);
        end;
        inc(Headers.UnknownHeaderCount);
      end else
      while P^>=' ' do inc(P);
  end;
  result := P;
end;

procedure HTTP_RESPONSE.SetHeaders(P: PAnsiChar; var UnknownHeaders: HTTP_UNKNOWN_HEADERs);
const XPN: PAnsiChar = XPOWEREDNAME;
      XPV: PAnsiChar = XPOWEREDVALUE;
begin
  Headers.pUnknownHeaders := pointer(UnknownHeaders);
  with UnknownHeaders[0] do begin
    pName := XPN;
    NameLength := length(XPOWEREDNAME);
    pRawValue := XPV;
    RawValueLength := length(XPOWEREDVALUE);
  end;
  Headers.UnknownHeaderCount := 1;
  if P<>nil then
  repeat
    while P^ in [#13,#10] do inc(P);
    if P^=#0 then
      break;
    P := AddCustomHeader(P,UnknownHeaders);
  until false;
end;

procedure HTTP_RESPONSE.SetStatus(code: integer; var OutStatus: RawByteString);
begin
  StatusCode := code;
  OutStatus := StatusCodeToReason(code);
  ReasonLength := length(OutStatus);
  pReason := pointer(OutStatus);
end;


{ ************ WinHttp / WinINet HTTP clients }

{$ifdef USEWININET}

{ TWinHttpAPI }

constructor TWinHttpAPI.Create(const aServer, aPort: RawByteString; aHttps: boolean;
  const aProxyName,aProxyByPass: RawByteString; SendTimeout,ReceiveTimeout: DWORD);
begin
  fPort := GetCardinal(pointer(aPort));
  if fPort=0 then
    if aHttps then
      fPort := INTERNET_DEFAULT_HTTPS_PORT else
      fPort := INTERNET_DEFAULT_HTTP_PORT;
  fServer := aServer;
  fHttps := aHttps;
  fProxyName := aProxyName;
  fProxyByPass := aProxyByPass;
  InternalConnect(SendTimeout,ReceiveTimeout); // should raise an exception on error
end;

function TWinHttpAPI.RegisterCompress(aFunction: THttpSocketCompress;
  aCompressMinSize: integer): boolean;
begin
  result := RegisterCompressFunc(fCompress,aFunction,fCompressAcceptEncoding,aCompressMinSize)<>'';
end;

const
  // while reading an HTTP response, read it in blocks of this size. 8K for now
  HTTP_RESP_BLOCK_SIZE = 8*1024;

function TWinHttpAPI.Request(const url, method: RawByteString;
  KeepAlive: cardinal; const InHeader, InData, InDataType: RawByteString;
  out OutHeader, OutData: RawByteString): integer;
var aData, aDataEncoding, aAcceptEncoding, aURL: RawByteString;
    Bytes, ContentLength, Read: DWORD;
    i: integer;
begin
  if (url='') or (url[1]<>'/') then
    aURL := '/'+url else // need valid url according to the HTTP/1.1 RFC
    aURL := url;
  fKeepAlive := KeepAlive;
  InternalRequest(method,aURL); // should raise an exception on error
  try
    // common headers
    InternalAddHeader(InHeader);
    if InDataType<>'' then
      InternalAddHeader(RawByteString('Content-Type: ')+InDataType);
    // handle custom compression
    aData := InData;
    if integer(fCompressHeader)<>0 then begin
      aDataEncoding := CompressDataAndGetHeaders(fCompressHeader,fCompress,
        InDataType,aData);
      if aDataEncoding<>'' then
        InternalAddHeader(RawByteString('Content-Encoding: ')+aDataEncoding);
    end;
    if fCompressAcceptEncoding<>'' then
      InternalAddHeader(fCompressAcceptEncoding);
    // send request to remote server
    InternalSendRequest(aData);
    // retrieve status and headers (HTTP_QUERY* and WINHTTP_QUERY* do match)
    result := InternalGetInfo32(HTTP_QUERY_STATUS_CODE);
    OutHeader := InternalGetInfo(HTTP_QUERY_RAW_HEADERS_CRLF);
    aDataEncoding := InternalGetInfo(HTTP_QUERY_CONTENT_ENCODING);
    aAcceptEncoding := InternalGetInfo(HTTP_QUERY_ACCEPT_ENCODING);
    // retrieve received content (if any)
    Read := 0;
    ContentLength := InternalGetInfo32(HTTP_QUERY_CONTENT_LENGTH);
    if ContentLength<>0 then begin
      SetLength(OutData,ContentLength);
      repeat
        Bytes := InternalReadData(OutData,Read);
        if Bytes=0 then begin
          SetLength(OutData,Read); // truncated content
          break;
        end else
          inc(Read,Bytes);
      until Read=ContentLength;
    end else begin
      // Content-Length not set: read response in blocks of HTTP_RESP_BLOCK_SIZE
      repeat
        SetLength(OutData,Read+HTTP_RESP_BLOCK_SIZE);
        Bytes := InternalReadData(OutData,Read);
        if Bytes=0 then
          break;
        inc(Read,Bytes);
      until false;
      SetLength(OutData,Read);
    end;
    // handle incoming answer compression
    if OutData<>'' then begin
      if aDataEncoding<>'' then
        for i := 0 to high(fCompress) do
          with fCompress[i] do
          if Name=aDataEncoding then
            if Func(OutData,false)='' then
              raise ECrtSocket.CreateFmt('%s uncompress',[Name]) else
              break; // successfully uncompressed content
      if aAcceptEncoding<>'' then
        fCompressHeader := ComputeContentEncoding(fCompress,pointer(aAcceptEncoding));
    end;
  finally
    InternalCloseRequest;
  end;
end;

class function TWinHttpAPI.InternalREST(const url,method,data,header: RawByteString): RawByteString;
var URI: TURI;
    outHeaders: RawByteString;
begin
  result := '';
  with URI do
  if From(url) then
  try
    with self.Create(Server,Port,Https) do
    try
      Request(Address,method,0,header,data,'',outHeaders,result);
    finally
      Free;
    end;
  except
    result := '';
  end;
end;

class function TWinHttpAPI.Get(const aURI, aHeader: RawByteString): RawByteString;
begin
  result := InternalREST(aURI,'GET','',aHeader);
end;

class function TWinHttpAPI.Post(const aURI, aData: RawByteString;
  const aHeader: RawByteString=''): RawByteString;
begin
  result := InternalREST(aURI,'POST',aData,aHeader);
end;

class function TWinHttpAPI.Put(const aURI, aData: RawByteString;
  const aHeader: RawByteString=''): RawByteString;
begin
  result := InternalREST(aURI,'PUT',aData,aHeader);
end;

class function TWinHttpAPI.Delete(const aURI: RawByteString;
  const aHeader: RawByteString=''): RawByteString;
begin
  result := InternalREST(aURI,'DELETE','',aHeader);
end;


{ EWinINet }

constructor EWinINet.Create;
var dwError, tmpLen: DWORD;
    msg, tmp: string;
begin // see http://msdn.microsoft.com/en-us/library/windows/desktop/aa383884
  fCode := GetLastError;
  msg := SysErrorMessagePerModule(fCode,'wininet.dll');
  if fCode=ERROR_INTERNET_EXTENDED_ERROR then begin
    InternetGetLastResponseInfo({$ifdef FPC}@{$endif}dwError,nil,tmpLen);
    if tmpLen > 0 then begin
      SetLength(tmp,tmpLen);
      InternetGetLastResponseInfo({$ifdef FPC}@{$endif}dwError,PChar(tmp),tmpLen);
      msg := msg+' ['+tmp+']';
    end;
  end;
  inherited CreateFmt('%s (%d)',[msg,fCode]);
end;


{ TWinINet }

destructor TWinINet.Destroy;
begin
  if fConnection<>nil then
    InternetCloseHandle(FConnection);
  if fSession<>nil then
    InternetCloseHandle(FSession);
  inherited;
end;

procedure TWinINet.InternalAddHeader(const hdr: RawByteString);
begin
  if (hdr<>'') and not HttpAddRequestHeadersA(fRequest,
     Pointer(hdr), length(hdr), HTTP_ADDREQ_FLAG_COALESCE) then
    raise EWinINet.Create;
end;

procedure TWinINet.InternalCloseRequest;
begin
  if fRequest<>nil then begin
    InternetCloseHandle(fRequest);
    fRequest := nil;
  end;
end;

procedure TWinINet.InternalConnect(SendTimeout,ReceiveTimeout: DWORD);
var OpenType: integer;
begin
  if fProxyName='' then
   OpenType := INTERNET_OPEN_TYPE_PRECONFIG else
   OpenType := INTERNET_OPEN_TYPE_PROXY;
  fSession := InternetOpenA(Pointer(DefaultUserAgent(self)), OpenType,
    pointer(fProxyName), pointer(fProxyByPass), 0);
  if fSession=nil then
    raise EWinINet.Create;
  InternetSetOption(fConnection,INTERNET_OPTION_SEND_TIMEOUT,
    @SendTimeout,SizeOf(SendTimeout));
  InternetSetOption(fConnection,INTERNET_OPTION_RECEIVE_TIMEOUT,
    @ReceiveTimeout,SizeOf(ReceiveTimeout));
  fConnection := InternetConnectA(fSession, pointer(fServer), fPort, nil, nil,
    INTERNET_SERVICE_HTTP, 0, 0);
  if fConnection=nil then
    raise EWinINet.Create;
end;

function TWinINet.InternalGetInfo(Info: DWORD): RawByteString;
var dwSize, dwIndex: DWORD;
begin
  result := '';
  dwSize := 0;
  dwIndex := 0;
  if not HttpQueryInfoA(fRequest, Info, nil, dwSize, dwIndex) and
     (GetLastError=ERROR_INSUFFICIENT_BUFFER) then begin
    SetLength(result,dwSize-1);
    if not HttpQueryInfoA(fRequest, Info, pointer(result), dwSize, dwIndex) then
      result := '';
  end;
end;

function TWinINet.InternalGetInfo32(Info: DWORD): DWORD;
var dwSize, dwIndex: DWORD;
begin
  dwSize := sizeof(result);
  dwIndex := 0;
  Info := Info or HTTP_QUERY_FLAG_NUMBER;
  if not HttpQueryInfoA(fRequest, Info, @result, dwSize, dwIndex) then
    result := 0;
end;

function TWinINet.InternalReadData(var Data: RawByteString; Read: integer): cardinal;
begin
  if not InternetReadFile(fRequest, @PByteArray(Data)[Read], length(Data)-Read, result) then
    raise EWinINet.Create;
end;

procedure TWinINet.InternalRequest(const method, aURL: RawByteString);
const ALL_ACCEPT: array[0..1] of PAnsiChar = ('*/*',nil);
var Flags: DWORD;
begin
  Flags := INTERNET_FLAG_HYPERLINK or INTERNET_FLAG_PRAGMA_NOCACHE or
    INTERNET_FLAG_RESYNCHRONIZE; // options for a true RESTful request
  if fKeepAlive<>0 then
    Flags := Flags or INTERNET_FLAG_KEEP_CONNECTION;
  if fHttps then
    Flags := Flags or INTERNET_FLAG_SECURE;
  FRequest := HttpOpenRequestA(FConnection, Pointer(method), Pointer(aURL), nil,
    nil, @ALL_ACCEPT, Flags,0);
  if FRequest=nil then
    raise EWinINet.Create;
end;

procedure TWinINet.InternalSendRequest(const aData: RawByteString);
begin
  if not HttpSendRequestA(fRequest, nil, 0, pointer(aData), length(aData)) then
    raise EWinINet.Create;
end;


{ TWinHTTP }

const
  winhttpdll = 'winhttp.dll';

  WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0;
  WINHTTP_ACCESS_TYPE_NAMED_PROXY = 3;
  WINHTTP_FLAG_REFRESH = $00000100;
  WINHTTP_FLAG_SECURE = $00800000;
  WINHTTP_ADDREQ_FLAG_COALESCE = $40000000;
  WINHTTP_QUERY_FLAG_NUMBER = $20000000;

function WinHttpOpen(pwszUserAgent: PWideChar; dwAccessType: DWORD;
  pwszProxyName, pwszProxyBypass: PWideChar; dwFlags: DWORD): HINTERNET; stdcall; external winhttpdll;
function WinHttpConnect(hSession: HINTERNET; pswzServerName: PWideChar;
  nServerPort: INTERNET_PORT; dwReserved: DWORD): HINTERNET; stdcall; external winhttpdll;
function WinHttpOpenRequest(hConnect: HINTERNET; pwszVerb: PWideChar;
  pwszObjectName: PWideChar; pwszVersion: PWideChar; pwszReferer: PWideChar;
  ppwszAcceptTypes: PLPWSTR; dwFlags: DWORD): HINTERNET; stdcall; external winhttpdll;
function WinHttpCloseHandle(hInternet: HINTERNET): BOOL; stdcall; external winhttpdll;
function WinHttpAddRequestHeaders(hRequest: HINTERNET; pwszHeaders: PWideChar; dwHeadersLength: DWORD;
  dwModifiers: DWORD): BOOL; stdcall; external winhttpdll;
function WinHttpSendRequest(hRequest: HINTERNET; pwszHeaders: PWideChar;
  dwHeadersLength: DWORD; lpOptional: Pointer; dwOptionalLength: DWORD; dwTotalLength: DWORD;
  dwContext: DWORD): BOOL; stdcall; external winhttpdll;
function WinHttpReceiveResponse(hRequest: HINTERNET;
  lpReserved: Pointer): BOOL; stdcall; external winhttpdll;
function WinHttpQueryHeaders(hRequest: HINTERNET; dwInfoLevel: DWORD; pwszName: PWideChar;
  lpBuffer: Pointer; var lpdwBufferLength, lpdwIndex: DWORD): BOOL; stdcall; external winhttpdll;
function WinHttpReadData(hRequest: HINTERNET; lpBuffer: Pointer;
  dwNumberOfBytesToRead: DWORD; var lpdwNumberOfBytesRead: DWORD): BOOL; stdcall; external winhttpdll;
function WinHttpSetTimeouts(hInternet: HINTERNET; dwResolveTimeout: DWORD;
  dwConnectTimeout: DWORD; dwSendTimeout: DWORD; dwReceiveTimeout: DWORD): BOOL; stdcall; external winhttpdll;

destructor TWinHTTP.Destroy;
begin
  if fConnection<>nil then
    WinHttpCloseHandle(fConnection);
  if fSession<>nil then
    WinHttpCloseHandle(fSession);
  inherited;
end;

procedure TWinHTTP.InternalAddHeader(const hdr: RawByteString);
begin
  if (hdr<>'') and
    not WinHttpAddRequestHeaders(FRequest, Pointer(Ansi7ToUnicode(hdr)), length(hdr),
      WINHTTP_ADDREQ_FLAG_COALESCE) then
    RaiseLastModuleError(winhttpdll,EWinHTTP);
end;

procedure TWinHTTP.InternalCloseRequest;
begin
  if fRequest<>nil then begin
    WinHttpCloseHandle(fRequest);
    FRequest := nil;
  end;
end;

procedure TWinHTTP.InternalConnect(SendTimeout,ReceiveTimeout: DWORD);
var OpenType: integer;
begin
  if fProxyName='' then
    OpenType := WINHTTP_ACCESS_TYPE_DEFAULT_PROXY else
    OpenType := WINHTTP_ACCESS_TYPE_NAMED_PROXY;
  fSession := WinHttpOpen(pointer(Ansi7ToUnicode(DefaultUserAgent(self))), OpenType,
    pointer(Ansi7ToUnicode(fProxyName)), pointer(Ansi7ToUnicode(fProxyByPass)), 0);
  if fSession=nil then
    RaiseLastModuleError(winhttpdll,EWinHTTP);
  // cf. http://msdn.microsoft.com/en-us/library/windows/desktop/aa384116
  if not WinHttpSetTimeouts(fSession,HTTP_DEFAULT_RESOLVETIMEOUT,
     HTTP_DEFAULT_CONNECTTIMEOUT,SendTimeout,ReceiveTimeout) then
    RaiseLastModuleError(winhttpdll,EWinHTTP);
  fConnection := WinHttpConnect(fSession, pointer(Ansi7ToUnicode(FServer)), fPort, 0);
  if fConnection=nil then
    RaiseLastModuleError(winhttpdll,EWinHTTP);
end;

function TWinHTTP.InternalGetInfo(Info: DWORD): RawByteString;
var dwSize, dwIndex: DWORD;
    tmp: RawByteString;
    i: integer;
begin
  result := '';
  dwSize := 0;
  dwIndex := 0;
  if not WinHttpQueryHeaders(fRequest, Info, nil, nil, dwSize, dwIndex) and
     (GetLastError=ERROR_INSUFFICIENT_BUFFER) then begin
    SetLength(tmp,dwSize);
    if WinHttpQueryHeaders(fRequest, Info, nil, pointer(tmp), dwSize, dwIndex) then begin
      dwSize := dwSize shr 1;
      SetLength(result,dwSize);
      for i := 0 to dwSize-1 do // fast ANSI 7 bit conversion
        PByteArray(result)^[i] := PWordArray(tmp)^[i];
    end;
  end;
end;

function TWinHTTP.InternalGetInfo32(Info: DWORD): DWORD;
var dwSize, dwIndex: DWORD;
begin
  dwSize := sizeof(result);
  dwIndex := 0;
  Info := Info or WINHTTP_QUERY_FLAG_NUMBER;
  if not WinHttpQueryHeaders(fRequest, Info, nil, @result, dwSize, dwIndex) then
    result := 0;
end;

function TWinHTTP.InternalReadData(var Data: RawByteString; Read: integer): cardinal;
begin
  if not WinHttpReadData(fRequest, @PByteArray(Data)[Read], length(Data)-Read, result) then
    RaiseLastModuleError(winhttpdll,EWinHTTP);
end;

procedure TWinHTTP.InternalRequest(const method, aURL: RawByteString);
const ALL_ACCEPT: array[0..1] of PWideChar = ('*/*',nil);
var Flags: DWORD;
begin
  Flags := WINHTTP_FLAG_REFRESH; // options for a true RESTful request
  if fHttps then
    Flags := Flags or WINHTTP_FLAG_SECURE;
  fRequest := WinHttpOpenRequest(fConnection, pointer(Ansi7ToUnicode(method)),
    pointer(Ansi7ToUnicode(aURL)), nil, nil, @ALL_ACCEPT, Flags);
  if fRequest=nil then
    RaiseLastModuleError(winhttpdll,EWinHTTP);
end;

procedure TWinHTTP.InternalSendRequest(const aData: RawByteString);
var L: integer;
begin
  L := length(aData);
  if not WinHttpSendRequest(fRequest, nil, 0, pointer(aData), L, L, 0) or
     not WinHttpReceiveResponse(fRequest,nil) then
    RaiseLastModuleError(winhttpdll,EWinHTTP);
end;

{$endif}


initialization
  {$ifdef DEBUGAPI}AllocConsole;{$endif}
  {$ifdef CPU64}
  Assert((sizeof(HTTP_REQUEST)=864) and
    (sizeof(HTTP_SSL_INFO)=48) and
    (sizeof(HTTP_DATA_CHUNK_INMEMORY)=32) and
    (sizeof(HTTP_DATA_CHUNK_FILEHANDLE)=32) and
    (sizeof(HTTP_REQUEST_HEADERS)=688) and
    (sizeof(HTTP_RESPONSE_HEADERS)=512) and
    (sizeof(HTTP_COOKED_URL)=40) and
    (sizeof(HTTP_RESPONSE)=568) and
    (ord(reqUserAgent)=40) and
    (ord(respLocation)=23) and (sizeof(THttpHeader)=4));
  {$else}
  Assert((sizeof(HTTP_REQUEST)=472) and
    (sizeof(HTTP_SSL_INFO)=28) and
    (sizeof(HTTP_DATA_CHUNK_INMEMORY)=24) and
    (sizeof(HTTP_DATA_CHUNK_FILEHANDLE)=32) and
    (sizeof(HTTP_REQUEST_HEADERS)=344) and
    (sizeof(HTTP_RESPONSE_HEADERS)=256) and
    (sizeof(HTTP_COOKED_URL)=24) and
    (sizeof(HTTP_RESPONSE)=288) and
    (ord(reqUserAgent)=40) and
    (ord(respLocation)=23) and (sizeof(THttpHeader)=4));
  {$endif}
  if InitSocketInterface then
    WSAStartup(WinsockLevel, WsaDataOnce) else
    fillchar(WsaDataOnce,sizeof(WsaDataOnce),0);

finalization
  if WsaDataOnce.wVersion<>0 then
  try
    if Assigned(WSACleanup) then
      WSACleanup;
  finally
    fillchar(WsaDataOnce,sizeof(WsaDataOnce),0);
  end;
  if Http.Module<>0 then begin
    FreeLibrary(Http.Module);
    Http.Module := 0;
  end;
  DestroySocketInterface;
end.


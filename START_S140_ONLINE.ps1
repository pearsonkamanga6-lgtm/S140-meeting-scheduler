param(
  [int]$Port = 8769
)

$ErrorActionPreference = "Stop"

# Force TLS 1.2 for Windows PowerShell 5.1 web requests.
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseUrl = "http://127.0.0.1:$Port/"
$LogFile = Join-Path $Root "S140_SERVER_ERROR_LOG.txt"

function Get-MimeType([string]$FilePath) {
  switch ([IO.Path]::GetExtension($FilePath).ToLowerInvariant()) {
    ".html"        { return "text/html; charset=utf-8" }
    ".js"          { return "application/javascript; charset=utf-8" }
    ".json"        { return "application/json; charset=utf-8" }
    ".webmanifest" { return "application/manifest+json; charset=utf-8" }
    ".css"         { return "text/css; charset=utf-8" }
    ".png"         { return "image/png" }
    ".txt"         { return "text/plain; charset=utf-8" }
    default        { return "application/octet-stream" }
  }
}

function Send-Response {
  param(
    $Stream,
    [int]$Status,
    [byte[]]$Body,
    [string]$ContentType,
    [hashtable]$ExtraHeaders = @{}
  )

  $Reason = switch ($Status) {
    200 { "OK" }
    400 { "Bad Request" }
    403 { "Forbidden" }
    404 { "Not Found" }
    405 { "Method Not Allowed" }
    413 { "Payload Too Large" }
    500 { "Internal Server Error" }
    502 { "Bad Gateway" }
    default { "OK" }
  }

  $Headers = ""
  $Headers += "HTTP/1.1 $Status $Reason`r`n"
  $Headers += "Content-Type: $ContentType`r`n"
  $Headers += "Content-Length: $($Body.Length)`r`n"
  $Headers += "X-Content-Type-Options: nosniff`r`n"
  $Headers += "Connection: close`r`n"

  foreach ($Key in $ExtraHeaders.Keys) {
    # Important: use $($Key) before ':' so PowerShell does not parse it as a drive variable.
    $Headers += "$($Key): $($ExtraHeaders[$Key])`r`n"
  }

  $Headers += "`r`n"

  $HeaderBytes = [Text.Encoding]::ASCII.GetBytes($Headers)
  $Stream.Write($HeaderBytes, 0, $HeaderBytes.Length)

  if ($Body -and $Body.Length -gt 0) {
    $Stream.Write($Body, 0, $Body.Length)
  }

  $Stream.Flush()
}

function Send-Text {
  param(
    $Stream,
    [int]$Status,
    [string]$Text,
    [string]$Type = "text/plain; charset=utf-8",
    [hashtable]$Headers = @{}
  )

  $Bytes = [Text.Encoding]::UTF8.GetBytes($Text)
  Send-Response -Stream $Stream -Status $Status -Body $Bytes -ContentType $Type -ExtraHeaders $Headers
}

function Get-QueryParam {
  param(
    [string]$Query,
    [string]$Name
  )

  if ([string]::IsNullOrWhiteSpace($Query)) {
    return $null
  }

  foreach ($Pair in $Query.TrimStart("?").Split("&")) {
    if ([string]::IsNullOrWhiteSpace($Pair)) {
      continue
    }

    $Parts = $Pair.Split("=", 2)
    $Key = [Uri]::UnescapeDataString($Parts[0].Replace("+", " "))

    if ($Key -eq $Name) {
      if ($Parts.Length -gt 1) {
        return [Uri]::UnescapeDataString($Parts[1].Replace("+", " "))
      }
      return ""
    }
  }

  return $null
}

function Write-FatalError {
  param($ErrorRecord)

  $Message = $ErrorRecord | Out-String

  try {
    Set-Content -LiteralPath $LogFile -Value $Message -Encoding UTF8
  } catch {}

  Write-Host ""
  Write-Host "S-140 SERVER STOPPED WITH AN ERROR" -ForegroundColor Red
  Write-Host "---------------------------------" -ForegroundColor Red
  Write-Host $Message -ForegroundColor Yellow
  Write-Host ""
  Write-Host "The error was also saved to:" -ForegroundColor Cyan
  Write-Host $LogFile -ForegroundColor Cyan
  Write-Host ""
  Write-Host "This window will remain open." -ForegroundColor Yellow
}

$Listener = $null

try {
  $Listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, $Port)
  $Listener.Start()

  Write-Host ""
  Write-Host "S-140 Meeting Scheduler is running." -ForegroundColor Green
  Write-Host "Online JW.org import is ENABLED." -ForegroundColor Green
  Write-Host "Address: $BaseUrl" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "KEEP THIS WINDOW OPEN while using the app." -ForegroundColor Yellow
  Write-Host "Press Ctrl+C here when you want to stop the server." -ForegroundColor Yellow
  Write-Host ""

  while ($true) {
    $Client = $null
    $Stream = $null
    $Reader = $null

    try {
      $Client = $Listener.AcceptTcpClient()
      $Stream = $Client.GetStream()

      $Reader = New-Object IO.StreamReader(
        $Stream,
        [Text.Encoding]::ASCII,
        $false,
        8192,
        $true
      )

      $RequestLine = $Reader.ReadLine()

      if ([string]::IsNullOrWhiteSpace($RequestLine)) {
        continue
      }

      while ($true) {
        $HeaderLine = $Reader.ReadLine()
        if ([string]::IsNullOrEmpty($HeaderLine)) {
          break
        }
      }

      $RequestParts = $RequestLine.Split(" ")

      if ($RequestParts.Length -lt 2) {
        Send-Text -Stream $Stream -Status 400 -Text "Bad request"
        continue
      }

      $Method = $RequestParts[0]
      $RawTarget = $RequestParts[1]

      if ($Method -ne "GET") {
        Send-Text -Stream $Stream -Status 405 -Text "Only GET is supported."
        continue
      }

      $LocalUri = New-Object Uri("http://127.0.0.1:$Port$RawTarget")
      $PathName = $LocalUri.AbsolutePath

      if ($PathName -eq "/api/health") {
        Send-Text `
          -Stream $Stream `
          -Status 200 `
          -Text '{"ok":true,"service":"s140-windows-local-importer","version":"5.3"}' `
          -Type "application/json; charset=utf-8" `
          -Headers @{"Cache-Control"="no-store"}
        continue
      }

      if ($PathName -eq "/api/jw-proxy") {
        $TargetText = Get-QueryParam -Query $LocalUri.Query -Name "url"

        if ([string]::IsNullOrWhiteSpace($TargetText)) {
          Send-Text -Stream $Stream -Status 400 -Text "Missing url"
          continue
        }

        try {
          $Target = New-Object Uri($TargetText)
        } catch {
          Send-Text -Stream $Stream -Status 400 -Text "Invalid URL"
          continue
        }

        if (
          $Target.Scheme -ne "https" -or
          $Target.Host -ne "www.jw.org" -or
          -not $Target.AbsolutePath.StartsWith("/nya/")
        ) {
          Send-Text `
            -Stream $Stream `
            -Status 403 `
            -Text "Only official Cinyanja pages on https://www.jw.org/nya/ are allowed."
          continue
        }

        try {
          Write-Host "Fetching JW.org: $($Target.AbsoluteUri)" -ForegroundColor DarkCyan

          $Response = Invoke-WebRequest `
            -Uri $Target.AbsoluteUri `
            -UseBasicParsing `
            -MaximumRedirection 5 `
            -Headers @{
              "User-Agent"      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/152 Safari/537.36"
              "Accept"          = "text/html,application/xhtml+xml"
              "Accept-Language" = "ny,en;q=0.7"
            }

          $Content = [string]$Response.Content

          if ($Content.Length -gt 6000000) {
            Send-Text `
              -Stream $Stream `
              -Status 413 `
              -Text "JW.org response was unexpectedly large."
            continue
          }

          Send-Text `
            -Stream $Stream `
            -Status 200 `
            -Text $Content `
            -Type "text/html; charset=utf-8" `
            -Headers @{"Cache-Control"="public, max-age=1800"}

        } catch {
          $WebError = $_.Exception.Message
          Write-Host "JW.org fetch failed: $WebError" -ForegroundColor Red

          Send-Text `
            -Stream $Stream `
            -Status 502 `
            -Text ("Could not fetch the official JW.org page. " + $WebError)
        }

        continue
      }

      $Relative = [Uri]::UnescapeDataString($PathName.TrimStart("/"))

      if ([string]::IsNullOrWhiteSpace($Relative)) {
        $Relative = "index.html"
      }

      $Requested = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
      $RootFull = [IO.Path]::GetFullPath($Root)

      if (-not $Requested.StartsWith($RootFull, [StringComparison]::OrdinalIgnoreCase)) {
        Send-Text -Stream $Stream -Status 403 -Text "Forbidden"
        continue
      }

      if (-not (Test-Path -LiteralPath $Requested -PathType Leaf)) {
        Send-Text -Stream $Stream -Status 404 -Text "Not found"
        continue
      }

      $Bytes = [IO.File]::ReadAllBytes($Requested)

      Send-Response `
        -Stream $Stream `
        -Status 200 `
        -Body $Bytes `
        -ContentType (Get-MimeType $Requested) `
        -ExtraHeaders @{"Cache-Control"="no-store, no-cache, must-revalidate"; "Pragma"="no-cache"; "Expires"="0"}

    } catch {
      $RequestError = $_.Exception.Message
      Write-Host "Request error: $RequestError" -ForegroundColor Red

      if ($Stream) {
        try {
          Send-Text -Stream $Stream -Status 500 -Text ("Server error: " + $RequestError)
        } catch {}
      }

    } finally {
      if ($Reader) {
        try { $Reader.Dispose() } catch {}
      }

      if ($Stream) {
        try { $Stream.Dispose() } catch {}
      }

      if ($Client) {
        try { $Client.Close() } catch {}
      }
    }
  }

} catch {
  Write-FatalError $_

  while ($true) {
    Start-Sleep -Seconds 3600
  }

} finally {
  if ($Listener) {
    try { $Listener.Stop() } catch {}
  }
}

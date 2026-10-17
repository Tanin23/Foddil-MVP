# FODDIL — Robust Zero-Dependency Local Dev Server for Windows PowerShell
$port = 3000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host " FODDIL Dev Server running on http://localhost:$port/" -ForegroundColor Cyan
    Write-Host " Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Green

    $baseDir = $PSScriptRoot

    $mimeTypes = @{
        ".html" = "text/html; charset=utf-8"
        ".css"  = "text/css; charset=utf-8"
        ".js"   = "application/javascript; charset=utf-8"
        ".json" = "application/json; charset=utf-8"
        ".svg"  = "image/svg+xml"
        ".jpg"  = "image/jpeg"
        ".jpeg" = "image/jpeg"
        ".png"  = "image/png"
        ".webp" = "image/webp"
        ".ico"  = "image/x-icon"
    }

    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            $urlPath = $request.Url.LocalPath.TrimStart('/')
            if ([string]::IsNullOrWhiteSpace($urlPath) -or $urlPath -eq "/") {
                $urlPath = "index.html"
            }

            # Normalize path separators
            $urlPath = $urlPath -replace '/', '\'
            $filePath = Join-Path $baseDir $urlPath

            if (Test-Path $filePath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }

                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = $mime
                $response.ContentLength64 = $bytes.Length
                $response.AddHeader("Access-Control-Allow-Origin", "*")
                $response.AddHeader("Cache-Control", "no-cache, no-store, must-revalidate")
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 404
                $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $urlPath")
                $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
            }

            $response.Close()
        }
        catch {
            # Ignore client disconnect exceptions and keep server alive
            try { $response.Close() } catch {}
        }
    }
}
finally {
    try { $listener.Stop() } catch {}
}

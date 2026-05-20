# =============================================================
#  Servidor Web - Sistema de Rotinas Coamo
#  Porta: 3000
#  Dados: dados.json (mesma pasta)
# =============================================================

$PORTA = 3000
$DIR   = $PSScriptRoot
$DADOS = Join-Path $DIR "dados.json"

if (-not (Test-Path $DADOS)) {
    Set-Content -Path $DADOS -Value "{}" -Encoding UTF8
}

# Descobre IPs da maquina
$ips = @("localhost")
try {
    $addrs = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName())
    foreach ($a in $addrs) {
        if ($a.AddressFamily -eq "InterNetwork" -and $a.ToString() -notlike "127.*") {
            $ips += $a.ToString()
        }
    }
} catch {}

# Inicia o listener
$listener = New-Object System.Net.HttpListener
foreach ($ip in $ips) {
    $listener.Prefixes.Add("http://${ip}:${PORTA}/")
}

try {
    $listener.Start()
} catch {
    # Fallback: tenta so localhost
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:${PORTA}/")
    $listener.Start()
    $ips = @("localhost")
}

$ipRede = $ips | Where-Object { $_ -ne "localhost" } | Select-Object -First 1

Write-Host ""
Write-Host "  Servidor iniciado na porta $PORTA"
if ($ipRede) {
    Write-Host "  Acesso na rede: http://${ipRede}:$PORTA"
}
Write-Host "  Acesso local:   http://localhost:$PORTA"
Write-Host "  Para encerrar:  Ctrl+C"
Write-Host ""

# Tipos MIME suportados
$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".ico"  = "image/x-icon"
    ".png"  = "image/png"
}

function Enviar-Resposta($ctx, $status, $tipo, $corpo) {
    $ctx.Response.StatusCode  = $status
    $ctx.Response.ContentType = $tipo
    $ctx.Response.Headers["Access-Control-Allow-Origin"]  = "*"
    $ctx.Response.Headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    $ctx.Response.Headers["Access-Control-Allow-Headers"] = "Content-Type"
    if ($null -ne $corpo) {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($corpo)
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    }
    $ctx.Response.OutputStream.Close()
}

function Ler-Body($req) {
    $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
    return $reader.ReadToEnd()
}

function Ler-Dados {
    try { return Get-Content -Path $DADOS -Raw -Encoding UTF8 } catch { return "{}" }
}

function Salvar-Dados($json) {
    Set-Content -Path $DADOS -Value $json -Encoding UTF8
}

# Loop principal
while ($listener.IsListening) {
    try {
        $ctx    = $listener.GetContext()
        $req    = $ctx.Request
        $metodo = $req.HttpMethod
        $caminho = $req.Url.AbsolutePath

        # Preflight CORS
        if ($metodo -eq "OPTIONS") {
            Enviar-Resposta $ctx 204 "text/plain" $null
            continue
        }

        # GET /api/dados — retorna todos os dados sincronizados
        if ($metodo -eq "GET" -and $caminho -eq "/api/dados") {
            Enviar-Resposta $ctx 200 "application/json; charset=utf-8" (Ler-Dados)
            continue
        }

        # POST /api/dados/CHAVE — salva uma chave no dados.json
        if ($metodo -eq "POST" -and $caminho.StartsWith("/api/dados/")) {
            $chave = [System.Uri]::UnescapeDataString($caminho.Substring(11))
            $body  = Ler-Body $req

            try   { $valor = ($body | ConvertFrom-Json).valor }
            catch { $valor = $body }

            try   { $obj = Ler-Dados | ConvertFrom-Json }
            catch { $obj = New-Object PSObject }

            $obj | Add-Member -MemberType NoteProperty -Name $chave -Value $valor -Force
            Salvar-Dados ($obj | ConvertTo-Json -Compress -Depth 20)
            Enviar-Resposta $ctx 200 "application/json" '{"ok":true}'
            continue
        }

        # Arquivos estaticos (HTML, CSS, JS, etc.)
        if ($caminho -eq "/") { $caminho = "/index.html" }
        $arquivo = Join-Path $DIR ($caminho.TrimStart("/").Replace("/", "\"))

        $dirReal     = (Resolve-Path $DIR).Path
        $arquivoReal = ""
        try { $arquivoReal = (Resolve-Path $arquivo -ErrorAction Stop).Path } catch {}

        if ($arquivoReal -eq "" -or -not $arquivoReal.StartsWith($dirReal) -or -not (Test-Path $arquivo -PathType Leaf)) {
            Enviar-Resposta $ctx 404 "text/plain" "Nao encontrado: $caminho"
            continue
        }

        $ext      = [System.IO.Path]::GetExtension($arquivo)
        $tipoMime = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
        $bytes    = [System.IO.File]::ReadAllBytes($arquivo)

        $ctx.Response.StatusCode      = 200
        $ctx.Response.ContentType     = $tipoMime
        $ctx.Response.Headers["Access-Control-Allow-Origin"] = "*"
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $ctx.Response.OutputStream.Close()

    } catch {
        Write-Host "  Erro: $($_.Exception.Message)"
    }
}

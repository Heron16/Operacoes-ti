# =============================================================
#  INSTALAR SERVICO - Executar UMA UNICA VEZ como Administrador
#  Apos isso o servidor inicia automaticamente com o Windows
# =============================================================

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Execute este arquivo como Administrador." -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

$PORTA        = "3000"
$NOME_SERVICO = "RotinasCoamo"
$DIR          = $PSScriptRoot
$SERVIDOR     = Join-Path $DIR "servidor.ps1"
$WRAPPER      = Join-Path $DIR "servico_wrapper.ps1"

Write-Host ""
Write-Host "  Instalando servico: $NOME_SERVICO" -ForegroundColor Cyan
Write-Host ""

# 1. Libera a porta para qualquer usuario (sem precisar de admin depois)
Write-Host "  [1/5] Liberando porta $PORTA..." -ForegroundColor White
netsh http delete urlacl url="http://+:${PORTA}/" 2>&1 | Out-Null
netsh http add urlacl url="http://+:${PORTA}/" user="Everyone" | Out-Null

# 2. Libera no firewall para acesso da rede interna
Write-Host "  [2/5] Configurando firewall..." -ForegroundColor White
netsh advfirewall firewall delete rule name="Rotinas Coamo" 2>&1 | Out-Null
netsh advfirewall firewall add rule name="Rotinas Coamo" dir=in action=allow protocol=TCP localport=$PORTA | Out-Null

# 3. Remove servico anterior se existir
Write-Host "  [3/5] Verificando instalacao anterior..." -ForegroundColor White
if (Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue) {
    Stop-Service -Name $NOME_SERVICO -Force -ErrorAction SilentlyContinue
    sc.exe delete $NOME_SERVICO | Out-Null
    Start-Sleep -Seconds 2
}

# 4. Cria o script wrapper que o servico executa
Write-Host "  [4/5] Criando servico Windows..." -ForegroundColor White
@"
Set-Location "$DIR"
& powershell -ExecutionPolicy Bypass -NonInteractive -File "$SERVIDOR"
"@ | Set-Content -Path $WRAPPER -Encoding UTF8

$psExe = (Get-Command powershell.exe).Source
$cmd   = "`"$psExe`" -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File `"$WRAPPER`""

sc.exe create $NOME_SERVICO binPath= $cmd start= auto DisplayName= "Rotinas Coamo" | Out-Null
sc.exe description $NOME_SERVICO "Servidor web do sistema de rotinas operacionais" | Out-Null
sc.exe failure $NOME_SERVICO reset= 60 actions= restart/5000/restart/10000/restart/30000 | Out-Null

# 5. Inicia o servico imediatamente
Write-Host "  [5/5] Iniciando servico..." -ForegroundColor White
Start-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# Descobre IP da maquina para exibir o endereco de acesso
$ip = "localhost"
try {
    $addrs = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName())
    foreach ($a in $addrs) {
        if ($a.AddressFamily -eq "InterNetwork" -and $a.ToString() -notlike "127.*") {
            $ip = $a.ToString(); break
        }
    }
} catch {}

$svc = Get-Service -Name $NOME_SERVICO -ErrorAction SilentlyContinue
$status = if ($svc -and $svc.Status -eq "Running") { "RODANDO" } else { "iniciando..." }

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Green
Write-Host "  INSTALACAO CONCLUIDA  |  Servico: $status" -ForegroundColor Green
Write-Host "  =============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Acesso neste computador:  http://localhost:$PORTA" -ForegroundColor White
Write-Host "  Acesso pela rede interna: http://${ip}:$PORTA" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Compartilhe o endereco AMARELO com a equipe." -ForegroundColor White
Write-Host "  O servidor inicia automaticamente com o Windows." -ForegroundColor White
Write-Host ""
Read-Host "  Pressione Enter para sair"

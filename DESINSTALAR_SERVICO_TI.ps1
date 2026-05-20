# =============================================================
#  DESINSTALAR SERVICO - Executar como Administrador
#  Use apenas se quiser remover o sistema completamente
# =============================================================

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Execute este arquivo como Administrador." -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

$NOME_SERVICO = "RotinasCoamo"
$PORTA        = "3000"

Write-Host ""
Write-Host "  Removendo servico $NOME_SERVICO..." -ForegroundColor Cyan

Stop-Service  -Name $NOME_SERVICO -Force -ErrorAction SilentlyContinue
sc.exe delete $NOME_SERVICO | Out-Null

netsh advfirewall firewall delete rule name="Rotinas Coamo" | Out-Null
netsh http delete urlacl url="http://+:${PORTA}/" | Out-Null

Write-Host "  Servico removido com sucesso." -ForegroundColor Green
Write-Host ""
Read-Host "  Pressione Enter para sair"

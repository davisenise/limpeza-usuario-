<#
================================================================
  LIMPEZA DE PERFIL DO USUARIO
  Tecnico: Davi Senise - Suporte TI
================================================================
  Limpa SOMENTE arquivos do perfil do usuario logado:
  temporarios, cache de internet, crash dumps, miniaturas
  e cache de navegadores (Chrome/Edge - so cache, nunca
  senhas, historico ou cookies).

  NAO precisa de administrador. NAO mexe na lixeira, em
  pastas do sistema nem em nada sincronizado com OneDrive.

  Conta o que removeu E o que pulou (arquivo em uso), e
  gera relatorio .txt no perfil do usuario.
================================================================
#>

# ---------------------------------------------------------------
#  CAMINHOS
# ---------------------------------------------------------------
$data    = Get-Date -Format 'yyyyMMdd_HHmm'
$arquivo = "$env:USERPROFILE\limpeza_usuario_$data.txt"

# ---------------------------------------------------------------
#  FUNCAO: LIMPAR PASTA (item a item)
#  Por que item a item e nao "Remove-Item pasta\*"?
#  Remove-Item em lote falha em cascata no primeiro arquivo em
#  uso e pula coisa em silencio. Item a item: o que esta travado
#  e contado como "pulado" e o resto e removido. Relatorio honesto.
# ---------------------------------------------------------------
function Limpar-Pasta {
    param(
        [string]$Caminho,
        [string]$Descricao
    )

    if (-not (Test-Path $Caminho)) {
        return [PSCustomObject]@{
            Descricao = $Descricao; Removidos = 0; Pulados = 0; MBLiberados = 0; Existe = $false
        }
    }

    $arquivos = Get-ChildItem -Path $Caminho -Recurse -Force -File -ErrorAction SilentlyContinue

    $removidos = 0; $pulados = 0; $bytes = 0
    foreach ($a in $arquivos) {
        try {
            $tam = $a.Length
            Remove-Item -LiteralPath $a.FullName -Force -ErrorAction Stop
            $removidos++; $bytes += $tam
        } catch {
            $pulados++   # arquivo em uso -> pula e segue
        }
    }

    # Remove subpastas vazias que sobraram (de baixo pra cima)
    Get-ChildItem -Path $Caminho -Recurse -Force -Directory -ErrorAction SilentlyContinue |
        Sort-Object { $_.FullName.Length } -Descending |
        ForEach-Object { try { Remove-Item -LiteralPath $_.FullName -Force -Recurse -ErrorAction Stop } catch {} }

    return [PSCustomObject]@{
        Descricao   = $Descricao
        Removidos   = $removidos
        Pulados     = $pulados
        MBLiberados = [math]::Round($bytes / 1MB, 1)
        Existe      = $true
    }
}

# ---------------------------------------------------------------
#  CABECALHO
# ---------------------------------------------------------------
$log  = @()
$log += '================================================'
$log += '   RELATORIO - LIMPEZA DE PERFIL DO USUARIO'
$log += '   Tecnico: Davi Senise - Suporte TI'
$log += '================================================'
$log += ''
$log += 'Data: '    + (Get-Date -Format 'dd/MM/yyyy HH:mm')
$log += 'Maquina: ' + $env:COMPUTERNAME
$log += 'Usuario: ' + $env:USERNAME
$log += ''

$totalArquivos = 0
$totalPulados  = 0
$totalMB       = 0

function Registrar($passo, $r) {
    if (-not $r.Existe) {
        Write-Host "$passo $($r.Descricao): pasta nao existe (ok, nem todo PC tem)" -ForegroundColor DarkGray
        $script:log += "$passo $($r.Descricao): pasta nao existe"
        return
    }
    $msg = "{0}: {1} removidos ({2} MB)" -f $r.Descricao, $r.Removidos, $r.MBLiberados
    if ($r.Pulados -gt 0) { $msg += ", {0} em uso (pulados)" -f $r.Pulados }
    Write-Host "$passo $msg"
    $script:log += "$passo $msg"
    $script:totalArquivos += $r.Removidos
    $script:totalPulados  += $r.Pulados
    $script:totalMB       += $r.MBLiberados
}

Write-Host ""
Write-Host "Limpando perfil de $env:USERNAME..." -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------
#  AVISO SOBRE NAVEGADORES
#  Cache de navegador aberto fica quase todo travado. Avisamos
#  antes pra pessoa poder fechar e aproveitar melhor a limpeza.
# ---------------------------------------------------------------
$navAbertos = @()
if (Get-Process chrome -ErrorAction SilentlyContinue) { $navAbertos += 'Chrome' }
if (Get-Process msedge -ErrorAction SilentlyContinue) { $navAbertos += 'Edge' }
if ($navAbertos.Count -gt 0) {
    Write-Host ("AVISO: {0} aberto(s). O cache deles vai ficar quase todo travado." -f ($navAbertos -join ' e ')) -ForegroundColor Yellow
    Write-Host "       Pra limpeza completa, feche o(s) navegador(es) e rode de novo." -ForegroundColor Yellow
    Write-Host ""
}

# ---------------------------------------------------------------
#  EXECUCAO
# ---------------------------------------------------------------

# [1/5] Temporarios do usuario
Registrar '[1/5]' (Limpar-Pasta -Caminho $env:TEMP -Descricao "Temporarios do usuario")

# [2/5] Cache de internet (WinINet - usado por apps do Windows)
Registrar '[2/5]' (Limpar-Pasta -Caminho "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" -Descricao "Cache de internet")

# [3/5] Crash dumps (despejos de erro de apps - so ocupam espaco)
Registrar '[3/5]' (Limpar-Pasta -Caminho "$env:LOCALAPPDATA\CrashDumps" -Descricao "Crash dumps")

# [4/5] Cache de miniaturas do Explorer (regenera sozinho)
Write-Host '[4/5] Limpando cache de miniaturas...'
$thumbs = 0; $thumbBytes = 0
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "thumbcache_*.db" -Force -ErrorAction SilentlyContinue |
    ForEach-Object {
        try { $t = $_.Length; Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop; $thumbs++; $thumbBytes += $t } catch {}
    }
$mbThumbs = [math]::Round($thumbBytes / 1MB, 1)
Write-Host "      Miniaturas: $thumbs removidas ($mbThumbs MB)"
$log += "[4/5] Miniaturas: $thumbs removidas ($mbThumbs MB)"
$totalArquivos += $thumbs
$totalMB       += $mbThumbs

# [5/5] Cache de navegadores - SO a pasta Cache.
# NUNCA tocar em Login Data, History, Cookies ou Bookmarks.
Write-Host '[5/5] Limpando cache de navegadores...'
$cachesNav = @(
    @{ Caminho = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache";    Nome = "Chrome (cache)" },
    @{ Caminho = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"; Nome = "Chrome (code cache)" },
    @{ Caminho = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache";   Nome = "Edge (cache)" },
    @{ Caminho = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"; Nome = "Edge (code cache)" }
)
$navRemovidos = 0; $navPulados = 0; $navMB = 0
foreach ($c in $cachesNav) {
    $r = Limpar-Pasta -Caminho $c.Caminho -Descricao $c.Nome
    if ($r.Existe) {
        $navRemovidos += $r.Removidos
        $navPulados   += $r.Pulados
        $navMB        += $r.MBLiberados
    }
}
$navMB = [math]::Round($navMB, 1)
$msgNav = "Navegadores: $navRemovidos removidos ($navMB MB)"
if ($navPulados -gt 0) { $msgNav += ", $navPulados em uso (pulados)" }
Write-Host "      $msgNav"
$log += "[5/5] $msgNav"
$totalArquivos += $navRemovidos
$totalPulados  += $navPulados
$totalMB       += $navMB
$totalMB = [math]::Round($totalMB, 1)

# ---------------------------------------------------------------
#  TOTAIS E RELATORIO
# ---------------------------------------------------------------
$log += ''
$log += '================================================'
$log += "TOTAL REMOVIDO: $totalArquivos arquivos ($totalMB MB)"
if ($totalPulados -gt 0) { $log += "EM USO (PULADOS): $totalPulados arquivos" }
$log += '================================================'
$log += ''
$log += 'Escopo: somente perfil do usuario. Lixeira, pastas de'
$log += 'sistema e dados de navegador (senhas/historico/cookies)'
$log += 'NAO sao tocados por este script.'
$log += ''
$log += 'Status: concluido'
$log | Out-File -FilePath $arquivo -Encoding UTF8

Write-Host ''
Write-Host '================================================' -ForegroundColor Green
Write-Host ' Limpeza concluida!' -ForegroundColor Green
Write-Host (" Removido: $totalArquivos arquivos ($totalMB MB)") -ForegroundColor Green
if ($totalPulados -gt 0) {
    Write-Host (" Em uso (nao removidos): $totalPulados arquivos") -ForegroundColor Yellow
    Write-Host ("   -> feche apps/navegadores e rode de novo pra pegar esses") -ForegroundColor DarkGray
}
Write-Host (" Relatorio: $arquivo") -ForegroundColor Green
Write-Host '================================================' -ForegroundColor Green
Write-Host ''
Read-Host 'Pressione Enter para sair'

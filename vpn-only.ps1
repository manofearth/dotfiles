#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Запрещает приложениям выходить в сеть мимо VPN (самодельный kill switch для отдельных программ).

.DESCRIPTION
    Создаёт исходящее блокирующее правило брандмауэра Windows для указанного .exe,
    ограниченное физическими сетевыми адаптерами (Wi-Fi, Ethernet и т.п.).
    Через VPN-туннель (виртуальный адаптер) приложение работает, напрямую — нет.

    Все правила скрипта лежат в группе "VPN-only apps".
    Не редактируйте их в wf.msc: оснастка не умеет показывать привязку к конкретным
    интерфейсам и может её сбросить при сохранении — тогда приложение заблокируется полностью.

.EXAMPLE
    .\vpn-only.ps1 "C:\Program Files\Google\Chrome\Application\chrome.exe"
    Добавить (или пересоздать) правило для приложения.

.EXAMPLE
    .\vpn-only.ps1
    Интерактивное меню: список правил, включение/выключение, добавление, удаление.

.EXAMPLE
    .\vpn-only.ps1 -Disable chrome
    Выключить правило (по номеру из списка или по части имени .exe). Аналогично -Enable, -Remove.

.EXAMPLE
    .\vpn-only.ps1 -Refresh
    Перепривязать все правила к текущему набору физических адаптеров (после подключения нового адаптера).
#>
[CmdletBinding(DefaultParameterSetName = 'Menu')]
param(
    [Parameter(ParameterSetName = 'Add', Position = 0, Mandatory)]
    [string]$Path,

    [Parameter(ParameterSetName = 'List', Mandatory)]
    [switch]$List,

    [Parameter(ParameterSetName = 'Enable', Mandatory)]
    [string]$Enable,

    [Parameter(ParameterSetName = 'Disable', Mandatory)]
    [string]$Disable,

    [Parameter(ParameterSetName = 'Remove', Mandatory)]
    [string]$Remove,

    [Parameter(ParameterSetName = 'Refresh', Mandatory)]
    [switch]$Refresh
)

$ErrorActionPreference = 'Stop'
$Group = 'VPN-only apps'

function Get-PhysicalInterfaces {
    $names = @(Get-NetAdapter -Physical | Select-Object -ExpandProperty Name)
    if (-not $names) { throw 'Не найдено ни одного физического сетевого адаптера.' }
    $names
}

function Get-VpnOnlyRules {
    $rules = @(Get-NetFirewallRule -Group $Group -ErrorAction SilentlyContinue | ForEach-Object {
        [pscustomobject]@{
            N          = 0
            Enabled    = [string]$_.Enabled -eq 'True'
            Program    = ($_ | Get-NetFirewallApplicationFilter).Program
            Interfaces = @(($_ | Get-NetFirewallInterfaceFilter).InterfaceAlias) -join ', '
            Rule       = $_
        }
    } | Sort-Object Program)
    for ($i = 0; $i -lt $rules.Count; $i++) { $rules[$i].N = $i + 1 }
    $rules
}

function Show-Rules {
    $rules = @(Get-VpnOnlyRules)
    if (-not $rules) {
        Write-Host 'Правил пока нет.' -ForegroundColor Yellow
        return
    }
    $rules | Format-Table -AutoSize N,
        @{ n = 'Состояние'; e = { if ($_.Enabled) { 'вкл' } else { 'ВЫКЛ' } } },
        @{ n = 'Приложение'; e = { $_.Program } },
        @{ n = 'Блок. интерфейсы'; e = { $_.Interfaces } } | Out-Host
}

# Селектор: номер из списка или часть имени .exe (например "chrome")
function Find-Rules([string]$Selector) {
    $rules = @(Get-VpnOnlyRules)
    if ($Selector -match '^\d+$') {
        $found = @($rules | Where-Object N -eq ([int]$Selector))
    } else {
        $found = @($rules | Where-Object { (Split-Path $_.Program -Leaf) -like "*$Selector*" })
    }
    if (-not $found) { throw "Правило '$Selector' не найдено." }
    $found
}

function Add-Rule([string]$AppPath) {
    $AppPath = $AppPath.Trim().Trim('"')
    if (-not (Test-Path -LiteralPath $AppPath -PathType Leaf)) { throw "Файл не найден: $AppPath" }
    $full = (Resolve-Path -LiteralPath $AppPath).ProviderPath
    if ([IO.Path]::GetExtension($full) -ne '.exe') { throw "Ожидается .exe файл: $full" }

    $existing = @(Get-VpnOnlyRules | Where-Object { $_.Program -eq $full })
    $ifs = Get-PhysicalInterfaces
    New-NetFirewallRule -DisplayName "VPN-only: $(Split-Path $full -Leaf)" -Group $Group `
        -Description "Блокирует $full вне VPN (создано vpn-only.ps1)" `
        -Direction Outbound -Action Block -Program $full -InterfaceAlias $ifs -Profile Any | Out-Null
    # Старое удаляем после создания нового, чтобы не было окна без блокировки
    $existing | ForEach-Object { $_.Rule | Remove-NetFirewallRule }

    $verb = if ($existing) { 'Пересоздано' } else { 'Добавлено' }
    Write-Host "$verb правило для $full (блок на: $($ifs -join ', '))" -ForegroundColor Green
}

function Set-RulesState([string]$Selector, [bool]$On) {
    foreach ($r in Find-Rules $Selector) {
        if ($On) { $r.Rule | Enable-NetFirewallRule } else { $r.Rule | Disable-NetFirewallRule }
        Write-Host "$(if ($On) { 'Включено' } else { 'Выключено' }): $($r.Program)"
    }
}

function Switch-RuleState([string]$Selector) {
    foreach ($r in Find-Rules $Selector) { Set-RulesState $r.N (-not $r.Enabled) }
}

function Remove-Rules([string]$Selector) {
    foreach ($r in Find-Rules $Selector) {
        $r.Rule | Remove-NetFirewallRule
        Write-Host "Удалено: $($r.Program)"
    }
}

function Update-RuleInterfaces {
    $ifs = Get-PhysicalInterfaces
    foreach ($r in Get-VpnOnlyRules) { $r.Rule | Set-NetFirewallRule -InterfaceAlias $ifs }
    Write-Host "Правила привязаны к: $($ifs -join ', ')" -ForegroundColor Green
}

function Start-Menu {
    while ($true) {
        Show-Rules
        Write-Host '[номер] вкл/выкл | a - добавить | d <номер> - удалить | u - обновить интерфейсы | q - выход'
        $cmd = (Read-Host '>').Trim()
        try {
            switch -Regex ($cmd) {
                '^q$'          { return }
                '^a$'          { Add-Rule (Read-Host 'Путь к .exe') }
                '^d\s*(\d+)$'  { Remove-Rules $Matches[1] }
                '^u$'          { Update-RuleInterfaces }
                '^\d+$'        { Switch-RuleState $cmd }
                '^$'           { }
                default        { Write-Host 'Неизвестная команда.' -ForegroundColor Yellow }
            }
        } catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
        Write-Host
    }
}

switch ($PSCmdlet.ParameterSetName) {
    'Add'     { Add-Rule $Path; Show-Rules }
    'List'    { Show-Rules }
    'Enable'  { Set-RulesState $Enable $true }
    'Disable' { Set-RulesState $Disable $false }
    'Remove'  { Remove-Rules $Remove }
    'Refresh' { Update-RuleInterfaces }
    'Menu'    { Start-Menu }
}

#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Направляет трафик к указанному IP напрямую, в обход VPN-туннеля.

.DESCRIPTION
    Создаёт постоянный маршрут к одному IPv4 (/32) или IPv6 (/128) через шлюз
    физического адаптера. Использует New-NetRoute — аналог route -p add.
    Маршрут сохраняется после перезагрузки и действует для всех приложений.

    Автоматически выбирает подключённый физический адаптер с маршрутом по
    умолчанию и минимальной суммой метрик маршрута и интерфейса. Можно указать
    -InterfaceIndex, а если VPN убрал обычный маршрут по умолчанию — ещё -Gateway.
    После смены сети/шлюза старый маршрут нужно удалить и добавить заново.

    У маршрутов Windows нет группы или метки скрипта. Список и удаление работают
    со ВСЕМИ постоянными маршрутами /32 и /128 через шлюзы физических адаптеров,
    в том числе созданными вручную. Временные и on-link маршруты не включаются.
    Наличие записи не гарантирует обход: VPN может блокировать прямой трафик
    своим kill switch. Блокировки из vpn-only.ps1 также продолжают действовать.

.EXAMPLE
    .\vpn-bypass.ps1 203.0.113.10
    Добавить постоянный маршрут через автоматически выбранный шлюз.

.EXAMPLE
    .\vpn-bypass.ps1 2001:db8::10
    Добавить маршрут к IPv6 (нужен физический адаптер с IPv6-шлюзом).

.EXAMPLE
    .\vpn-bypass.ps1 203.0.113.10 -InterfaceIndex 12 -Gateway 192.168.1.1
    Указать адаптер и шлюз вручную. Индексы: Get-NetAdapter -Physical.

.EXAMPLE
    .\vpn-bypass.ps1 -List
    Показать постоянные маршруты обхода VPN.

.EXAMPLE
    .\vpn-bypass.ps1 -Remove 203.0.113.10
    Удалить маршруты к IP. Можно указать номер из списка: -Remove 1.

.EXAMPLE
    .\vpn-bypass.ps1 203.0.113.10 -WhatIf
    Показать планируемое изменение без добавления маршрута.

.EXAMPLE
    .\vpn-bypass.ps1
    Интерактивное меню: список, добавление и удаление маршрутов.

.LINK
    https://learn.microsoft.com/powershell/module/nettcpip/new-netroute
#>
[CmdletBinding(DefaultParameterSetName = 'Menu', SupportsShouldProcess)]
param(
    [Parameter(ParameterSetName = 'Add', Position = 0, Mandatory)]
    [Alias('IP', 'IPAddress')]
    [string]$Address,

    [Parameter(ParameterSetName = 'Add')]
    [ValidateRange(1, 2147483647)]
    [int]$InterfaceIndex,

    [Parameter(ParameterSetName = 'Add')]
    [string]$Gateway,

    [Parameter(ParameterSetName = 'List', Mandatory)]
    [switch]$List,

    [Parameter(ParameterSetName = 'Remove', Mandatory)]
    [string]$Remove
)

$ErrorActionPreference = 'Stop'

function ConvertTo-IPAddress([string]$Value) {
    $value = $Value.Trim()
    $ip = $null
    if (-not [System.Net.IPAddress]::TryParse($value, [ref]$ip)) {
        throw "Некорректный IP-адрес: '$Value'. Укажите один IP, без маски и имени домена."
    }
    # TryParse допускает сокращённые, числовые, восьмеричные и hex-формы IPv4.
    if ($ip.AddressFamily -eq 'InterNetwork' -and
        $value -notmatch '^(0|[1-9][0-9]{0,2})(\.(0|[1-9][0-9]{0,2})){3}$') {
        throw "Укажите IPv4 полностью, например 203.0.113.10: '$Value'."
    }
    if ($ip.AddressFamily -eq 'InterNetworkV6' -and ($ip.IsIPv4MappedToIPv6 -or $value.Contains('%'))) {
        throw 'Укажите обычный IPv4 или IPv6 без идентификатора зоны (%). Интерфейс задаётся через -InterfaceIndex.'
    }
    if ([System.Net.IPAddress]::IsLoopback($ip) -or
        ($ip.AddressFamily -eq 'InterNetwork' -and ($ip.GetAddressBytes()[0] -eq 0 -or $ip.GetAddressBytes()[0] -ge 224)) -or
        ($ip.AddressFamily -eq 'InterNetworkV6' -and ($ip.Equals([System.Net.IPAddress]::IPv6Any) -or $ip.IsIPv6Multicast))) {
        throw "Ожидается одноадресный IP, не loopback, multicast или неопределённый адрес: '$Value'."
    }
    $ip
}

function Get-HostPrefix([string]$Value) {
    $ip = ConvertTo-IPAddress $Value
    if ($ip.AddressFamily -eq 'InterNetworkV6' -and $ip.IsIPv6LinkLocal) {
        throw 'Link-local IPv6 не маршрутизируется через шлюз. Укажите глобальный IPv6 или ULA.'
    }
    if ($ip.AddressFamily -eq 'InterNetwork') { "$ip/32" } else { "$ip/128" }
}

function Get-DirectGateway([string]$Family, [int]$Index, [string]$NextHop) {
    if ($NextHop -and -not $Index) { throw 'Вместе с -Gateway укажите -InterfaceIndex.' }
    $adapters = @(Get-NetAdapter -Physical -IncludeHidden | Where-Object {
        $_.Status -eq 'Up' -and (-not $Index -or $_.InterfaceIndex -eq $Index)
    })
    if (-not $adapters) {
        throw 'Не найден подключённый физический адаптер. Проверьте подключение и -InterfaceIndex (Get-NetAdapter -Physical).'
    }
    if ($NextHop) {
        $ip = ConvertTo-IPAddress $NextHop
        $gatewayFamily = if ($ip.AddressFamily -eq 'InterNetwork') { 'IPv4' } else { 'IPv6' }
        if ($gatewayFamily -ne $Family) { throw "IP и шлюз должны быть одной версии ($Family)." }
        return [pscustomobject]@{ InterfaceIndex = $Index; NextHop = $ip.ToString() }
    }

    $defaultPrefix = if ($Family -eq 'IPv4') { '0.0.0.0/0' } else { '::/0' }
    $routes = @(Get-NetRoute -AddressFamily $Family -PolicyStore ActiveStore | Where-Object {
        $_.DestinationPrefix -eq $defaultPrefix -and $_.InterfaceIndex -in $adapters.InterfaceIndex -and
        $_.NextHop -notin @('0.0.0.0', '::')
    } | Sort-Object @{ e = { [long]$_.RouteMetric + [long]$_.InterfaceMetric } }, InterfaceIndex, NextHop)
    if (-not $routes) {
        throw "Не найден обычный шлюз $Family. Укажите -InterfaceIndex и -Gateway вручную или повторите без VPN."
    }
    $routes[0]
}

function Get-BypassRoutes {
    $adapters = @(Get-NetAdapter -Physical -IncludeHidden)
    if (-not $adapters) { return }
    $rules = @(Get-NetRoute -PolicyStore PersistentStore | Where-Object {
        $_.DestinationPrefix -match '/(32|128)$' -and $_.InterfaceIndex -in $adapters.InterfaceIndex -and
        $_.NextHop -notin @('0.0.0.0', '::')
    } | Sort-Object DestinationPrefix, InterfaceIndex, NextHop | ForEach-Object {
        [pscustomobject]@{
            N          = 0
            IP         = ($_.DestinationPrefix -split '/')[0]
            Gateway    = $_.NextHop
            Interface  = $_.InterfaceAlias
            Index      = $_.InterfaceIndex
            Metric     = $_.RouteMetric
            Prefix     = $_.DestinationPrefix
        }
    })
    for ($i = 0; $i -lt $rules.Count; $i++) { $rules[$i].N = $i + 1 }
    $rules
}

function Show-Rules {
    $rules = @(Get-BypassRoutes)
    if (-not $rules) {
        Write-Host 'Постоянных маршрутов обхода через физические адаптеры нет.' -ForegroundColor Yellow
        return
    }
    Write-Host 'Постоянные маршруты к IP через физические адаптеры (включая добавленные вручную):'
    $rules | Format-Table -AutoSize N, IP,
        @{ n = 'Шлюз'; e = { $_.Gateway } },
        @{ n = 'Интерфейс'; e = { $_.Interface } },
        @{ n = 'ifIndex'; e = { $_.Index } },
        @{ n = 'Метрика'; e = { $_.Metric } } | Out-Host
}

function Get-MatchingRoutes([hashtable]$Identity, [string]$Store) {
    # Перечисление без фильтра CIM не выдаёт ошибку «не найдено» на пустой таблице.
    Get-NetRoute -PolicyStore $Store | Where-Object {
        $_.DestinationPrefix -eq $Identity.DestinationPrefix -and
        $_.InterfaceIndex -eq $Identity.InterfaceIndex -and $_.NextHop -eq $Identity.NextHop
    }
}

function Add-Rule([string]$Value, [int]$Index, [string]$NextHop) {
    $prefix = Get-HostPrefix $Value
    $family = if ($prefix.EndsWith('/32')) { 'IPv4' } else { 'IPv6' }
    $direct = Get-DirectGateway $family $Index $NextHop
    $identity = @{
        DestinationPrefix = $prefix
        InterfaceIndex    = $direct.InterfaceIndex
        NextHop           = $direct.NextHop
    }
    $saved = @(Get-MatchingRoutes $identity 'PersistentStore')
    $active = @(Get-MatchingRoutes $identity 'ActiveStore')
    $target = "$prefix -> $($direct.NextHop), ifIndex $($direct.InterfaceIndex)"
    if ($saved) {
        if (-not $active -and $PSCmdlet.ShouldProcess($target, 'Восстановить активный маршрут')) {
            New-NetRoute @identity -RouteMetric $saved[0].RouteMetric -PolicyStore ActiveStore | Out-Null
        }
        Write-Host "Постоянный маршрут уже настроен: $target" -ForegroundColor Green
        return
    }
    # Не удаляем временную запись (она может принадлежать другому ПО).
    if ($active) {
        throw "Уже есть временный маршрут: $target. Удалите его в создавшей программе перед добавлением постоянного."
    }
    if (-not $PSCmdlet.ShouldProcess($target, 'Создать постоянный маршрут обхода VPN')) { return }
    # Без -PolicyStore маршрут создаётся сразу в ActiveStore и PersistentStore.
    New-NetRoute @identity -RouteMetric 1 | Out-Null
    Write-Host "Добавлен постоянный маршрут: $target" -ForegroundColor Green

    $competitors = @(Get-NetRoute -AddressFamily $family -PolicyStore ActiveStore | Where-Object {
        $_.DestinationPrefix -eq $prefix -and
        ($_.InterfaceIndex -ne $direct.InterfaceIndex -or $_.NextHop -ne $direct.NextHop)
    })
    if ($competitors) {
        Write-Warning 'Для этого IP есть другие маршруты той же длины. Выбор зависит от суммы метрик маршрута и интерфейса; проверьте Find-NetRoute -RemoteIPAddress <IP>.'
    }
}

function Remove-Rules([string]$Selector) {
    $selector = $Selector.Trim()
    $rules = @(Get-BypassRoutes)
    if ($selector -match '^\d+$') {
        $found = @($rules | Where-Object { [string]$_.N -eq $selector })
    } else {
        $prefix = Get-HostPrefix $selector
        $found = @($rules | Where-Object Prefix -eq $prefix)
    }
    if (-not $found) { throw "Постоянный маршрут '$Selector' не найден в списке обхода." }
    foreach ($rule in $found) {
        $identity = @{
            DestinationPrefix = $rule.Prefix
            InterfaceIndex    = $rule.Index
            NextHop           = $rule.Gateway
        }
        $target = "$($rule.Prefix) -> $($rule.Gateway), ifIndex $($rule.Index)"
        if (-not $PSCmdlet.ShouldProcess($target, 'Удалить постоянный и активный маршруты')) { continue }
        Remove-NetRoute @identity -PolicyStore PersistentStore -Confirm:$false
        if (@(Get-MatchingRoutes $identity 'ActiveStore').Count) {
            Remove-NetRoute @identity -PolicyStore ActiveStore -Confirm:$false
        }
        Write-Host "Удалено: $target"
    }
}

function Start-Menu {
    while ($true) {
        Show-Rules
        Write-Host 'a - добавить | d <номер или IP> - удалить | q - выход'
        $cmd = (Read-Host '>').Trim()
        try {
            switch -Regex ($cmd) {
                '^q$'        { return }
                '^a$'        { Add-Rule (Read-Host 'IP-адрес') }
                '^d\s+(.+)$' { Remove-Rules $Matches[1] }
                '^$'         { }
                default      { Write-Host 'Неизвестная команда.' -ForegroundColor Yellow }
            }
        } catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
        Write-Host
    }
}

switch ($PSCmdlet.ParameterSetName) {
    'Add'    { Add-Rule $Address $InterfaceIndex $Gateway; Show-Rules }
    'List'   { Show-Rules }
    'Remove' { Remove-Rules $Remove; Show-Rules }
    'Menu'   { Start-Menu }
}

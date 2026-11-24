# Run with Pester 3/4: Invoke-Pester -Script .\tests\vpn-bypass.Tests.ps1
# Every network cmdlet is mocked; tests never change the machine's routes.
$sourcePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'vpn-bypass.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }

# Run the actual parameter binding/dispatch without requiring elevation in tests.
$script:entryPoint = [scriptblock]::Create(($ast.Extent.Text -replace '(?m)^#Requires[^\r\n]*', ''))
foreach ($definition in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
    . ([scriptblock]::Create($definition.Extent.Text))
}

function New-TestRoute($Prefix, $Index = 12, $Hop = '192.168.1.1', $Metric = 1, $InterfaceMetric = 25) {
    [pscustomobject]@{
        DestinationPrefix = $Prefix
        InterfaceIndex    = $Index
        InterfaceAlias    = "Adapter $Index"
        NextHop           = $Hop
        RouteMetric       = $Metric
        InterfaceMetric   = $InterfaceMetric
        AddressFamily     = $(if ($Prefix.Contains(':')) { 'IPv6' } else { 'IPv4' })
    }
}

Describe 'vpn-bypass routes' {
    BeforeEach {
        $script:adapters = @(
            [pscustomobject]@{ InterfaceIndex = 12; Status = 'Up' }
            [pscustomobject]@{ InterfaceIndex = 24; Status = 'Up' }
            [pscustomobject]@{ InterfaceIndex = 36; Status = 'Disconnected' }
        )
        $script:savedRoutes = @()
        $script:activeRoutes = @(
            (New-TestRoute '0.0.0.0/0' 99 '10.8.0.1' 0 1) # VPN must never be selected.
            (New-TestRoute '0.0.0.0/0' 12 '192.168.1.1' 5 50)
            (New-TestRoute '0.0.0.0/0' 24 '192.168.2.1' 20 5)
            (New-TestRoute '0.0.0.0/0' 36 '192.168.3.1' 0 0)
        )
        Mock Get-NetAdapter { $script:adapters }
        Mock Get-NetRoute {
            $routes = if ($PolicyStore -eq 'PersistentStore') { $script:savedRoutes } else { $script:activeRoutes }
            $routes | Where-Object { -not $AddressFamily -or $_.AddressFamily -eq [string]$AddressFamily }
        }
        Mock New-NetRoute {
            $route = New-TestRoute $DestinationPrefix $InterfaceIndex $NextHop $RouteMetric
            if ($PolicyStore -ne 'ActiveStore') { $script:savedRoutes += $route }
            $script:activeRoutes += $route
            $route
        }
        Mock Remove-NetRoute {
            $removePrefix = @($DestinationPrefix)[0]
            $removeIndex = @($InterfaceIndex)[0]
            $removeHop = @($NextHop)[0]
            $keep = {
                $_.DestinationPrefix -ne $removePrefix -or
                $_.InterfaceIndex -ne $removeIndex -or $_.NextHop -ne $removeHop
            }
            if ($PolicyStore -eq 'PersistentStore') {
                $script:savedRoutes = @($script:savedRoutes | Where-Object $keep)
            } elseif ($PolicyStore -eq 'ActiveStore') {
                $script:activeRoutes = @($script:activeRoutes | Where-Object $keep)
            } else {
                throw 'Removal must explicitly specify a store.'
            }
        }
        Mock Write-Host {}
        Mock Write-Warning {}
        Mock Out-Host {}
    }

    It 'selects a connected physical default gateway using both metrics' {
        & $script:entryPoint '203.0.113.10'
        Assert-MockCalled New-NetRoute -Scope It -Times 1 -Exactly -ParameterFilter {
            $DestinationPrefix -eq '203.0.113.10/32' -and $InterfaceIndex -eq 24 -and
            $NextHop -eq '192.168.2.1' -and $RouteMetric -eq 1 -and -not $PolicyStore
        }
        $script:savedRoutes.Count | Should Be 1
    }

    It 'honors the selected physical interface' {
        & $script:entryPoint '203.0.113.10' -InterfaceIndex 12
        $script:savedRoutes[0].InterfaceIndex | Should Be 12
        $script:savedRoutes[0].NextHop | Should Be '192.168.1.1'
    }

    It 'accepts an explicit gateway when VPN removed physical default routes' {
        $script:activeRoutes = @($script:activeRoutes | Where-Object InterfaceIndex -eq 99)
        & $script:entryPoint '203.0.113.10' -InterfaceIndex 12 -Gateway '192.168.1.254'
        $script:savedRoutes[0].NextHop | Should Be '192.168.1.254'
    }

    It 'supports IPv6 host routes and link-local gateways' {
        $script:activeRoutes += New-TestRoute '::/0' 12 'fe80::1'
        & $script:entryPoint '2001:0db8:0:0:0:0:0:10'
        $script:savedRoutes[0].DestinationPrefix | Should Be '2001:db8::10/128'
        $script:savedRoutes[0].NextHop | Should Be 'fe80::1'
    }

    It 'does not create duplicates on repeated runs' {
        & $script:entryPoint '203.0.113.10'
        & $script:entryPoint '203.0.113.10'
        Assert-MockCalled New-NetRoute -Scope It -Times 1 -Exactly
        $script:savedRoutes.Count | Should Be 1
    }

    It 'restores a missing active entry without duplicating the persistent entry' {
        $script:savedRoutes = @((New-TestRoute '203.0.113.10/32' 24 '192.168.2.1' 7))
        & $script:entryPoint '203.0.113.10'
        Assert-MockCalled New-NetRoute -Scope It -Times 1 -Exactly -ParameterFilter {
            $PolicyStore -eq 'ActiveStore' -and $RouteMetric -eq 7
        }
        $script:savedRoutes.Count | Should Be 1
    }

    It 'does not replace an existing temporary route' {
        $script:activeRoutes += New-TestRoute '203.0.113.10/32' 24 '192.168.2.1'
        { & $script:entryPoint '203.0.113.10' } | Should Throw
        Assert-MockCalled New-NetRoute -Scope It -Times 0 -Exactly
        Assert-MockCalled Remove-NetRoute -Scope It -Times 0 -Exactly
    }

    It 'lists only persistent gateway host routes on physical adapters' {
        $script:savedRoutes = @(
            (New-TestRoute '203.0.113.10/32')
            (New-TestRoute '2001:db8::10/128' 12 'fe80::1')
            (New-TestRoute '203.0.113.11/32' 36 '192.168.3.1') # Disconnected, but still configured.
            (New-TestRoute '203.0.113.12/32' 99 '10.8.0.1')
            (New-TestRoute '192.168.1.5/32' 12 '0.0.0.0')
            (New-TestRoute '2001:db8::20/128' 12 '::')
            (New-TestRoute '203.0.113.0/24')
        )
        $script:activeRoutes += New-TestRoute '203.0.113.13/32'
        $rules = @(Get-BypassRoutes)
        $rules.Count | Should Be 3
        $rules[0].N | Should Be 1
        $rules[2].N | Should Be 3
        & $script:entryPoint -List
        Assert-MockCalled New-NetRoute -Scope It -Times 0 -Exactly
        Assert-MockCalled Remove-NetRoute -Scope It -Times 0 -Exactly
    }

    It 'removes only the selected route from both stores' {
        $selected = New-TestRoute '203.0.113.10/32'
        $vpn = New-TestRoute '203.0.113.10/32' 99 '10.8.0.1'
        $other = New-TestRoute '203.0.113.11/32'
        $script:savedRoutes = @($selected, $vpn, $other)
        $script:activeRoutes += @($selected, $vpn, $other)
        & $script:entryPoint -Remove 1
        Assert-MockCalled Remove-NetRoute -Scope It -Times 2 -Exactly -ParameterFilter {
            $DestinationPrefix -eq '203.0.113.10/32' -and $InterfaceIndex -eq 12 -and $NextHop -eq '192.168.1.1'
        }
        $script:savedRoutes.Count | Should Be 2
        @($script:activeRoutes | Where-Object InterfaceIndex -eq 99).Count | Should Be 2
    }

    It 'removes all matching physical routes when selecting by IP' {
        $script:savedRoutes = @(
            (New-TestRoute '203.0.113.10/32')
            (New-TestRoute '203.0.113.10/32' 24 '192.168.2.1')
        )
        $script:activeRoutes += $script:savedRoutes
        & $script:entryPoint -Remove '203.0.113.10'
        $script:savedRoutes.Count | Should Be 0
        Assert-MockCalled Remove-NetRoute -Scope It -Times 4 -Exactly
    }

    It 'removes an inactive persistent route' {
        $script:savedRoutes = @((New-TestRoute '203.0.113.10/32'))
        & $script:entryPoint -Remove '203.0.113.10'
        Assert-MockCalled Remove-NetRoute -Scope It -Times 1 -Exactly -ParameterFilter { $PolicyStore -eq 'PersistentStore' }
    }

    It 'does not delete anything for a missing selector' {
        { & $script:entryPoint -Remove '203.0.113.10' } | Should Throw
        Assert-MockCalled Remove-NetRoute -Scope It -Times 0 -Exactly
    }

    It 'honors WhatIf for add, restore and remove' {
        & $script:entryPoint '203.0.113.10' -WhatIf
        $script:savedRoutes = @((New-TestRoute '203.0.113.10/32' 24 '192.168.2.1'))
        & $script:entryPoint '203.0.113.10' -WhatIf
        & $script:entryPoint -Remove 1 -WhatIf
        Assert-MockCalled New-NetRoute -Scope It -Times 0 -Exactly
        Assert-MockCalled Remove-NetRoute -Scope It -Times 0 -Exactly
    }

    It 'warns about competing host routes without removing them' {
        $script:activeRoutes += New-TestRoute '203.0.113.10/32' 99 '10.8.0.1'
        & $script:entryPoint '203.0.113.10'
        Assert-MockCalled Write-Warning -Scope It -Times 1 -Exactly
        Assert-MockCalled Remove-NetRoute -Scope It -Times 0 -Exactly
    }

    It 'refuses to use VPN when no physical default gateway exists' {
        $script:activeRoutes = @($script:activeRoutes | Where-Object InterfaceIndex -eq 99)
        { & $script:entryPoint '203.0.113.10' } | Should Throw
        Assert-MockCalled New-NetRoute -Scope It -Times 0 -Exactly
    }

    It 'rejects virtual and disconnected interface selections' {
        { & $script:entryPoint '203.0.113.10' -InterfaceIndex 99 -Gateway '192.168.1.1' } | Should Throw
        { & $script:entryPoint '203.0.113.10' -InterfaceIndex 36 -Gateway '192.168.1.1' } | Should Throw
        Assert-MockCalled New-NetRoute -Scope It -Times 0 -Exactly
    }

    It 'validates gateway family and requires its interface' {
        { & $script:entryPoint '203.0.113.10' -Gateway '192.168.1.1' } | Should Throw
        { & $script:entryPoint '203.0.113.10' -InterfaceIndex 12 -Gateway 'fe80::1' } | Should Throw
        Assert-MockCalled New-NetRoute -Scope It -Times 0 -Exactly
    }

    It 'rejects malformed and special destination addresses before making changes' {
        foreach ($invalid in @('example.com', '203.0.113.10/24', '999.1.2.3', '127.1', '1234', '0x7f000001', '010.1.2.3',
            '0.0.0.0', '127.0.0.1', '224.0.0.1', '255.255.255.255', '::', '::1', 'ff02::1', 'fe80::1',
            'fe80::1%12', '::ffff:203.0.113.10')) {
            { & $script:entryPoint $invalid } | Should Throw
        }
        Assert-MockCalled New-NetRoute -Scope It -Times 0 -Exactly
        Assert-MockCalled Remove-NetRoute -Scope It -Times 0 -Exactly
    }

    It 'adds and removes a route through the interactive menu' {
        $script:answers = New-Object System.Collections.Queue
        foreach ($answer in @('a', '203.0.113.10', 'd 1', 'q')) { $script:answers.Enqueue($answer) }
        Mock Read-Host {
            if (-not $script:answers.Count) { throw 'Unexpected menu prompt.' }
            $script:answers.Dequeue()
        }
        & $script:entryPoint
        $script:answers.Count | Should Be 0
        $script:savedRoutes.Count | Should Be 0
        Assert-MockCalled New-NetRoute -Scope It -Times 1 -Exactly
        Assert-MockCalled Remove-NetRoute -Scope It -Times 2 -Exactly
    }

    It 'propagates route enumeration errors instead of reporting an empty list' {
        Mock Get-NetRoute { throw 'CIM unavailable' }
        { & $script:entryPoint -List } | Should Throw 'CIM unavailable'
        Assert-MockCalled New-NetRoute -Scope It -Times 0 -Exactly
    }
}

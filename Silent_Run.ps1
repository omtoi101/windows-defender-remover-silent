# Silent_Run.ps1
# This script provides a silent execution flow for Windows Defender removal.

# --- 1. RunAsTI Function (De-obfuscated for readability) ---
function RunAsTI {
    param(
        [string]$cmd = "powershell.exe",
        [string]$arg = ""
    )

    $id = 'RunAsTI'
    $userSid = ((whoami /user) -split ' ')[-1]
    $key = "Registry::HKU\$userSid\Volatile Environment"

    $code = @'
    $Int = [int32]; $Marshal = [System.Runtime.InteropServices.Marshal]
    $IntPtrType = [System.IntPtr]; $String = [string]
    $Types = @(); $TaskTypes = @();
    $Module = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('AveYo')), 1).DefineDynamicModule('AveYo')
    $Size = [uintptr]::Size

    0..5 | % { $Types += $Module.DefineType("AveYo_$_", 1179913, [ValueType]) }
    $Types += [uintptr]; 4..6 | % { $Types += $Types[$_].MakeByRefType() }

    $Kernel32 = 'kernel32.dll'; $Advapi32 = 'advapi32.dll'
    $CreateProcessParams = @($String, $String, $Int, $Int, $Int, $Int, $Int, $String, $Types[7], $Types[8])
    $RegOpenKeyExParams = @([uintptr], $String, $Int, $Int, $Types[9])
    $RegSetValueExParams = @([uintptr], $String, $Int, $Int, [byte[]], $Int)

    $Methods = @(
        @('CreateProcess', $Kernel32, $CreateProcessParams),
        @('RegOpenKeyEx', $Advapi32, $RegOpenKeyExParams),
        @('RegSetValueEx', $Advapi32, $RegSetValueExParams)
    )

    $Methods | % { $Module.DefineType("AveYo_Win32", 1179913).DefinePInvokeMethod($_[0], $_[1], 8214, 1, $String, $_[2], 1, 4) }

    # Structure definitions (simplified)
    $Structs = @(
        @($IntPtrType, $Int, $IntPtrType),
        @($Int, $Int, $Int, $Int, $IntPtrType, $Types[1]),
        @($Int, $String, $String, $String, $Int, $Int, $Int, $Int, $Int, $Int, $Int, $Int, [int16], [int16], $IntPtrType, $IntPtrType, $IntPtrType, $IntPtrType),
        @($Types[3], $IntPtrType),
        @($IntPtrType, $IntPtrType, $Int, $Int)
    )

    1..5 | % { $k = $_; $n = 1; $Structs[$_ - 1] | % { $Types[$k].DefineField('f' + $n++, $_, 6) } }
    0..5 | % { $TaskTypes += $Types[$_].CreateType() }
    0..5 | % { New-Variable "A$_" ([Activator]::CreateInstance($TaskTypes[$_])) -Force }

    function Invoke-Win32 ($method, $args) { $TaskTypes[0].GetMethod($method).Invoke(0, $args) }

    $isTI = (whoami /groups) -like '*1-16-16384*'
    $ProcessToImpersonate = 0
    if (!$isTI) {
        'TrustedInstaller', 'lsass', 'winlogon' | % {
            if (!$ProcessToImpersonate) {
                sc.exe start $_ | Out-Null
                $ProcessToImpersonate = (Get-Process -Name $_ -ErrorAction SilentlyContinue | Select-Object -First 1)
            }
        }

        $AllocHGlobal = $Marshal.GetMethod("AllocHGlobal", [type[]]@($Int))
        $WriteIntPtr = $Marshal.GetMethod("WriteIntPtr", [type[]]@($IntPtrType, $IntPtrType))
        $StructureToPtr = $Marshal.GetMethod("StructureToPtr", [type[]]@([object], $IntPtrType, [bool]))

        $HandlePtr = $AllocHGlobal.Invoke($null, @($Size))
        $AttrListPtr = $AllocHGlobal.Invoke($null, @(4 * $Size + 16))

        $WriteIntPtr.Invoke($null, @($HandlePtr, $ProcessToImpersonate.Handle))

        $A1.f1 = 131072; $A1.f2 = $Size; $A1.f3 = $HandlePtr
        $A2.f1 = 1; $A2.f2 = 1; $A2.f3 = 1; $A2.f4 = 1; $A2.f6 = $A1
        $A3.f1 = 10 * $Size + 32; $A4.f1 = $A3; $A4.f2 = $AttrListPtr

        $StructureToPtr.Invoke($null, @(($A2 -as $TaskTypes[2]), $A4.f2, $false))

        $ProcessParams = @($null, "powershell -win 1 -nop -c iex `$env:R; # $id", 0, 0, 0, 0x0E080600, 0, $null, ($A4 -as $TaskTypes[4]), ($A5 -as $TaskTypes[5]))
        Invoke-Win32 'CreateProcess' $ProcessParams
        return
    }

    $env:R = ''
    Remove-ItemProperty $volatileEnvKey $id -Force -ErrorAction SilentlyContinue
    $priv = [Diagnostics.Process].GetMember('SetPrivilege', 42)[0]
    'SeSecurityPrivilege', 'SeTakeOwnershipPrivilege', 'SeBackupPrivilege', 'SeRestorePrivilege' | % { $priv.Invoke($null, @("$_", 2)) }

    $HKU = [uintptr][uint32]2147483651
    $NT_AUTHORITY_SYSTEM = 'S-1-5-18'
    $reg = @($HKU, $NT_AUTHORITY_SYSTEM, 8, 2, ($HKU -as $Types[9]))
    Invoke-Win32 'RegOpenKeyEx' $reg
    $LinkHandle = $reg[4]

    function Set-SymbolicLink ($sid, $handle, $target) {
        Set-ItemProperty 'HKLM:\Software\Classes\AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}' 'RunAs' $target -Force -ErrorAction SilentlyContinue
        $bytes = [Text.Encoding]::Unicode.GetBytes("\Registry\User\$sid")
        Invoke-Win32 'RegSetValueEx' @($handle, 'SymbolicLinkValue', 0, 6, [byte[]]$bytes, $bytes.Length)
    }

    function Get-ExplorerPid { (Get-WmiObject Win32_Process -Filter 'Name="explorer.exe"' | Where-Object { $_.GetOwnerSid().Sid -eq $NT_AUTHORITY_SYSTEM } | Select-Object -Last 1).ProcessId }

    $isWin11Bug = ($((Get-WmiObject Win32_OperatingSystem).BuildNumber) -eq '22000') -and (($cmd -eq 'file:') -or (Test-Path -LiteralPath $cmd -PathType Container))
    if ($isWin11Bug) {
        [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
        [Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
        $path = '^(l)' + ($cmd -replace '([\+\^\%\~\(\)\[\]])', '{$1}') + '{ENTER}'
        $cmd = 'control.exe'; $arg = 'admintools'
    }

    Set-SymbolicLink ($volatileEnvKey -split '\\')[1] $LinkHandle ''
    $Proc = [Diagnostics.Process]::Start($cmd, $arg)
    if ($Proc) { $Proc.PriorityClass = 'High'; $Proc.WaitForExit() }

    if ($isWin11Bug) {
        $w = 0; do { if ($w -gt 40) { break }; Start-Sleep -Milliseconds 250; $w++ } until (Get-ExplorerPid)
        [Microsoft.VisualBasic.Interaction]::AppActivate($(Get-ExplorerPid))
        [System.Windows.Forms.SendKeys]::SendWait($path)
    }

    do { Start-Sleep -Seconds 7 } while (Get-ExplorerPid)
    Set-SymbolicLink '.Default' $LinkHandle 'Interactive User'
'@

    $vars = ''
    'cmd', 'arg', 'id', 'key' | % {
        $val = Get-Variable $_ -ValueOnly
        $vars += "`n`$$_='$($val -replace "'", "''")';"
    }

    Set-ItemProperty $key $id ($vars + $code) -Type ExpandString -Force -ErrorAction SilentlyContinue
    Start-Process powershell -ArgumentList "-win 1 -nop -c `n$vars `$env:R=(Get-ItemProperty `$key -ErrorAction SilentlyContinue).`$id; iex `$env:R" -Verb RunAs
}

# --- 2. Self-elevation Check ---
$isTI = (whoami /groups) -like '*1-16-16384*'

if (-not $isTI) {
    Write-Host "Elevating to TrustedInstaller..."
    RunAsTI "powershell.exe" "-noprofile -executionpolicy bypass -file `"$PSCommandPath`""
    exit
}

# --- 3. Main Execution Logic ---
try {
    Write-Host "Running as TrustedInstaller. Starting removal..."

    # Disable hypervisor
    bcdedit /set hypervisorlaunchtype off | Out-Null

    # Remove Windows Security UWP App
    $removeSecHealthPath = Join-Path $PSScriptRoot "RemoveSecHealthApp.ps1"
    if (Test-Path $removeSecHealthPath) {
        & $removeSecHealthPath
    }

    # Registry files
    $regDirs = @("Remove_defender", "Remove_SecurityComp")
    foreach ($dir in $regDirs) {
        $fullPath = Join-Path $PSScriptRoot $dir
        if (Test-Path $fullPath) {
            Get-ChildItem -Path $fullPath -Filter *.reg -Recurse | ForEach-Object {
                regedit.exe /s "$($_.FullName)"
            }
        }
    }

    # File and Directory Deletion (Consolidated)
    $itemsToDelete = @(
        "C:\Windows\WinSxS\FileMaps\wow64_windows-defender*.manifest",
        "C:\Windows\WinSxS\FileMaps\x86_windows-defender*.manifest",
        "C:\Windows\WinSxS\FileMaps\amd64_windows-defender*.manifest",
        "C:\Windows\System32\SecurityAndMaintenance_Error.png",
        "C:\Windows\System32\SecurityAndMaintenance.png",
        "C:\Windows\System32\SecurityHealthSystray.exe",
        "C:\Windows\System32\SecurityHealthService.exe",
        "C:\Windows\System32\SecurityHealthHost.exe",
        "C:\Windows\System32\drivers\SgrmAgent.sys",
        "C:\Windows\System32\drivers\WdDevFlt.sys",
        "C:\Windows\System32\drivers\WdBoot.sys",
        "C:\Windows\System32\drivers\WdFilter.sys",
        "C:\Windows\System32\wscsvc.dll",
        "C:\Windows\System32\drivers\WdNisDrv.sys",
        "C:\Windows\System32\wscproxystub.dll",
        "C:\Windows\System32\wscisvif.dll",
        "C:\Windows\System32\SecurityHealthProxyStub.dll",
        "C:\Windows\System32\smartscreen.dll",
        "C:\Windows\SysWOW64\smartscreen.dll",
        "C:\Windows\System32\smartscreen.exe",
        "C:\Windows\SysWOW64\smartscreen.exe",
        "C:\Windows\System32\DWWIN.EXE",
        "C:\Windows\SysWOW64\smartscreenps.dll",
        "C:\Windows\System32\smartscreenps.dll",
        "C:\Windows\System32\SecurityHealthCore.dll",
        "C:\Windows\System32\SecurityHealthSsoUdk.dll",
        "C:\Windows\System32\SecurityHealthUdk.dll",
        "C:\Windows\System32\SecurityHealthAgent.dll",
        "C:\Windows\System32\wscapi.dll",
        "C:\Windows\System32\wscadminui.exe",
        "C:\Windows\SysWOW64\GameBarPresenceWriter.exe",
        "C:\Windows\System32\GameBarPresenceWriter.exe",
        "C:\Windows\SysWOW64\DeviceCensus.exe",
        "C:\Windows\SysWOW64\CompatTelRunner.exe",
        "C:\Windows\system32\drivers\msseccore.sys",
        "C:\Windows\system32\drivers\MsSecFltWfp.sys",
        "C:\Windows\system32\drivers\MsSecFlt.sys",
        "C:\Windows\WinSxS\amd64_security-octagon*",
        "C:\Windows\WinSxS\x86_windows-defender*",
        "C:\Windows\WinSxS\wow64_windows-defender*",
        "C:\Windows\WinSxS\amd64_windows-defender*",
        "C:\Windows\SystemApps\Microsoft.Windows.AppRep.ChxApp_cw5n1h2txyewy",
        "C:\ProgramData\Microsoft\Windows Defender",
        "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection",
        "C:\Program Files (x86)\Windows Defender Advanced Threat Protection",
        "C:\Program Files\Windows Defender Advanced Threat Protection",
        "C:\ProgramData\Microsoft\Windows Security Health",
        "C:\ProgramData\Microsoft\Storage Health",
        "C:\WINDOWS\System32\drivers\wd",
        "C:\Program Files (x86)\Windows Defender",
        "C:\Program Files\Windows Defender",
        "C:\Windows\System32\SecurityHealth",
        "C:\Windows\System32\WebThreatDefSvc",
        "C:\Windows\System32\Sgrm",
        "C:\Windows\Containers\WindowsDefenderApplicationGuard.wim",
        "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\DefenderPerformance",
        "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\DefenderPerformance",
        "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Defender",
        "C:\Windows\System32\Tasks_Migrated\Microsoft\Windows\Windows Defender",
        "C:\Windows\System32\Tasks\Microsoft\Windows\Windows Defender",
        "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules\Defender",
        "C:\Windows\System32\HealthAttestationClient",
        "C:\Windows\GameBarPresenceWriter",
        "C:\Windows\bcastdvr",
        "C:\Windows\Containers\serviced\WindowsDefenderApplicationGuard.wim"
    )

    foreach ($item in $itemsToDelete) {
        Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Removal complete. Rebooting in 10 seconds..."
    shutdown /r /f /t 10
}
catch {
    $_.Exception.Message | Out-File -FilePath (Join-Path $env:TEMP "DefenderRemover_Error.log")
}

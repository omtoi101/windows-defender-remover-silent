# Silent_Run.ps1
# This script replaces Script_Run.bat and PowerRun.exe to provide a fully silent execution flow.

# --- 1. Define the RunAsTI function ---
# This function is copied from defender_remover13.ps1
function RunAsTI ($cmd,$arg) { $id='RunAsTI'; $key="Registry::HKU\$(((whoami /user)-split' ')[-1])\Volatile Environment"; $code=@'
 $I=[int32]; $M=$I.module.gettype("System.Runtime.Interop`Services.Mar`shal"); $P=$I.module.gettype("System.Int`Ptr"); $S=[string]
 $D=@(); $T=@(); $DM=[AppDomain]::CurrentDomain."DefineDynami`cAssembly"(1,1)."DefineDynami`cModule"(1); $Z=[uintptr]::size
 0..5|% {$D += $DM."Defin`eType"("AveYo_$_",1179913,[ValueType])}; $D += [uintptr]; 4..6|% {$D += $D[$_]."MakeByR`efType"()}
 $F='kernel','advapi','advapi', ($S,$S,$I,$I,$I,$I,$I,$S,$D[7],$D[8]), ([uintptr],$S,$I,$I,$D[9]),([uintptr],$S,$I,$I,[byte[]],$I)
 0..2|% {$9=$D[0]."DefinePInvok`eMethod"(('CreateProcess','RegOpenKeyEx','RegSetValueEx')[$_],$F[$_]+'32',8214,1,$S,$F[$_+3],1,4)}
 $DF=($P,$I,$P),($I,$I,$I,$I,$P,$D[1]),($I,$S,$S,$S,$I,$I,$I,$I,$I,$I,$I,$I,[int16],[int16],$P,$P,$P,$P),($D[3],$P),($P,$P,$I,$I)
 1..5|% {$k=$_; $n=1; $DF[$_-1]|% {$9=$D[$k]."Defin`eField"('f' + $n++, $_, 6)}}; 0..5|% {$T += $D[$_]."Creat`eType"()}
 0..5|% {nv "A$_" ([Activator]::CreateInstance($T[$_])) -fo}; function F ($1,$2) {$T[0]."G`etMethod"($1).invoke(0,$2)}
 $TI=(whoami /groups)-like'*1-16-16384*'; $As=0; if(!$cmd) {$cmd='control';$arg='admintools'}; if ($cmd-eq'This PC'){$cmd='file:'}
 if (!$TI) {'TrustedInstaller','lsass','winlogon'|% {if (!$As) {$9=sc.exe start $_; $As=@(get-process -name $_ -ea 0|% {$_})[0]}}
 function M ($1,$2,$3) {$M."G`etMethod"($1,[type[]]$2).invoke(0,$3)}; $H=@(); $Z,(4*$Z+16)|% {$H += M "AllocHG`lobal" $I $_}
 M "WriteInt`Ptr" ($P,$P) ($H[0],$As.Handle); $A1.f1=131072; $A1.f2=$Z; $A1.f3=$H[0]; $A2.f1=1; $A2.f2=1; $A2.f3=1; $A2.f4=1
 $A2.f6=$A1; $A3.f1=10*$Z+32; $A4.f1=$A3; $A4.f2=$H[1]; M "StructureTo`Ptr" ($D[2],$P,[boolean]) (($A2 -as $D[2]),$A4.f2,$false)
 $Run=@($null, "powershell -win 1 -nop -c iex `$env:R; # $id", 0, 0, 0, 0x0E080600, 0, $null, ($A4 -as $T[4]), ($A5 -as $T[5]))
 F 'CreateProcess' $Run; return}; $env:R=''; rp $key $id -force; $priv=[diagnostics.process]."GetM`ember"('SetPrivilege',42)[0]
 'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege' |% {$priv.Invoke($null, @("$_",2))}
 $HKU=[uintptr][uint32]2147483651; $NT='S-1-5-18'; $reg=($HKU,$NT,8,2,($HKU -as $D[9])); F 'RegOpenKeyEx' $reg; $LNK=$reg[4]
 function L ($1,$2,$3) {sp 'HKLM:\Software\Classes\AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}' 'RunAs' $3 -force -ea 0
  $b=[Text.Encoding]::Unicode.GetBytes("\Registry\User\$1"); F 'RegSetValueEx' @($2,'SymbolicLinkValue',0,6,[byte[]]$b,$b.Length)}
 function Q {[int](gwmi win32_process -filter 'name="explorer.exe"'|?{$_.getownersid().sid-eq$NT}|select -last 1).ProcessId}
 $11bug=($((gwmi Win32_OperatingSystem).BuildNumber)-eq'22000')-AND(($cmd-eq'file:')-OR(test-path -lit $cmd -PathType Container))
 if ($11bug) {'System.Windows.Forms','Microsoft.VisualBasic' |% {[Reflection.Assembly]::LoadWithPartialName("'$_")}}
 if ($11bug) {$path='^(l)'+$($cmd -replace '([\+\^\%\~\(\)\[\]])','{$1}')+'{ENTER}'; $cmd='control.exe'; $arg='admintools'}
 L ($key-split'\\')[1] $LNK ''; $R=[diagnostics.process]::start($cmd,$arg); if ($R) {$R.PriorityClass='High'; $R.WaitForExit()}
 if ($11bug) {$w=0; do {if($w-gt40){break}; sleep -mi 250;$w++} until (Q); [Microsoft.VisualBasic.Interaction]::AppActivate($(Q))}
 if ($11bug) {[Windows.Forms.SendKeys]::SendWait($path)}; do {sleep 7} while(Q); L '.Default' $LNK 'Interactive User'
'@; $V='';'cmd','arg','id','key'|%{$V+="`n`$$_='$($(gv $_ -val)-replace"'","''")';"}; sp $key $id $($V,$code) -type 7 -force -ea 0
 start powershell -args "-win 1 -nop -c `n$V `$env:R=(gi `$key -ea 0).getvalue(`$id)-join''; iex `$env:R" -verb runas
}

# --- 2. Main execution logic ---
try {
    # Set hypervisor launch type
    RunAsTI "bcdedit" "/set hypervisorlaunchtype off"

    # Remove Windows Security UWP App
    $removeSecHealthPath = Join-Path $PSScriptRoot "RemoveSecHealthApp.ps1"
    Start-Process powershell "-noprofile -executionpolicy bypass -file `"$removeSecHealthPath`"" -WindowStyle Hidden -Wait

    # Import registry files
    $regFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Remove_defender") -Filter *.reg -Recurse
    $regFiles += Get-ChildItem -Path (Join-Path $PSScriptRoot "Remove_SecurityComp") -Filter *.reg -Recurse
    foreach ($regFile in $regFiles) {
        RunAsTI "regedit.exe" "/s `"$($regFile.FullName)`""
    }

    # List of files to delete
    $filesToDelete = @(
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
        "C:\Windows\system32\drivers\MsSecFlt.sys"
    )
    foreach ($file in $filesToDelete) {
        RunAsTI "powershell.exe" "-command `"Remove-Item -Path '$file' -Force -ErrorAction SilentlyContinue`""
    }

    # List of directories to delete
    $dirsToDelete = @(
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
    foreach ($dir in $dirsToDelete) {
        RunAsTI "powershell.exe" "-command `"Remove-Item -Path '$dir' -Recurse -Force -ErrorAction SilentlyContinue`""
    }

    # Reboot the system
    Start-Process shutdown "/r /f /t 10" -WindowStyle Hidden
}
catch {
    # Log errors to a file in the temp directory
    $_.Exception.Message | Out-File -FilePath (Join-Path $env:TEMP "DefenderRemover_Error.log")
}

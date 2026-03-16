# Build.ps1 - Script to create a standalone executable for Defender Remover

# --- 1. Check and Install ps2exe ---
if (-not (Get-Command ps2exe -ErrorAction SilentlyContinue)) {
    Write-Host "ps2exe not found. Installing it from the PowerShell Gallery..."
    try {
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
        # Using -SkipPublisherCheck and -AcceptLicense for non-interactive environments
        Install-Script -Name ps2exe -Force -Scope CurrentUser -ErrorAction Stop
    } catch {
        Write-Error "Failed to install ps2exe. Ensure internet connectivity and PowerShell Gallery access."
        exit 1
    }
}

# --- 2. Gather All Necessary Files ---
$rootDir = Get-Location
Write-Host "Gathering files from: $rootDir"
$filesToEmbed = Get-ChildItem -Path $rootDir -Recurse | Where-Object {
    -not $_.PSIsContainer -and
    $_.Name -ne 'Build.ps1' -and
    $_.Name -ne 'DefenderRemover.exe' -and
    $_.FullName -notlike "*.git*" -and
    $_.Name -ne 'Master.ps1'
}

# --- 3. Generate the Master PowerShell Script (Optimized) ---
$masterScriptPath = Join-Path $rootDir "Master.ps1"
Write-Host "Generating master script at: $masterScriptPath"

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Master.ps1 - Compiled standalone entry point")
[void]$sb.AppendLine("`$tempDir = Join-Path `$env:TEMP ([System.Guid]::NewGuid().ToString())")
[void]$sb.AppendLine("New-Item -ItemType Directory -Path `$tempDir -Force | Out-Null")
[void]$sb.AppendLine("try {")

foreach ($file in $filesToEmbed) {
    $relativePath = $file.FullName.Substring($rootDir.Path.Length + 1)
    $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $base64String = [System.Convert]::ToBase64String($fileBytes)

    [void]$sb.AppendLine("    # Embedding '$relativePath'")
    [void]$sb.AppendLine("    `$b64 = '$base64String'")
    [void]$sb.AppendLine("    `$bytes = [System.Convert]::FromBase64String(`$b64)")
    [void]$sb.AppendLine("    `$target = Join-Path `$tempDir '$relativePath'")
    [void]$sb.AppendLine("    New-Item -ItemType Directory -Path (Split-Path `$target) -Force | Out-Null")
    [void]$sb.AppendLine("    [System.IO.File]::WriteAllBytes(`$target, `$bytes)")
}

$masterScriptTemplateTail = @"

    # Execute the main powershell script silently
    `$scriptPath = Join-Path `$tempDir "Silent_Run.ps1"

    # Track the execution
    `$process = Start-Process powershell "-noprofile -executionpolicy bypass -file `"$scriptPath`"" -WindowStyle Hidden -PassThru
    `$process.WaitForExit()

    # Wait for the self-elevated process if it exists
    Start-Sleep -Seconds 5
    do {
        `$running = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {
            try { `$_.CommandLine -like "*Silent_Run.ps1*" } catch { `$false }
        }
        if (`$running) { Start-Sleep -Seconds 2 }
    } while (`$running)
}
catch {
    `$_.Exception.Message | Out-File -FilePath (Join-Path `$env:TEMP "DefenderRemover_Error.log")
}
finally {
    if (Test-Path `$tempDir) {
        Remove-Item -Path `$tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
"@

[void]$sb.AppendLine($masterScriptTemplateTail)
Set-Content -Path $masterScriptPath -Value $sb.ToString() -Encoding UTF8

# --- 4. Compile the Executable ---
$outputExe = Join-Path $rootDir "DefenderRemover.exe"
Write-Host "Compiling into $outputExe..."
try {
    ps2exe -inputFile $masterScriptPath -outputFile $outputExe -noConsole
} catch {
    Write-Error "Compilation failed. Ensure ps2exe is correctly installed."
    exit 1
}

# --- 5. Clean Up ---
Remove-Item -Path $masterScriptPath
Write-Host "Build complete!"

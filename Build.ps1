# Build.ps1 - Script to create a standalone executable for Defender Remover

# --- 1. Check and Install ps2exe ---
if (-not (Get-Command ps2exe -ErrorAction SilentlyContinue)) {
    Write-Host "ps2exe not found. Installing it from the PowerShell Gallery..."
    try {
        # Set execution policy for the current process to allow installation
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
        Install-Script -Name ps2exe -Force -Scope CurrentUser
    } catch {
        Write-Error "Failed to install ps2exe. Please ensure you have an internet connection and PowerShell Gallery is accessible."
        exit 1
    }
}

# --- 2. Gather All Necessary Files ---
$rootDir = Get-Location
Write-Host "Gathering files from: $rootDir"
$filesToEmbed = Get-ChildItem -Path $rootDir -Recurse | Where-Object { -not $_.PSIsContainer -and $_.Name -ne 'Build.ps1' -and $_.Name -ne 'DefenderRemover.exe' }

# --- 3. Generate the Master PowerShell Script ---
$masterScriptPath = Join-Path $rootDir "Master.ps1"
Write-Host "Generating master script at: $masterScriptPath"

# --- 3a. Create Code to Embed Files ---
$embeddingCode = ""
foreach ($file in $filesToEmbed) {
    $relativePath = $file.FullName.Substring($rootDir.Path.Length + 1)
    $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $base64String = [System.Convert]::ToBase64String($fileBytes)

    $embeddingCode += @"
    # Embedding '$relativePath'
    `$base64String = '$base64String'
    `$fileBytes = [System.Convert]::FromBase64String(`$base64String)
    `$targetPath = Join-Path `$tempDir '$relativePath'
    New-Item -ItemType Directory -Path (Split-Path `$targetPath) -Force | Out-Null
    [System.IO.File]::WriteAllBytes(`$targetPath, `$fileBytes)
"@
}

# --- 3b. Define the Master Script Template ---
$masterScriptTemplate = @"
# Master.ps1 - This script will be compiled into an EXE

`$tempDir = Join-Path `$env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path `$tempDir | Out-Null

try {
    # Extract all embedded files
$embeddingCode

    # Execute the main powershell script silently
    `$scriptRunPsPath = Join-Path `$tempDir "Silent_Run.ps1"
    Start-Process powershell "-noprofile -executionpolicy bypass -file `"$scriptRunPsPath`"" -WindowStyle Hidden -Wait
}
catch {
    # Optional: Log any errors for debugging purposes
    `$_.Exception.Message | Out-File -FilePath (Join-Path `$env:TEMP "DefenderRemover_Error.log")
}
finally {
    # Clean up the temporary directory
    if (Test-Path `$tempDir) {
        Remove-Item -Path `$tempDir -Recurse -Force
    }
}
"@

# --- 3c. Create the Master.ps1 file ---
Set-Content -Path $masterScriptPath -Value $masterScriptTemplate

# --- 4. Compile the Executable ---
$outputExe = Join-Path $rootDir "DefenderRemover.exe"
Write-Host "Compiling Master.ps1 into $outputExe..."
try {
    ps2exe -inputFile $masterScriptPath -outputFile $outputExe -noConsole
} catch {
    Write-Error "Failed to compile the script. Please ensure ps2exe is installed correctly."
    exit 1
}


# --- 5. Clean Up ---
Remove-Item -Path $masterScriptPath

Write-Host "Build complete! The standalone executable is located at: $outputExe"

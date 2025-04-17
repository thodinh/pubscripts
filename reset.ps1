# Check if started with elevated privileges
param(
    [switch]$Elevated
)

# Set color theme
$Theme = @{
    Primary   = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
}

# ASCII Logo
$Logo = @"
██████╗ ███████╗███████╗███████╗████████╗    ████████╗ ██████╗  ██████╗ ██╗     
██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
██████╔╝█████╗  ███████╗█████╗     ██║          ██║   ██║   ██║██║   ██║██║     
██╔══██╗██╔══╝  ╚════██║██╔══╝     ██║          ██║   ██║   ██║██║   ██║██║     
██║  ██║███████╗███████║███████╗   ██║          ██║   ╚██████╔╝╚██████╔╝███████╗
╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝          ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
"@

# Styled output function
function Write-Styled {
    param (
        [string]$Message,
        [string]$Color = $Theme.Info,
        [string]$Prefix = "",
        [switch]$NoNewline
    )
    $emoji = switch ($Color) {
        $Theme.Success { "✅" }
        $Theme.Error   { "❌" }
        $Theme.Warning { "⚠️" }
        default        { "ℹ️" }
    }
    
    $output = if ($Prefix) { "$emoji $Prefix :: $Message" } else { "$emoji $Message" }
    if ($NoNewline) {
        Write-Host $output -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $output -ForegroundColor $Color
    }
}

# Check administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-NOT $isAdmin) {
    Write-Styled "Administrator privileges required to run the reset tool" -Color $Theme.Warning -Prefix "Privileges"
    Write-Styled "Requesting administrator privileges..." -Color $Theme.Primary -Prefix "Elevation"
    
    # Display operation options
    Write-Host "`nSelect operation:" -ForegroundColor $Theme.Primary
    Write-Host "1. Request administrator privileges" -ForegroundColor $Theme.Info
    Write-Host "2. Exit program" -ForegroundColor $Theme.Info
    
    $choice = Read-Host "`nPlease enter option (1-2)"
    
    if ($choice -ne "1") {
        Write-Styled "Operation cancelled" -Color $Theme.Warning -Prefix "Cancel"
        Write-Host "`nPress any key to exit..." -ForegroundColor $Theme.Info
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit
    }
    
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Elevated"
        exit
    }
    catch {
        Write-Styled "Unable to obtain administrator privileges" -Color $Theme.Error -Prefix "Error"
        Write-Styled "Please run PowerShell as administrator and try again" -Color $Theme.Warning -Prefix "Tip"
        Write-Host "`nPress any key to exit..." -ForegroundColor $Theme.Info
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
}

# If this is an elevated window, wait a moment to ensure visibility
if ($Elevated) {
    Start-Sleep -Seconds 1
}

# Display Logo
Write-Host $Logo -ForegroundColor $Theme.Primary
Write-Host "Created by YeongPin`n" -ForegroundColor $Theme.Info

# Set TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create temporary directory
$TmpDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null

# Cleanup function
function Cleanup {
    if (Test-Path $TmpDir) {
        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
    }
}

try {
    # Download URL
    $url = "https://github.com/yeongpin/cursor-free-vip/releases/download/ManualReset/reset_machine_manual.exe"
    $output = Join-Path $TmpDir "reset_machine_manual.exe"

    # Download file
    Write-Styled "Downloading reset tool..." -Color $Theme.Primary -Prefix "Download"
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Styled "Download complete!" -Color $Theme.Success -Prefix "Complete"

    # Run reset tool
    Write-Styled "Starting reset tool..." -Color $Theme.Primary -Prefix "Execute"
    Start-Process -FilePath $output -Wait
    Write-Styled "Reset complete!" -Color $Theme.Success -Prefix "Complete"
}
catch {
    Write-Styled "Operation failed" -Color $Theme.Error -Prefix "Error"
    Write-Styled $_.Exception.Message -Color $Theme.Error
}
finally {
    Cleanup
    Write-Host "`nPress any key to exit..." -ForegroundColor $Theme.Info
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
} 
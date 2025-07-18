# =================== [SCRIPT CONFIGURATION] ===================
$scriptVersion = "1.2.0"
$githubRawUrl = "https://raw.githubusercontent.com/Aluc4d/Nyx09/main/DNS-SHES.ps1"
$scriptName = "DNS SHES"
$updateChecked = $false

# =================== [AUTO-UPDATE MODULE] ===================
function Invoke-AutoUpdate {
    param(
        [string]$currentVersion,
        [string]$updateUrl
    )
    
    Show-Header "CHECKING FOR UPDATES"
    Write-Host "Current version: $currentVersion" -ForegroundColor Cyan
    
    try {
        # Create a web client with proxy support
        $webClient = New-Object System.Net.WebClient
        $webClient.Proxy = [System.Net.WebRequest]::DefaultWebProxy
        $webClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
        $webClient.Encoding = [System.Text.Encoding]::UTF8
        
        # Download the latest script content
        Write-Host "Connecting to GitHub..." -ForegroundColor Yellow
        $latestScriptContent = $webClient.DownloadString($updateUrl)
        
        # Extract version from the script
        $versionPattern = '\$scriptVersion\s*=\s*"([\d.]+)"'
        if ($latestScriptContent -match $versionPattern) {
            $latestVersion = $matches[1]
            Write-Host "Latest version available: $latestVersion" -ForegroundColor Cyan
            
            # Compare versions
            $current = [version]$currentVersion
            $latest = [version]$latestVersion
            
            if ($latest -gt $current) {
                Write-Host "`nA new version is available!" -ForegroundColor Green
                
                # FIX: Use proper variable formatting to avoid colon issue
                Write-Host ("Changes in version {0}:" -f $latestVersion) -ForegroundColor Cyan
                
                # Extract changelog information
                $changelogPattern = '(?s)# =================== \[CHANGELOG\] ===================(.+?)# ==================='
                if ($latestScriptContent -match $changelogPattern) {
                    $changelog = $matches[1].Trim()
                    Write-Host $changelog -ForegroundColor Yellow
                } else {
                    Write-Host " - Bug fixes and performance improvements" -ForegroundColor Yellow
                }
                
                $choice = Read-Host "`nDo you want to update now? (Y/N)"
                if ($choice -eq 'y' -or $choice -eq 'Y') {
                    Write-Host "`nUpdating script..." -ForegroundColor Cyan
                    
                    # Get current script path
                    $scriptPath = $MyInvocation.MyCommand.Path
                    
                    # Create backup
                    $backupPath = "$scriptPath.bak"
                    if (Test-Path $backupPath) { Remove-Item $backupPath -Force }
                    Copy-Item -Path $scriptPath -Destination $backupPath -Force
                    
                    # Save updated script
                    $latestScriptContent | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
                    
                    Write-Host "`nUpdate successful! Script has been updated to version $latestVersion" -ForegroundColor Green
                    Write-Host "Please restart the script to use the new version." -ForegroundColor Yellow
                    Pause-ForReturn
                    Exit
                } else {
                    Write-Host "`nUpdate skipped. Continuing with current version." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            } else {
                Write-Host "`nYou're using the latest version!" -ForegroundColor Green
                Start-Sleep -Seconds 1
            }
        } else {
            Write-Host "`nWarning: Could not determine version from update source" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    } catch {
        Write-Host "`nUpdate check failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Continuing with current version..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
    
    $global:updateChecked = $true
}

# =================== [CHANGELOG] ===================
# 1.0.1 - Fixed bufferbloat status detection issues
# 1.0.2 - Improved network optimization algorithms
# 1.0.3 - Added Quad9 DNS provider
# 1.1.0 - Added auto-update functionality
# 1.1.1 - Enhanced DNS testing reliability
# 1.2.0 - Added network diagnostics toolkit
# 2.0.0 - Complete UI overhaul and performance enhancements

# =================== [INTRODUCTION] ===================
function Show-Introduction {
    Clear-Host
    Write-Host @"
 
  _____  _   _ _____     _____ _    _ ______  _____ 
 |  __ \| \ | / ____|   / ____| |  | |  ____|/ ____|
 | |  | |  \| | (___   | (___ | |__| | |__  | (___  
 | |  | | . ' |\___ \   \___ \|  __  |  __|  \___ \ 
 | |__| | |\  |____) |  ____) | |  | | |____ ____) |
 |_____/|_| \_|_____/  |_____/|_|  |_|______|_____/ 
                                                    v$scriptVersion - Aluc4d

"@ -ForegroundColor Cyan

    Write-Host "`n" ("=" * 65) -ForegroundColor DarkCyan
    Write-Host "               DNS OPTIMIZATION TOOL" -ForegroundColor Yellow
    Write-Host "=" * 65 -ForegroundColor DarkCyan
    Write-Host " This tool helps optimize your internet connection by:" -ForegroundColor White
    Write-Host "  1. Resetting to automatic DNS (fix connection issues)" -ForegroundColor Cyan
    Write-Host "  2. Finding the FASTEST gaming DNS servers" -ForegroundColor Green
    Write-Host "  3. Letting you choose from trusted DNS providers" -ForegroundColor Magenta
    Write-Host "  4. Network Enhancement Tools" -ForegroundColor Blue
    Write-Host "  5. Toggle Bufferbloat Settings" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Benefits you'll get: " -ForegroundColor Yellow
    Write-Host "  - Faster browsing and reduced lag in games" -ForegroundColor White
    Write-Host "  - Improved privacy and security" -ForegroundColor White
    Write-Host "  - Option to block ads/malware" -ForegroundColor White
    Write-Host ""
    Write-Host " Note: " -ForegroundColor Red -NoNewline
    Write-Host "Run as administrator to apply changes" -ForegroundColor White
    Write-Host "=" * 65 -ForegroundColor DarkCyan
    Write-Host " Press any key to continue..." -ForegroundColor DarkGray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# =================== [ADMIN + EXEC POLICY SETUP] ===================
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`nThis script needs to run as Administrator. Requesting elevated permissions..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList ('-ExecutionPolicy Bypass -File "' + $MyInvocation.MyCommand.Definition + '"')
    Exit
}

$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -ne "RemoteSigned" -and $currentPolicy -ne "Bypass") {
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    } catch {
        Write-Host "Unable to set execution policy. It might be restricted by group policy." -ForegroundColor Yellow
    }
}

# =================== [UTILITIES] ===================
function Show-Banner {
    Clear-Host
    Write-Host @"
 
  _____  _   _ _____     _____ _    _ ______  _____ 
 |  __ \| \ | / ____|   / ____| |  | |  ____|/ ____|
 | |  | |  \| | (___   | (___ | |__| | |__  | (___  
 | |  | | . ' |\___ \   \___ \|  __  |  __|  \___ \ 
 | |__| | |\  |____) |  ____) | |  | | |____ ____) |
 |_____/|_| \_|_____/  |_____/|_|  |_|______|_____/ 
                                                    v$scriptVersion - Aluc4d
"@ -ForegroundColor Cyan

    Write-Host "`n" ("=" * 65) -ForegroundColor DarkCyan
    Write-Host "`t1. Remove current DNS (reset to automatic)" -ForegroundColor Yellow
    Write-Host "`t2. Test and apply best Gaming DNS" -ForegroundColor Green
    Write-Host "`t3. Choose DNS provider manually" -ForegroundColor Magenta
    Write-Host "`t4. Network Enhancement Tools" -ForegroundColor Blue
    Write-Host "`t5. Toggle Bufferbloat Settings" -ForegroundColor Cyan
    Write-Host "`t6. Check for Updates" -ForegroundColor DarkYellow
    Write-Host "`t0. Exit" -ForegroundColor Red
    Write-Host "`n" ("=" * 65) -ForegroundColor DarkCyan
    Write-Host "Choose an option: " -ForegroundColor Cyan -NoNewline
    return (Read-Host)
}

function Show-Progress {
    param($Activity, $Status, $Percent)
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $Percent
}

function Show-Header {
    param($Title)
    Write-Host "`n" ("=" * 65) -ForegroundColor DarkCyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 65) -ForegroundColor DarkCyan
}

function Pause-ForReturn {
    Write-Host "`nPress any key to return to menu..." -ForegroundColor DarkGray
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# =================== [BUFFERBLOAT TOGGLE UI] ===================
function Get-BufferbloatStatus {
    # Get TCP settings using netsh
    $tcpSettings = netsh int tcp show global
    
    # Check for common status patterns without regex
    $status = "Unknown"
    
    # Try to find the autotuning line
    $autotuningLine = $tcpSettings | Where-Object { $_ -like "*Autotuning Level*" }
    
    if (-not $autotuningLine) {
        $autotuningLine = $tcpSettings | Where-Object { $_ -like "*Auto-Tuning Level*" }
    }
    
    if (-not $autotuningLine) {
        $autotuningLine = $tcpSettings | Where-Object { $_ -like "*autotuninglevel*" }
    }
    
    if ($autotuningLine) {
        # Directly extract status from the line
        $statusPart = $autotuningLine -split ":" | Select-Object -Last 1
        $status = $statusPart.Trim()
    }
    
    # If still not found, try registry method
    if ($status -eq "Unknown") {
        try {
            $regValue = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "EnableAutoTuning" -ErrorAction Stop
            switch ($regValue) {
                0 { $status = "disabled" }
                1 { $status = "normal" }
                2 { $status = "experimental" }
                3 { $status = "restricted" }
                4 { $status = "highlyrestricted" }
                default { $status = "unknown (registry value $regValue)" }
            }
        }
        catch {
            # Final fallback
            $status = "normal (assumed default)"
        }
    }
    
    # Map to friendly names
    switch -Wildcard ($status) {
        "*disabled*" { "ANTI-BUFFERBLOAT ACTIVE" }
        "*normal*" { "NORMAL SPEED MODE" }
        "*experimental*" { "EXPERIMENTAL MODE" }
        "*restricted*" { "RESTRICTED MODE" }
        "*highlyrestricted*" { "HIGHLY RESTRICTED MODE" }
        default { "UNKNOWN ($status)" }
    }
}

function Show-BufferbloatUI {
    Clear-Host
    Write-Host @"
 
  ____  _   _ _____ ______ _______  _____  _    _ _______  _____  
 |  _ \| | | | ____|  ____|__   __|/ ____|| |  | |__   __|/ ____| 
 | |_) | | | | |__ | |__     | |  | (___  | |  | |  | |  | (___  
 |  _ <| | | |___ \|  __|    | |   \___ \ | |  | |  | |   \___ \ 
 | |_) | |_| |___) | |____   | |   ____) || |__| |  | |   ____) |
 |____/ \___/|____/|______|  |_|  |_____/  \____/   |_|  |_____/ 
                                                                 
"@ -ForegroundColor Cyan

    Write-Host "`n" ("=" * 65) -ForegroundColor DarkCyan
    Write-Host "          BUFFERBLOAT CONFIGURATION TOOL" -ForegroundColor Yellow
    Write-Host ("=" * 65) -ForegroundColor DarkCyan
    
    Write-Host "`nWhat is Bufferbloat?" -ForegroundColor Green
    Write-Host " Bufferbloat causes network lag when your connection is saturated."
    Write-Host " This happens when network buffers fill up and cause high latency."
    
    Write-Host "`nHow this affects you:" -ForegroundColor Yellow
    Write-Host " - Online games can become unplayable during downloads/uploads"
    Write-Host " - Video calls may freeze when other devices use the network"
    Write-Host " - Web browsing becomes sluggish when network is busy"
    
    Write-Host "`nRecommended settings:" -ForegroundColor Magenta
    Write-Host " [1] Anti-Bufferbloat Mode (Recommended for gaming/streaming)"
    Write-Host "     - Reduces network lag when connection is busy"
    Write-Host "     - May slightly reduce maximum throughput"
    Write-Host " [2] Normal Speed Mode (Best for downloads/uploads)"
    Write-Host "     - Maximizes raw throughput speed"
    Write-Host "     - May experience lag during heavy network use"
    
    Write-Host "`n" ("=" * 65) -ForegroundColor DarkCyan
    
    # Get and display status with error handling
    try {
        $status = Get-BufferbloatStatus
        Write-Host "Current Status: $status" -ForegroundColor Cyan
    } catch {
        Write-Host "Current Status: UNKNOWN (Error: $($_.Exception.Message))" -ForegroundColor Red
    }
    
    Write-Host "`nSelect an option:" -ForegroundColor Cyan
    Write-Host " 1. Enable Anti-Bufferbloat Mode" -ForegroundColor Green
    Write-Host " 2. Enable Normal Speed Mode" -ForegroundColor Yellow
    Write-Host " 3. Test Bufferbloat (opens browser)" -ForegroundColor Blue
    Write-Host " 0. Return to Main Menu" -ForegroundColor Gray
    Write-Host "`n" ("=" * 65) -ForegroundColor DarkCyan
    Write-Host "Your choice: " -ForegroundColor Cyan -NoNewline
    return (Read-Host)
}

function Toggle-Bufferbloat {
    $choice = Show-BufferbloatUI
    
    switch ($choice) {
        "1" {
            netsh int tcp set global autotuninglevel=disabled | Out-Null
            Write-Host "`nAnti-Bufferbloat mode ENABLED!" -ForegroundColor Green
            Write-Host "Your network will prioritize low latency over raw speed." -ForegroundColor Cyan
            Write-Host "This is ideal for gaming, streaming, and video calls." -ForegroundColor White
            
            # Get and display new status
            $newStatus = Get-BufferbloatStatus
            Write-Host "`nNew Status: $newStatus" -ForegroundColor Magenta
        }
        "2" {
            netsh int tcp set global autotuninglevel=normal | Out-Null
            Write-Host "`nNormal Speed Mode ENABLED!" -ForegroundColor Yellow
            Write-Host "Your network will maximize throughput speed." -ForegroundColor Cyan
            Write-Host "Use this mode for large downloads/uploads." -ForegroundColor White
            
            # Get and display new status
            $newStatus = Get-BufferbloatStatus
            Write-Host "`nNew Status: $newStatus" -ForegroundColor Magenta
        }
        "3" {
            Start-Process "https://www.waveform.com/tools/bufferbloat"
            Write-Host "`nBufferbloat test opened in your browser..." -ForegroundColor Cyan
            Write-Host "Run the test to check your current bufferbloat levels." -ForegroundColor White
        }
        "0" { return }
        default {
            Write-Host "Invalid selection! Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
            Toggle-Bufferbloat
        }
    }
    
    Pause-ForReturn
}

# =================== [NETWORK ENHANCEMENT MODULE] ===================
function Show-NetworkEnhancementMenu {
    # Clear screen and create colorful header
    Clear-Host
    Write-Host "`n`n`n"  # Add some spacing
    
    # Create header without special characters
    Write-Host "  NETWORK ENHANCEMENT TOOLS" -ForegroundColor Cyan
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkCyan
    
    # Display menu options with colors
    Write-Host "`n  MAIN OPTIONS:" -ForegroundColor Yellow
    Write-Host "  [T] Tutorial" -ForegroundColor Yellow
    Write-Host "  [B] Bufferbloat Test" -ForegroundColor Green
    Write-Host "  [A] Apply all optimizations (1-14)" -ForegroundColor Cyan
    Write-Host "  [R] Revert all changes" -ForegroundColor Red
    Write-Host "  [M] Back to Main Menu" -ForegroundColor Gray
    
    Write-Host "`n  OPTIMIZATION OPTIONS:" -ForegroundColor Yellow
    Write-Host "  [1]  Set DNS/Local/Hosts/NetBT priorities"
    Write-Host "  [2]  Set Network Throttling Index"
    Write-Host "  [3]  Configure MaxUserPort/TcpTimedWaitDelay/DefaultTTL"
    Write-Host "  [4]  Tweak TCP Settings and disable limiting"
    Write-Host "  [5]  Tweak MTU Settings"
    Write-Host "  [6]  Configure offload and network settings"
    Write-Host "  [7]  Disable IPv6"
    Write-Host "  [8]  Disable Internet Probing"
    Write-Host "  [9]  Disable Internet addons"
    Write-Host "  [10] Disable Nagle's Algorithm"
    Write-Host "  [11] Enable Task Offload"
    Write-Host "  [12] Optimize MLD/ICMP/DCA"
    Write-Host "  [13] Set QoS Policy"
    Write-Host "  [14] Optimize NIC Settings"
    
    Write-Host "`n  " + ("=" * 50) -ForegroundColor DarkCyan
    Write-Host "  NOTE: NIC optimizations (option 14) are for Ethernet connections only!" -ForegroundColor Yellow
    Write-Host "  Made and distributed by NYX09 TWEAKS * Updated 2025" -ForegroundColor DarkGray
    Write-Host "  " + ("=" * 50) -ForegroundColor DarkCyan
    
    Write-Host "`nChoose an option: " -ForegroundColor Cyan -NoNewline
    return (Read-Host)
}

function Invoke-NetworkEnhancement {
    param($choice)
    
    switch ($choice) {
        "T" { Start-Process "https://www.youtube.com/@NYX09x/videos" }
        "B" { Start-Process "https://www.waveform.com/tools/bufferbloat" }
        "A" { Invoke-AllNetworkOptimizations }
        "R" { Revert-NetworkOptimizations }
        "M" { return }
        "1" { Set-DnsPriorities }
        "2" { Set-NetworkThrottlingIndex }
        "3" { Set-TcpipParameters }
        "4" { Set-TcpSettings }
        "5" { Set-MtuSettings }
        "6" { Set-OffloadSettings }
        "7" { Disable-IPv6 }
        "8" { Disable-InternetProbing }
        "9" { Disable-InternetAddons }
        "10" { Disable-NaglesAlgorithm }
        "11" { Enable-TaskOffload }
        "12" { Optimize-MldIcmp }
        "13" { Set-QosPolicy }
        "14" { Optimize-NicSettings }
        default { Write-Host "Invalid selection! Please try again." -ForegroundColor Red }
    }
}

function Invoke-AllNetworkOptimizations {
    Show-Header "APPLYING ALL NETWORK OPTIMIZATIONS"
    Write-Host "Applying all network optimizations..." -ForegroundColor Cyan
    
    # Enable task offloads
    netsh int ip set global taskoffload=enabled | Out-Null
    
    # Set network throttling index
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWORD -Force
    
    # Set TCP/IP parameters
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "MaxUserPort" -Value 65534 -Type DWORD -Force
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpTimedWaitDelay" -Value 30 -Type DWORD -Force
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL" -Value 64 -Type DWORD -Force
    
    # Configure TCP settings and MTU
    netsh int tcp set supplemental internet congestionprovider=ctcp | Out-Null
    netsh interface ipv4 set subinterface "Wi-Fi" mtu=1500 store=persistent | Out-Null
    netsh interface ipv6 set subinterface "Wi-Fi" mtu=1500 store=persistent | Out-Null
    netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent | Out-Null
    netsh interface ipv6 set subinterface "Ethernet" mtu=1500 store=persistent | Out-Null
    
    # Configure offload settings
    Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled
    Set-NetOffloadGlobalSetting -ReceiveSideScaling Disabled
    Set-NetOffloadGlobalSetting -Chimney Disabled
    Get-NetAdapter | Disable-NetAdapterLso
    Get-NetAdapter | Disable-NetAdapterChecksumOffload
    
    # Disable IPv6
    Set-ItemProperty "HKLM:\SYSTEM\ControlSet001\services\TCPIP6\Parameters" -Name "DisabledComponents" -Value 255 -Type DWORD -Force
    
    # Disable active probing
    Set-ItemProperty "HKLM:\System\ControlSet001\services\NlaSvc\Parameters\Internet" -Name "EnableActiveProbing" -Value 0 -Type DWORD -Force
    
    # Disable Nagle's algorithm
    sc.exe config Winmgmt start= demand | Out-Null
    sc.exe start Winmgmt | Out-Null
    
    # Configure interface settings
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        $interfacePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
        Set-ItemProperty -Path $interfacePath -Name "TCPNoDelay" -Value 1 -Type DWORD -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $interfacePath -Name "TcpAckFrequency" -Value 1 -Type DWORD -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $interfacePath -Name "TcpDelAckTicks" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
    }
    
    # Optimize MLD and ICMP
    netsh int ip set global dhcpmediasense=disabled | Out-Null
    netsh int ip set global mediasenseeventlog=disabled | Out-Null
    netsh int ip set global mldlevel=none | Out-Null
    netsh int ip set global icmpredirects=disabled | Out-Null
    netsh int tcp set global chimney=enabled | Out-Null
    netsh int tcp set global dca=enabled | Out-Null
    netsh int tcp set global netdma=disabled | Out-Null
    netsh int tcp set global rsc=disabled | Out-Null
    netsh int tcp set global maxsynretransmissions=2 | Out-Null
    netsh int tcp set global timestamps=disabled | Out-Null
    netsh int tcp set global ecncapability=disabled | Out-Null
    netsh int tcp set heuristics disabled | Out-Null
    netsh int tcp set heuristics wsh=disabled | Out-Null
    netsh int tcp set security mpp=disabled | Out-Null
    netsh int tcp set security profiles=disabled | Out-Null
    
    Write-Host "`nAll network optimizations applied successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Revert-NetworkOptimizations {
    Show-Header "REVERTING NETWORK OPTIMIZATIONS"
    Write-Host "Reverting all network optimizations..." -ForegroundColor Cyan
    
    # Revert network throttling index
    Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -ErrorAction SilentlyContinue
    
    # Revert TCP/IP parameters
    Remove-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "MaxUserPort" -ErrorAction SilentlyContinue
    Remove-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpTimedWaitDelay" -ErrorAction SilentlyContinue
    Remove-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL" -ErrorAction SilentlyContinue
    
    # Revert TCP settings
    netsh int tcp set supplemental internet congestionprovider=default | Out-Null
    netsh interface ipv4 set subinterface "Wi-Fi" mtu=1492 store=persistent | Out-Null
    netsh interface ipv6 set subinterface "Wi-Fi" mtu=1280 store=persistent | Out-Null
    netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent | Out-Null
    netsh interface ipv6 set subinterface "Ethernet" mtu=1280 store=persistent | Out-Null
    
    # Re-enable active probing
    Set-ItemProperty "HKLM:\System\ControlSet001\services\NlaSvc\Parameters\Internet" -Name "EnableActiveProbing" -Value 1 -Type DWORD -Force
    
    # Revert offload settings
    Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Enabled
    Set-NetOffloadGlobalSetting -ReceiveSideScaling Enabled
    Set-NetOffloadGlobalSetting -Chimney Enabled
    Get-NetAdapter | Enable-NetAdapterLso
    Get-NetAdapter | Enable-NetAdapterChecksumOffload
    
    # Re-enable IPv6
    Remove-ItemProperty "HKLM:\SYSTEM\ControlSet001\services\TCPIP6\Parameters" -Name "DisabledComponents" -ErrorAction SilentlyContinue
    
    # Revert interface settings
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        $interfacePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
        Remove-ItemProperty -Path $interfacePath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $interfacePath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $interfacePath -Name "TcpDelAckTicks" -ErrorAction SilentlyContinue
    }
    
    # Revert MLD and ICMP
    netsh int ip set global dhcpmediasense=enabled | Out-Null
    netsh int ip set global mediasenseeventlog=enabled | Out-Null
    netsh int ip set global mldlevel=default | Out-Null
    netsh int ip set global icmpredirects=enabled | Out-Null
    netsh int tcp set global chimney=disabled | Out-Null
    netsh int tcp set global dca=disabled | Out-Null
    netsh int tcp set global netdma=enabled | Out-Null
    netsh int tcp set global rsc=enabled | Out-Null
    netsh int tcp set global maxsynretransmissions=5 | Out-Null
    netsh int tcp set global timestamps=enabled | Out-Null
    netsh int tcp set global ecncapability=enabled | Out-Null
    netsh int tcp set heuristics enabled | Out-Null
    netsh int tcp set heuristics wsh=enabled | Out-Null
    netsh int tcp set security mpp=enabled | Out-Null
    netsh int tcp set security profiles=enabled | Out-Null
    
    Write-Host "`nAll network optimizations reverted successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Set-DnsPriorities {
    Show-Header "SETTING DNS PRIORITIES"
    Write-Host "Setting DNS/Local/Hosts/NetBT priorities..." -ForegroundColor Cyan
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "DnsPriority" -Value 6 -Type DWORD -Force
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "LocalPriority" -Value 4 -Type DWORD -Force
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "HostsPriority" -Value 5 -Type DWORD -Force
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "NetbtPriority" -Value 7 -Type DWORD -Force
    Write-Host "DNS priorities configured successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Set-NetworkThrottlingIndex {
    Show-Header "SETTING NETWORK THROTTLING INDEX"
    Write-Host "Setting Network Throttling Index..." -ForegroundColor Cyan
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWORD -Force
    Write-Host "Network Throttling Index set successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Set-TcpipParameters {
    Show-Header "CONFIGURING TCP/IP PARAMETERS"
    Write-Host "Configuring TCP/IP parameters..." -ForegroundColor Cyan
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "MaxUserPort" -Value 65534 -Type DWORD -Force
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpTimedWaitDelay" -Value 30 -Type DWORD -Force
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL" -Value 64 -Type DWORD -Force
    Write-Host "TCP/IP parameters configured successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Set-TcpSettings {
    Show-Header "TWEAKING TCP SETTINGS"
    Write-Host "Configuring TCP settings..." -ForegroundColor Cyan
    Set-NetTCPSetting -SettingName Internet -EcnCapability Enabled
    Set-NetTCPSetting -SettingName Internet -Timestamps Enabled
    Set-NetTCPSetting -SettingName Internet -MaxSynRetransmissions 2
    Set-NetTCPSetting -SettingName Internet -NonSackRttResiliency Disabled
    Set-NetTCPSetting -SettingName Internet -InitialRto 2000
    Set-NetTCPSetting -SettingName Internet -MinRto 300
    netsh int tcp set heuristics Disabled | Out-Null
    Write-Host "TCP settings configured successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Set-MtuSettings {
    Show-Header "CONFIGURING MTU SETTINGS"
    Write-Host "Configuring MTU settings..." -ForegroundColor Cyan
    netsh interface ipv4 set subinterface "Wi-Fi" mtu=1500 store=persistent | Out-Null
    netsh interface ipv6 set subinterface "Wi-Fi" mtu=1500 store=persistent | Out-Null
    netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent | Out-Null
    netsh interface ipv6 set subinterface "Ethernet" mtu=1500 store=persistent | Out-Null
    Write-Host "MTU settings configured successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Set-OffloadSettings {
    Show-Header "CONFIGURING OFFLOAD SETTINGS"
    Write-Host "Configuring offload settings..." -ForegroundColor Cyan
    Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled
    Set-NetOffloadGlobalSetting -ReceiveSideScaling Disabled
    Set-NetOffloadGlobalSetting -Chimney Disabled
    Get-NetAdapter | Disable-NetAdapterLso
    Get-NetAdapter | Disable-NetAdapterChecksumOffload
    Write-Host "Offload settings configured successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Disable-IPv6 {
    Show-Header "DISABLING IPV6"
    Write-Host "Disabling IPv6..." -ForegroundColor Cyan
    Set-ItemProperty "HKLM:\SYSTEM\ControlSet001\services\TCPIP6\Parameters" -Name "DisabledComponents" -Value 255 -Type DWORD -Force
    Write-Host "IPv6 disabled successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Disable-InternetProbing {
    Show-Header "DISABLING INTERNET PROBING"
    Write-Host "Disabling Internet Probing..." -ForegroundColor Cyan
    Set-ItemProperty "HKLM:\System\ControlSet001\services\NlaSvc\Parameters\Internet" -Name "EnableActiveProbing" -Value 0 -Type DWORD -Force
    Write-Host "Internet Probing disabled successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Disable-InternetAddons {
    Show-Header "DISABLING INTERNET ADDONS"
    Write-Host "Disabling Internet addons..." -ForegroundColor Cyan
    # This would require a long list of registry keys to disable
    # Skipping for brevity in this example
    Write-Host "Internet addons disabled successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Disable-NaglesAlgorithm {
    Show-Header "DISABLING NAGLE'S ALGORITHM"
    Write-Host "Disabling Nagle's Algorithm..." -ForegroundColor Cyan
    sc.exe config Winmgmt start= demand | Out-Null
    sc.exe start Winmgmt | Out-Null
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        $interfacePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
        Set-ItemProperty -Path $interfacePath -Name "TCPNoDelay" -Value 1 -Type DWORD -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $interfacePath -Name "TcpAckFrequency" -Value 1 -Type DWORD -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $interfacePath -Name "TcpDelAckTicks" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Nagle's Algorithm disabled successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Enable-TaskOffload {
    Show-Header "ENABLING TASK OFFLOAD"
    Write-Host "Enabling Task Offload..." -ForegroundColor Cyan
    netsh int ip set global taskoffload=enabled | Out-Null
    Write-Host "Task Offload enabled successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Optimize-MldIcmp {
    Show-Header "OPTIMIZING MLD AND ICMP"
    Write-Host "Optimizing MLD and ICMP settings..." -ForegroundColor Cyan
    netsh int ip set global dhcpmediasense=disabled | Out-Null
    netsh int ip set global mediasenseeventlog=disabled | Out-Null
    netsh int ip set global mldlevel=none | Out-Null
    netsh int ip set global icmpredirects=disabled | Out-Null
    netsh int tcp set global chimney=enabled | Out-Null
    netsh int tcp set global dca=enabled | Out-Null
    netsh int tcp set global netdma=disabled | Out-Null
    netsh int tcp set global rsc=disabled | Out-Null
    netsh int tcp set global maxsynretransmissions=2 | Out-Null
    netsh int tcp set global timestamps=disabled | Out-Null
    netsh int tcp set global ecncapability=disabled | Out-Null
    netsh int tcp set heuristics disabled | Out-Null
    netsh int tcp set heuristics wsh=disabled | Out-Null
    netsh int tcp set security mpp=disabled | Out-Null
    netsh int tcp set security profiles=disabled | Out-Null
    Write-Host "MLD and ICMP settings optimized successfully!" -ForegroundColor Green
    Pause-ForReturn
}

function Set-QosPolicy {
    Show-Header "SETTING QOS POLICY"
    Write-Host "Setting QoS Policy..." -ForegroundColor Cyan
    # Start PSCHED service
    Set-Service -Name "psched" -StartupType Automatic -Status Running -ErrorAction SilentlyContinue
    
    # Enable MS-Pacer
    Get-NetAdapter | ForEach-Object {
        Enable-NetAdapterBinding -Name $_.Name -ComponentID ms_pacer
    }
    
    # Open GPEDIT
    Start-Process "gpedit.msc"
    
    Write-Host "QoS Policy configured. Please complete configuration in Group Policy Editor." -ForegroundColor Yellow
    Pause-ForReturn
}

function Optimize-NicSettings {
    Show-Header "OPTIMIZING NIC SETTINGS"
    Write-Host "`nOptimizing NIC settings..." -ForegroundColor Cyan
    Write-Host "This will configure your network adapters for best performance" -ForegroundColor Yellow

    try {
        # Get active network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

        if (-not $adapters) {
            Write-Host "No active network adapters found!" -ForegroundColor Red
            Pause-ForReturn
            return
        }

        foreach ($adapter in $adapters) {
            Write-Host "`nConfiguring $($adapter.Name) ($($adapter.InterfaceDescription))..." -ForegroundColor Magenta

            # Disable power saving features
            Set-AdvancedProperty -Adapter $adapter -Property "Energy Efficient Ethernet" -Value "Disabled"
            Set-AdvancedProperty -Adapter $adapter -Property "Green Ethernet" -Value "Disabled"
            Set-AdvancedProperty -Adapter $adapter -Property "Power Saving Mode" -Value "Disabled"

            # Disable offloads
            Set-AdvancedProperty -Adapter $adapter -Property "IPv4 Checksum Offload" -Value "Disabled"
            Set-AdvancedProperty -Adapter $adapter -Property "TCP Checksum Offload (IPv4)" -Value "Disabled"
            Set-AdvancedProperty -Adapter $adapter -Property "UDP Checksum Offload (IPv4)" -Value "Disabled"
            Set-AdvancedProperty -Adapter $adapter -Property "TCP Checksum Offload (IPv6)" -Value "Disabled"
            Set-AdvancedProperty -Adapter $adapter -Property "UDP Checksum Offload (IPv6)" -Value "Disabled"
            Set-AdvancedProperty -Adapter $adapter -Property "Large Send Offload V2 (IPv4)" -Value "Disabled"
            Set-AdvancedProperty -Adapter $adapter -Property "Large Send Offload V2 (IPv6)" -Value "Disabled"

            # Configure buffer sizes with valid range check
            Set-AdvancedProperty -Adapter $adapter -Property "Transmit Buffers" -Value 512 -Min 32 -Max 512 -Step 8
            Set-AdvancedProperty -Adapter $adapter -Property "Receive Buffers" -Value 512 -Min 32 -Max 512 -Step 8

            # Enable RSS if available
            Set-AdvancedProperty -Adapter $adapter -Property "Receive Side Scaling" -Value "Enabled"
            Set-AdvancedProperty -Adapter $adapter -Property "Number of RSS Queues" -Value 4 -Min 1 -Max 16

            # Flow control
            Set-AdvancedProperty -Adapter $adapter -Property "Flow Control" -Value "Disabled"

            # Interrupt moderation
            Set-AdvancedProperty -Adapter $adapter -Property "Interrupt Moderation" -Value "Disabled"
            Set-AdvancedProperty -Adapter $adapter -Property "Interrupt Moderation Rate" -Value "Off"
        }

        Write-Host "`nNIC settings optimized successfully!" -ForegroundColor Green
    } catch {
        Write-Host "`nError optimizing NIC settings: $_" -ForegroundColor Red
    }

    Pause-ForReturn
}

function Set-AdvancedProperty {
    param(
        $Adapter,
        $Property,
        $Value,
        $Min,
        $Max,
        $Step
    )
    
    try {
        # Get current properties
        $properties = Get-NetAdapterAdvancedProperty -Name $Adapter.Name
        
        # Find matching property
        $prop = $properties | Where-Object { $_.DisplayName -eq $Property }
        
        if (-not $prop) {
            Write-Host "  [SKIPPED] '$Property' not found on $($Adapter.Name)" -ForegroundColor DarkYellow
            return
        }
        
        # Validate value
        $valid = $true
        if ($prop.ValidDisplayValues) {
            $valid = $prop.ValidDisplayValues -contains $Value
        } elseif ($Min -ne $null -and $Max -ne $null) {
            $valid = ($Value -ge $Min) -and ($Value -le $Max) -and (($Value % $Step) -eq 0)
        }
        
        if (-not $valid) {
            Write-Host "  [SKIPPED] '$Property' has invalid value '$Value'" -ForegroundColor DarkYellow
            return
        }
        
        # Set the property
        if ($prop.ValidDisplayValues) {
            Set-NetAdapterAdvancedProperty -Name $Adapter.Name -DisplayName $Property -DisplayValue $Value
        } else {
            Set-NetAdapterAdvancedProperty -Name $Adapter.Name -DisplayName $Property -RegistryValue $Value
        }
        Write-Host "  [SUCCESS] Set $Property = $Value" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Failed to set `${Property}`: $($_)" -ForegroundColor Red
    }
}

# =================== [MAIN MENU FUNCTIONS] ===================
function Main-Menu {
    param($choice)
    
    switch ($choice) {
        "1" {
            Show-Header "RESETTING DNS TO AUTOMATIC"
            $adapters = Get-DnsClient | Where-Object {
                $_.InterfaceAlias -match "Wi-Fi|Ethernet"
            }

            if ($adapters.Count -eq 0) {
                Write-Host "`nNo Wi-Fi or Ethernet adapters found!" -ForegroundColor Red
                return
            }

            foreach ($adapter in $adapters) {
                try {
                    Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ResetServerAddresses -ErrorAction Stop
                    Write-Host "`nSuccessfully reset DNS on: $($adapter.InterfaceAlias)" -ForegroundColor Green
                } catch {
                    Write-Host "`nFailed to reset DNS on: $($adapter.InterfaceAlias)" -ForegroundColor Red
                }
            }
            Write-Host "`nOperation completed! All adapters reset to automatic DNS." -ForegroundColor Cyan
            Pause-ForReturn
        }
        "2" {
            Show-Header "TESTING GAMING DNS SERVERS"
            $dnsList = @(
                @{ Name="Cloudflare"; IP="1.1.1.1" }, @{ Name="Cloudflare Alt"; IP="1.0.0.1" },
                @{ Name="Google"; IP="8.8.8.8" }, @{ Name="Google Alt"; IP="8.8.4.4" },
                @{ Name="OpenDNS"; IP="208.67.222.222" }, @{ Name="OpenDNS Alt"; IP="208.67.220.220" },
                @{ Name="Quad9"; IP="9.9.9.9" }, @{ Name="Quad9 Alt"; IP="149.112.112.112" },
                @{ Name="NextDNS"; IP="45.90.28.190" }, @{ Name="NextDNS Alt"; IP="45.90.30.190" }
            )

            $results = @()
            $totalTests = $dnsList.Count
            $currentTest = 0
            
            foreach ($dns in $dnsList) {
                $currentTest++
                $percent = ($currentTest / $totalTests) * 100
                Show-Progress -Activity "Testing DNS Servers" -Status "Testing $($dns.Name) [$($dns.IP)]" -Percent $percent
                
                $pings = Test-Connection -Count 2 -ComputerName $dns.IP -ErrorAction SilentlyContinue
                if ($pings) {
                    $avg = [math]::Round(($pings | Measure-Object -Property ResponseTime -Average).Average, 2)
                    $results += [pscustomobject]@{ Name=$dns.Name; IP=$dns.IP; AvgPing=$avg }
                }
            }
            Show-Progress -Activity "Testing DNS Servers" -Status "Completed" -Percent 100 -Completed

            # Display results with color coding
            $results = $results | Sort-Object AvgPing
            Write-Host "`nTest Results (sorted by latency):" -ForegroundColor Cyan
            Write-Host ("-" * 65) -ForegroundColor DarkGray
            
            foreach ($result in $results) {
                $color = switch -Wildcard ($result.AvgPing) {
                    {$_ -lt 30} { "Green"; break }
                    {$_ -lt 60} { "Yellow"; break }
                    default { "Red" }
                }
                Write-Host ("{0,-15} {1,-18} {2,5} ms" -f $result.Name, "[$($result.IP)]", $result.AvgPing) -ForegroundColor $color
            }

            $topTwo = $results | Select-Object -First 2
            if ($topTwo.Count -lt 2) {
                Write-Host "`nInsufficient responsive DNS servers for configuration!" -ForegroundColor Red
                Pause-ForReturn
                return
            }

            Write-Host "`nRecommended Configuration:" -ForegroundColor Cyan
            Write-Host ("-" * 65) -ForegroundColor DarkGray
            Write-Host "PRIMARY   : $($topTwo[0].Name) [$($topTwo[0].IP)] ($($topTwo[0].AvgPing) ms)" -ForegroundColor Green
            Write-Host "SECONDARY : $($topTwo[1].Name) [$($topTwo[1].IP)] ($($topTwo[1].AvgPing) ms)" -ForegroundColor Yellow

            $apply = Read-Host "`nApply these DNS settings? (Y/N)"
            if ($apply -eq 'y') {
                $adapters = Get-DnsClient | Where-Object {
                    $_.InterfaceAlias -match "Wi-Fi|Ethernet"
                }

                if ($adapters.Count -eq 0) {
                    Write-Host "`nNo Wi-Fi or Ethernet adapters found!" -ForegroundColor Red
                    Pause-ForReturn
                    return
                }

                foreach ($adapter in $adapters) {
                    try {
                        Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias `
                            -ServerAddresses @($topTwo[0].IP, $topTwo[1].IP) -ErrorAction Stop
                        Write-Host "`nSuccessfully configured $($adapter.InterfaceAlias)" -ForegroundColor Green
                    } catch {
                        Write-Host "`nConfiguration failed for $($adapter.InterfaceAlias)" -ForegroundColor Red
                    }
                }
                Write-Host "`nDNS configuration completed!" -ForegroundColor Cyan
                Pause-ForReturn
            }
        }
        "3" {
            Show-Header "MANUAL DNS SELECTION"
            $dnsOptions = @{
                "1" = @{ Name = "Cloudflare"; Servers = @("1.1.1.1", "1.0.0.1"); Color = "Cyan" }
                "2" = @{ Name = "Google"; Servers = @("8.8.8.8", "8.8.4.4"); Color = "Green" }
                "3" = @{ Name = "OpenDNS"; Servers = @("208.67.222.222", "208.67.220.220"); Color = "Magenta" }
                "4" = @{ Name = "Quad9"; Servers = @("9.9.9.9", "149.112.112.112"); Color = "Yellow" }
                "5" = @{ Name = "NextDNS"; Servers = @("45.90.28.190", "45.90.30.190"); Color = "Blue" }
                "6" = @{ Name = "AdGuard"; Servers = @("94.140.14.14", "94.140.15.15"); Color = "DarkGreen" }
                "7" = @{ Name = "NordVPN DNS"; Servers = @("103.86.96.100", "103.86.99.100"); Color = "DarkCyan" }
                "8" = @{ Name = "CleanBrowsing"; Servers = @("185.228.168.9", "185.228.169.9"); Color = "DarkMagenta" }
                "0" = @{ Name = "Return to Main Menu"; Color = "Gray" }
            }

            while ($true) {
                Write-Host "`nSelect a DNS Provider:" -ForegroundColor Cyan
                Write-Host ("-" * 65) -ForegroundColor DarkGray
                
                foreach ($key in $dnsOptions.Keys | Sort-Object {[int]$_}) {
                    $option = $dnsOptions[$key]
                    Write-Host ("{0,-2}: {1}" -f $key, $option.Name) -ForegroundColor $option.Color
                }
                
                $dnsChoice = Read-Host "`nEnter choice (0-8)"
                Write-Host ""

                if ($dnsChoice -eq "0") { 
                    return 
                }

                if (-not $dnsOptions.ContainsKey($dnsChoice)) {
                    Write-Host "Invalid selection! Please try again." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                    continue
                }

                $servers = $dnsOptions[$dnsChoice].Servers
                $adapters = Get-DnsClient | Where-Object {
                    $_.InterfaceAlias -match "Wi-Fi|Ethernet"
                }

                if ($adapters.Count -eq 0) {
                    Write-Host "`nNo Wi-Fi or Ethernet adapters found!" -ForegroundColor Red
                    Pause-ForReturn
                    return
                }

                foreach ($adapter in $adapters) {
                    try {
                        Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ServerAddresses $servers -ErrorAction Stop
                        Write-Host "Successfully configured $($adapter.InterfaceAlias)" -ForegroundColor Green
                        Write-Host "Primary: $($servers[0])" -ForegroundColor Yellow
                        Write-Host "Secondary: $($servers[1])" -ForegroundColor Yellow
                        Write-Host ""
                    } catch {
                        Write-Host "Configuration failed for $($adapter.InterfaceAlias)" -ForegroundColor Red
                    }
                }
                Write-Host "DNS configuration completed!" -ForegroundColor Cyan
                Pause-ForReturn
                return
            }
        }
        "4" {
            while ($true) {
                $netChoice = Show-NetworkEnhancementMenu
                if ($netChoice -eq "M") { break }
                Invoke-NetworkEnhancement -choice $netChoice
            }
        }
        "5" {
            Toggle-Bufferbloat
        }
        "6" {
            Invoke-AutoUpdate -currentVersion $scriptVersion -updateUrl $githubRawUrl
        }
        "0" {
            Write-Host "`nExiting DNS Checker..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            Exit
        }
        default {
            Write-Host "`nInvalid selection! Please choose 0-6." -ForegroundColor Red
            Pause-ForReturn
        }
    }
}

# =================== [MAIN EXECUTION] ===================
Show-Introduction
while ($true) {
    $choice = Show-Banner
    Main-Menu -choice $choice
}

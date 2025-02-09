function Write-DarkGrayDate {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String]
        $Message
    )
    if ($Message) {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) $Message"
    }
    else {
        Write-Host -ForegroundColor DarkGray "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) " -NoNewline
    }
}
function Write-DarkGrayHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Message
    )
    Write-Host -ForegroundColor DarkGray $Message
}
function Write-DarkGrayLine {
    [CmdletBinding()]
    param ()
    Write-Host -ForegroundColor DarkGray '========================================================================='
}
function Write-SectionHeader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Message
    )
    Write-DarkGrayLine
    Write-DarkGrayDate
    Write-Host -ForegroundColor Cyan $Message
}
function Write-SectionSuccess {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [System.String]
        $Message = 'Success!'
    )
    Write-DarkGrayDate
    Write-Host -ForegroundColor Green $Message
}

function New-SetupCompleteOSDCloudFiles{
    
    $SetupCompletePath = "C:\OSDCloud\Scripts\SetupComplete"
    $ScriptsPath = $SetupCompletePath

    if (!(Test-Path -Path $ScriptsPath)){New-Item -Path $ScriptsPath -ItemType Directory -Force | Out-Null}

    $RunScript = @(@{ Script = "SetupComplete"; BatFile = 'SetupComplete.cmd'; ps1file = 'SetupComplete.ps1';Type = 'Setup'; Path = "$ScriptsPath"})

    Write-Output "Creating $($RunScript.Script) Files in $SetupCompletePath"

    $BatFilePath = "$($RunScript.Path)\$($RunScript.batFile)"
    $PSFilePath = "$($RunScript.Path)\$($RunScript.ps1File)"
            
    #Create Batch File to Call PowerShell File
    if (Test-Path -Path $PSFilePath){
        copy-item $PSFilePath -Destination "$ScriptsPath\SetupComplete.ps1.bak"
    }        
    New-Item -Path $BatFilePath -ItemType File -Force
    $CustomActionContent = New-Object system.text.stringbuilder
    [void]$CustomActionContent.Append('%windir%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -File C:\OSDCloud\Scripts\SetupComplete\SetupComplete.ps1')
    Add-Content -Path $BatFilePath -Value $CustomActionContent.ToString()

    #Create PowerShell File to do actions

    New-Item -Path $PSFilePath -ItemType File -Force
    Add-Content -path $PSFilePath "Write-Output 'Starting SetupComplete HOPE Script Process'"
    Add-Content -path $PSFilePath "Write-Output 'iex (irm startosd.tighenet.com)'"
    Add-Content -path $PSFilePath 'if ((Test-WebConnection) -ne $true){Write-error "No Internet, Sleeping 2 Minutes" ; start-sleep -seconds 120}'
    Add-Content -path $PSFilePath 'iex (irm startosd.tighenet.com)'
}

iex (irm functions.tighenet.com)

if ($env:SystemDrive -eq 'X:') {
    $LogName = "CapacityOSD-$((Get-Date).ToString('yyyy-MM-dd-HHmmss')).log"
    Start-Transcript -Path $env:TEMP\$LogName -Append -Force
}
Write-SectionHeader -Message "Starting $ScriptName1 $ScriptVersion1"
write-host "Added Function New-SetupCompleteOSDCloudFiles" -ForegroundColor Green

$ScriptName = 'startosd'
$ScriptVersion = '25.2.3.1'

Set-ExecutionPolicy Bypass -Force

#WinPE Stuff
if ($env:SystemDrive -eq 'X:') {
    #Create Custom SetupComplete on USBDrive, this will get copied and run during SetupComplete Phase thanks to OSD Function: Set-SetupCompleteOSDCloudUSB
    
    #Doing this now with a new process that will create the files right on C, skipping the need to use a USB Drive... not sure why I was doing that before.
    #Set-SetupCompleteCreateStartHOPEonUSB
    if (Test-Connection -ComputerName wd1tb -ErrorAction SilentlyContinue){
        Write-SectionHeader -Message "Mapping Drive W: to \\WD1TB\OSD"
        net use w: \\wd1tb\osd /user:OSDCloud P@ssw0rd
        start-sleep -s 2
        if (Test-Path -Path W:\OSDCloud){
            Write-Host -ForegroundColor Green "Successfully Mapped Drive"
        }
        else{
            Write-Host -ForegroundColor Red "Failed to Map Drive"
        }
    }
    else{
        Write-Host -ForegroundColor DarkGray "No Connection to WD1TB, Skipping Drive Mapping"
    }
    Write-SectionHeader -Message "Starting win11.tighenet.com"
    iex (irm win11.tighenet.com)

    
    #Just go ahead and create the Setup Complete files on the C Drive in the correct Location now that OSDCloud is done in WinPE
    Write-SectionHeader -Message "Creating Custom SetupComplete Files for Hope"
    New-SetupCompleteOSDCloudFiles

    if (Test-Path -Path $env:TEMP\$LogName){
        Write-DarkGrayHost -Message "Copying Log to C:\OSDCloud\Logs"
        Stop-Transcript
        Copy-Item -Path $env:TEMP\$LogName -Destination C:\OSDCloud\Logs -Force
    }
    #restart-computer
}

#Non-WinPE
if ($env:SystemDrive -ne 'X:') {
    Set-ExecutionPolicy Bypass -Force

    #Setup Post Actions Scheduled Task
    iex (irm postactiontask.tighenet.com)

    #Disable Auto Bitlocker
    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker -Name PreventDeviceEncryption -PropertyType dword -Value 1 -Force
    
    #Remove Personal Teams
    Write-Host -ForegroundColor Gray "**Removing Default Chat Tool**" 
    try {
        iex (irm https://raw.githubusercontent.com/suazione/CodeDump/main/Set-ConfigureChatAutoInstall.ps1)
    }
    catch {}
    

    Write-SectionHeader -Message "**Running Set-ByPassOOBE**"
    Set-ByPassOOBE

    Write-SectionHeader -Message "**Running Set-AcceptEULA**"
    Set-AcceptEULA
    
    Write-SectionHeader -Message "**Running Test.tighenet.com**" 
    iex (irm test.tighenet.com)
     
    #Set Time Zone to Automatic Update
    #Write-Host -ForegroundColor Gray "**Setting Time Zone for Auto Update**" 
    #Enable-AutoZimeZoneUpdate

    #Enable Microsoft Other Updates:
    (New-Object -com "Microsoft.Update.ServiceManager").AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")

    #Enable "Notify me when a restart is required to finish updating"
    New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name RestartNotificationsAllowed2 -PropertyType dword -Value 1

    Write-SectionHeader -Message  "**Setting Default Profile Personal Preferences**" 
    Set-DefaultProfilePersonalPref
    
    #Try to prevent crap from auto installing
    Write-Host -ForegroundColor Gray "**Disabling Cloud Content**" 
    Disable-CloudContent
    
    #Set Win11 Bypasses
    Write-Host -ForegroundColor Gray "**Enabling Win11 Bypasses**" 
    Set-Win11ReqBypassRegValues
    
    #Windows Updates
    Write-SectionHeader -Message "**Running MS Updates**"
    Write-Host -ForegroundColor Gray "**Running Defender Updates**"
    Update-DefenderStack
    Write-Host -ForegroundColor Gray "**Running Windows Updates**"
    Start-WindowsUpdate
    Write-Host -ForegroundColor Gray "**Running Driver Updates**"
    Start-WindowsUpdateDriver

    #Store Updates
    Write-Host -ForegroundColor Gray "**Running Winget Updates**"
    Write-Host -ForegroundColor Gray "Invoke-UpdateScanMethodMSStore"
    Invoke-UpdateScanMethodMSStore
    #Write-Host -ForegroundColor Gray "winget upgrade --all --accept-package-agreements --accept-source-agreements"
    #winget upgrade --all --accept-package-agreements --accept-source-agreements

    #Modified Version of Andrew's Debloat Script
    Write-SectionHeader -Message "**Running Debloat Script**" 
    iex (irm debloat.tighenet.com)

    #OEM Updates
    try {
        iex (irm https://raw.githubusercontent.com/gwblok/garytown/master/Dev/CloudScripts/LenovoUpdate.ps1)
    }
    catch {}

    try {
        iex (irm https://dell.tighenet.com)
    }
    catch {}

    #Set Time Zone
    Write-Host -ForegroundColor Gray "**Setting TimeZone based on IP**"
    Set-TimeZoneFromIP

    Write-SectionHeader -Message  "**Completed startosd.tighenet.com sub script**" 
}

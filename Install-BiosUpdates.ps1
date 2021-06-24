#!PS
#timeout=600000
$downloadLocation = 'C:\temp\BIOS_Updates\'

$biosUpdateURLS = @{
                    'Latitude 3410'='https://dl.dell.com/FOLDER07410413M/1/Latitude_3410_3510_1.9.0.exe'
                    'Latitude 3510'='https://dl.dell.com/FOLDER07410413M/1/Latitude_3410_3510_1.9.0.exe'
                    'Latitude 3420'='https://dl.dell.com/FOLDER07473921M/1/Latitude_3420_3520_1.8.0.exe'
                    'Latitude 3520'='https://dl.dell.com/FOLDER07473921M/1/Latitude_3420_3520_1.8.0.exe'
                    'Latitude 5410'='https://dl.dell.com/FOLDER07488211M/1/Latitude_5X10_Precision_3550_1.6.0.exe'
                    'Latitude 5510'='https://dl.dell.com/FOLDER07488211M/1/Latitude_5X10_Precision_3550_1.6.0.exe'
                    'Precision 3550'='https://dl.dell.com/FOLDER07488211M/1/Latitude_5X10_Precision_3550_1.6.0.exe'
                    'Optiplex 3080'='https://dl.dell.com/FOLDER07410379M/1/OptiPlex_3080_2.1.1.exe'
                    'Optiplex 7080'='https://dl.dell.com/FOLDER07411854M/1/OptiPlex_7080_1.4.0.exe'
                    'Precision 3551'='https://dl.dell.com/FOLDER07414616M/1/Latitude_5X11_Precision_3551_1.6.0.exe'
                    'Latitude 5411'='https://dl.dell.com/FOLDER07414616M/1/Latitude_5X11_Precision_3551_1.6.0.exe'
                    'Latitude 5511'='https://dl.dell.com/FOLDER07414616M/1/Latitude_5X11_Precision_3551_1.6.0.exe'
                    'XPS 15 9500'='https://dl.dell.com/FOLDER07401752M/1/XPS_9500_1.8.1.exe'
                    }

$biosUpdateVersions = @{
                    'Latitude 3410'='1.9.0'
                    'Latitude 3510'='1.9.0'
                    'Latitude 3420'='1.8.0'
                    'Latitude 3520'='1.8.0'
                    'Latitude 5410'='1.6.0'
                    'Latitude 5510'='1.6.0'
                    'Precision 3550'='1.6.0'
                    'Optiplex 3080'='2.1.1'
                    'Optiplex 7080'='1.4.0'
                    'Precision 3551'='1.6.0'
                    'Latitude 5411'='1.6.0'
                    'Latitude 5511'='1.6.0'
                    'XPS 15 9500'='1.8.1'
                    }

function create-DownloadFolder
{
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $DownloadPath
    )

    If(!(test-path $DownloadPath))
    {
        New-Item -ItemType Directory -Force -Path $DownloadPath
    }
}

function downloadAndInstall-File
{
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $DownloadURL,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $InstallSwitch
    )

    $Url = $DownloadURL
    $FileName = $(Split-Path -Path $Url -Leaf) 
    $Destination= $downloadLocation 
    $FilePath = $Destination + $FileName
 
    Invoke-WebRequest -Uri $Url -OutFile $FilePath
    & $FilePath $InstallSwitch

    Get-Process -Name $FilePath -ErrorAction SilentlyContinue | Wait-Process
}

function get-BiosVersion
{
    # Install Dell CC if necessary
    If(!(test-path 'C:\Program Files (x86)\Dell\Command Configure\'))
    {
        downloadAndInstall-File 'https://dl.dell.com/FOLDER06874295M/2/Dell-Command-Configure_N9DPF_WIN_4.4.0.86_A00.EXE' '/s'
    }

    
    # It takes a minute to install, so we'll wait...
    $counter = 0
    $maxWait = 360
    do
    {
        Start-Sleep -Seconds 1
        $counter++
    } while ((!(test-path 'C:\Program Files (x86)\Dell\Command Configure\X86_64\cctk.exe')) -and ($counter -lt $maxWait))

    If($counter -ge $maxWait)
    {
        Write-Host "File failed to install Dell Command Configure in a timely fashion"
        exit 1
    }
    

    Set-Alias -Name cctk64 -Value 'C:\Program Files (x86)\Dell\Command Configure\X86_64\cctk.exe'
    Set-Alias -Name cctk86 -Value 'C:\Program Files (x86)\Dell\Command Configure\X86\cctk.exe'

    # Determine current BIOS version
    $biosVerRaw = cctk64 --BiosVer
    $biosVer = $biosVerRaw.split('=')[1]

    Write-Host "Current BIOS version is: " $biosVer

    return $biosVer
}

function install-BiosUpdate
{
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Model
    )

    write-host $Model

    $URL = $biosUpdateURLS.$Model

    downloadAndInstall-File $URL '/s'

}

create-DownloadFolder($downloadLocation)

# Determine Model #
$Model = $(WMIC CSPRODUCT GET NAME)[2].trim()

# Check if it already has latest update
$BiosVersion = get-BiosVersion
$BiosNeededVersion = $biosUpdateVersions.$model

If ($BiosVersion -eq $BiosNeededVersion) {
    Write-Host("Bios version is $BiosVersion")
    Write-Host("Bios needed is $BiosNeededVersion")
    Write-Host("These are the same. Exiting...")
    exit 0
}

write-host("Model is $model")

install-BiosUpdate($Model)


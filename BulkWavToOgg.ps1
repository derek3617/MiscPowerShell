<#
.Synopsis
    Bulk convert wav to ogg files using ffmpeg.exe
.DESCRIPTION
    This script will take each wav file in the current folder, convert them, and place 
    them in an "ogg" child folder. Files will be processed recursively and any 
    sub-folders containing wav files will be recreated in the ogg folder.

    e.g. 
    If the script is called from C:\MyFolder\
    the file: C:\MyFolder\childFolder\music.wav
    will be copied to: C:\MyFolder\ogg\childFolder\music.wav

    If you do not have ffmpeg installed you will need to download it from
    https://ffmpeg.org/download.html

    This script could be repurposed to call other executables in bulk.
.EXAMPLE
   cd C:\MySoundFiles\
   C:\MyPowerShell\BatchWaveToOgg.ps1
.EXAMPLE
   BatchWaveToOgg.ps1 "C:\Program Files\ffmpeg\bin\ffmpeg.exe"
.LINK
    https://github.com/derek3617/MiscPowerShell
.NOTES
    Author: Derek Goldspink
    Version: 2020-12-06

    This script is free to use and comes with no warranty or support.
#>
param (
    [string]$executableLocation = "C:\Program Files\ffmpeg\bin\ffmpeg.exe",
    [string]$subFolderName = "ogg",
    [string]$sourceExtension = "wav",
    [string]$destinationExtension = "ogg", 
    [string]$argumentString = "-n -i `"{0}`" -acodec libvorbis `"{1}`"", # source and destiation
    [int]$batchSize=300 # higher numbers mean tougher workloads
)

clear 

function TrackProgress([string]$procName)
{
    #loop until no more processes running

    [int]$startProcCount = (Get-Process | Where-Object { $_.Name -eq $procName } | Measure-Object).Count
    [int]$procCount = $startProcCount
    
    While($procCount -gt 0)
    {
        [int]$procCount = (Get-Process | Where-Object { $_.Name -eq $procName } | Measure-Object).Count
        $percentDone = 100 - 100 * $procCount / $startProcCount;

        Write-Progress -Activity "Batch Running" -Status "$procCount $procName processes running" -PercentComplete $percentDone;

        Sleep -Seconds 1
    }
}

function BulkExecute(
    [string]$executableLocation,
    [string]$subFolderName,
    [string]$sourceExtension,
    [string]$destinationExtension, 
    [string]$argumentString,
    [int]$batchSize
)
{
    If (!(Test-Path $executableLocation))
    {
        Write-Host "Could not locate executable location, please provide full path of .exe file as argument, or replace at top of script.";
        return;
    }

    $fileList = Get-ChildItem -Filter ("*." + $sourceExtension) -Recurse | % { $_.FullName.Substring(0,$_.FullName.Length-$sourceExtension.Length-1) }
    [string]$currentFolder = [string](Get-Location)
    [string]$procTrackingName = ""
    
    [int]$batchCount = 0;

    foreach($fileName in $fileList)
    {
        Write-Host "---------------------------------------------------------------------";
        
        #Calculate Source and Destination
        $newFolder = "$currentFolder\$subFolderName"

        $source = "$fileName.$sourceExtension"
        $destination = $fileName.Replace($currentFolder, $newFolder) + ".$destinationExtension"

        Write-Host "Source: " $source;
        Write-Host "Destination: " $destination;

        If ((Test-Path $destination) -eq $False)
        {
            Write-Host "*** CREATING FILE **************************"
        
            # Create Folder location
            $newPath = Split-Path -Path $destination
            New-Item -ItemType "directory" -Path $newPath -Force

            # Input file > Convert > Output File
            $proc = Start-Process -WindowStyle Hidden -PassThru `
                -FilePath $executableLocation `
                -ArgumentList ($argumentString -f $source, $destination)

            $procTrackingName = $proc.Name
            $batchCount++;
        }
        else
        {
            Write-Host "*** SKIP FILE EXISTS ***********************"
        }

        # Wait for processes to finish if over batch size
        if($batchCount -eq $batchSize)
        {
            TrackProgress $procTrackingName
            $batchCount = 0;
        }
    }

    TrackProgress $procTrackingName
    
    # Report file counts
    Write-Host "$sourceExtension file count:" (Get-ChildItem -Include "*.$sourceExtension" -Recurse | Measure-Object).Count
    Write-Host "$destinationExtension file count:" (Get-ChildItem -Include "*.$destinationExtension" -Recurse | Measure-Object).Count
}

BulkExecute $executableLocation $subFolderName $sourceExtension $destinationExtension $argumentString, $batchSize

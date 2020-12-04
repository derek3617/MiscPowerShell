<#
.Synopsis
    Move images to a folder named after the year and date
.DESCRIPTION
   This script will move your images to a folder named after the year and date
   yyyy\yyyy-MM-dd\image.jpg

   If the image data is missing a date, the script will attempt to get date data 
   from the file names.

   Parameters include sourceFolder and destinationFolder, if they are left blank 
   the current location is used.

   Example:
   C:\myPowerShell\MoveAndSortPictures.ps1 -destinationFolder "C:\mySortedPhotos"
.LINK
    https://github.com/derek3617/MiscPowerShell
.NOTES
    Author: Derek Goldspink
    Version: 2020-12-06

    This script is free to use and comes with no warranty or support.
#>
param(
    [string]$sourceFolder = "",
    [string]$destinationFolder = ""
)

function GetImageDate([string] $file)
{
    [Reflection.Assembly]::LoadFile('C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Drawing.dll') | Out-Null
 
    try
    {
        # try and get date taken from image data

        $image = New-Object System.Drawing.Bitmap -ArgumentList $file

        $takenData = $image.GetPropertyItem(36867).Value

        if ($takenData -eq $null)
        {
            return $null;
        }

  
        $takenValue = [System.Text.Encoding]::Default.GetString($takenData, 0, $takenData.Length - 1)
        $taken = [DateTime]::ParseExact($takenValue, 'yyyy:MM:dd HH:mm:ss', $null);
        return $taken;
    }
    catch
    {
        # check for date in file name
		if($file -match '20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]' -and $matches.Count -eq 1 )
		{
			$takenDate = [DateTime]$matches[0];
			return $takenDate;
		}
        # check for another date in file name
		elseif($file -match '20[0-9][0-9][0-1][0-9][0-3][0-9]' -and $matches.Count -eq 1)
		{
			$takenDate = [DateTime]($matches[0].Insert(4,"-").Insert(7,"-"));
			return $takenDate;
		}
		
        return $null
    }
    finally
    {
        if($image -ne $null)
        {
            $image.Dispose()
        }
    }
}


function MoveAndSortPictures(
    [string]$sourceFolder = "",
    [string]$destinationFolder = ""
)
{
    if($sourceFolder -eq ""){ $sourceFolder = Get-Location; }
    if($destinationFolder -eq ""){ $destinationFolder = Get-Location; }

    $fileList = Get-ChildItem -Recurse


    foreach ($file in $fileList)
    {
	    if ($file.Attributes -ne "Directory")
	    {
            #longer format string would be yyyy-MM-dd-HH_mm_ss_fff
            $fileDate = GetImageDate($file.FullName)

            if($fileDate -ne $null)
            {
		        $date = $fileDate.ToString("yyyy-MM-dd");
		        $year = $fileDate.ToString("yyyy");
		        $dateFolder = ("$destinationFolder\$year\$date");
		
		        if (!(Test-Path -path $dateFolder))
		        {
			        New-Item $dateFolder -type directory
			        Write-Host ("-".PadRight(80,'-'));
			        Write-Host ("Creating folder: $dateFolder");
		        }

		        if (!(Test-Path -path ("$dateFolder\$file.Name")))
		        {
    		        Move-Item $file.FullName $dateFolder;
		            Write-Host ("Moving file: $file.FullName to location $dateFolder");
                }
                else
                {
                    Write-Host ("Skipped file: $file.FullName file already exist in location $dateFolder");
                }
            }
            else
            {
               Write-Host ("Skipped file: $file.FullName unable to retrieve date data.");
            }
	    }
    }
}

MoveAndSortPictures -sourceFolder $sourceFolder -destinationFolder $destinationFolder;
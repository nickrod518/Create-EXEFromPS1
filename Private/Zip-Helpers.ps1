# This zip method is not as reliable, and slower, but we must use it if .NET 4.5+ is not available
function Zip-FileOld {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $SourceDirectoryPath,
        [Parameter(Mandatory=$true)]
        [string]
        $DestinationDirectoryPath
    )

    Write-Verbose 'Using shell application based zip process'

    # Get the full path of the source zip archive
    $SourceDirectoryFullPath = (Get-Item $SourceDirectoryPath).FullName
    Write-Verbose "Full path of source directory: $SourceDirectoryFullPath"
        
    $TargetZipPath = "$DestinationDirectoryPath\$($SourceDirectoryFullPath.Split('\')[-1]).zip"

    # Create empty zip file that is not read only
    Set-Content $TargetZipPath ([byte[]] @(80, 75, 5, 6 + (,0 * 18))) -Encoding Byte
    (Get-Item $TargetZipPath).IsReadOnly = $false

    $Shell = New-Object -ComObject Shell.Application
    $ZipFile = $Shell.NameSpace($TargetZipPath)
    Write-Verbose "Zip file location: $TargetZipPath"

    # User Force parameter to make sure we get hidden items too
    Get-ChildItem $SourceDirectoryFullPath -Force | ForEach-Object {
        # Skip empty directories
        if (($_.Mode -like 'd-----') -and (-not (Get-ChildItem $_.FullName | Measure-Object).Count)) {
            Write-Verbose "$($_.Name) is an empty directory; skipping"
        } else {
            # Copy file into zip
            $ZipFile.CopyHere($_.FullName)
            Write-Verbose "Copied $($_.Name) into zip"

            # Limitation of shell, wait to make sure each file is copied before continuing
            while ($ZipFile.Items().Item($_.Name) -eq $null) {
                Start-Sleep -Milliseconds 500
            }
        }
    }

    # Return the path of the zip file
    $TargetZipPath
}

# This zip method requires .NET 4.5+, so we check for that
function Zip-File {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $SourceDirectoryPath,
        [Parameter(Mandatory=$true)]
        [string]
        $DestinationDirectoryPath
    )

    Write-Verbose 'Using assembly based zip process'

    # Get the full path of the source zip archive
    $SourceDirectoryFullPath = (Get-Item $SourceDirectoryPath).FullName
    Write-Verbose "Full path of source directory: $SourceDirectoryFullPath"

    $TargetZipPath = "$DestinationDirectoryPath\$($SourceDirectoryFullPath.Split('\')[-1]).zip"

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($SourceDirectoryFullPath, $TargetZipPath)
    Write-Verbose "Zip file location: $TargetZipPath"

    # Return the path of the zip file
    $TargetZipPath
}

# We need to make this function available to the exe, so save it to a variable for later
$UnZipFunction = {
    function UnZip-File {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)]
            [string]
            $SourceZipPath
        )

        $Shell = New-Object -ComObject Shell.Application

        # Get the full path of the source zip archive
        $SourceZipFullPath = (Get-Item $SourceZipPath).FullName
        Write-Verbose "Full path of zip archive: $SourceZipFullPath"

        # Create the destination folder with the same name as the source
        $DestinationDirectory = (New-Item ($SourceZipFullPath -replace '.zip', '') -ItemType Directory -Force).FullName
        Write-Verbose "Destination for zip archive contents: $DestinationDirectory"

        # UnZip files answering yes to all prompts
        $Shell.NameSpace($DestinationDirectory).CopyHere($Shell.NameSpace($SourceZipFullPath).Items(), 16) 
    }
}
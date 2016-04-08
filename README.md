# Create-EXEFromPS1
Takes one PowerShell script and any number of supplementary files or even a directory and creates an exe using Windows's built in iexpress program. The exe will run on any machine with PowerShell 2.0+.

## Install
Copy the repo into your modules directory (C:\Users\<username>\Documents\WindowsPowerShell\Modules\) and then you will be able to import by typing 
`Import-Module Create-EXEFromPS1` in PowerShell.
If you wish for the module to be automatically imported you can enter `Add-Content $profile 'Import-Module Create-EXEFromPS1'` in PowerShell.

## Running
To simply turn one ps1 into an exe, you can type `New-EXEFromPS1` and you will be prompted to select the file from a file browser. For details on advanced parameters, reference below:

`.SYNOPSIS`

    Convert a PowerShell script into a deployable exe using iexpress.

`.DESCRIPTION`

    Takes one PowerShell script and any number of supplementary files and create an exe using Windows's built in iexpress program.
    If you use one of the parameters that allows you to provide a folder, the script will zip that folder and add it as a supplemental file.
    Upon running the exe, the directory will first be unzipped and made available with the same structure, retaining relative path calls.
    Verbose output is available for most of the processes in this script if you call it using the -Verbose parameter.

`.PARAMETER PSScriptPath`

    Path string to PowerShell script that you want to use as the first thing iexpress calls when the exe is run.
    If blank, you will be prompted with a file browse dialog where you can select a file.

`.PARAMETER SupplementalFilePaths`

    Array of comma separated supplemental file paths that you want to include as resources.

`.PARAMETER SelectSupplementalFiles`

    Use this flag to be prompted to select the supplementary files in an Open File Dialog.

`.PARAMETER SupplementalDirectoryPath`

    Path to a directory that will be zipped and added as a supplementary file. 
    When the exe is run, this script will first be unzipped and all files are available.

`.PARAMETER SelectSupplementalDirectory`

    Use this flag to be prompted to select a directory in an Open File Dialog that will be zipped and added as a supplementary file.
    When the exe is run, this script will first be unzipped and all files are available.

`.PARAMETER RemoveTempDir`

    Set this to false to keep the temp directory around after the exe is created. It is available at the root of C:.

`.PARAMETER x64`

    Use the 64-bit iexpress path so that 64-bit PowerShell is consequently called.

`.OUTPUTS`

    An exe file in the same directory as the ps1 script you specify

`.EXAMPLE`

    .\Create-EXEFrom.ps1 -PSScriptPath .\test.ps1 -SupplementalFilePaths '..\test2.ps1', .\ps1toexe.ps1
    # Creates an exe using the provided PowerShell script and supplemental files.

`.EXAMPLE`

    .\Create-EXEFrom.ps1 -SelectSupplementalFiles
    # Prompts the user to select the PowerShell script and supplemental files using an Open File Dialog.

`.EXAMPLE`

    .\Create-EXEFrom.ps1 -SupplementalDirectoryPath 'C:\Temp\MyTestDir' -RemoveTempDir $false
    # Zips MyTestDir and attaches it to the exe. When the exe is run, but before the user's script gets run, 
    # it will be extracted to the same directory as the user's script. Temp directory used during exe creation
    # will be left intact for user inspection or debugging purposes.

`.NOTES`

    Created by Nick Rodriguez

    Requires iexpress, which is included in most versions of Windows (https://en.wikipedia.org/wiki/IExpress).

    Version 1.4 - 3/29/16
        -Added x64 switch for creating exe using 64-bit iexpress.

    Version 1.3 - 2/29/16
        -Added PS Version 2.0 support

    Version 1.2 - 2/27/16
        -Added parameter for leaving temp directory intact - useful for bug smashing.
        -Added options for selecting or specifying an entire directory as a supplemental file.
        -Added functions for zipping, unzipping, testing .NET version (related to zipping), and GUI for selecting directory.

    Version 1.1 - 2/27/16
        -Removed $PSScriptRoot references in process block, which were causing errors when run from ISE.
        -New target exe destination is directory of target ps1.
        -Changed location of temp directory to root of C: to prevent issues with path names containing spaces.
        -Changed method of getting target name from trimming to replacing to prevent cutting off chars of file name.

    Version 1.0 - 2/26/16

`.LINK`

    https://github.com/nickrod518/Create-EXEFromPS1

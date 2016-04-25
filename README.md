# Create-EXEFromPS1
Takes one PowerShell script and any number of supplementary files or even a directory and creates an exe using Windows's built in iexpress program. The exe will run on any machine with PowerShell 2.0+.

## Portable Script
If you don't want to mess with the module, you can simply use the Create-EXEFrom.ps1 script. For details on advanced parameters, reference below. 

## Module
Copy the repo into your modules directory (C:\Users\<username>\Documents\WindowsPowerShell\Modules\) and then you will be able to import by typing 
`Import-Module Create-EXEFromPS1` in PowerShell.
If you wish for the module to be automatically imported you can enter `Add-Content $profile 'Import-Module Create-EXEFromPS1'` in PowerShell. The command can be run with New-EXEFromPS1.

## Running
To simply turn one ps1 into an exe, run with no parameters and you will be prompted to select the file from a file browser. For details on advanced parameters, reference below.

By default, if your scripts reference relative paths or you use $PSScriptRoot, the temporary directory that the exe's contents were extracted to will be used. To use the directory that the exe is run from, use `$(Split-Path -Parent $args[0])`.

### Parameters
**PSScriptPath** - Path string to PowerShell script that you want to use as the first thing iexpress calls when the exe is run.
If blank, you will be prompted with a file browse dialog where you can select a file.

**SupplementalFilePaths** - Array of comma separated supplemental file paths that you want to include as resources.

**SelectSupplementalFiles** - Use this flag to be prompted to select the supplementary files in an Open File Dialog.

**SupplementalDirectoryPath** - Path to a directory that will be zipped and added as a supplementary file. When the exe is run, this script will first be unzipped and all files are available.

**SelectSupplementalDirectory** - Use this flag to be prompted to select a directory in an Open File Dialog that will be zipped and added as a supplementary file. When the exe is run, this script will first be unzipped and all files are available.

**KeepTempDir** - Keep the temp directory around after the exe is created. It is available at the root of C:.

**x64** - Use the 64-bit iexpress path so that 64-bit PowerShell is consequently called.

### Examples
```
New-EXEFromPS1 -PSScriptPath .\test.ps1 -SupplementalFilePaths '..\test2.ps1', .\ps1toexe.ps1
# Creates an exe using the provided PowerShell script and supplemental files.

New-EXEFromPS1 -SelectSupplementalFiles
Prompts the user to select the PowerShell script and supplemental files using an Open File Dialog.

New-EXEFromPS1 -SupplementalDirectoryPath 'C:\Temp\MyTestDir' -KeepTempDir
# Zips MyTestDir and attaches it to the exe. When the exe is run, but before the user's script gets run, 
# it will be extracted to the same directory as the user's script. Temp directory used during exe creation
# will be left intact for user inspection or debugging purposes.
```

## Issues
None that I'm aware of, but please let me know if you find any!

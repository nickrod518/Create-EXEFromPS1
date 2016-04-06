function Get-File {
    [CmdletBinding()]
    [OutputType([psobject[]])]
    param (
        [Parameter(Mandatory=$false)]
        [switch]
        $SupplementalFiles
    ) 

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    # PSScriptRoot will be null if run from the ISE or PS Version < 3.0
    $OpenFileDialog.InitialDirectory = $PSScriptRoot
    if ($SupplementalFiles) {
        $OpenFileDialog.Title = 'Select one or more files'
        $OpenFileDialog.filter = "All Files| *.*"
        $OpenFileDialog.Multiselect = 'true'
    } else {
        $OpenFileDialog.Title = 'Select a file'
        $OpenFileDialog.filter = "PowerShell (*.ps1)| *.ps1"
    }
    $OpenFileDialog.ShowHelp = $true
    $OpenFileDialog.ShowDialog() | Out-Null
    try {
        if ($SupplementalFiles) {
            foreach ($FileName in $OpenFileDialog.FileNames) { Get-Item $FileName }
        } else {
            Get-Item $OpenFileDialog.FileName
        }
    } catch {
        Write-Warning 'Open File Dialog was closed or cancelled without selecting any files'
    }
}

function Get-Directory {
    [CmdletBinding()]
    [OutputType([psobject])]
    param()

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenDirectoryDialog = New-Object Windows.Forms.FolderBrowserDialog
    $OpenDirectoryDialog.ShowDialog() | Out-Null
    try {
        Get-Item $OpenDirectoryDialog.SelectedPath
    } catch {
        Write-Warning 'Open Directory Dialog was closed or cancelled without selecting a Directory'
    }
}
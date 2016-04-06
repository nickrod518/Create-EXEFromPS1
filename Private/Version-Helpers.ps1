function Test-NETVersion {
    $NETPath = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client'

    # Get the .NET version, or leave null if less than 4
    try { $NETVersion = (Get-ItemProperty $NETPath -ErrorAction SilentlyContinue).Version } catch { }

    # Return true if .NET client is at least version 4.5
    if ($NETVersion -ge 4.5) {
        Write-Verbose 'Client .NET is version 4.5 or greater'
        $true 
    } else {
        Write-Verbose 'Client .NET is less than version 4.5'
        $false 
    }
}
    
function Test-PSVersion {
    # Return true if PowerShell is at least version 3
    if ($PSVersionTable.PSVersion.Major -ge 3) {
        Write-Verbose 'PowerShell is version 3 or greater'
        $true
    } else {
        Write-Verbose 'PowerShell is less than version 3'
        $false
    }
}
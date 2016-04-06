# Get public function definition files
$PublicFunctions  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )

# Get private function definition files
$PrivateFunctions = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
foreach ($Import in @($PublicFunctions + $PrivateFunctions)) {
    try {
        . $Import
    } catch {
        Write-Error -Message "Failed to import function $Import`: $_"
    }
}

# Only export the public functions
Export-ModuleMember -Function $PublicFunctions.Basename
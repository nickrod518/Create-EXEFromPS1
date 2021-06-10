function New-EXEFromPS1 {
    <#
    .SYNOPSIS
        Convert a PowerShell script into a deployable exe using iexpress.

    .DESCRIPTION
        Takes one PowerShell script and any number of supplementary files and create an exe using Windows's built in iexpress program.
        If you use one of the parameters that allows you to provide a folder, the script will zip that folder and add it as a supplemental file.
        Upon running the exe, the directory will first be unzipped and made available with the same structure, retaining relative path calls.
        Verbose output is available for most of the processes in this script if you call it using the -Verbose parameter.

    .PARAMETER PSScriptPath
        Path string to PowerShell script that you want to use as the first thing iexpress calls when the exe is run.
        If blank, you will be prompted with a file browse dialog where you can select a file.

    .PARAMETER SupplementalFilePaths
        Array of comma separated supplemental file paths that you want to include as resources.

    .PARAMETER SelectSupplementalFiles
        Use this flag to be prompted to select the supplementary files in an Open File Dialog.

    .PARAMETER SupplementalDirectoryPath
        Path to a directory that will be zipped and added as a supplementary file.
        When the exe is run, this script will first be unzipped and all files are available.

    .PARAMETER SelectSupplementalDirectory
        Use this flag to be prompted to select a directory in an Open File Dialog that will be zipped and added as a supplementary file.
        When the exe is run, this script will first be unzipped and all files are available.

    .PARAMETER KeepTempDir
        Keep the temp directory around after the exe is created. It is available at the root of C:.

    .PARAMETER x64
        Use the 64-bit iexpress path so that 64-bit PowerShell is consequently called.
		
	.PARAMETER SigningCertificate
        Sign all PowerShell scripts and subsequent executable with the defined certificate.
        Expected format of Cert:\CurrentUser\My\XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
		
    .OUTPUTS
        An exe file in the same directory as the ps1 script you specify

    .EXAMPLE
        .\Create-EXEFrom.ps1 -PSScriptPath .\test.ps1 -SupplementalFilePaths '..\test2.ps1', .\ps1toexe.ps1
        # Creates an exe using the provided PowerShell script and supplemental files.

    .EXAMPLE
        .\Create-EXEFrom.ps1 -SelectSupplementalFiles
        # Prompts the user to select the PowerShell script and supplemental files using an Open File Dialog.

    .EXAMPLE
        .\Create-EXEFrom.ps1 -SupplementalDirectoryPath 'C:\Temp\MyTestDir' -KeepTempDir
        # Zips MyTestDir and attaches it to the exe. When the exe is run, but before the user's script gets run,
        # it will be extracted to the same directory as the user's script. Temp directory used during exe creation
        # will be left intact for user inspection or debugging purposes.

    .NOTES
        Created by Nick Rodriguez

        Requires iexpress, which is included in most versions of Windows (https://en.wikipedia.org/wiki/IExpress).

    #>

    [CmdletBinding(DefaultParameterSetName = 'NoSupplementalFiles')]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            if ((Get-Item $_).Extension -ne '.ps1') {
                throw "[$_] is not a PowerShell script (ps1)."
            } else { $true }
        })]
        [string]
        $PSScriptPath,

        [Parameter(Mandatory=$false, ParameterSetName = 'SpecifyFiles')]
        [ValidateScript({
            foreach ($FilePath in $_) {
                if (-not (Get-Item $FilePath)) {
                    throw "[$FilePath] was not found."
                } else { $true }
            }
        })]
        [string[]]
        $SupplementalFilePaths,

        [Parameter(Mandatory=$false, ParameterSetName = 'SelectFiles')]
        [switch]
        $SelectSupplementalFiles,

        [Parameter(Mandatory=$false, ParameterSetName = 'SpecifyDirectory')]
        [ValidateScript({
            if (-not (Get-Item $_).PSIsContainer) {
                throw "[$_] is not a directory."
            } else { $true }
        })]
        [string]
        $SupplementalDirectoryPath,

        [Parameter(Mandatory=$false, ParameterSetName = 'SelectDirectory')]
        [switch]
        $SelectSupplementalDirectory,

        [Parameter(Mandatory=$false)]
        [switch]
        $KeepTempDir,

        [Parameter(Mandatory=$false)]
        [switch]
        $x64,
		
        [Parameter(Mandatory=$false)]
        [ValidateScript({
                  if (Test-Path $_) {
        		if ((Get-Item $_).HasPrivateKey -ne $true) {
        			throw "[$_] You do not have the corresponding private key to sign with this certificate."
        		} else { $true }
        	}
        	else {
        		throw "[$_] Cannot find the certificate."
        	}
              })]
              [string]
              $SigningCertificate
    )

    begin {
        # use 32-bit iexpress for wider compatibility unless user specifies otherwise
        if ($x64) {
            $IExpress = "C:\WINDOWS\System32\iexpress"
        } else {
            $IExpress = "C:\WINDOWS\SysWOW64\iexpress"
        }
    }

    process {
        # If no PowerShell script specified, prompt the user to select one
        if ($PSScriptPath) {
            $PSScriptName = (Get-Item $PSScriptPath).Name
        } else {
            try {
                $PSScriptPath = (Get-File).FullName
                $PSScriptName = $PSScriptPath.Split('\')[-1]
            } catch { exit }
        }
        Write-Verbose "PowerShell script selected: $PSScriptPath"

        # If signing certificate defined, generate objects to be used to sign subsequent scrips/executables.
		if ($SigningCertificate -ne $null) {
			Write-Verbose "Signing Certificate defined, will detect and sign any unsigned supplemental PowerShell scripts and final executable."
			$certificateobject = Get-Item $SigningCertificate
			$certificatethumb = $certificateobject.Thumbprint
			$SignFiles = $true
		} else {
			$SignFiles = $false
		}
		
		# Name of the extensionless target, replace spaces with underscores
        $Target = ($PSScriptName -replace '.ps1', '') -replace " ", '_'

        # Get the directory the script was found in
        $ScriptRoot = $PSScriptPath.Substring(0, $PSScriptPath.LastIndexOf('\'))

        # Create temp directory to store all files
        $Temp = New-Item "C:\$Target$(Get-Date -Format "HHmmss")" -ItemType Directory -Force
        Write-Verbose "Using temp directory $Temp"

        # Copy the PowerShell script to our temp directory
		if ($SignFiles) {
			Write-Verbose "Checking primary PowerShell scripts for signature."
			if (((Get-AuthenticodeSignature $PSScriptPath).Status) -ne 'Valid') {
				Write-Verbose "$($PSScriptPath) is not signed, signing with certificate thumb print: $($certificatethumb)"
				Set-AuthenticodeSignature -Certificate $certificateobject -FilePath $PSScriptPath | Out-Null
				if ((((Get-AuthenticodeSignature -FilePath $PSScriptPath).SignerCertificate).Thumbprint) -ne $certificatethumb) {
					Write-verbose "Signing $($PSScriptPath) failed"
				} else {
					Write-verbose "$($PSScriptPath) signing successful."
				}
			} else {
				Write-verbose "$($PSScriptPath) already has a valid signature."
			}
		}
        Copy-Item $PSScriptPath $Temp

        Write-Verbose "Using Parameter Set: $($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -eq 'NoSupplementalFiles') {
            Write-Verbose 'Not using supplemental files'

        } else {
            if ($PSCmdlet.ParameterSetName -eq 'SelectFiles') {
                # Prompt user to select supplemental files
                $SupplementalFilePaths = (Get-File -SupplementalFiles).FullName
                $SupplementalFiles = (Get-Item $SupplementalFilePaths).Name
                Write-Verbose "Supplemental files: `n$SupplementalFilePaths"
				if ($SignFiles) {
					# Determine if any of the specified files are PowerShell scripts and sign them if they are.
					Write-Verbose "Checking supplemental files for any PowerShell scripts and signing them."
					foreach ($SupplementalFile in $SupplementalFilePaths) {
						if ((Get-item $SupplementalFile).Extension -eq '.ps1') {
							$SupplementalScript = Get-item $SupplementalFile
							if (((Get-AuthenticodeSignature $SupplementalScript).Status) -ne 'Valid') {
								Write-Verbose "$($SupplementalScript) is not signed, signing with certificate thumb print: $($certificatethumb)"
								Set-AuthenticodeSignature -Certificate $certificateobject -FilePath $SupplementalScript | Out-Null
								if ((((Get-AuthenticodeSignature -FilePath $SupplementalScript).SignerCertificate).Thumbprint) -ne $certificatethumb) {
									Write-verbose "Signing $($SupplementalScript) failed"
								} else {
									Write-verbose "$($SupplementalScript) signing successful."
								}
							} else {
								Write-verbose "$($SupplementalScript) already has a valid signature."
							}
						}
					}
				}
				
                # Copy supplemental files to temp directory
                Copy-Item $SupplementalFilePaths $Temp

            } elseif ($PSCmdlet.ParameterSetName -eq 'SpecifyFiles') {
                # Get the paths of the files the user supplied
                $SupplementalFilePaths = (Get-Item $SupplementalFilePaths).FullName
                $SupplementalFiles = (Get-Item $SupplementalFilePaths).Name
                Write-Verbose "Supplemental files: `n$SupplementalFilePaths"
				if ($SignFiles) {
					# Determine if any of the specified files are PowerShell scripts and sign them if they are.
					Write-Verbose "Checking supplemental files for any PowerShell scripts and signing them."
					foreach ($SupplementalFile in $SupplementalFilePaths) {
						if ((Get-item $SupplementalFile).Extension -eq '.ps1') {
							$SupplementalScript = Get-item $SupplementalFile
							if (((Get-AuthenticodeSignature $SupplementalScript).Status) -ne 'Valid') {
								Write-Verbose "$($SupplementalScript) is not signed, signing with certificate thumb print: $($certificatethumb)"
								Set-AuthenticodeSignature -Certificate $certificateobject -FilePath $SupplementalScript | Out-Null
								if ((((Get-AuthenticodeSignature -FilePath $SupplementalScript).SignerCertificate).Thumbprint) -ne $certificatethumb) {
									Write-verbose "Signing $($SupplementalScript) failed"
								} else {
									Write-verbose "$($SupplementalScript) signing successful."
								}
							} else {
								Write-verbose "$($SupplementalScript) already has a valid signature."
							}
						}
					}
				}
				
                # Copy supplemental files to temp directory
                Copy-Item $SupplementalFilePaths $Temp

            } elseif ($PSCmdlet.ParameterSetName -eq 'SelectDirectory') {
                # Prompt user to select supplemental directory
                $SupplementalDirectoryPath = (Get-Directory).FullName
                Write-Verbose "Supplemental directory: $SupplementalDirectoryPath"
				if ($SignFiles) {
					# Find and sign any unsigned PowerShell scripts in the supplemental directory and sign them before zipping.
					foreach ($SupplementalScript in (Get-ChildItem "$($SupplementalDirectoryPath)\*.ps1" -recurse)) {
						if (((Get-AuthenticodeSignature $SupplementalScript).Status) -ne 'Valid') {
							Write-Verbose "$($SupplementalScript) is not signed, signing with certificate thumb print: $($certificatethumb)"
							Set-AuthenticodeSignature -Certificate $certificateobject -FilePath $SupplementalScript | Out-Null
							if ((((Get-AuthenticodeSignature -FilePath $SupplementalScript).SignerCertificate).Thumbprint) -ne $certificatethumb) {
								Write-verbose "Signing $($SupplementalScript) failed"
							} else {
								Write-verbose "$($SupplementalScript) signing successful."
							}
						} else {
							Write-verbose "$($SupplementalScript) already has a valid signature."
						}
					}
				}
                if ((Test-NETVersion) -and (Test-PSVersion)) {
                    $SupplementalFilePaths = Zip-File -SourceDirectoryPath $SupplementalDirectoryPath -DestinationDirectoryPath $Temp
                } else {
                    $SupplementalFilePaths = Zip-FileOld -SourceDirectoryPath $SupplementalDirectoryPath -DestinationDirectoryPath $Temp
                }
                $SupplementalFiles = $SupplementalFilePaths.Split('\')[-1]

                # Move supplemental zip to temp directory
                Move-Item $SupplementalFilePaths $Temp
            } elseif ($PSCmdlet.ParameterSetName -eq 'SpecifyDirectory') {
                # Get the path of the directory the user supplied
                $SupplementalDirectoryPath = $SupplementalDirectoryPath.TrimEnd('\')
                $SupplementalDirectoryPath = (Get-Item $SupplementalDirectoryPath).FullName
                Write-Verbose "Supplemental directory: $SupplementalDirectoryPath"
				if ($SignFiles) {
					# Find and sign any unsigned PowerShell scripts in the supplemental directory and sign them before zipping.
					foreach ($SupplementalScript in (Get-ChildItem "$($SupplementalDirectoryPath)\*.ps1" -recurse)) {
						if (((Get-AuthenticodeSignature $SupplementalScript).Status) -ne 'Valid') {
							Write-Verbose "$($SupplementalScript) is not signed, signing with certificate thumb print: $($certificatethumb)"
							Set-AuthenticodeSignature -Certificate $certificateobject -FilePath $SupplementalScript | Out-Null
							if ((((Get-AuthenticodeSignature -FilePath $SupplementalScript).SignerCertificate).Thumbprint) -ne $certificatethumb) {
								Write-verbose "Signing $($SupplementalScript) failed"
							} else {
								Write-verbose "$($SupplementalScript) signing successful."
							}
						} else {
							Write-verbose "$($SupplementalScript) already has a valid signature."
						}
					}
				}
                if ((Test-NETVersion) -and (Test-PSVersion)) {
                    $SupplementalFilePaths = Zip-File -SourceDirectoryPath $SupplementalDirectoryPath -DestinationDirectoryPath $Temp
                } else {
                    $SupplementalFilePaths = Zip-FileOld -SourceDirectoryPath $SupplementalDirectoryPath -DestinationDirectoryPath $Temp
                }
                $SupplementalFiles = $SupplementalFilePaths.Split('\')[-1]

                # Move supplemental zip to temp directory
                Move-Item $SupplementalFilePaths $Temp

            }
   
		}

        # If creating 64-bit exe, append to name to clarify
        if ($x64) {
            $EXE = "$ScriptRoot\$Target (x64).exe"
        } else {
            $EXE = "$ScriptRoot\$Target.exe"
        }
		
		# Determine if the EXE target already exists, and if it does prompt the user on how to continue.
		if (Test-Path $EXE) {
			Write-Output "$($EXE) already exists, would you like to replace it?"
			$ClearExisting = Read-Host "[y]/n"
			if (($ClearExisting.ToUpper()) -eq 'N') {
				Write-Host "Please re-run after you have cleaned up the destination directory." -ForegroundColor Red
				Start-sleep -seconds 30
				Remove-Item $Temp -Recurse -Force 
				break
			} else {
				Remove-item $EXE -Force | Out-Null
			}
		}
		
        Write-Verbose "Target EXE: $EXE"

        # create the sed file used by iexpress
        $SED = "$Temp\$Target.sed"
        New-Item $SED -ItemType File -Force | Out-Null

        # populate the sed with config info
        Add-Content $SED "[Version]"
        Add-Content $SED "Class=IEXPRESS"
        Add-Content $SED "sedVersion=3"
        Add-Content $SED "[Options]"
        Add-Content $SED "PackagePurpose=InstallApp"
        Add-Content $SED "ShowInstallProgramWindow=0"
        Add-Content $SED "HideExtractAnimation=1"
        Add-Content $SED "UseLongFileName=1"
        Add-Content $SED "InsideCompressed=0"
        Add-Content $SED "CAB_FixedSize=0"
        Add-Content $SED "CAB_ResvCodeSigning=0"
        Add-Content $SED "RebootMode=N"
        Add-Content $SED "TargetName=%TargetName%"
        Add-Content $SED "FriendlyName=%FriendlyName%"
        Add-Content $SED "AppLaunched=%AppLaunched%"
        Add-Content $SED "PostInstallCmd=%PostInstallCmd%"
        Add-Content $SED "SourceFiles=SourceFiles"
        Add-Content $SED "[Strings]"
        Add-Content $SED "TargetName=$EXE"
        Add-Content $SED "FriendlyName=$Target"

        # If we've zipped a file, we need to modify things
        if ('SelectDirectory', 'SpecifyDirectory' -contains $PSCmdlet.ParameterSetName) {
            $IndexOffset = 2
            # Create a script to unzip the user's zip
            $UnZipScript = New-Item "$Temp\UnZip.ps1" -ItemType File -Force
            Add-Content $UnZipScript $UnZipFunction
            Add-Content $UnZipScript "UnZip-File `'$SupplementalFiles`'"
            # If we're dealing with a zip file, we need to set the primary command to unzip the user's files
            Add-Content $SED "AppLaunched=cmd /c PowerShell -NoProfile -ExecutionPolicy Bypass -File `".\UnZip.ps1`""
			# After we've staged our files, run the user's script
            Add-Content $SED "PostInstallCmd=cmd /c for /f `"skip=1 tokens=1* delims=`" %i in (`'wmic process where `"name=`'$target.exe`'`" get ExecutablePath`') do PowerShell -NoProfile -ExecutionPolicy Bypass -Command Clear-Host; `".\$PSScriptName`" `"%i`" & exit"
            Add-Content $SED "FILE0=UnZip.ps1"
            Add-Content $SED "FILE1=$PSScriptName"
			
			# Add custom signing certificate to unzip.ps1 to allow for strict PowerShell execution policies.
			if ($SignFiles) {
				Write-Verbose "Signing unzip.ps1 with certificate thumb print: $($certificatethumb)."
				$unzipscript = Get-item "$($Temp)\Unzip.ps1"
				Set-AuthenticodeSignature -Certificate $certificateobject -FilePath $unzipscript | Out-Null
				# Ensure the script is signed successfully with the Thumbprint
				if ((((Get-AuthenticodeSignature -FilePath $unzipscript).SignerCertificate).Thumbprint) -ne $certificatethumb) {
					Write-verbose "Signing unzip.ps1 failed"
				} else {
					Write-verbose "unzip.ps1 signing successful."
				}
			}
			
        } else {
            $IndexOffset = 1
            Add-Content $SED "AppLaunched=cmd /c for /f `"skip=1 tokens=1* delims=`" %i in (`'wmic process where `"name=`'$target.exe`'`" get ExecutablePath`') do PowerShell -NoProfile -ExecutionPolicy Bypass -Command Clear-Host; `".\$PSScriptName`" `"%i`" & exit"
            Add-Content $SED "PostInstallCmd=<None>"
            Add-Content $SED "FILE0=$PSScriptName"
        }

        # Add the ps1 and supplemental files
        If ($SupplementalFiles) {
            $Index = $IndexOffset
            ForEach ($File in $SupplementalFiles) {
                $Index++
                Add-Content $SED "FILE$Index=$File"
            }
        }
        Add-Content $SED "[SourceFiles]"
        Add-Content $SED "SourceFiles0=$Temp"

        Add-Content $SED "[SourceFiles0]"
        Add-Content $SED "%FILE0%="
        if ('SelectDirectory', 'SpecifyDirectory' -contains $PSCmdlet.ParameterSetName) {
            # We've already specified this file, so leave it blank here
            Add-Content $SED "%FILE1%="
        }
        # Add the ps1 and supplemental files
        If ($SupplementalFiles) {
            $Index = $IndexOffset
            ForEach ($File in $SupplementalFiles) {
                $Index++
                Add-Content $SED "%FILE$Index%="
            }
        }

        Write-Verbose "SED file contents: `n$(Get-Content $SED | Out-String)"

        # Call IExpress to create exe from the sed we just created (run as admin)
        Start-Process $IExpress "/N $SED" -Wait -Verb RunAs

		# Sign the final executable with the declared certificate if defined.
		if ($SignFiles) {
			Write-Verbose "Signing $($EXE) with certificate thumb print: $($certificatethumb)."
			Set-AuthenticodeSignature -Certificate $certificateobject -FilePath $EXE | Out-Null
			# Ensure the script is signed successfully with the Thumbprint
			if ((((Get-AuthenticodeSignature -FilePath $EXE).SignerCertificate).Thumbprint) -ne $certificatethumb) {
				Write-verbose "Signing $($EXE) failed"
			} else {
				Write-verbose "$($EXE) signing successful."
			}
			
		}
		
        # Clean up unless user specified not to
        if (-not $KeepTempDir) { Remove-Item $Temp -Recurse -Force }
    }
}
# Check if window is in elevated mode
if ( -not (Test-PSFPowerShell -Elevated) ) {
    Stop-PSFFunction -Message "Module requires elevation. Please run the console in Administrator mode" -FunctionName 'Post Import'
}

if (-not (Test-PSDCDatabaseClone -WindowsVersion)) {
    Stop-PSFFunction -Message "Unsupported version of Windows" -FunctionName 'Post Import'
}

# Load Configurations
foreach ($file in (Get-ChildItem "$ModuleRoot\internal\configurations\*.ps1" -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $file.FullName
}

# Load Tab Expansion
foreach ($file in (Get-ChildItem "$ModuleRoot\internal\tepp\*.tepp.ps1" -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $file.FullName
}

# Load Tab Expansion Assignment
. Import-ModuleFile -Path "$ModuleRoot\internal\tepp\assignment.ps1"

# Load License
. Import-ModuleFile -Path "$ModuleRoot\internal\scripts\license.ps1"

# Check if the configuration has been set
if (-not (Test-PSDCDatabaseClone -SetupStatus)) {
    Write-PSFMessage -Message "The module is not yet configured. Please run Set-PSDCConfiguration to make the neccesary changes" -Level Warning
}

# Check the information mode
if ([bool](Get-PSFConfigValue -FullName psdatabaseclone.informationstore.mode) -eq 'File') {
    # Get the json file
    $jsonFolder = Get-PSFConfigValue -FullName psdatabaseclone.informationstore.path
    $jsonCred = Get-PSFConfigValue -FullName psdatabaseclone.informationstore.credential

    # Create a PS Drive
    if (-not [bool](Get-PSDrive -Name PSDCJSONFolder -Scope Global -ErrorAction SilentlyContinue)) {
        try {
            $null = New-PSDrive -Name PSDCJSONFolder -Root $jsonFolder -Credential $jsonCred -PSProvider FileSystem -Scope Global
            Start-Sleep -Seconds 1
        }
        catch {
            Stop-PSFFunction -Message "Couldn't create PS Drive" -Target $jsonFolder -ErrorRecord $_
        }
    }
}

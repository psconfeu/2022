function Get-UserData {
    param (
        [Parameter(Mandatory)]
        $Path
    )

    $users = Get-Content -Path $Path -Encoding UTF8 | ConvertFrom-Json

    $users | Foreach-Object {
        $user = $_

        $completeUser = [PSCustomObject]@{
            Name      = $_.name
            Age       = $_.age
            Languages = @{}
        }

        $user.languages | ForEach-Object { 
            $language = $_            
            $languageDescription = $null
            $languagePath = Join-Path $PSScriptRoot "$language.json"
            $languageDescription = (Get-Content -Path $languagePath | ConvertFrom-Json).description
            $completeUser.Languages[$language] = $languageDescription
        }

        $completeUser.Languages = [PSCustomObject]$completeUser.Languages

        Write-Log -Message "Processed user $($_.name)" -Level "Verbose"

        $completeUser
    }
}

$script:LogLevel = "Error"

function Set-LogLevel { 
    param(
        [Parameter(Mandatory)]
        $Level
    )
    $script:LogLevel = $Level
    $script:IsVerboseEnabled = (Get-LogLevelNumber $Level) -le (Get-LogLevelNumber "Verbose")
    # etc...
}

function Get-LogLevelNumber {
    param(
        [Parameter(Mandatory)]
        $Level
    )

    switch ($Level) {
        "error" { 1 }
        "info" { 2 }
        "verbose" { 3 }
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        $Message,
        $Level = "Info"
    )

    if ((Get-LogLevelNumber $Level) -le (Get-LogLevelNumber $script:LogLevel)) { 
        Write-Host $Message
    }
}

function Get-UserData {
    param (
        [Parameter(Mandatory)]
        $Path
    )

    # STEP2: Use -Raw to read data
    $users = Get-Content -Path $Path -Encoding UTF8 -Raw | ConvertFrom-Json
    # $users = Get-Content -Path $Path -Encoding UTF8 | ConvertFrom-Json


    # STEP1: Cache the languages:
    $languages = [System.Collections.Generic.Dictionary[string, string]]::new() # (or @{}, but not New-Object)
    # STEP 4: Replace ForEach-Object with foreach loop (we see mysterious } on line 46, and this is the start of the scriptblock)
    foreach ($user in $users) {
    # $users | Foreach-Object {
    #    $user = $_

        $completeUser = [PSCustomObject]@{
            Name      = $_.name
            Age       = $_.age
            Languages = @{}
        }

        # STEP3: Replace ForEach-Object with foreach loop (just a guess)
        foreach ($language in $user.languages) {
        # $user.languages | ForEach-Object { 
        #     $language = $_

            $languageDescription = $null
            # STEP1: Cache the languages.
            if (-not ($languages.TryGetValue($language, [ref] $languageDescription))) {
                $languagePath = Join-Path $PSScriptRoot "$language.json"
                $languageDescription = (Get-Content -Path $languagePath -Raw | ConvertFrom-Json).description
                $languages[$language] = $languageDescription
            }
            
            $completeUser.Languages[$language] = $languageDescription
        }

        $completeUser.Languages = [PSCustomObject]$completeUser.Languages
        
        # STEP5: Avoid calling unnecessary functions
         # if ($script:IsVerboseEnabled) {
            Write-Log -Message "Processed user $($_.name)" -Level "Verbose"
        #  }

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

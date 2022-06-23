$helpText = & az account list --help

$AccountSetCommand = New-CrescendoCommand -Verb get -Noun AzCliAccount -OriginalName az
$AccountSetCommand.OriginalText = $helpText
$AccountSetCommand.OriginalCommandElements = @('account', 'list')

$rawParams = @()

$Mode = ''
Foreach ($helpLine in $($helptext -split '\v')) {
    switch -Regex ($helpLine) {
        '^Command' {
            $mode = 'description'
            break
        }
        '(^Arguments)|(^Global Arguments)' {
            $mode = 'params'
            break
        }
        '^$' {
            $mode = ''
            break
        }
        default {
            switch ($mode) {
                'description' {
                    if ($helpLine -match ': *(.+)') {
                        $AccountSetCommand.Description = $Matches[1]
                    }
                    break
                }
                'params' {
                    if ($helpLine -match '--(?<pname>[-\w]+)[^\[]+(\[(?<required>Required)\])?\s+: *(?<phelp>.*)') {
                        if ($matches['pname'] -match '(help)|(verbose)|(debug)') {
                        } else {
                            $rawParams += @{
                                name     = $matches['pname']
                                required = -not [string]::IsNullOrEmpty($matches['required'])
                                help     = $matches['phelp']
                            }
                        }
                    } elseif ($helpLine -match ' +(?<exthelp>[^-].+)') {
                        $rawParams[-1].help = $rawParams[-1].help + $matches['exthelp']
                    }
                    break
                }
                default {

                }
            }
        }
    }
}

foreach ($rawParam in $rawparams) {
    $paramObject = New-ParameterInfo -Name $rawParam.Name.replace('-', '') -OriginalName "--$($rawParam.Name)"

    $paramObject.Description = $rawParam.help
    $paramObject.Mandatory = $rawParam.required
    $paramObject.ParameterType = 'string'

    $AccountSetCommand.Parameters += $paramObject
}

$outhandler = New-OutputHandler
$outhandler.ParameterSetName = 'Default'
$outhandler.Handler = '$args[0] | out-string | ConvertFrom-Json'
$outhandler.HandlerType = 'Inline'

$AccountSetCommand.OutputHandlers = @($outhandler)

[ordered]@{
    '$schema'  = 'https://aka.ms/PowerShell/Crescendo/Schemas/2021-11'
    'Commands' = @($AccountSetCommand)
} | ConvertTo-Json -Depth 5 | Set-Content $PSScriptRoot/bin/azcli.json -Force

Export-CrescendoModule -ConfigurationFile $PSScriptRoot/bin/azcli.json -ModuleName azcli -Force

function ParseTerraformApply {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        $input
    )

    begin {
        $outputs = @()
    }

    process {

        $objects = $input | ConvertFrom-Json

        $message = $objects | Select-Object -ExpandProperty '@message'

        $message -replace 'subscriptions/[a-z0-9-]+/', 'subscriptions/NotGonnaShowYou/' | Write-Host

        $outputs += $objects
    }

    end{
        $outputs
    }
}

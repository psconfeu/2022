BeforeAll {
    try {
        $here = Split-Path $MyInvocation.MyCommand.Path
        $sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
        $o = "$here\$sut"
    }
    catch {
        Write-Host -ForegroundColor Red ERROR: $_
    }

    $o = $PSCommandPath.Replace(".Tests.", ".")
    Write-Host -ForegroundColor Yellow $o

    $o = "$PSScriptRoot\demo2.ps1"
    Write-Host -ForegroundColor Yellow $o
}

Describe "d1" { 
    It "i1" { }
}
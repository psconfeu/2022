function Get-Avocado {
    Get-EmojiInternal -Emoji avocado
}

function Get-Unicorn {
    Get-EmojiInternal -Emoji unicorn
}

Export-ModuleMember -Function Get-Avocado, Get-Unicorn













































function  Get-EmojiInternal ($Emoji) {
    $ProgressPreference = 'SilentlyContinue'

    $uri = "https://emojipedia.org/$($Emoji.ToLowerInvariant())/"
    $r = Invoke-WebRequest -Method GET -Uri $uri -UseBasicParsing
    if (200 -ne $r.StatusCode) { 
        throw "Error"
    }

    $match = $r.Content.ToString() -split "`n" | Select-String '<h1><span\s+class="emoji">(.*)</span>'
    $emoji = $match.Matches.Groups[-1].Value
    $emoji * 50
}

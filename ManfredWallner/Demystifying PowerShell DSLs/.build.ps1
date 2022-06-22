
Get-ChildItem (Join-Path $PSScriptRoot "../ib.tasks.*.ps1") | ForEach-Object {
    . $_.FullName
}

# Synposis: use 'marp' to generate .pdf and .html files from the markdown presentation
Task Build GetMarp, {
    $filename = "demystifying_powershell_dsls"
    & $script:_the_marp "${filename}.md" -o "${filename}.pdf" --allow-local-files --html
    & $script:_the_marp "${filename}.md" -o "${filename}.html" --html
}

# Synposis: the default task: build
Task . Build

# ReadMe

This is a simple robocopy wrapper using PowerShell Crescendo. It only supports a couple of things. Namely copying files (or folders) and showing a progress bar (or not if so desired).

## Build

This needs to be built (or at least it should be). This is done using the
"Microsoft.PowerShell.Crescendo" Module. The "handler.ps1" needs to be dot-sourced, afterwards "Export-CrescendoModule" may be called to generate the actual module.

```powershell
. ./handler.ps1
Export-CrescendoModule -ModuleName PSRoboCopy -ConfigurationFile <Full Path>/robocopy.crescendo.config.json -Verbose
```

## Usage

To use the module robocopy needs to be in the "$env:PATH" variable (default on Windows). Then it can be used using "Copy-RobocopyFile".

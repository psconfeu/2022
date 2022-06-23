#region Dotfiles

<#
Dotfiles are used to customize your system. The "dotfiles" name is derived
from the configuration files in Unix-like systems that start with a dot
(e.g. .bash_profile and .gitconfig). For normal users, this indicates these
are not regular documents, and by default are hidden in directory listings.
For power users, however, they are a core tool belt.
#>

Start-Process 'https://dotfiles.github.io'

# Many applications store their configuration files in a ".config" file.
Get-ChildItem ~ -Force -Filter .* | Format-Table name

# PowerShell does too, for example for the CurrentUser-profiles
$profile | Format-List -Force

# And for the current user`s modules
$env:PSModulePath -split ':'

Start-Process 'https://code.visualstudio.com/docs/remote/containers#_personalizing-with-dotfile-repositories'

# Gotcha - executable bit must be set on scripts to be run
chmod 444 ./install.sh

<# Errors might happen during bootstrapping:
2022-06-18 20:08:07.984Z: New-Item: /workspaces/.codespaces/.persistedshare/dotfiles/install.ps1:5
2022-06-18 20:08:07.999Z: Line |
2022-06-18 20:08:08.013Z:    5 |      New-Item -Path (Join-Path '~/.config' $_.Name) -ItemType Symbolic …
2022-06-18 20:08:08.028Z:      |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2022-06-18 20:08:08.042Z:      | No such file or directory
#>

# Hence, it is useful to log actions and errors to a log file
~\dotfiles.log

# Example dotfiles
Start-Process https://github.com/janegilring/dotfiles

# Tip: Look into using Stow for managing dotfiles
# https://www.youtube.com/watch?v=FHuwzbpTTo0

#endregion

#region Contoso management

code "~/git/2022psconfeu/JanEgilRing/VSCodeDevContainers/contoso-management"

#endregion

#region Git credentials & SSH keys

Start-Process 'https://code.visualstudio.com/docs/remote/containers#_sharing-git-credentials-with-your-container'

<#

    If you do not have your user name or email address set up locally, you
    may be prompted to do so. You can do this on your local machine by
    running the following commands:

    git config --global user.name "Your Name"
    git config --global user.email "your.email@address"

    The extension will automatically copy your local .gitconfig file into
    the container on startup so you should not need to do this in the container itself.

#>


<#
You can add your local SSH keys to the agent if it is running by using the ssh-add command. For example, run this from a terminal or PowerShell:

ssh-add $HOME/.ssh/github_rsa

#>

# Windows
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent

# Linux

<#
Then add these lines to your ~/.bash_profile or ~/.zprofile (for Zsh) so it starts on login:

if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent`
fi
#>


#endregion


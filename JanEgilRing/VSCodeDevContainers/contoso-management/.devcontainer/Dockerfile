FROM mcr.microsoft.com/dotnet/runtime:6.0

RUN apt-get update && apt-get -y upgrade

RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    gnupg \
	curl \
    libgdiplus \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Prerequisite for .NET Interactive Notebooks: https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.dotnet-interactive-vscode
# https://docs.microsoft.com/en-gb/dotnet/core/install/linux-ubuntu#2004-

# Download the powershell '.tar.gz' archive
RUN curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.2.4/powershell-7.2.4-linux-x64.tar.gz

# Create the target folder where powershell will be placed
RUN mkdir -p /opt/microsoft/powershell/7

# Expand powershell to the target folder
RUN tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7

# Set execute permissions
RUN chmod +x /opt/microsoft/powershell/7/pwsh

# Create the symbolic link that points to pwsh
RUN ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

RUN useradd --create-home vscode

RUN wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v8.5.2/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
RUN chmod +x /usr/local/bin/oh-my-posh

RUN apt-get update;apt-get install openssh-client -y

# ImportExcel prerequsites
RUN apt-get install -y --no-install-recommends libgdiplus libc6-dev

# Switch to non-root user:
WORKDIR /home/vscode
USER vscode

# Not needed when using dotfiles
# SHELL ["pwsh","-NoProfile", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
# RUN mkdir /home/vscode/.config;mkdir /home/vscode/.config/powershell
# RUN Set-Content -Path /home/vscode/.config/powershell/Microsoft.VSCode_profile.ps1 -Value ". /workspaces/contoso/.devcontainer/powershell/profile.ps1"
# RUN Install-Module -Name PSReadLine -Force -AllowPreRelease
# RUN Install-Module PSDepend -Force
# RUN Invoke-PSDepend /workspace/powershell/requirements.psd1 -Force
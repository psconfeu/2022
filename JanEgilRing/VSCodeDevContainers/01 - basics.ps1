<#

Prerequisites:
- A computer running Linux, MacOS or Windows
- VS Code
- Docker

Docker - The fastest way to containerize applications on your desktop

https://www.docker.com/docker-windows
https://desktop.docker.com/mac/stable/Docker.dmg
https://hub.docker.com/search?q=&type=edition&offering=community&operating_system=linux

#>

# Public Docker Hub
Start-Process https://hub.docker.com

# Run a container
# This example will run the latest version of the Azure PowerShell image
docker run --rm -it mcr.microsoft.com/azure-cli:latest
# -it       run interactive
# --rm      automatically remove container


docker pull mcr.microsoft.com/powershell

<#
  Alpine Linux is a Linux distribution built around musl libc and BusyBox. The image is only 5 MB in size and has access
  to a package repository that is much more complete than other BusyBox based images.
  This makes Alpine Linux a great image base for utilities and even production applications.
#>

docker pull mcr.microsoft.com/powershell:preview-7.3-alpine-3.15

docker image list

docker run --rm -it mcr.microsoft.com/powershell:preview-7.3-alpine-3.15

<#
 CBL-Mariner is an internal Linux distribution for Microsoft’s cloud infrastructure and edge products
 and services. CBL-Mariner is designed to provide a consistent platform for these devices and
 services and will enhance Microsoft’s ability to stay current on Linux updates.

 https://github.com/microsoft/CBL-Mariner

#>

docker run --rm -it mcr.microsoft.com/powershell:lts-7.2-mariner-2.0

Start-Process https://hub.docker.com/_/microsoft-azure-powershell

# About 100-200 MB of the size is the PowerShell binaries (varies between versions)
docker image ls | Select-String powershell

# Inspect history for each layer
docker history mcr.microsoft.com/powershell:preview-7.3-alpine-3.15
docker history mcr.microsoft.com/powershell:lts-7.2-mariner-2.0

<# Key points:
 - Containers in general are small and light weight
 - Provides isolation
 #>

# What about data? Containers are ephemeral and don't have a persistent storage

# Map local folder to container
docker run --rm -it -v "c:\git:/home/jan/git" mcr.microsoft.com/powershell

<#
For use in applications, for example on Azure Kubernetes Service, CSI drivers makes it
possible to mount Azure Disks (Managed Disks) and Azure Files (SMB shares) to containers

https://docs.microsoft.com/en-us/azure/aks/csi-storage-drivers
#>

#region Remote containers in VS Code

# Install extension and read documentation
Start-Process https://code.visualstudio.com/docs/remote/containers

# Windows
mkdir C:\temp\demo
code C:\temp\demo

# Linux/MacOS
mkdir /tmp/demo
code /tmp/demo

# Command pallette->Remote Containers->Add Development Container Configuration Files

# Clean-up
Remove-Item C:\temp\somerepo -Recurse -Force
Remove-Item /tmp/demo -Force -Recurse

#region Azure Cloud Shell image

Start-Process https://github.com/Azure/CloudShell

docker pull mcr.microsoft.com/azure-cloudshell:latest

docker run -it mcr.microsoft.com/azure-cloudshell pwsh

# Add to dev-container Dockerfile: FROM mcr.microsoft.com/azure-cloudshell:latest

# After rebuilding and restarting the container

# Ansible, git, chef and many others pre-installed
Get-Command -CommandType Application
Get-Command ansible, az, bicep, chef, kubectl, pwsh, terraform

apt list --installed


# Trade-off: Container image size of Azure CLoud Shell is rather huge: 9.3 GB
Start-Process https://github.com/Azure/CloudShell/issues/90

# For example, azure-functions-core-tools and chef-workstation alone are over 1.2 GB.


#endregion
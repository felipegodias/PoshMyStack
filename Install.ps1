#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted

Write-Host "Instaling OhMyPosh..."
winget install JanDeDobbeleer.OhMyPosh --accept-package-agreements --accept-source-agreements

Write-Host "Instaling NuGet..."
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser

Write-Host "Instaling Posh Git..."
Install-Module -Name posh-git -AllowClobber -Scope CurrentUser -Force

Write-Host "Instaling Get-ChildItemColor..."
Install-Module -Name Get-ChildItemColor -AllowClobber -Scope CurrentUser -Force

$CurrentLocation = Get-Location
$CurrentLocation = $CurrentLocation.path

New-Item -Path $profile -ItemType File -Force
Add-Content -Path $profile -Value "Import-Module $CurrentLocation"
Add-Content -Path $profile -Value "Invoke-Main $CurrentLocation/dummy.json"
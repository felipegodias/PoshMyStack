$VS_WHERE = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
$POSH_THEME = ".mytheme.omp.json"

function Set-ListFilesAliases {
    Import-Module Get-ChildItemColor -Global
        
    Set-Alias -Name l -Value Get-ChildItem -Option AllScope -Scope Global
    Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope -Scope Global
}

function Set-NavigableMenu {
    # Shows navigable menu of all options when hitting Tab
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

    # Autocompletion for arrow keys
    Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
}

function Start-Cmd($cmd, $arguments) {
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $cmd
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $arguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    return $p.StandardOutput.ReadToEnd()
}

function Enter-DevShell {
    $VsWhereExists = Test-Path -Path $VS_WHERE -PathType Leaf
    if (-NOT $VsWhereExists) {
        return
    }

    $vsInstanceId = Start-Cmd $VS_WHERE "-latest -property instanceId"
    $vsInstallPath = Start-Cmd $VS_WHERE "-latest -property installationPath"

    $vsInstanceId = $vsInstanceId -replace "\r\n", ""
    $vsInstallPath = $vsInstallPath -replace "\r\n", ""
    
    Import-Module "$vsInstallPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Enter-VsDevShell -VsInstanceId $vsInstanceId -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -no_logo'
}

function Set-PersonalAliases {
    Set-Alias -Name i -Value Invoke-Pipeline -Scope Global
    Set-Alias -Name open -Value Invoke-Open -Scope Global
}

function Invoke-Open([string] $Path) {
    if ($Path -eq "") {
        explorer .
    }
    else {
        Invoke-Item $Path
    }
}
Export-ModuleMember Invoke-Open

function Set-LocationOrThrow {
    param(
        $Path
    ) 

    $PathExists = Test-Path -Path $Path
    if (-NOT $PathExists) {
        throw "Cannot find path '$Path' because it does not exist."
    }

    $CurrentLocation = Set-Location -PassThru $Path
    if (-NOT $CurrentLocation) {
        throw
    }
}

function Invoke-PipelineStep {
    param(
        $PipelineStep
    )

    $CurrentWorkingDirectory = Get-Location
    $IsChangingWorkingDiretory = $PipelineStep.Contains("working_directory")
    try {
        if ($IsChangingWorkingDiretory) {
            Set-LocationOrThrow $PipelineStep.working_directory
        }

        Invoke-Expression $PipelineStep.command
        $ExpressionExitCode = $LASTEXITCODE
        if ($ExpressionExitCode -NE 0) {
            throw "Pipeline step failed with exit code '$ExpressionExitCode'!"
        }
    }
    finally {
        if ($IsChangingWorkingDiretory) {
            Set-Location $CurrentWorkingDirectory
        }
    }
}

function Invoke-Pipeline {
    param(
        $PipelineName
    )

    $ProfileContent = Get-Content $Global:InProfile
    $SelectedProfile = $ProfileContent | ConvertFrom-Yaml
    $Pipelines = $SelectedProfile.pipelines

    $PipelineExists = $null -NE $PipelineName -AND $Pipelines.Contains($PipelineName)
    if (-NOT $PipelineExists) {
        Write-Host "The Pipeline '$PipelineName' does not exists in the profile! Do you mean one of these?"

        $Table = @()
        foreach ($PipelineName in $Pipelines.Keys | Sort-Object) {
            $Row = "" | Select-Object Pipeline, Description
            $Row.Pipeline = $PipelineName
            $Row.Description = $Pipelines.$PipelineName.description
            $Table += $Row
        }
        $Table
        return
    }

    $CurrentWorkingDirectory = Get-Location
    $IsChangingWorkingDiretory = $Pipelines.$PipelineName.Contains("working_directory")
    try {
        if ($IsChangingWorkingDiretory) {
            Set-LocationOrThrow $Pipelines.$PipelineName.working_directory
        }
    
        foreach ($PipelineStep in  $Pipelines.$PipelineName.steps) {
            Invoke-PipelineStep $PipelineStep
        }
    }
    finally {
        if ($IsChangingWorkingDiretory) {
            Set-Location $CurrentWorkingDirectory
        }
    }
}
Export-ModuleMember Invoke-Pipeline

function Invoke-Main {
    param(
        $InProfile
    )

    $module = Get-Module PowerShellProfile
    $ModuleDir = $Module.ModuleBase

    oh-my-posh prompt init pwsh --config "$moduleDir\$POSH_THEME" | Invoke-Expression

    Set-ListFilesAliases
    
    Set-NavigableMenu

    Enter-DevShell

    Set-PersonalAliases

    Set-Alias -Name open -Value Invoke-Open

    $Global:InProfile = $InProfile

    Import-Module posh-git -Global
}
Export-ModuleMember Invoke-Main
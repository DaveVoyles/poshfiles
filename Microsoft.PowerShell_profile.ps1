$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

#install choco if not present
if (-not (Get-Command choco -ErrorAction Ignore)){
    $InstallDir='C:\ProgramData\chocoportable'
    $env:ChocolateyInstall="$InstallDir"
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
#Install/Upgrade git using choco
if (-not (Get-Command git -ErrorAction Ignore)) {
    Write-Host "Attention GIT not installed"
    Write-Host "Run 'choco install git'"
}

 # enable ssh-agent from posh-git
if ((Test-Path "$env:ProgramFiles\Git\usr\bin") -and ($env:path.IndexOf("$($env:ProgramFiles)\Git\usr\bin", [StringComparison]::CurrentCultureIgnoreCase) -lt 0)) {
    $env:path="$env:path;$env:ProgramFiles\Git\usr\bin"
}

#Az - Manage Azure Resources
if (-not (Get-Module -ListAvailable -Name Az))
{
  Install-Module -Name Az -Force -AllowClobber
}

if ((Test-Path "$root\Modules\psake") -and ($env:path.IndexOf("$($root)\Modules\psake", [StringComparison]::CurrentCultureIgnoreCase) -lt 0)) {
    $env:path="$env:path;$root\Modules\psake"
}
Import-Module "$root\modules\posh-git\src\posh-git.psd1"
Start-SshAgent -Quiet 2>&1 | Out-Null                        #Some process that start a powershell process threats this output as an error.
Import-Module "$root\modules\oh-my-posh\oh-my-posh.psm1" #don't import the psd1, it has an incorrect string in the version field
Set-Theme Mesh
if (Get-Command colortool -ErrorAction Ignore) { colortool --quiet campbell }
Import-Module z
Import-Module $root\Modules\psake\src\psake.psd1
Import-Module $root\Modules\posh-docker\posh-docker\posh-docker.psd1

Set-PSReadLineOption -Colors @{
    "Error" = [ConsoleColor]::DarkRed
    "Keyword" = [ConsoleColor]::Cyan
    "Command" = [ConsoleColor]::Yellow
    "String" = [ConsoleColor]::Magenta
}

. "$root/PsakeTabExpansion.ps1"
. "$root/CreateAliases.ps1"

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    Import-Module "$ChocolateyProfile"
}

#install vscode
if (-not (Get-Command code -ErrorAction Ignore)) {
    Write-Host "Attention GIT not installed"
    Write-Host "Run 'choco install vscode'"
}else{
    git config --global core.editor "code --wait"
}

if (Get-Command vim -ErrorAction Ignore) {
    Set-PSReadlineOption -EditMode Vi
    Set-PSReadlineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
    Set-PSReadlineKeyHandler -Key Ctrl+Shift+r -Function ForwardSearchHistory
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadlineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
}

function time() {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Invoke-Expression $($args -join ' ')
    $sw.Stop()
    $sw.elapsed
} # call like: `time ls` or `time git log`

function color ($lexer='javascript') {
    Begin { $t = "" }
    Process { $t = "$t
    $_" }
    End { $t | pygmentize.exe -l $lexer -O style=vs -f console16m; }
} # call like: `docker inspect foo | color`

if (Get-Command dotnet -ErrorAction Ignore) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

if (!(Test-Path "$root\Modules\VSSetup")) {
    Install-Module VSSetup -Scope CurrentUser -Confirm -SkipPublisherCheck
}

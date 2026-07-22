# dotfiles
Personal cross-platform ( with primary focus on _Windows_ ) configuration using `chezmoi`.

## WIP Fixes
1. Handle `dotnet` pathing and location on _*nix_. Still relying on `shellenv pwsh` being run manually before a `chezmoi apply`.
1. sometimes `$env:PSModulePath` in `powershell` doesn't reflect the `.\OneDrive\Documents` folder and only has `.\Documents`.
1. add positional parameter expansion to alias, parameter keyhandler expansion. might be able to derive it.
1. work on `py` handling. No longer needed or functional for oh-my-posh. Need to disable the App Execution Aliases in Windows. Appears one would need to clear entry from `HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths` and the file at `$env:LOCALAPPDATA\Microsoft\WindowsApps`. https://superuser.com/a/1746939 Use `py -m pip list` instead of `pip`
1. check for missing key handlers when moving to vi mode like copy and paste and ctrl backspace.
1. handle `@''@` and `@""@` in psrl
1. Handle `nvim` folders on for _*nix_
1. Handle missing `scoop` and avoid the publish script
1. Handle dependencies on `vim.pack` like `cl.exe`. Need the below
   ```powershell
    sudo choco install visualstudio2026buildtools -y
    sudo choco install visualstudio2026-workload-vctools -y
    ```
1. Handle other binaries like `make`, `unzip`, `gzip`, `mingw`, `tree-sitter`, `luarocks` ( main lua package has old verison ). Can use `scoop` to install these.
1. add `gsudo` change token to non-admin to install `scoop` in certain scenarios.
   ```powershell
    gsudo --integrity Medium 'pwsh -c { irm get.scoop.sh | iex}'
   ```
1. Explore `nvim` mini status line with `mssql.nvim`. add it to the left side instead maybe.
1. explore `vim.pack` plugin which makes jumping easier with `f` an `t`. something easy jump or the like that highlights the second or third `t` or the like to go further than word, etc.
1. figure out why `at` and `top` won't work inside `s { $_.commandline | slexe | at 1}` context initiall until `at` is run once outside. Might need to initialize the class somehow on module load before
1. handle none found on `scoop fsearch vimdiff`. Need to check output of `sfsu` as it must be piping something in a native fashion into the pipe.
1. alias psrl key handler doesn't work when using an alias like `badb` before the module is loaded. need to add `get-command` lookup or `ipmo` or maybe `if` with `gmo`.
1. `mssql.nvim`, handle results output opt. maybe make the bottom window have a different size depending on results size.
1. `mssql.nvim` has another op delegate for the handle for the messages. would need a `function()` to collect all the messages into one and then write it to a buffer.
1. maybe disable arrow keys to force keyboard changing. need better special characters
1. set up lsp for `pwsh` and `.cs`
1. handle carapace excludes better between unix and windows. `strings` is an example which breaks on windows.
1. add _powertoys_ keymap settings for cmd pal. local app data microsoft powertoys. there is a backup file in onedrive documents powertoys that is a zip archive too.
1. set up `.chezmoitemplates` for _*nix_ and _windows_
1. set up `.gitattributes` for the nvim lock json. probably need a template of the file and then in the actual file had a `chezmoi` directive for the line endings.
1. sync up my nvim configs across locals and remotes. some features are only on certain machines.
1. handle syncing up the chromium _vimium_ json config. is there a way to auto import it or sync it on the file system or does the import have to happen manually in the browser?
1. redo the `mini.statusline` to better present the _mssql.nvim_ data.
1. fix `nvim` `telescope` handling with scratch buffers and files that aren't save. we need to see the live active contents. 
1. set up `:te` with keybind
1. configure `:te` with `wezterm` plugins. there are two that were favorited
1. set up the osc where `cd` will change the working `nvim` dir. see that that integrates with the above plugins
1. get _c#_ going in _nvim_ with debugger and lsp and refactorings
1. get debugging with a binary module going with `powershell` and update the dap configurations like _vscode_
1. get formatting going with _powershell_ so maybe tabs to spaces, etc. kind of like _vscode_
1. get formatting going with _c#_
1. figure out snippets with _powershell_
1. figure out snippets with _c#_
1. figure out the expand aliases feature in _powershell_ . can `:Powershell` be used.

## Road to Full Auto
1. Core hard dep to get to prompt.
    ```powershell
    Set-ExecutionPolicy RemoteSigned CurrentUser -Force; Invoke-RestMethod get.scoop.sh | Invoke-Expression; scoop install git; scoop update; scoop install chezmoi pwsh oh-my-posh dotnet-sdk; pwsh -Command { Install-PSResource ctypes, ezout -TrustRepository -Quiet -Confirm:$false }; chezmoi init mattcargile --apply
    ```
1. Consider setting up local admin user.
   ```powershell
   New-LocalUser -AccountNeverExpires -Name matt -PasswordNeverExpires -Password (credential na).password
   Add-LocalGroupMember -Group Administrators -Member matt
   ```
1. Dedupe onedrive folders and registry
    ```powershell
    ls 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace' | ? { $_ | gp -Name '(default)' | ? '(default)' -eq 'OneDrive'} | rm -conf
    rm $env:USERPROFILE\OneDrive -conf -for
    ```
1. Set up the secret management module
    ```powershell
    register-secretVault -Name dp -ModuleName SecretManagement.DpapiNG
    register-keepassSecretVault -Path keys.kdbx -UseMasterPassword -ShowFullTitle
    register-KeepassSecretVault -Path $env:onedrive\Main\keepass.kdbx -UseMasterPassword -ShowFullTitle
    Set-Secret du -Secret (Get-Credential WORKDOMAIN\workUser) -v dp
    set-secret dund -Secret (Get-Credential workUser) -v dp
    set-secret da -Secret (credential WORKDOMAIN\workAdminUser) -v dp
    set-secret dbakey -Secret (read-host -AsSecureString) -v dp
    set-secret alt -Secret (credential first.name@publicEmailDomain.org) -v dp
    set-secret dubr -Secret ([pscredential]::new( 'workUser@publicEmailDomain.org', (gsc dund dp).password ) ) -v dp
    ```
1. `Set-ExecutionPolicy RemoteSigned CurrentUser -Confirm:$false -Force`
1. Install scoop with the below.
    ```powershell
    irm get.scoop.sh | iex
    ```
1. `scoop` requires a `scoop install git` first for buckets and such
    * Should run `scoop update` after
1. Hard requirements in bootstrapper. (NOTE: Should `pwsh` be `choco` or `scoop`?)
    ```powershell
    scoop install pwsh chezmoi dotnet-sdk oh-my-posh
    ```
1. Need to figure the flow to go from `powershell` to `pwsh`.
1. `isres ctypes,EZOut`
1. `chezmoi init mattcargile --apply`
1. Need admin script for `vcredist2022` for `delta` and `sfsu`
1. Then run `scoop install lessmsi` prior to `scoop import`.
1. Import the scoop json excluding above.
1. Set the trust on the repos and maybe install `Microsoft.PowerShell.PSResourceGet` first in `powershell`.
   ```powershell
   sudo install-module microsoft.powershell.psresourceget -Scope AllUsers
   Set-PSResourceRepository -Name PSGallery -Trusted
   sudo Set-PSResourceRepository -Name PSGallery -Trusted
   ```
1. Change Downloads folder location with `SHSetKnownFolderPath`
    * https://ss64.com/ps/syntax-knownfolders.html
1. Install `vmrc`. `choco` is busted because _BroadCom_ took down the update site. Silent install pulled from `choco`.
    ```powershell
    isudo { .\VMware-VMRC-12.0.5-22744838.exe /s /v /qn EULAS_AGREED=1 AUTOSOFTWAREUPDATE=1 DATACOLLECTION=0 REBOOT=ReallySuppress }
    ```
1. Uninstall Windows older _OpenSSH_. Required before the `openssh` install.
    * Use below command
    ```powershell
    sudo {Get-WindowsCapability -n *ssh*clie* -on | Remove-WindowsCapability -On}
    ```
1. Install chocolatey
   ```powershell
   sudo { irm community.chocolatey.org/install.ps1 | iex }
   ```
1. `choco` packages with special handling
    * `powershell-core` has extra parameters
        ```powershell
        sudo { C:\ProgramData\chocolatey\bin\choco.exe install powershell-core -y --ia='REGISTER_MANIFEST=1 ENABLE_PSREMOTING=1 DISABLE_TELEMETRY=1' }
        ```
    * `sql-server-management-studio` has `--all` parameters
    * `ssis-vs2022` needs _Visual Studio_ installed first
    * `openssh` has a bad latest version and special parameters
        ```powershell
        sudo { choco install openssh --pre --version=9.5.0-beta1 -y --params='"/SSHServerFeature /SSHAgentFeature /PathSpecsToProbeForShellEXEString:$env:programfiles\PowerShell\*\pwsh.exe"' }
        ```
    * `sysinternals` may need `--ignore-checksums` because the package installs from the same link
    * `vmrc` appears to be a deprecated package
    * `discord` and `discord.install` should be removed as they cause a butchered install
    * `logparser` has special parameters.
        ```powershell
        sudo {choco install logparser -y --ia='LPTARGETDIR=C:\ProgramData\chocolatey\lib\logparser\tools\'}
        ```
    * Install below manually
        ```xml
        <package id="sql-server-management-studio" />
        <package id="ssis-vs2022" />
        <package id="ssms-tools-pack" />
        <package id="logparser" />
        <package id="powershell-core" />
        <package id="openssh" />
        <package id="sysinternals" />
        <package id="PDFXchangeEditor" />
        ```
    * `PDFXChangeEditor` has annoying auto updater and a flag must be used to disable it. Use below to install. May need to pass this flag during updates too.
        ```powershell
        sudo choco install PDFXchangeEditor -y --params '"/NOUPDATER"'
        ```
1. Import the choco `xml` config.
   ```powershell
   sudo { choco install $env:OneDrive\Backup\choco_packages_auto.config -y }
   ```
1. Pin some `choco` apps with issues on new versions or upgrades failing because the resource is in use like fonts.
    ```powershell
    sudo choco pin add -n openssh --version='9.5.0-beta1'
    choco list -r nerd-font | % { $_ | split '\|' | top 1 } | % { sudo choco pin add --name="$_" }
    ```
1. Fix the duplicate OneDrive folder.
1. Enable more _*nix_-ey `sudo`-ing.
    ```powershell
    gsudo config CacheMode Auto
    ```
1. Install the modules
    ```powershell
    Import-PowerShellDataFile .\requirements\module.psd1 | % gete* | ? { $_.Value['PSEdition'] -eq 'Desktop' } | ? { $_.Value['Scope'] -eq 'AllUsers' }
    ```
1. Install the capabilities
    ```powershell
    Add-ForcedWindowsCapability (import-PowerShellDataFile .\requirements\capability.psd1 |% gete*).name
    ```
1. optional _hyper-v_ and _sandbox_. requires reboot. did one after the other with reboots inbetween. `gcim win32_optionalfeature` to see `Caption`. `get-windowsoptionalfeature` gets the actual feature name but the `Caption` displayed in the `OptionalFeatures.exe` UI is not shown.
    ```powershell
    sudo {Enable-WindowsOptionalFeature -FeatureName 'Microsoft-Hyper-V-All' -Online -NoRestart}
    sudo {Enable-WindowsOptionalFeature -FeatureName 'Containers-DisposableClientVM' -Online -NoRestart} # Sandbox
    ```
1. install, build, etc the `MonoLisa` font. previously used `wsl` instance and special repo and pulled files from the website from a zip

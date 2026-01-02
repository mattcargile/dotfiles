# dotfiles
Personal cross-platform configuration using chezmoi.

## Road to Full Auto
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
1. Install scoop with the below.
    ```powershell
    irm get.scoop.sh | iex
    ```
1. `scoop` requires a `scoop install git` first for buckets and such
    * Should run `scoop update` after
1. Add aliases back.
    ```powershell
    Import-CliXml $env:onedrive\backup\scoop_export_alias_cli.xml | % { scoop alias add $_.Name $_.Command $_.Summary }
    ```
1. Import the scoop json.
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
1. Add to `glyphs.ps1` in `Terminal-Icons`. [Issue](https://github.com/devblackops/Terminal-Icons/issues/155)
    ```powershell
    'nf-dev-microsoftsqlserver'                      = ''
    ```
1. Run `Set-MyTerminalIcons` to set the theme

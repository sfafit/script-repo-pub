## Elevates the Console
param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

'running with full privileges'

##Variables
$cred = get-credential sfaf.int\gvalentine

$Compname = Read-Host -Prompt "What is the Expected name of this Machine?"
$OUTest =  Read-Host -Prompt "Is this an HQ or STRUT Machine?"
if ($OUTest -eq "HQ"){
    $Off = 'OU=Computers,OU=SFAF-1035,DC=sfaf,DC=int'} 
    elseif ($OUTest -eq "STRUT") {
        $Off = 'OU=Computers,OU=SFAF-470,DC=sfaf,DC=int'}
$OUTest =  Read-Host -Prompt "What Floor is this machine on?"
if ($OUTest -eq '1'){
    $Floor = 'OU=1st Floor,' } 
    elseif ($OUTest -eq '2'){
        $Floor = 'OU=2nd Floor,' } 
        elseif ($OUTest -eq '3'){
            $Floor = 'OU=3rd Floor,' }
             elseif ($OUTest -eq '4'){
                 $Floor = 'OU=4th Floor,' } 

$OU = -join($Floor,$Off)

$DesktopPath = [Environment]::GetFolderPath("Desktop")



##Installs Chocolatey##
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

## Maps the share##
New-PSDrive -Name "X" -PSProvider FileSystem -Root "\\archive\SHARED\IT\INSTALL" -Credential $cred
set-location "X:\Scripts\Decommissioning\Decom Files"

##update Old Decoms List
$name = hostname
$4Serial = Get-WmiObject Win32_bios 
$date = get-date -Format "yyyy.MM.dd.HH.mm.ss"
$LineEntry =  -join ($date," RECOMMISSION - Serial = ",$4Serial.SerialNumber," / Name = ",$name)   
Out-File  -InputObject $LineEntry -FilePath '.\Image-Log.txt' -Append -Encoding ascii

#Moves Finalizing files
start-bitstransfer -source ".\Finalize-Commission.ps1" -Destination $DesktopPath


## Tests If the computer is Domain Joined ##            -Restart
$test = Test-ComputerSecureChannel
if ($test -eq $True) {Rename-Computer -DomainCredential $Cred -NewName $Compname -rest} Else {
Add-Computer -DomainName sfaf.int -DomainCredential $cred  -OUPath $OU
Rename-Computer -DomainCredential $Cred -NewName $Compname -rest }
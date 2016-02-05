#Dot source all functions in all ps1 files located in the module folder
Get-ChildItem -Path $PSScriptRoot\*.ps1 -OutVariable Ps1Files |
ForEach-Object {
    . $_.FullName
}

#Export all of the functions in the PS1 files located in the module folder
Export-ModuleMember -Function $Ps1Files.BaseName
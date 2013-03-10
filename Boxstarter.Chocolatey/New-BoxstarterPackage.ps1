function New-BoxstarterPackage {
<#
.SYNOPSIS
Creates a new Chocolatey package source directory intended for a Boxstarter Install

.DESCRIPTION
New-BoxstarterPackage creates a new Directory in your local 
Boxstarter repository located at $Boxstarter.LocalRepo. If no path is
provided, Boxstarter creates a minimal nuspec and 
ChocolateyInstall.ps1 file. If a path is provided, Boxstarter will 
copy the contents of the path to the new package directory. If the
path does not include a nuspec or ChocolateyInstall.ps1, Boxstarter
will create one. You can use Invoke-BoxstarterBuild to pack the 
repository directory to a Chocolatey nupkg.

.PARAMETER Name
The name of the package to create

.PARAMETER Description
Description of the package to be written to the nuspec

.PARAMETER Path
Optional path whose contents will be copied to the repository

.LINK
http://boxstarter.codeplex.com
about_boxstarter_chocolatey
about_boxstarter_variable_in_chocolatey
Invoke-BoxstarterBuild
#>
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$description,
        [string]$path
    )
    $pkgDir = Join-Path $Boxstarter.LocalRepo $Name
    MkDir $pkgDir | out-null
    Pushd $pkgDir
    if($path){
        Copy-Item "$path\*" . -recurse
    }
    $pkgFile = Join-Path $pkgDir "$name.nuspec"
    if(!(test-path $pkgFile)){
        ."$env:ChocolateyInstall\ChocolateyInstall\nuget" spec $Name -NonInteractive
        [xml]$xml = Get-Content $pkgFile
        $metadata = $xml.package.metadata
        $nodesToDelete = @()
        $nodesNamesToDelete = @("licenseUrl","projectUrl","iconUrl","requireLicenseAcceptance","releaseNotes", "copyright","dependencies")
        $metadata.ChildNodes | ? { $nodesNamesToDelete -contains $_.Name } | % { $nodesToDelete += $_ }
        $nodesToDelete | %{ $metadata.RemoveChild($_) } | out-null
        $metadata.Description=$Description
        $metadata.tags="Boxstarter"
        $xml.Save($pkgFile)
    }
    if(!(test-path "tools")){
        Mkdir "tools" | out-null
    }
    $installScript=@"
try {

    Write-ChocolateySuccess '$name'
} catch {
  Write-ChocolateyFailure '$name' `$(`$_.Exception.Message)
  throw
}
"@
    if(!(test-path "tools\ChocolateyInstall.ps1")){
        new-Item "tools\ChocolateyInstall.ps1" -type file -value $installScript| out-null
    }
    Popd
}
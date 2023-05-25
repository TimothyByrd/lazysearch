$Version = "3.6.8"
$Commit = 'a2013165c7299acb9bdf44b50b4d9890c29f2fb2'
$Commit = git rev-parse HEAD

$StagingFolder = "$PSScriptRoot/stage"
if (Test-Path -Path $StagingFolder) {
    "Removing existing $StagingFolder"
    Remove-Item -LiteralPath "$StagingFolder" -Force -Recurse
}
else
{
#    "$StagingFolder not found"
}

# New-Item -Path "$StagingFolder" -ItemType Directory

Copy-Item -Path "$PSScriptRoot/src" -Destination "$StagingFolder" -recurse -Force


Function ReplaceInserts([string]$path) {
    #"Replacing $path"
    $origText = [System.IO.File]::ReadAllText($path)
    $text = $origText
    #$text = $text -replace '@@VERSION@@', "$Version"
    #$text = $text -replace '@@COMMIT@@', "$Commit"
    $text = $text.replace('@@VERSION@@', "$Version")
    $text = $text.replace('@@COMMIT@@', "$Commit")

    if ($origText -ne $text) {
        [System.IO.File]::WriteAllText($path, $text)
        Write-Output "Updated $path"
    }
    else
    {
        Write-Output "$path already up to date"
    }
}

ReplaceInserts ([System.IO.Path]::Combine($StagingFolder, 'LazySearch2/install.xml'))
ReplaceInserts ([System.IO.Path]::Combine($StagingFolder, 'LazySearch2/Plugin.pm'))

$zip = "$PSScriptRoot/releases/LazySearch2-8-$Version.zip"
if (Test-Path -Path $zip) {
    Remove-Item -LiteralPath "$zip" -Force
}

Compress-Archive -Path "$StagingFolder\*" -DestinationPath $zip

$hash = (Get-FileHash -Path $zip -Algorithm 'SHA1').Hash

$xmlPath = "$PSScriptRoot/repo.xml"

$xml = [xml](Get-Content -Path $xmlPath)

$node = $xml.extensions.plugins.plugin |
    where {$_.name -eq 'LazySearch2'}
$node.version = $Version

$node.url = "https://github.com/TimothyByrd/lazysearch/raw/master/releases/LazySearch2-8-$Version.zip"
$node.sha = $hash

$xml.Save($xmlPath)

git add "releases/LazySearch2-8-$Version.zip" repo.xml



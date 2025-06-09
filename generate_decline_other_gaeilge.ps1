# Update WordInfo\decline_other.txt for Irish

$PSDefaultParameterValues["*:Encoding"] = "UTF8"

# Get the DLC folders (including Core)
$dlcs = Get-ChildItem -Directory | Where-Object { Test-Path -Path (Join-Path -Path $_.FullName -ChildPath "DefInjected") }

# Paths of the XML files in which the words should be searched
# and the regex pattern to match the elements
$items = [ordered]@{
    "DefInjected\FactionDef\*" = "\w+\.pawnsPlural"
    "DefInjected\RoyalTitleDef\*" = "\w+\.label"
    "DefInjected\PreceptDef\Precepts_Role.xml" = "\w+\.label"
    "DefInjected\PawnKindDef\*" = ".+\.label"
    "DefInjected\ThingDef\*" = "\w+\.label"
}

# New Header line for decline_other.txt for Irish
$header = @(
    "NOM"        # Nominative Singular (bare form)
    "1_GEN_SG"   # Genitive Singular
    "2_GEN_PL"   # Genitive Plural (optional, can be left blank)
    "3_NOM_DEF"  # Definite Nominative Singular (with article and mutation if needed)
)

# Usage description. Using comment flag "//" instead of "#" as RW doesn't support it.
$comments = "@
// Declension for special cases in Irish
// NOM: Nominative Singular (e.g., fear)
// 1_GEN_SG: Genitive Singular (e.g., fir)
// 2_GEN_PL: Genitive Plural (optional) (e.g., fear)
// 3_NOM_DEF: Definite Nominative Singular (with article) (e.g., an fear)
// --- 
"

# Enumerate DLC folders (including Core)
$tempFile = New-Item "$env:temp\$([GUID]::NewGuid()).txt"
foreach ($dlc in $dlcs) {
    Clear-Content -Path $tempFile
    Set-Location -Path "$PSScriptRoot\$dlc"
    $declineFile = "WordInfo\decline_other.txt"

    # Create a hash table of nominative words
    $HashTable = @{}
    $declineFileLines = @()
    if (Test-Path $declineFile) {
        $declineFileLines = Get-Content -Path $declineFile
        Remove-Item $declineFile
    }
    foreach ($line in ($declineFileLines | ConvertFrom-Csv -Delimiter ";" -Header $header)) {
        if ($line.NOM.Length -ge 2 -and $line.NOM.Substring(0, 2) -eq "//") { continue } # skip comments
        $fields = $line.PSObject.Properties.Value -join ";"
        $fields = $fields -replace "(?<=;);" # clean up empty fields
        $HashTable[$line.NOM] = $fields
    }

    # Search words in the XML files and add them to a temp file
    $items.GetEnumerator() | ForEach-Object {
        $paths = ($_.Key -split ',').Trim()
        $pattern = $_.Value
        $elements = @()
        $ps = @()
        foreach ($path in $paths) {
            if (!(Test-Path $path)) { continue } # skip non-existing paths
            $ps += $path
            $elements += Get-Content -Path $path -Filter "*.xml" | Select-String -Pattern "<($pattern)>(?<value>.*?)</\1>" -All
        }
        if ($elements.Count -eq 0) { return } # no elements, move on
        "// $($ps -join ', ') ($pattern)" >> $tempFile # add header in output
        # extract values
        $tempFileLines = @()
        foreach ($element in $elements) {
            $tempFileLines += $element.Matches[0].Groups["value"].Value
        }
        Add-Content -Path $tempFile -Value ($tempFileLines | Sort-Object)
    }

    # Merge the temp file with decline_other.txt
    $tempFileLines = Get-Content $tempFile
    if ($tempFileLines.Count -eq 0) { continue } # no new lines
    $declineFileLines = @($header -join ";")
    $declineFileLines += $comments
    foreach ($line in ($tempFileLines | Select-Object -Unique)) {
        if ($line.Substring(0, 2) -eq "//") {
            $declineFileLines += $line
        } elseif ($HashTable.ContainsKey($line)) {
            $declineFileLines += $HashTable[$line]
        } else {
            $declineFileLines += $line + ";" # blank fields, ready to fill later
        }
    }
    New-Item $declineFile -Force | Out-Null
    Set-Content -Path $declineFile -Value $declineFileLines
}
Set-Location -Path $PSScriptRoot
Remove-Item $tempFile
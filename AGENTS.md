# AGENTS.md

**Rule:** In each command, define → use.
Do not escape $.
Use generic 'path/to/file.ext'.

---

## READ (UTF-8 no BOM, line-numbered)

bash -lc 'powershell -NoLogo -Command "
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false);
Set-Location -LiteralPath (Convert-Path .);
function Read-Utf8NoBom { param([string]$Path,[int]$Skip=0,[int]$First=200)
  $enc=[Text.UTF8Encoding]::new($false)
  $text=[IO.File]::ReadAllText($Path,$enc)
  if($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF){ $text=$text.Substring(1) }
  $ls=$text -split "`r?`n"
  for($i=$Skip; $i -lt [Math]::Min($Skip+$First,$ls.Length); $i++){
    "{0:D4}: {1}" -f ($i+1), $ls[$i]
  }
}
Read-Utf8NoBom -Path "path/to/file.ext" -First 200 -Skip 0
"'

---

## WRITE (UTF-8 no BOM, atomic replace)

bash -lc 'powershell -NoLogo -Command "
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false);
Set-Location -LiteralPath (Convert-Path .);

function Write-Utf8NoBom { param([string]$Path,[string]$Content)
  $enc=[Text.UTF8Encoding]::new($false)
  $tmp=[IO.Path]::GetTempFileName()
  [IO.File]::WriteAllText($tmp,$Content,$enc)
  Move-Item $tmp $Path -Force
}

$file = "path/to/file.ext"
Write-Utf8NoBom -Path $file -Content "YOUR_TEXT_HERE"
"'

---

## PATCH (safe replace)

bash -lc 'powershell -NoLogo -Command "
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false);
Set-Location -LiteralPath (Convert-Path .);

function Patch-Utf8NoBom { param([string]$Path, [string]$Old, [string]$New)
  $enc=[Text.UTF8Encoding]::new($false)
  $text=[IO.File]::ReadAllText($Path,$enc)
  $text=$text.Replace($Old,$New)
  [IO.File]::WriteAllText($Path,$text,$enc)
}

$file = "path/to/file.ext"
Patch-Utf8NoBom -Path $file -Old "OLD_TEXT" -New "NEW_TEXT"
"'

---

## CREATE (new UTF-8 file)

bash -lc 'powershell -NoLogo -Command "
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false);
Set-Location -LiteralPath (Convert-Path .);

function Create-Utf8NoBom { param([string]$Path,[string]$Content)
  $enc=[Text.UTF8Encoding]::new($false)
  [IO.File]::WriteAllText($Path,$Content,$enc)
}

$file = "path/to/file.ext"
Create-Utf8NoBom -Path $file -Content "YOUR_TEXT_HERE"
"'

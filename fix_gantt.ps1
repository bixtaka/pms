$path = 'c:\Users\USER1\Documents\App\pms\lib\features\gantt\presentation\mock_legacy_gantt_screen.dart'
$enc = [System.Text.Encoding]::UTF8
$content = [IO.File]::ReadAllText($path, $enc)

# 1. Remove LinearGradient and Container, replace with SizedBox(width: 80)
# Target both Master and Project (if it remains)
$content = $content -replace 'child:\s+Container\(\s+width: 110,[\s\S]+?Decoration\(\s+gradient: LinearGradient\([\s\S]+?withValues\(alpha: 0\.1\),\s+\]\s+\),\s+\),\s+', "child: SizedBox(`r`n                                  width: 80,"

# 2. Adjust background offset (left: 0 -> left: 80)
$content = $content -replace '(top: kAxisHeight,\s+)left: 0,', '${1}left: 80,'

# 3. Update Text Shadow for better visibility (Halo effect)
$haloShadow = 'style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          shadows: [
                                            Shadow(offset: Offset(0, 1), blurRadius: 3.0, color: Colors.white),
                                            Shadow(offset: Offset(0, -1), blurRadius: 3.0, color: Colors.white),
                                            Shadow(offset: Offset(1, 0), blurRadius: 3.0, color: Colors.white),
                                            Shadow(offset: Offset(-1, 0), blurRadius: 3.0, color: Colors.white),
                                          ],
                                        ),'

$content = $content -replace 'style: TextStyle\(\s+fontSize: 9,[\s\S]+?offset: Offset\(0, 1\),[\s\S]+?\],\s+\),', $haloShadow

[IO.File]::WriteAllText($path, $content, $enc)

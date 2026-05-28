$ErrorActionPreference = "Stop"

$candidates = @(
    "~\.gitconfig",
    "~\.gitignore_global",
    "~\.editorconfig",
    "~\.config\git\ignore",
    "~\.config\nvim",
    "~\.config\alacritty",
    "~\.config\wezterm",
    "~\AppData\Roaming\Code\User\settings.json",
    "~\.ssh\config",
    "~\.local\bin"
)

Write-Host "Existing dotfile candidates:"
Write-Host ""

foreach ($path in $candidates) {
    $expanded = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)

    if (Test-Path $expanded) {
        $item = Get-Item $expanded

        if ($item.PSIsContainer) {
            $count = Get-ChildItem $expanded -Recurse -File -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
            Write-Host "[dir ] $path  files=$count"
        } else {
            $size = $item.Length
            Write-Host "[file] $path  size=${size}B"
        }
    } else {
        Write-Host "[none] $path"
    }
}

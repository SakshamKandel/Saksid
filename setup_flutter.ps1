$ErrorActionPreference = "Stop"

$flutterVersion = "3.27.1" # Using a likely stable version for compatibility
$url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$flutterVersion-stable.zip"
$zipFile = "flutter.zip"
$destination = Get-Location

Write-Host "Downloading Flutter $flutterVersion from $url..."
Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing

Write-Host "Extracting Flutter to $destination..."
Expand-Archive -Path $zipFile -DestinationPath $destination -Force

Write-Host "Cleaning up zip file..."
Remove-Item $zipFile

Write-Host "Flutter setup complete."
Write-Host "Path: $destination\flutter\bin"
Write-Host "You can now run: $destination\flutter\bin\flutter doctor"

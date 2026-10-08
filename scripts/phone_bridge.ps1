# QueueLess Mobile Phone USB Bridge Script
# Automatically forwards backend port 8000 over USB cable to your connected phone.

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  QueueLess Mobile Phone USB Bridge" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

$devices = adb devices
Write-Host $devices

if ($devices -match "device\b") {
    Write-Host "[*] Connected Android phone detected." -ForegroundColor Green
    Write-Host "[*] Running: adb reverse tcp:8000 tcp:8000..." -ForegroundColor Yellow
    adb reverse tcp:8000 tcp:8000
    Write-Host "[+] ADB Reverse Active: localhost:8000 on your phone -> PC port 8000" -ForegroundColor Green

    # Display Wi-Fi alternative IP
    $wifiIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "*Wi-Fi*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress -First 1)
    if ($wifiIp) {
        Write-Host "[i] Wi-Fi alternative URL: http://${wifiIp}:8000" -ForegroundColor Cyan
    }
    Write-Host "`nAll set! You can now use the app on your phone without connection errors." -ForegroundColor Green
} else {
    Write-Host "[!] No Android device found. Please make sure:" -ForegroundColor Red
    Write-Host "    1. Your phone is connected with a USB cable" -ForegroundColor Yellow
    Write-Host "    2. USB Debugging is turned ON in Developer Options" -ForegroundColor Yellow
    Write-Host "    3. Tap 'Allow USB Debugging' on your phone screen" -ForegroundColor Yellow
}

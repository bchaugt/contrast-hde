Stop-Service -Name "Contrast.NET Main Service"
Start-Sleep -s 60
Start-Service -Name "Contrast.NET Main Service"
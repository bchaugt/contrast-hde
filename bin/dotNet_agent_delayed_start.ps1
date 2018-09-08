Start-Sleep -s 120
Stop-Service -Name "Contrast.NET Main Service"
Start-Service -Name "Contrast.NET Main Service"
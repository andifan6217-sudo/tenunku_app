@echo off
:: Auto-start Tenunku Backend via PM2
:: File ini dijalankan otomatis oleh Windows Task Scheduler saat startup

cd /d "C:\tenunku\backend"

:: Cari path node & npm
set PATH=%PATH%;C:\Program Files\nodejs;%APPDATA%\npm

:: Resurrect semua proses PM2 yang tersimpan
pm2 resurrect

:: Jika belum ada, start langsung
pm2 start index.js --name "tenunku-backend" --restart-delay=3000 --max-restarts=10 2>nul

:: Simpan state terbaru
pm2 save

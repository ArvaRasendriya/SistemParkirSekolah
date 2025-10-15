@echo off
title 🚀 Supabase Full Auto Setup (Interaktif)
color 0a

echo =========================================
echo 🔧 Supabase Local Environment Auto Setup
echo =========================================
echo.

REM =====================================================
REM Fungsi Konfirmasi Sebelum Melanjutkan
REM =====================================================
:CONFIRM
set /p CONFIRM_STEP="Tekan Y untuk melanjutkan langkah ini, N untuk melewati: "
if /i "%CONFIRM_STEP%"=="N" (
    echo Langkah dilewati.
    goto :EOF
) 
if /i not "%CONFIRM_STEP%"=="Y" (
    echo Input tidak valid. Masukkan Y atau N.
    goto CONFIRM
)

REM =====================================================
REM 0️⃣ BUAT FILE .ENV DAN .ENV.LOCAL
REM =====================================================
echo 🌱 Mengecek file konfigurasi (.env dan .env.local)...
for %%F in (.env .env.local) do (
    if not exist %%F (
        echo Membuat %%F...
        echo SUPABASE_URL=https://rfpsfzbmhhxksisxciwx.supabase.co>%%F
        echo SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...>>%%F
        echo SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...>>%%F
        echo ✅ File %%F dibuat.
    ) else (
        echo File %%F sudah ada. Dilewati.
    )
)

REM =====================================================
REM 1️⃣ CEK NODEJS
REM =====================================================
echo.
set /p CONFIRM_STEP="Apakah ingin cek Node.js terpasang? (Y/N): "
if /i "%CONFIRM_STEP%"=="Y" (
    where node >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Node.js belum terpasang!
        echo Silakan install dari https://nodejs.org/en/download/
        pause
    ) else (
        echo ✅ Node.js terpasang.
    )
) else (
    echo Langkah cek Node.js dilewati.
)

REM =====================================================
REM 2️⃣ CEK DAN INSTALL SUPABASE CLI
REM =====================================================
set /p CONFIRM_STEP="Apakah ingin cek Supabase CLI? (Y/N): "
if /i "%CONFIRM_STEP%"=="Y" (
    where supabase >nul 2>&1
    if %errorlevel% neq 0 (
        echo 🟡 Supabase CLI tidak ditemukan. Menginstal sekarang...
        powershell -Command "iwr https://github.com/supabase/cli/releases/latest/download/installer.ps1 -useb | iex"
    ) else (
        echo ✅ Supabase CLI sudah terpasang.
    )
) else (
    echo Langkah cek Supabase CLI dilewati.
)

REM =====================================================
REM 3️⃣ CEK POSTGRESQL
REM =====================================================
set /p CONFIRM_STEP="Apakah ingin cek PostgreSQL? (Y/N): "
if /i "%CONFIRM_STEP%"=="Y" (
    where psql >nul 2>&1
    if %errorlevel% neq 0 (
        echo 🟡 PostgreSQL tidak ditemukan.
        echo 🔽 Menginstal via Chocolatey...
        where choco >nul 2>&1
        if %errorlevel% neq 0 (
            echo 🟡 Chocolatey tidak ditemukan. Menginstal Chocolatey...
            powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        )
        choco install postgresql -y
    ) else (
        echo ✅ PostgreSQL sudah terpasang.
    )
) else (
    echo Langkah cek PostgreSQL dilewati.
)

REM =====================================================
REM 4️⃣ JALANKAN SUPABASE LOKAL
REM =====================================================
set /p CONFIRM_STEP="Apakah ingin menjalankan Supabase lokal? (Y/N): "
if /i "%CONFIRM_STEP%"=="Y" (
    echo 🚀 Menjalankan Supabase lokal...
    supabase start
    echo ⏳ Menunggu Supabase siap...
    timeout /t 10 >nul
) else (
    echo Langkah jalankan Supabase dilewati.
)

REM =====================================================
REM 5️⃣ DUMP DATA DARI CLOUD SUPABASE
REM =====================================================
set /p CONFIRM_STEP="Apakah ingin dump data dari Cloud Supabase? (Y/N): "
if /i "%CONFIRM_STEP%"=="Y" (
    echo 💾 Membuat dump data dari Cloud Supabase...
    supabase db dump --data-only --file dump_data.sql
) else (
    echo Langkah dump data dilewati.
)

REM =====================================================
REM 6️⃣ RESTORE KE DATABASE LOKAL
REM =====================================================
set /p CONFIRM_STEP="Apakah ingin restore data ke database lokal? (Y/N): "
if /i "%CONFIRM_STEP%"=="Y" (
    echo ♻️ Merestore data ke database lokal...
    psql "postgresql://postgres:postgres@localhost:54322/postgres" -f dump_data.sql
) else (
    echo Langkah restore dilewati.
)

REM =====================================================
REM 8️⃣ SETUP TAMBAHAN
REM =====================================================
set /p CONFIRM_STEP="Apakah ingin menjalankan setup tambahan (migrasi data)? (Y/N): "
if /i "%CONFIRM_STEP%"=="Y" (
    if exist scripts\setup_supabase_full.mjs (
        echo ⚙️ Menjalankan setup tambahan...
        node scripts/setup_supabase_full.mjs
    ) else (
        echo Tidak ada setup_supabase_full.mjs, dilewati.
    )
) else (
    echo Langkah setup tambahan dilewati.
)

REM =====================================================
REM ✅ KONFIRMASI TERAKHIR SEBELUM MENUTUP
REM =====================================================
echo.
echo =========================================
echo 🎉 SEMUA PROSES SELESAI!
echo Supabase lokal siap digunakan.
echo =========================================
echo Tekan sembarang tombol untuk menutup jendela...
pause >nul

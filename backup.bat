@echo off
setlocal EnableDelayedExpansion

title Minecraft Backup Tool

:: ============================================================
:: github.com/v1entur 
:: Minecraft Server Backup Script // Скрипт для бэкапирования папок Майнкрафт сервера
::
:: Creates ZIP backups of selected folders while the server // Создает ZIP архив выбранных папок когда сервер работает
:: is running by first copying them to a temporary directory. // по принципу сначала копирования их в временное расположение
::
:: Uses: // Использует:
::   - Robocopy
::   - PowerShell Compress-Archive
::
:: Example: // Пример:
::   set WORLD_FOLDERS=world world_nether world_the_end plugins mods
::
:: ============================================================

:: ===== SETTINGS // НАСТРОЙКИ =====

:: Path to the Minecraft server folder // Путь к папке с Майнкрафт сервером
set SERVER_DIR=C:\Users\PC\Desktop\mineserver1.16.5

:: Folder where backups will be stored // Путь к папке где будут храниться бэкапы
set BACKUP_DIR=C:\mineserver backups

:: Folders to backup // Какие папки копировать
set WORLD_FOLDERS=world world_nether world_the_end plugins

:: Delay between backups (seconds) // Задержка между бэкапами (секунды)
set BACKUP_DELAY=600

:: Maximum number of backups to keep (0 = unlimited) // Максимальное число существующих бэкапов (0 = не удалять)
set MAX_BACKUPS=10

:: Log file location (same folder as script) // Расположение лог-файла (та же папка что и скрипт)
set LOG_FILE=%~dp0backup_log.txt

:: Create backup folder if it doesn't exist // Создание папки с бэкапами если ее не существует
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: ===== MAIN LOOP =====

:backup_loop

:: Generate timestamp: 2026-06-21_01-24-30 // Пример даты: 2026-06-21_01-24-30 (ГГГГ-ММ-ДД_ЧЧ_ММ_СС)
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do (
set DATETIME=%%i
)

set BACKUP_FILE=%BACKUP_DIR%\mc_backup_%DATETIME%.zip

:: Temporary copy directory // Папка для временного копирования
set TEMP_COPY=%SERVER_DIR%\temp_backup

:: Remove previous temp directory if it exists // Удаление предыдущей временной папки если она существует
if exist "%TEMP_COPY%" rmdir /s /q "%TEMP_COPY%"

mkdir "%TEMP_COPY%"

echo [%date% %time%] Copying files...

:: Copy selected folders // Временное копирование выбранных папок
for %%F in (%WORLD_FOLDERS%) do (
robocopy "%SERVER_DIR%%%F" "%TEMP_COPY%%%F" /MIR /R:3 /W:5 /NP /LOG+:"%LOG_FILE%"
)

echo [%date% %time%] Creating ZIP archive...


:: Create ZIP archive // Создание ZIP архива
powershell -NoProfile -Command ^
"Compress-Archive -Path '%TEMP_COPY%*' -DestinationPath '%BACKUP_FILE%' -Force"

:: Remove temporary files // Удаление временных файлов
rmdir /s /q "%TEMP_COPY%"

:: Delete old backups if limit exceeded // Удаление старых бэкапов если превышен лимит
if %MAX_BACKUPS% GTR 0 (
for /f "skip=%MAX_BACKUPS% delims=" %%F in (
'dir /b /o-d /a-d "%BACKUP_DIR%\mc_backup_*.zip" 2^>nul'
) do (
del "%BACKUP_DIR%%%F"
echo Old backup deleted: %%F
)
)

echo [%date% %time%] Backup completed: %BACKUP_FILE%
echo Next backup in %BACKUP_DELAY% seconds...

timeout /t %BACKUP_DELAY% /nobreak >nul

goto backup_loop

@echo off
setlocal enabledelayedexpansion
cls
color f0
echo -----------------------------
echo - Update tool ESP32 TEF6686 -
echo -       Development         -
echo -----------------------------
echo.
:selectCOM
echo Available COM-ports:
set "_key=HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM"

for /f "tokens=3 delims= " %%c in ('reg query "!_key!" ^| find /v "HKEY"') do (
    set "_com_N=%%c"
    echo/!_com_N:~3! = !_com_N!
)

echo.
set /p "COM=Enter radio's COM-port number (example: 3): "

set "validCOM="
for /f "tokens=3 delims= " %%c in ('reg query "!_key!" ^| find /v "HKEY"') do (
    set "_com_N=%%c"
    if /i "!_com_N:~3!"=="%COM%" set "validCOM=1"
)

if not defined validCOM (
    echo.
    echo Invalid COM-port!
    echo Please enter a valid COM-port number from the list.
    echo.
    goto selectCOM
)

:inputLoop
echo.
set "validInput="
set /p "tempInput=Does your radio have a BOOT-button to flash the radio? (Y/n): "
if not defined tempInput set "tempInput=y"

set "userInput=!tempInput:~0,1!"
if /i "!userInput!" neq "Y" if /i "!userInput!" neq "N" (
    echo Incorrect input. Please enter 'y' or 'n'.
    goto inputLoop
)

echo.
if /i "%userInput%"=="Y" (
    echo Switch ON the radio while holding the BOOT-button and press any key.
    pause >NUL
)
echo.
echo Formatting filesystem......
esptool.exe --chip esp32 --port COM%COM% --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 bootloader.bin 0x8000 partitions.bin 0xe000 boot_app0.bin 0x10000 format_Spiffs.ino.bin 2>NUL | findstr /r /c:"Writing at"
if /i "%userInput%"=="Y" (
    echo.
    echo Now switch your radio OFF and back ON.
    echo When you see the message 'Formatting finished' on your radio, switch OFF the radio.
    echo Next, switch your radio ON while holding the BOOT-button and press any key.
    pause >NUL
) else (
    timeout /t 14 /nobreak > nul
)
echo.
echo Uploading software......
esptool.exe --chip esp32 --port COM%COM% --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 bootloader.bin 0x8000 partitions.bin 0xe000 boot_app0.bin 0x10000 TEF6686_ESP32.ino.bin 0x00310000 "TEF6686_ESP32.spiffs.bin" 2>NUL | findstr /r /c:"Writing at"

if %ERRORLEVEL% neq 0 (
    echo.
    echo Error uploading! Please check the COM-port and radio for download state.
    echo Press any key to exit the update tool.
    pause >NUL
    exit /b %ERRORLEVEL%
)

echo.
echo Update completed, press any key to close this program.
pause >NUL
endlocal

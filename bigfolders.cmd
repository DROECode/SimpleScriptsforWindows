@echo off
setlocal EnableDelayedExpansion

REM Set variables
set "DRIVE=C:"
set "OUTPUT_FILE=C:\LargeFoldersReport_%date:~10,4%-%date:~4,2%-%date:~7,2%_%time:~0,2%%time:~3,2%.txt"
set "MIN_SIZE=1073741824" REM 1GB in bytes

REM Create report header
echo Large Folders Report (1GB or higher) - Generated on %date% %time% > "%OUTPUT_FILE%"
echo ================================================== >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

REM Temporary file to store folder sizes
set "TEMP_FILE=%TEMP%\dirsize.txt"
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

REM Scan directories and calculate sizes
echo Scanning %DRIVE% for large folders...
for /f "delims=" %%D in ('dir "%DRIVE%\" /ad /s /b') do (
    set "FOLDER=%%D"
    set "SIZE=0"
    REM Calculate folder size using dir
    for /f "tokens=3" %%S in ('dir "%%D" /s ^| find "File(s)"') do (
        set "SIZE=%%S"
        REM Remove commas from size
        set "SIZE=!SIZE:,=!"
    )
    REM Check if size exceeds 1GB
    if !SIZE! GTR %MIN_SIZE% (
        set "SIZE_GB=!SIZE:~0,-9!.!SIZE:~-9,-7!"
        if "!SIZE_GB:~0,1!"=="." set "SIZE_GB=0!SIZE_GB!"
        echo Folder: %%D >> "%TEMP_FILE%"
        echo Size: !SIZE_GB! GB (!SIZE! bytes) >> "%TEMP_FILE%"
        echo ---------------------------------------- >> "%TEMP_FILE%"
    )
)

REM Sort and append to final report
if exist "%TEMP_FILE%" (
    sort /r "%TEMP_FILE%" >> "%OUTPUT_FILE%"
    del "%TEMP_FILE%"
    REM Calculate total size (approximate)
    set "TOTAL_SIZE=0"
    for /f "tokens=2" %%S in ('type "%OUTPUT_FILE%" ^| find "Size:"') do (
        set /a "TOTAL_SIZE+=%%S"
    )
    echo. >> "%OUTPUT_FILE%"
    echo Total approximate size of large folders: %TOTAL_SIZE% GB >> "%OUTPUT_FILE%"
) else (
    echo No folders over 1GB found. >> "%OUTPUT_FILE%"
)

echo Report generated at: %OUTPUT_FILE%
echo Done.

REM Open the report
start notepad "%OUTPUT_FILE%"

endlocal
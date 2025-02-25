@echo off
setlocal EnableDelayedExpansion

REM Set variables
set "DRIVE=C:"
set "OUTPUT_FILE=C:\LargeFoldersReport_%date:~10,4%-%date:~4,2%-%date:~7,2%_%time:~0,2%%time:~3,2%.txt"
set "MIN_SIZE=1073741824" REM 1GB in bytes
set "exclude=Windows System32 SysWOW64 "Program Files" "Program Files (x86)" "$Recycle.Bin""

REM Create report header
echo Large Folders Report (1GB or higher) - Generated on %date% %time% > "%OUTPUT_FILE%"
echo ================================================== >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

REM Display all top-level folders in C:\
echo Listing all top-level folders in %DRIVE%\
echo ------------------------
for /d %%F in ("%DRIVE%\*") do (
    echo %%F
)
echo ------------------------
echo.

REM Temporary file to store folder sizes
set "TEMP_FILE=%TEMP%\dirsize.txt"
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

REM Scan directories and calculate sizes
echo Scanning %DRIVE% for large folders...
for /d %%T in ("%DRIVE%\*") do (
    set "skip="
    set "TOPFOLDER=%%~nxT"
    REM Check if top-level folder should be excluded
    for %%E in (%exclude%) do (
        if /i "!TOPFOLDER!"=="%%~E" set "skip=1"
    )
    if not defined skip (
        echo Processing top-level folder: %%T
        REM Scan subdirectories of this top-level folder
        for /f "delims=" %%D in ('dir "%%T" /ad /s /b 2^>nul') do (
            set "SUBFOLDER=%%~nxD"
            set "skip_sub="
            REM Check if subfolder should be excluded
            for %%E in (%exclude%) do (
                if /i "!SUBFOLDER!"=="%%~E" set "skip_sub=1"
            )
            if not defined skip_sub (
                echo Evaluating folder: %%D
                set "SIZE=0"
                REM Calculate folder size, redirect errors to nul
                for /f "tokens=3" %%S in ('dir "%%D" /s ^| find "File(s)" 2^>nul') do (
                    set "SIZE=%%S"
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
        )
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
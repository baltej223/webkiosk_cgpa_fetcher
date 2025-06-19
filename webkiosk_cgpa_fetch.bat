@echo off
setlocal enabledelayedexpansion

:: ========================
:: Script Configuration
:: ========================
set "LOGIN_URL=https://webkiosk.thapar.edu/CommonFiles/UserAction.jsp"
set "CGPA_URL=https://webkiosk.thapar.edu/StudentFiles/Exam/StudCGPAReport.jsp"
set "COOKIES_FILE=cookies.txt"
set "OUTPUT_FILE=latest_cgpa.html"
set "DEFAULT_SLEEP=150"

:: ========================
:: Usage Function
:: ========================
:usage
echo Usage: %~nx0 --roll-number ^<num^> --password ^<pass^> [-s ^<seconds^>]
echo.
echo Options:
echo   -r, --roll-number     Your Enrollment Number (e.g., 102103682)
echo   -p, --password        Your WebKiosk password
echo   -s, --sleep           Sleep interval in seconds (default: %DEFAULT_SLEEP%)
echo.
goto :eof

:: ========================
:: Argument Parsing
:: ========================
set "ENROLLMENT_NO="
set "PASSWORD="
set "SLEEP_INTERVAL=%DEFAULT_SLEEP%"

:parse_args_loop
if "%~1" == "" goto :end_parse_args_loop

if /i "%~1" == "-r" (
    set "ENROLLMENT_NO=%~2"
    shift
) else if /i "%~1" == "--roll-number" (
    set "ENROLLMENT_NO=%~2"
    shift
) else if /i "%~1" == "-p" (
    set "PASSWORD=%~2"
    shift
) else if /i "%~1" == "--password" (
    set "PASSWORD=%~2"
    shift
) else if /i "%~1" == "-s" (
    set "SLEEP_INTERVAL=%~2"
    shift
) else if /i "%~1" == "--sleep" (
    set "SLEEP_INTERVAL=%~2"
    shift
) else (
    echo [!] Error: Unknown parameter passed: %~1
    call :usage
    exit /b 1
)
shift
goto :parse_args_loop
:end_parse_args_loop

if "%ENROLLMENT_NO%"=="" goto missing_args
if "%PASSWORD%"=="" goto missing_args
goto :continue_script

:missing_args
echo [!] Error: Enrollment Number and Password are required.
echo.
call :usage
exit /b 1

:continue_script
echo [*] Starting CGPA checker for enrollment: %ENROLLMENT_NO%
echo [*] Using sleep interval: %SLEEP_INTERVAL% seconds

:: ========================
:: Cleanup
:: ========================
del "%COOKIES_FILE%" >nul 2>&1

:: ========================
:: Login Function
:: ========================
:login
set "LOGIN_FAILED="
echo [*] Logging into WebKiosk...
curl -s -c "%COOKIES_FILE%" -L "%LOGIN_URL%" ^
  -d "txtuType=Member+Type" ^
  -d "UserType=S" ^
  -d "txtCode=Enrollment+No" ^
  -d "MemberCode=%ENROLLMENT_NO%" ^
  -d "txtPin=Password%%2FPin" ^
  -d "Password=%PASSWORD%" ^
  -d "BTNSubmit=Submit" >nul 2>&1

if not exist "%COOKIES_FILE%" (
    echo [!] Login failed. Cookie file not created.
    set "LOGIN_FAILED=1"
)
goto :eof

:: ========================
:: Fetch CGPA Function
:: ========================
:fetch_cgpa
set "CGPA_FETCH_FAILED="
echo [*] Fetching CGPA report...

if exist "%OUTPUT_FILE%.tmp" del "%OUTPUT_FILE%.tmp" >nul 2>&1

for /f "delims=" %%a in ('curl -s -b "%COOKIES_FILE%" "%CGPA_URL%"') do (
    echo %%a >> "%OUTPUT_FILE%.tmp"
)
move /y "%OUTPUT_FILE%.tmp" "%OUTPUT_FILE%" >nul

findstr /i /c:"session timeout" /c:"login" /c:"not authorized" /c:"useraction.jsp" "%OUTPUT_FILE%" >nul
if %errorlevel% equ 0 (
    echo [!] Session expired or not logged in.
    set "CGPA_FETCH_FAILED=1"
) else (
    echo [+] CGPA report saved to %OUTPUT_FILE%
)
goto :eof

:: ========================
:: Main Loop
:: ========================
call :login
if defined LOGIN_FAILED (
    echo [!] Initial login failed. Exiting.
    goto :end_script
)

:main_loop
call :fetch_cgpa
if defined CGPA_FETCH_FAILED (
    echo [*] Re-attempting login...
    call :login
    if defined LOGIN_FAILED (
        echo [!] Re-login failed. Exiting.
        goto :end_script
    )
    call :fetch_cgpa
    if defined CGPA_FETCH_FAILED (
        echo [!] Fetch after re-login failed. Exiting.
        goto :end_script
    )
)
echo.
echo [*] Sleeping for %SLEEP_INTERVAL% seconds...
timeout /t %SLEEP_INTERVAL% /nobreak >nul
goto :main_loop

:end_script
echo.
echo [+] Exiting and cleaning up...
del "%COOKIES_FILE%" >nul 2>&1
endlocal
exit /b 0

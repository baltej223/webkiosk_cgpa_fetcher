@echo off
setlocal

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

:: Parse arguments
set "arg_idx=1"
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
:: Cleanup on Exit (Best Effort)
:: ========================
:: We can't directly trap Ctrl+C like in Bash.
:: This batch script will attempt to clean up on normal exit or if login/fetch fails permanently.
:: For a robust solution, consider a scheduled task or PowerShell.
del "%COOKIES_FILE%" >nul 2>&1

:: ========================
:: Login function
:: ========================
:login
echo [*] Logging into WebKiosk...
:: Use curl to perform the login POST request and save cookies
:: -s: silent mode
:: -c: cookie-jar (save cookies to this file)
:: -L: follow redirects
:: -d: data for POST request
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
    exit /b 1 :: Exit the script if login fails initially
)
echo [+] Login request sent. Verifying session...
exit /b 0

:: ========================
:: Fetch CGPA report
:: ========================
:fetch_cgpa
echo [*] Fetching CGPA report...
:: Use curl to get the CGPA page using the saved cookies
:: -s: silent mode
:: -b: cookie file (read cookies from this file)
for /f "delims=" %%a in ('curl -s -b "%COOKIES_FILE%" "%CGPA_URL%"') do (
    echo %%a >> "%OUTPUT_FILE%.tmp"
)
move /y "%OUTPUT_FILE%.tmp" "%OUTPUT_FILE%" >nul

:: Check for session expiry/login required keywords
findstr /i /c:"session timeout" /c:"login" /c:"not authorized" /c:"useraction.jsp" "%OUTPUT_FILE%" >nul
if %errorlevel% equ 0 (
    echo [!] Session expired or not logged in.
    exit /b 1
)

echo [+] CGPA report saved to %OUTPUT_FILE%
exit /b 0

:: ========================
:: Main Loop
:: ========================
call :login
if %errorlevel% neq 0 (
    echo [!] Initial login failed. Exiting.
    goto :end_script
)

:main_loop
call :fetch_cgpa
if %errorlevel% neq 0 (
    echo [*] Re-attempting login...
    call :login
    if %errorlevel% neq 0 (
        echo [!] Re-login failed. Exiting.
        goto :end_script
    )
    call :fetch_cgpa
    if %errorlevel% neq 0 (
        echo [!] Fetch after re-login failed. Exiting.
        goto :end_script
    )
)
echo.
echo [*] Sleeping for %SLEEP_INTERVAL% seconds...
timeout /t %SLEEP_INTERVAL% /nobreak >nul
goto :main_loop

:end_script
echo -e "\n[+] Exiting and cleaning up..."
del "%COOKIES_FILE%" >nul 2>&1
endlocal
exit /b 0

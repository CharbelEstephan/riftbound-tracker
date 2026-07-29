@echo off
REM Double-click this to start the logger and open it in your browser.
REM Closing the black window stops the app.
cd /d "%~dp0"
start "" /min cmd /c "python app.py"
timeout /t 2 /nobreak >nul
start "" http://localhost:5001
exit

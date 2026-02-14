@echo off
REM GitHub Push Script for opencode-coding
REM Run this after creating the repository on GitHub

echo Pushing opencode-coding to GitHub...
echo.

cd /d "C:\Users\admin\.openclaw\workspace\skills\opencode-coding"

REM Check if remote exists
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo Adding remote origin...
    git remote add origin https://github.com/wumajiehechuan-lab/opencode-coding.git
) else (
    echo Remote origin already exists
)

echo.
echo Pushing to GitHub...
git push -u origin master

if errorlevel 1 (
    echo.
    echo Push failed. Possible reasons:
    echo 1. Repository doesn't exist on GitHub
    echo 2. Authentication required
    echo 3. Network issue
    echo.
    echo To create the repository:
    echo 1. Visit: https://github.com/new
    echo 2. Name: opencode-coding
    echo 3. Set to Public
    echo 4. Don't initialize with README
    echo 5. Click Create
    echo 6. Then run this script again
) else (
    echo.
    echo Successfully pushed to GitHub!
    echo Repository: https://github.com/wumajiehechuan-lab/opencode-coding
)

pause

@echo off
rem FateCode Google Play release. See docs\PLAY_RELEASE.md
rem   play-release.cmd check | internal | production | metadata | details   [key:value ...]
rem   internal closed:true  = also put the same build into closed testing (alpha)
rem NOTE: keep this file pure ASCII. cmd.exe parses it in the system codepage
rem       before "chcp 65001" takes effect, so non-ASCII comments break it.
setlocal
chcp 65001 >nul
if "%~1"=="" (
  echo Usage: play-release.cmd check ^| internal ^| production ^| metadata ^| details  [version_code:N] [version_name:x.y.z] [closed:true] [yes:true]
  exit /b 2
)
where bundle >nul 2>nul || set "PATH=C:\Ruby33-x64\bin;%PATH%"
where bundle >nul 2>nul || (
  echo Ruby/Bundler not found. Install: winget install RubyInstallerTeam.RubyWithDevKit.3.3 ; then: cd app\android ^&^& bundle install
  exit /b 1
)
cd /d "%~dp0app\android"
bundle exec fastlane android %*

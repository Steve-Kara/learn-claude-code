@echo off
rem ASCII-ONLY wrapper. Real logic lives in run.ps1 (UTF-8 with BOM).
rem NOTE 1: keep this file pure ASCII -- cmd.exe reads .cmd as the OEM codepage
rem         (936/GBK here), so UTF-8 Chinese comments get mis-decoded.
rem NOTE 2: do NOT add "chcp 65001" here. Measured: chcp consumes a redirected
rem         stdin, so the REPL would get EOF and exit immediately. The console
rem         codepage is switched from run.ps1 instead (see [Console]::OutputEncoding).
rem
rem PYTHONUTF8/PYTHONIOENCODING keep Python on UTF-8 so a model reply containing
rem non-GBK glyphs cannot crash it.
set PYTHONIOENCODING=utf-8
set PYTHONUTF8=1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*

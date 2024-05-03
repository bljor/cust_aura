REM Kopier filer fra GIS-AURA-WEB til DINEL-WEB

@echo off
set src_folder=\\GIS-AURA-WEB\Galten_el$
set dst_folder=\\192.168.186.15\dinel$
for /f "tokens=*" %%i in (C:\Script\File-list.txt) DO (
    xcopy /D/Y "%src_folder%\%%i" "%dst_folder%"

)

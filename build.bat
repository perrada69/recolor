@echo off
rem Build script for recolor dot command (ZX Spectrum Next)
rem Requires: sjasmplus

echo Building recolor...

sjasmplus --raw=recolor recolor.asm

if errorlevel 1 (
    echo BUILD FAILED
    exit /b 1
)

echo.
echo OK - output: recolor
echo Copy 'recolor' to /dot/ folder on your Next SD card.
echo Usage: .recolor filename.nxi

echo Spoustim CSpect...

D:\Source\Assembler\CSpect\hdfmonkey.exe put D:\Source\Assembler\CSpect\cspect-next-2gb.img recolor /dot/

D:\Source\Assembler\CSpect\hdfmonkey.exe put D:\Source\Assembler\CSpect\cspect-next-2gb.img palette.nxp /
D:\Source\Assembler\CSpect\hdfmonkey.exe put D:\Source\Assembler\CSpect\cspect-next-2gb.img voltix.sna /



D:\Source\Assembler\CSpect\CSpect.exe -zxnext -basickeys -tv -mmc=D:\Source\Assembler\CSpect\cspect-next-2gb.img 

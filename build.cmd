set compiler=C:\Program Files (x86)\AutoHotKey\Compiler\Ahk2Exe.exe
set zipper=C:\Program Files\7-Zip\7z.exe

if exist todo.exe del todo.exe

"%compiler%" /in todo.ahk /out todo.exe /icon todo.ico

if exist todo.zip del todo.zip

"%zipper%" a todo.zip Anchor.ahk LICENSE.txt README.txt todo.ahk todo.exe todo.ico todo.ini.example


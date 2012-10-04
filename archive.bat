@echo off
REM build a snapshot for putting in the Downloads section of googlecode.

pushd ..

x:\tools\7za.exe -tzip -x@lua-files\archive-exclude.lst a lua-files\lua-files-%date:~10,4%-%date:~4,2%-%date:~7,2%.zip lua-files

popd

@echo off
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "ScanMap Code" /t REG_BINARY /d "00000000000000000200000000003A0000000000" /f
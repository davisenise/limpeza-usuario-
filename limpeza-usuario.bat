@echo off
title Limpeza de Perfil do Usuario - Davi Senise TI
color 0A

cls
echo ================================================
echo      LIMPEZA DE PERFIL DO USUARIO
echo      Tecnico: Davi Senise - Suporte TI
echo ================================================
echo.
echo  Limpa SOMENTE arquivos do seu perfil:
echo.
echo   [1] Temporarios do usuario
echo   [2] Cache de internet
echo   [3] Crash dumps
echo   [4] Cache de miniaturas
echo   [5] Cache de navegadores (Chrome/Edge)
echo.
echo  NAO mexe em: lixeira, pastas do sistema,
echo  senhas, historico ou cookies de navegador.
echo.
echo  NAO precisa de administrador.
echo.
echo ================================================
set /p confirma= Iniciar limpeza? (S/N): 
if /i "%confirma%"=="N" goto SAIR
if /i not "%confirma%"=="S" goto SAIR

echo.
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0limpeza-usuario.ps1"

:SAIR
exit

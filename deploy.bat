@echo off
echo ===========================================
echo   Publicando corrección de compilación API
echo ===========================================
cd /d "c:\PROYECTOS\PROYECTO TESIS\Ganadero"
git add .
git commit -m "fix(api): agregar using API.DTOs en WebAuthController para resolver compilacion en Render"
git push origin main
echo ===========================================
echo   Proceso finalizado!
echo ===========================================

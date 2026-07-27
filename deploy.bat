@echo off
echo ===========================================
echo   Publicando actualización de iconos y UI
echo ===========================================
cd /d "c:\PROYECTOS\PROYECTO TESIS\Ganadero"
git add .
git commit -m "style: optimizar iconos tematicos (ordeño, sanidad, hato) en Flutter y plataforma WEB"
git push origin main
echo ===========================================
echo   Proceso finalizado!
echo ===========================================

@echo off
echo ===========================================
echo   Configurando Repositorio HTTPS y Publicando
echo   Repository: https://github.com/luisenrriquealvaressori-cmyk/tesis-.git
echo ===========================================

cd /d "c:\PROYECTOS\PROYECTO TESIS\Ganadero"

if not exist .git (
    echo [INFO] Inicializando repositorio Git en Ganadero...
    git init
    git branch -M main
)

echo [INFO] Configurando origen remoto HTTPS...
git remote remove origin 2>nul
git remote add origin https://github.com/luisenrriquealvaressori-cmyk/tesis-.git

echo [INFO] Agregando archivos modificados...
git add .

echo [INFO] Creando commit...
git commit -m "fix(mobile): corregir enum SexoAnimal, centralizar ApiConfig y alinear sincronizacion" 2>nul

echo [INFO] Subiendo cambios a GitHub (https://github.com/luisenrriquealvaressori-cmyk/tesis-.git)...
git push -u origin main

echo ===========================================
echo   Publicacion en GitHub completada!
echo ===========================================
pause

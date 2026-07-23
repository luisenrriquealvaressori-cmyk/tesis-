@echo off
echo ===========================================
echo   Configurando Repositorio y Publicando
echo   Repository: git@github.com:luisenrriquealvaressori-cmyk/tesis-.git
echo ===========================================

cd /d "c:\PROYECTOS\PROYECTO TESIS\Ganadero"

if not exist .git (
    echo [INFO] Inicializando repositorio Git en Ganadero...
    git init
    git branch -M main
)

echo [INFO] Configurando origen remoto...
git remote remove origin 2>nul
git remote add origin git@github.com:luisenrriquealvaressori-cmyk/tesis-.git

echo [INFO] Agregando archivos modificados...
git add .

echo [INFO] Creando commit...
git commit -m "fix(mobile): corregir enum SexoAnimal, centralizar ApiConfig y alinear sincronizacion"

echo [INFO] Subiendo cambios a GitHub (branch main)...
git push -u origin main

if %errorlevel% neq 0 (
    echo [INFO] Intentando subida a branch master...
    git push -u origin master
)

echo ===========================================
echo   Publicacion en GitHub completada!
echo ===========================================
pause

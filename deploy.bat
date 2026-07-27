@echo off
echo ===========================================
echo   Limpiando e ignorando temporales (.vs)
echo ===========================================
cd /d "c:\PROYECTOS\PROYECTO TESIS\Ganadero"
git rm -r --cached .vs 2>nul
git rm -r --cached API/.vs 2>nul
git rm -r --cached WEB/.vs 2>nul
echo ===========================================
echo   Añadiendo archivos de código fuente
echo ===========================================
git add .
echo ===========================================
echo   Guardando commit
echo ===========================================
git commit -m "feat: actualizacion integral de onboarding, formulas zootecnicas KPI, WEB app y API .NET 9"
echo ===========================================
echo   Enviando a GitHub (git push origin main)
echo ===========================================
git push origin main
echo ===========================================
echo   Proceso finalizado!
echo ===========================================

import subprocess, os

os.chdir(r"c:\PROYECTOS\PROYECTO TESIS\Ganadero")

print("[1/4] Ignorando archivos temporales de Visual Studio (.vs)...")
subprocess.run(["git", "rm", "-r", "--cached", ".vs"], capture_output=True, text=True)
subprocess.run(["git", "rm", "-r", "--cached", "API/.vs"], capture_output=True, text=True)
subprocess.run(["git", "rm", "-r", "--cached", "WEB/.vs"], capture_output=True, text=True)

print("[2/4] Añadiendo código fuente, scripts y documentación...")
res1 = subprocess.run(["git", "add", "."], capture_output=True, text=True)
print(res1.stdout, res1.stderr)

commit_msg = (
    "fix: proyectar DTOs sin ciclos en SyncController.cs y hacer el mapeo JSON a prueba de fallos en la app"
)

print("[3/4] Creando commit en Git...")
res2 = subprocess.run(["git", "commit", "-m", commit_msg], capture_output=True, text=True)
print(res2.stdout, res2.stderr)

print("[4/4] Enviando cambios a GitHub (git push origin main)...")
res3 = subprocess.run(["git", "push", "origin", "main"], capture_output=True, text=True)
print(res3.stdout, res3.stderr)

if res3.returncode == 0 or "Everything up-to-date" in res3.stdout or "Everything up-to-date" in res3.stderr:
    print("[SUCCESS] Commit y Push completados con éxito en GitHub!")

import subprocess
import os

os.chdir(r"c:\PROYECTOS\PROYECTO TESIS\Ganadero")

print("[1/3] Ejecutando git add .")
res1 = subprocess.run(["git", "add", "."], capture_output=True, text=True)
print("STDOUT:", res1.stdout)
print("STDERR:", res1.stderr)

print("[2/3] Ejecutando git commit...")
res2 = subprocess.run(["git", "commit", "-m", "feat(deploy): agregar render.yaml Blueprint para despliegue automatico en Render"], capture_output=True, text=True)
print("STDOUT:", res2.stdout)
print("STDERR:", res2.stderr)

print("[3/3] Ejecutando git push origin main...")
res3 = subprocess.run(["git", "push", "origin", "main"], capture_output=True, text=True)
print("STDOUT:", res3.stdout)
print("STDERR:", res3.stderr)

if res3.returncode == 0:
    print("[Exito] render.yaml subido a GitHub!")
else:
    print("[Aviso] Intentando push con master...")
    res4 = subprocess.run(["git", "push", "origin", "master"], capture_output=True, text=True)
    print("STDOUT:", res4.stdout)
    print("STDERR:", res4.stderr)

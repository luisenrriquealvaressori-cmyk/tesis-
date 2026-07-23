import subprocess
import os

os.chdir(r"c:\PROYECTOS\PROYECTO TESIS\Ganadero")

print("[1/3] Agregando archivos modificados...")
res1 = subprocess.run(["git", "add", "."], capture_output=True, text=True)
print("STDOUT:", res1.stdout)
print("STDERR:", res1.stderr)

print("[2/3] Creando commit...")
res2 = subprocess.run(["git", "commit", "-m", "fix(web): corregir tipos TypeScript en AuthContext.tsx y remover useState sin uso en FarmMap.tsx para build limpio en Render"], capture_output=True, text=True)
print("STDOUT:", res2.stdout)
print("STDERR:", res2.stderr)

print("[3/3] Subiendo cambios a GitHub...")
res3 = subprocess.run(["git", "push", "origin", "main"], capture_output=True, text=True)
print("STDOUT:", res3.stdout)
print("STDERR:", res3.stderr)

if res3.returncode == 0:
    print("[SUCCESS] Cambios subidos exitosamente a GitHub!")
else:
    print("[INFO] Probando push a master...")
    res4 = subprocess.run(["git", "push", "origin", "master"], capture_output=True, text=True)
    print("STDOUT:", res4.stdout)
    print("STDERR:", res4.stderr)

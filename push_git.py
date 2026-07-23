import subprocess, os

os.chdir(r"c:\PROYECTOS\PROYECTO TESIS\Ganadero")

res1 = subprocess.run(["git", "add", "."], capture_output=True, text=True)
res2 = subprocess.run(["git", "commit", "-m",
    "fix(web-auth): enviar rol como int en create_admin.py y corregir deserializacion enum en WebAuthController"],
    capture_output=True, text=True)
print(res2.stdout, res2.stderr)

res3 = subprocess.run(["git", "push", "origin", "main"], capture_output=True, text=True)
print(res3.stdout, res3.stderr)
if res3.returncode == 0:
    print("[SUCCESS] Push exitoso!")

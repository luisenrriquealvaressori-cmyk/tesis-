import subprocess
import os

os.chdir(r"c:\PROYECTOS\PROYECTO TESIS\Ganadero")

print("[1/3] Agregando todos los cambios...")
res1 = subprocess.run(["git", "add", "."], capture_output=True, text=True)
print("STDOUT:", res1.stdout)
print("STDERR:", res1.stderr)

print("[2/3] Creando commit...")
res2 = subprocess.run(["git", "commit", "-m",
    "feat(users): separar tabla usuarios_web de usuarios_app\n\n"
    "- Nuevo modelo UsuarioWeb (Email+Clave, Rol, Cargo) para supervisores/admins Web\n"
    "- Nuevo WebAuthController: POST /api/web-auth/login y /api/web-auth/register\n"
    "- El primer registro siempre es Administrador (bootstrap sin auth)\n"
    "- AgroDbContext: DbSet<UsuarioWeb>, index UNIQUE en Email, soft-delete filter\n"
    "- Migracion EF Core AddUsuarioWebTable: crea tabla usuarios_web\n"
    "- Web Login.tsx: campo email en lugar de telefono\n"
    "- api.ts: loginApi usa /api/web-auth/login, nuevo registerWebUserApi\n"
    "- create_admin.py: usa nuevo endpoint /api/web-auth/register"], capture_output=True, text=True)
print("STDOUT:", res2.stdout)
print("STDERR:", res2.stderr)

print("[3/3] Subiendo a GitHub...")
res3 = subprocess.run(["git", "push", "origin", "main"], capture_output=True, text=True)
print("STDOUT:", res3.stdout)
print("STDERR:", res3.stderr)

if res3.returncode == 0:
    print("[SUCCESS] Cambios subidos exitosamente!")
else:
    print("[ERROR]", res3.stderr)

"""
create_admin.py — Registrar el primer Administrador en la plataforma Web de AgroStats.

Usa el endpoint POST /api/web-auth/register.
Si la tabla usuarios_web está vacía, el primer registro siempre se crea como Administrador.
"""

import requests
import getpass

API_URL = "https://tesis-api-t5zw.onrender.com/api"

def crear_admin():
    print("=" * 50)
    print("  Crear Primer Administrador — AgroStats Web")
    print("=" * 50)
    print()

    email = input("Correo electrónico del administrador: ").strip()
    nombre = input("Nombre completo: ").strip()
    clave = getpass.getpass("Contraseña (no se mostrará): ")
    clave2 = getpass.getpass("Confirmar contraseña: ")

    if clave != clave2:
        print("[ERROR] Las contraseñas no coinciden.")
        return

    cargo = input("Cargo (opcional, ej: 'Director'): ").strip() or None

    payload = {
        "email": email,
        "nombre": nombre,
        "clave": clave,
        "rol": "Administrador",
        "cargo": cargo
    }

    try:
        print(f"\nConectando a {API_URL}/web-auth/register ...")
        resp = requests.post(f"{API_URL}/web-auth/register", json=payload, timeout=30)

        if resp.status_code == 200:
            data = resp.json()
            print()
            print("[SUCCESS] ¡Administrador creado exitosamente!")
            print(f"  ID      : {data.get('usuarioId')}")
            print(f"  Email   : {data.get('email')}")
            print(f"  Nombre  : {data.get('nombre')}")
            print(f"  Rol     : {data.get('rol')}")
            print()
            print("Puedes iniciar sesión en la plataforma web con estas credenciales.")
        elif resp.status_code == 409:
            print(f"[ERROR] Ya existe un usuario con ese correo: {resp.json().get('error')}")
        elif resp.status_code == 401:
            print("[ERROR] La tabla ya tiene usuarios. Debes autenticarte primero para agregar más.")
        else:
            print(f"[ERROR] Código {resp.status_code}: {resp.text}")

    except requests.exceptions.ConnectionError:
        print(f"[ERROR] No se pudo conectar a {API_URL}. ¿Está corriendo la API en Render?")
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    crear_admin()

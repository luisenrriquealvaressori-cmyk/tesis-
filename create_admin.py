import urllib.request
import json
import sys

API_URL = "https://tesis-api-t5zw.onrender.com"

def create_admin(telefono="88888888", nombre="Administrador Principal", clave="Admin123*", comarca="Central"):
    # 1. Obtener municipios para tomar un MunicipioId valido
    print(f"[1/2] Obteniendo municipios de {API_URL}...")
    municipio_id = "00000000-0000-0000-0000-000000000000"
    try:
        req = urllib.request.Request(f"{API_URL}/api/auth/municipios")
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            if data and len(data) > 0 and len(data[0].get("municipios", [])) > 0:
                municipio_id = data[0]["municipios"][0]["id"]
                print(f"[OK] Municipio seleccionado: {data[0]['municipios'][0]['nombre']} ({municipio_id})")
    except Exception as e:
        print(f"[AVISO] No se pudieron obtener municipios ({e}), se usara ID por defecto.")

    # 2. Registrar usuario Admin
    print(f"[2/2] Registrando usuario Admin con telefono: {telefono}...")
    payload = {
        "telefono": telefono,
        "nombre": nombre,
        "clave": clave,
        "municipioId": municipio_id,
        "comarca": comarca
    }
    
    req_body = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        f"{API_URL}/api/auth/register",
        data=req_body,
        headers={"Content-Type": "application/json"}
    )
    
    try:
        with urllib.request.urlopen(req) as resp:
            res_data = json.loads(resp.read().decode('utf-8'))
            print("\n================================================")
            print("  ¡USUARIO ADMINISTRADOR CREADO EXITOSAMENTE!")
            print("================================================")
            print(f" Teléfono: {telefono}")
            print(f" Clave:    {clave}")
            print(f" Nombre:   {nombre}")
            print(f" ID:       {res_data.get('usuarioId', 'N/A')}")
            print("================================================\n")
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode('utf-8')
        print(f"[ERROR HTTP {e.code}]: {err_msg}")
    except Exception as e:
        print(f"[ERROR]: {e}")

if __name__ == "__main__":
    telefono = sys.argv[1] if len(sys.argv) > 1 else "88888888"
    clave = sys.argv[2] if len(sys.argv) > 2 else "Admin123*"
    nombre = sys.argv[3] if len(sys.argv) > 3 else "Administrador Principal"
    create_admin(telefono, nombre, clave)

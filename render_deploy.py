import urllib.request
import json
import sys

RENDER_API_KEY = "rnd_BjBpENDlR1P2YxqR9pcf6O4YwdQS"
HEADERS = {
    "Authorization": f"Bearer {RENDER_API_KEY}",
    "Accept": "application/json",
    "Content-Type": "application/json"
}

def list_services():
    url = "https://api.render.com/v1/services?limit=20"
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read().decode('utf-8')
            data = json.loads(res_body)
            return data
    except Exception as e:
        print(f"[ERROR] No se pudieron obtener los servicios de Render: {e}")
        return []

def trigger_deploy(service_id, service_name):
    url = f"https://api.render.com/v1/services/{service_id}/deploys"
    req = urllib.request.Request(url, data=b"{}", headers=HEADERS, method="POST")
    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read().decode('utf-8')
            data = json.loads(res_body)
            print(f"[SUCCESS] Despliegue iniciado exitosamente para '{service_name}' (ID: {service_id})")
            print(f"         Deploy ID: {data.get('id', 'N/A')} - Status: {data.get('status', 'created')}")
    except Exception as e:
        print(f"[ERROR] Error al iniciar despliegue para '{service_name}': {e}")

if __name__ == "__main__":
    print("==================================================")
    print("  Conectando a la API de Render...")
    print("==================================================")
    services = list_services()
    if not services:
        print("No se encontraron servicios o fallo la autenticacion.")
        sys.exit(1)

    print(f"Se encontraron {len(services)} servicio(s) en tu cuenta de Render:\n")
    for item in services:
        srv = item.get("service", {})
        srv_id = srv.get("id")
        srv_name = srv.get("name")
        srv_type = srv.get("type")
        repo = srv.get("repo")
        print(f" -> Servicio: {srv_name} | Tipo: {srv_type} | Repo: {repo} | ID: {srv_id}")

        if srv_id:
            print(f"    Iniciando despliegue de '{srv_name}'...")
            trigger_deploy(srv_id, srv_name)
            print("-" * 50)

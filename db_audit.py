"""
db_audit.py — Consultar tablas, columnas y conteos de registros en NeonDB (PostgreSQL).
"""

import subprocess, sys

# Asegurar psycopg2
try:
    import psycopg2
except ImportError:
    print("Instalando psycopg2-binary...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary", "-q"])
    import psycopg2

# Cadena de conexión NeonDB
CONN = {
    "host": "ep-fancy-unit-axb2z72v.c-4.us-east-2.aws.neon.tech",
    "dbname": "neondb",
    "user": "neondb_owner",
    "password": "npg_dM8UfQ0kTbWw",
    "sslmode": "require",
    "connect_timeout": 15
}

def bold(text): return f"\033[1m{text}\033[0m"
def green(text): return f"\033[92m{text}\033[0m"
def yellow(text): return f"\033[93m{text}\033[0m"
def red(text): return f"\033[91m{text}\033[0m"

try:
    print(f"\nConectando a NeonDB ({CONN['host']})...")
    conn = psycopg2.connect(**CONN)
    cur = conn.cursor()
    print(green("✔ Conectado exitosamente.\n"))

    # ──────────────────────────────────────────────
    # 1. Listar todas las tablas del schema public
    # ──────────────────────────────────────────────
    cur.execute("""
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY tablename;
    """)
    tablas = [row[0] for row in cur.fetchall()]

    print(bold(f"{'='*55}"))
    print(bold(f"  BASE DE DATOS: {CONN['dbname']} @ NeonDB"))
    print(bold(f"  TOTAL DE TABLAS: {len(tablas)}"))
    print(bold(f"{'='*55}"))
    print()

    # ──────────────────────────────────────────────
    # 2. Para cada tabla: columnas y conteo de filas
    # ──────────────────────────────────────────────
    for tabla in tablas:
        # Contar filas
        cur.execute(f'SELECT COUNT(*) FROM "{tabla}";')
        count = cur.fetchone()[0]

        # Obtener columnas y sus tipos
        cur.execute("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = %s
            ORDER BY ordinal_position;
        """, (tabla,))
        columnas = cur.fetchall()

        color = green if count > 0 else yellow
        print(color(f"  📋 {tabla}") + f"  ({count} registros)")
        for col_name, col_type, nullable, default in columnas:
            null_flag = "" if nullable == "YES" else bold(" NOT NULL")
            def_flag = f" [default: {default}]" if default else ""
            print(f"      ├─ {col_name:<30} {col_type}{null_flag}{def_flag}")
        print()

    # ──────────────────────────────────────────────
    # 3. Estado de migraciones EF Core
    # ──────────────────────────────────────────────
    cur.execute("""
        SELECT EXISTS (
            SELECT FROM pg_tables
            WHERE schemaname = 'public' AND tablename = '__EFMigrationsHistory'
        );
    """)
    tiene_historial = cur.fetchone()[0]

    if tiene_historial:
        cur.execute('SELECT "MigrationId", "ProductVersion" FROM "__EFMigrationsHistory" ORDER BY "MigrationId";')
        migraciones = cur.fetchall()
        print(bold("  📜 MIGRACIONES APLICADAS:"))
        for m_id, m_ver in migraciones:
            print(green(f"      ✔ {m_id}") + f"  (EF {m_ver})")
        print()

    cur.close()
    conn.close()
    print(bold("Auditoría completada."))

except Exception as e:
    print(red(f"\n[ERROR] {e}"))

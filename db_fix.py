"""
db_fix.py — Aplicar correcciones y crear tablas faltantes en NeonDB.

Correcciones que aplica:
  1. Agregar columna 'rol' a 'usuarios_app' (si no existe)
  2. Crear tabla 'usuarios_web' (si no existe)
  3. Corregir animales con estado=0 → estado=1 (Sana)
  4. Registrar las 3 migraciones pendientes en __EFMigrationsHistory
"""

import subprocess, sys

try:
    import psycopg2
    from psycopg2 import sql
except ImportError:
    print("Instalando psycopg2-binary...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary", "-q"])
    import psycopg2

CONN = {
    "host": "ep-fancy-unit-axb2z72v.c-4.us-east-2.aws.neon.tech",
    "dbname": "neondb",
    "user": "neondb_owner",
    "password": "npg_dM8UfQ0kTbWw",
    "sslmode": "require",
    "connect_timeout": 15
}

def ok(msg):  print(f"  \033[92m✔\033[0m {msg}")
def warn(msg): print(f"  \033[93m⚠\033[0m {msg}")
def err(msg):  print(f"  \033[91m✘\033[0m {msg}")
def step(msg): print(f"\n\033[1m{msg}\033[0m")

try:
    print("\nConectando a NeonDB...")
    conn = psycopg2.connect(**CONN)
    conn.autocommit = False
    cur = conn.cursor()
    ok("Conectado.")

    # ──────────────────────────────────────────────────────
    # PASO 1: Agregar columna 'rol' a usuarios_app
    # ──────────────────────────────────────────────────────
    step("PASO 1: Columna 'rol' en 'usuarios_app'")
    cur.execute("""
        SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema='public' AND table_name='usuarios_app' AND column_name='rol';
    """)
    if cur.fetchone()[0] == 0:
        cur.execute("""
            ALTER TABLE usuarios_app
            ADD COLUMN rol INTEGER NOT NULL DEFAULT 1;
        """)
        ok("Columna 'rol' creada (default=1 / Ganadero).")
    else:
        warn("Columna 'rol' ya existía. Omitida.")

    # ──────────────────────────────────────────────────────
    # PASO 2: Crear tabla 'usuarios_web'
    # ──────────────────────────────────────────────────────
    step("PASO 2: Tabla 'usuarios_web'")
    cur.execute("""
        SELECT COUNT(*) FROM pg_tables
        WHERE schemaname='public' AND tablename='usuarios_web';
    """)
    if cur.fetchone()[0] == 0:
        cur.execute("""
            CREATE TABLE usuarios_web (
                id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                email       TEXT NOT NULL,
                nombre      TEXT NOT NULL,
                clave_hash  TEXT NOT NULL,
                rol         INTEGER NOT NULL DEFAULT 2,
                cargo       TEXT,
                created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                updated_at  TIMESTAMP WITH TIME ZONE,
                is_deleted  BOOLEAN NOT NULL DEFAULT FALSE
            );
        """)
        cur.execute("""
            CREATE UNIQUE INDEX ix_usuarios_web_email
            ON usuarios_web (email);
        """)
        ok("Tabla 'usuarios_web' creada con índice UNIQUE en email.")
    else:
        warn("Tabla 'usuarios_web' ya existía. Omitida.")

    # ──────────────────────────────────────────────────────
    # PASO 3: Corregir animales con estado=0
    # ──────────────────────────────────────────────────────
    step("PASO 3: Corregir animales.estado = 0 → 1 (Sana)")
    cur.execute("SELECT COUNT(*) FROM animales WHERE estado = 0;")
    count_bad = cur.fetchone()[0]
    if count_bad > 0:
        cur.execute("UPDATE animales SET estado = 1 WHERE estado = 0;")
        ok(f"{count_bad} registro(s) corregidos (estado 0 → 1).")
    else:
        warn("No hay animales con estado=0. Nada que corregir.")

    # ──────────────────────────────────────────────────────
    # PASO 4: Registrar migraciones en __EFMigrationsHistory
    # ──────────────────────────────────────────────────────
    step("PASO 4: Registrar migraciones pendientes en __EFMigrationsHistory")

    migraciones_pendientes = [
        ("20260723211500_AddRolToUsuarioApp", "9.0.2"),
        ("20260723212500_AddUsuarioWebTable",  "9.0.2"),
    ]

    for migration_id, product_version in migraciones_pendientes:
        cur.execute("""
            SELECT COUNT(*) FROM "__EFMigrationsHistory"
            WHERE migration_id = %s;
        """, (migration_id,))
        if cur.fetchone()[0] == 0:
            cur.execute("""
                INSERT INTO "__EFMigrationsHistory" (migration_id, product_version)
                VALUES (%s, %s);
            """, (migration_id, product_version))
            ok(f"Migración registrada: {migration_id}")
        else:
            warn(f"Migración ya registrada: {migration_id}")

    # ──────────────────────────────────────────────────────
    # COMMIT
    # ──────────────────────────────────────────────────────
    conn.commit()
    print()
    ok("\033[1mTodos los cambios aplicados y confirmados (COMMIT).\033[0m")

    # ──────────────────────────────────────────────────────
    # VERIFICACIÓN FINAL
    # ──────────────────────────────────────────────────────
    step("VERIFICACIÓN FINAL")
    cur.execute("""
        SELECT tablename FROM pg_tables
        WHERE schemaname='public' ORDER BY tablename;
    """)
    tablas = [r[0] for r in cur.fetchall()]
    print(f"  Total de tablas: {len(tablas)}")
    for t in tablas:
        cur.execute(f'SELECT COUNT(*) FROM "{t}";')
        c = cur.fetchone()[0]
        sym = "✔" if c > 0 else "○"
        print(f"    {sym} {t:<35} ({c} registros)")

    cur.close()
    conn.close()
    print("\n\033[1mScript finalizado.\033[0m\n")

except Exception as e:
    try:
        conn.rollback()
    except Exception:
        pass
    err(f"ERROR — Se hizo ROLLBACK: {e}")
    import traceback
    traceback.print_exc()

using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace API.Migrations
{
    /// <inheritdoc />
    public partial class InitialCatalogsUpdate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "departamentos",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_departamentos", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "enfermedades",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "text", nullable: false),
                    descripcion = table.Column<string>(type: "text", nullable: false),
                    notificacion_obligatoria = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_enfermedades", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "medicamentos",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre_comercial = table.Column<string>(type: "text", nullable: false),
                    principio_activo = table.Column<string>(type: "text", nullable: true),
                    tipo = table.Column<string>(type: "text", nullable: true),
                    via_administracion = table.Column<string>(type: "text", nullable: true),
                    dosis_sugerida = table.Column<string>(type: "text", nullable: true),
                    dias_retiro_leche = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_medicamentos", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "razas_bovinas",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "text", nullable: false),
                    origen_genetico = table.Column<string>(type: "text", nullable: false),
                    proposito = table.Column<int>(type: "integer", nullable: false),
                    descripcion = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_razas_bovinas", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "sintomas",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "text", nullable: false),
                    descripcion = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_sintomas", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "municipios",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    departamento_id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_municipios", x => x.id);
                    table.ForeignKey(
                        name: "fk_municipios_departamentos_departamento_id",
                        column: x => x.departamento_id,
                        principalTable: "departamentos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "enfermedad_medicamento",
                columns: table => new
                {
                    enfermedad_id = table.Column<Guid>(type: "uuid", nullable: false),
                    medicamento_id = table.Column<Guid>(type: "uuid", nullable: false),
                    notas_tratamiento = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_enfermedad_medicamento", x => new { x.enfermedad_id, x.medicamento_id });
                    table.ForeignKey(
                        name: "fk_enfermedad_medicamento_enfermedades_enfermedad_id",
                        column: x => x.enfermedad_id,
                        principalTable: "enfermedades",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_enfermedad_medicamento_medicamentos_medicamento_id",
                        column: x => x.medicamento_id,
                        principalTable: "medicamentos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "enfermedad_sintoma",
                columns: table => new
                {
                    enfermedad_id = table.Column<Guid>(type: "uuid", nullable: false),
                    sintoma_id = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_enfermedad_sintoma", x => new { x.enfermedad_id, x.sintoma_id });
                    table.ForeignKey(
                        name: "fk_enfermedad_sintoma_enfermedades_enfermedad_id",
                        column: x => x.enfermedad_id,
                        principalTable: "enfermedades",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_enfermedad_sintoma_sintomas_sintoma_id",
                        column: x => x.sintoma_id,
                        principalTable: "sintomas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "comarcas",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    municipio_id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_comarcas", x => x.id);
                    table.ForeignKey(
                        name: "fk_comarcas_municipios_municipio_id",
                        column: x => x.municipio_id,
                        principalTable: "municipios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "usuarios_app",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    telefono = table.Column<string>(type: "text", nullable: false),
                    nombre = table.Column<string>(type: "text", nullable: false),
                    clave_hash = table.Column<string>(type: "text", nullable: false),
                    municipio_id = table.Column<Guid>(type: "uuid", nullable: false),
                    comarca = table.Column<string>(type: "text", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_usuarios_app", x => x.id);
                    table.ForeignKey(
                        name: "fk_usuarios_app_municipios_municipio_id",
                        column: x => x.municipio_id,
                        principalTable: "municipios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "fincas",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    usuario_app_id = table.Column<Guid>(type: "uuid", nullable: false),
                    municipio_id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "text", nullable: false),
                    comarca = table.Column<string>(type: "text", nullable: false),
                    latitud = table.Column<double>(type: "double precision", nullable: false),
                    longitud = table.Column<double>(type: "double precision", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_fincas", x => x.id);
                    table.ForeignKey(
                        name: "fk_fincas_municipios_municipio_id",
                        column: x => x.municipio_id,
                        principalTable: "municipios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_fincas_usuarios_app_usuario_app_id",
                        column: x => x.usuario_app_id,
                        principalTable: "usuarios_app",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "animales",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    finca_id = table.Column<Guid>(type: "uuid", nullable: false),
                    raza_id = table.Column<Guid>(type: "uuid", nullable: false),
                    identificacion = table.Column<string>(type: "text", nullable: false),
                    sexo = table.Column<int>(type: "integer", nullable: false),
                    fecha_nacimiento = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_animales", x => x.id);
                    table.ForeignKey(
                        name: "fk_animales_fincas_finca_id",
                        column: x => x.finca_id,
                        principalTable: "fincas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_animales_razas_raza_id",
                        column: x => x.raza_id,
                        principalTable: "razas_bovinas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "auditoria_logs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    usuario_app_id = table.Column<Guid>(type: "uuid", nullable: false),
                    finca_id = table.Column<Guid>(type: "uuid", nullable: true),
                    tipo_entidad = table.Column<string>(type: "text", nullable: false),
                    accion = table.Column<string>(type: "text", nullable: false),
                    latitud = table.Column<double>(type: "double precision", nullable: true),
                    longitud = table.Column<double>(type: "double precision", nullable: true),
                    fecha_sincronizacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_auditoria_logs", x => x.id);
                    table.ForeignKey(
                        name: "fk_auditoria_logs_fincas_finca_id",
                        column: x => x.finca_id,
                        principalTable: "fincas",
                        principalColumn: "id");
                    table.ForeignKey(
                        name: "fk_auditoria_logs_usuarios_app_usuario_app_id",
                        column: x => x.usuario_app_id,
                        principalTable: "usuarios_app",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "produccion_leche",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    animal_id = table.Column<Guid>(type: "uuid", nullable: false),
                    fecha = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    jornada = table.Column<int>(type: "integer", nullable: false),
                    volumen_litros = table.Column<decimal>(type: "numeric", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_produccion_leche", x => x.id);
                    table.ForeignKey(
                        name: "fk_produccion_leche_animales_animal_id",
                        column: x => x.animal_id,
                        principalTable: "animales",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "registros_salud",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    animal_id = table.Column<Guid>(type: "uuid", nullable: false),
                    enfermedad_id = table.Column<Guid>(type: "uuid", nullable: false),
                    fecha_deteccion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    observaciones = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_registros_salud", x => x.id);
                    table.ForeignKey(
                        name: "fk_registros_salud_animales_animal_id",
                        column: x => x.animal_id,
                        principalTable: "animales",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_registros_salud_enfermedades_enfermedad_id",
                        column: x => x.enfermedad_id,
                        principalTable: "enfermedades",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "registro_salud_sintomas",
                columns: table => new
                {
                    registro_salud_id = table.Column<Guid>(type: "uuid", nullable: false),
                    sintoma_id = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_registro_salud_sintomas", x => new { x.registro_salud_id, x.sintoma_id });
                    table.ForeignKey(
                        name: "fk_registro_salud_sintomas_registros_salud_registro_salud_id",
                        column: x => x.registro_salud_id,
                        principalTable: "registros_salud",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_registro_salud_sintomas_sintomas_sintoma_id",
                        column: x => x.sintoma_id,
                        principalTable: "sintomas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "tratamientos",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    registro_salud_id = table.Column<Guid>(type: "uuid", nullable: false),
                    medicamento_id = table.Column<Guid>(type: "uuid", nullable: false),
                    dosis_aplicada = table.Column<decimal>(type: "numeric", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_tratamientos", x => x.id);
                    table.ForeignKey(
                        name: "fk_tratamientos_medicamentos_medicamento_id",
                        column: x => x.medicamento_id,
                        principalTable: "medicamentos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_tratamientos_registros_salud_registro_salud_id",
                        column: x => x.registro_salud_id,
                        principalTable: "registros_salud",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_animales_finca_id",
                table: "animales",
                column: "finca_id");

            migrationBuilder.CreateIndex(
                name: "ix_animales_raza_id",
                table: "animales",
                column: "raza_id");

            migrationBuilder.CreateIndex(
                name: "ix_auditoria_logs_finca_id",
                table: "auditoria_logs",
                column: "finca_id");

            migrationBuilder.CreateIndex(
                name: "ix_auditoria_logs_usuario_app_id",
                table: "auditoria_logs",
                column: "usuario_app_id");

            migrationBuilder.CreateIndex(
                name: "ix_comarcas_municipio_id",
                table: "comarcas",
                column: "municipio_id");

            migrationBuilder.CreateIndex(
                name: "ix_enfermedad_medicamento_medicamento_id",
                table: "enfermedad_medicamento",
                column: "medicamento_id");

            migrationBuilder.CreateIndex(
                name: "ix_enfermedad_sintoma_sintoma_id",
                table: "enfermedad_sintoma",
                column: "sintoma_id");

            migrationBuilder.CreateIndex(
                name: "ix_fincas_municipio_id",
                table: "fincas",
                column: "municipio_id");

            migrationBuilder.CreateIndex(
                name: "ix_fincas_usuario_app_id",
                table: "fincas",
                column: "usuario_app_id");

            migrationBuilder.CreateIndex(
                name: "ix_municipios_departamento_id",
                table: "municipios",
                column: "departamento_id");

            migrationBuilder.CreateIndex(
                name: "ix_produccion_leche_animal_id",
                table: "produccion_leche",
                column: "animal_id");

            migrationBuilder.CreateIndex(
                name: "ix_registro_salud_sintomas_sintoma_id",
                table: "registro_salud_sintomas",
                column: "sintoma_id");

            migrationBuilder.CreateIndex(
                name: "ix_registros_salud_animal_id",
                table: "registros_salud",
                column: "animal_id");

            migrationBuilder.CreateIndex(
                name: "ix_registros_salud_enfermedad_id",
                table: "registros_salud",
                column: "enfermedad_id");

            migrationBuilder.CreateIndex(
                name: "ix_tratamientos_medicamento_id",
                table: "tratamientos",
                column: "medicamento_id");

            migrationBuilder.CreateIndex(
                name: "ix_tratamientos_registro_salud_id",
                table: "tratamientos",
                column: "registro_salud_id");

            migrationBuilder.CreateIndex(
                name: "ix_usuarios_app_municipio_id",
                table: "usuarios_app",
                column: "municipio_id");

            migrationBuilder.CreateIndex(
                name: "ix_usuarios_app_telefono",
                table: "usuarios_app",
                column: "telefono",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "auditoria_logs");

            migrationBuilder.DropTable(
                name: "comarcas");

            migrationBuilder.DropTable(
                name: "enfermedad_medicamento");

            migrationBuilder.DropTable(
                name: "enfermedad_sintoma");

            migrationBuilder.DropTable(
                name: "produccion_leche");

            migrationBuilder.DropTable(
                name: "registro_salud_sintomas");

            migrationBuilder.DropTable(
                name: "tratamientos");

            migrationBuilder.DropTable(
                name: "sintomas");

            migrationBuilder.DropTable(
                name: "medicamentos");

            migrationBuilder.DropTable(
                name: "registros_salud");

            migrationBuilder.DropTable(
                name: "animales");

            migrationBuilder.DropTable(
                name: "enfermedades");

            migrationBuilder.DropTable(
                name: "fincas");

            migrationBuilder.DropTable(
                name: "razas_bovinas");

            migrationBuilder.DropTable(
                name: "usuarios_app");

            migrationBuilder.DropTable(
                name: "municipios");

            migrationBuilder.DropTable(
                name: "departamentos");
        }
    }
}

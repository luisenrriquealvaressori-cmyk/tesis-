using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace API.Migrations
{
    /// <inheritdoc />
    public partial class AddRolToUsuarioApp : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Agregar columna rol con valor por defecto 1 (Ganadero)
            migrationBuilder.AddColumn<int>(
                name: "rol",
                table: "usuarios_app",
                type: "integer",
                nullable: false,
                defaultValue: 1);

            // Corregir registros legacy con estado=0 en animales (debe ser 1=Sana)
            migrationBuilder.Sql("UPDATE animales SET estado = 1 WHERE estado = 0;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "rol",
                table: "usuarios_app");
        }
    }
}

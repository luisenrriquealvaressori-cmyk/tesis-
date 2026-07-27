using System;
using System.Collections.Generic;

namespace API.DTOs
{
    public class CrearEnfermedadDto
    {
        public required string Nombre { get; set; }
        public required string Descripcion { get; set; }
        public bool NotificacionObligatoria { get; set; }
        public List<string> Sintomas { get; set; } = new List<string>();
    }

    public class EnfermedadResponseDto
    {
        public Guid Id { get; set; }
        public required string Nombre { get; set; }
        public required string Descripcion { get; set; }
        public bool NotificacionObligatoria { get; set; }
        public List<string> Sintomas { get; set; } = new List<string>();
    }

    public class CrearMedicamentoDto
    {
        public required string NombreComercial { get; set; }
        public string? PrincipioActivo { get; set; }
        public string? ViaAdministracion { get; set; }
        public int DiasRetiroLeche { get; set; }
    }

    public class MedicamentoResponseDto
    {
        public Guid Id { get; set; }
        public required string NombreComercial { get; set; }
        public string? PrincipioActivo { get; set; }
        public string? ViaAdministracion { get; set; }
        public int DiasRetiroLeche { get; set; }
    }

    public class RazaResponseDto
    {
        public Guid Id { get; set; }
        public required string Nombre { get; set; }
        public required string OrigenGenetico { get; set; }
        public int Proposito { get; set; }
        public string? Descripcion { get; set; }
    }

    public class DashboardKpiDto
    {
        public int TotalFincas { get; set; }
        public int TotalVacas { get; set; }
        public double TotalUGM { get; set; }
        public int AlertasMedicas { get; set; }
        public double ProduccionHoyLitros { get; set; }
        public double ProduccionHoyKg { get; set; }
        public double PromedioLitrosVaca { get; set; }
    }

    public class ProduccionTendenciaDto
    {
        public string Fecha { get; set; } = string.Empty;
        public double Litros { get; set; }
        public double Kg { get; set; }
    }

    public class MapaFincaDto
    {
        public Guid Id { get; set; }
        public required string Nombre { get; set; }
        public string GanaderoNombre { get; set; } = string.Empty;
        public string Municipio { get; set; } = string.Empty;
        public string Comarca { get; set; } = string.Empty;
        public double Latitud { get; set; }
        public double Longitud { get; set; }
        public int TotalGanado { get; set; }
        public double TotalUGM { get; set; }
        public bool TieneAlertasSanitarias { get; set; }
        public string? UltimaAlerta { get; set; }
    }

    public class GanaderoAppDto
    {
        public Guid Id { get; set; }
        public required string Nombre { get; set; }
        public required string Telefono { get; set; }
        public string Municipio { get; set; } = string.Empty;
        public string Comarca { get; set; } = string.Empty;
        public int TotalFincas { get; set; }
        public int TotalAnimales { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class AuditoriaSyncDto
    {
        public Guid Id { get; set; }
        public string GanaderoNombre { get; set; } = string.Empty;
        public string? FincaNombre { get; set; }
        public required string TipoEntidad { get; set; }
        public required string Accion { get; set; }
        public double? Latitud { get; set; }
        public double? Longitud { get; set; }
        public DateTime FechaSincronizacion { get; set; }
    }
}

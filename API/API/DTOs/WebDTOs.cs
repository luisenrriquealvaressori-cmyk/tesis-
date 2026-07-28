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

    // ── Módulo: Detalle de Finca ──────────────────────────────────────────────
    public class FincaDetalleDto
    {
        public Guid Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string GanaderoNombre { get; set; } = string.Empty;
        public string GanaderoTelefono { get; set; } = string.Empty;
        public string Municipio { get; set; } = string.Empty;
        public string Comarca { get; set; } = string.Empty;
        public double Latitud { get; set; }
        public double Longitud { get; set; }
        public int TotalAnimales { get; set; }
        public int TotalHembras { get; set; }
        public int TotalMachos { get; set; }
        public int AnimalesEnfermos { get; set; }
        public double TotalUGM { get; set; }
        public double ProduccionHoyLitros { get; set; }
        public double ProduccionHoyKg { get; set; }
        public bool TieneAlertasSanitarias { get; set; }
        public List<AnimalItemDto> Animales { get; set; } = new();
        public List<RegistroSaludItemDto> UltimosSalud { get; set; } = new();
        public List<ProduccionTendenciaDto> Tendencia30Dias { get; set; } = new();
    }

    public class AnimalItemDto
    {
        public Guid Id { get; set; }
        public string Identificacion { get; set; } = string.Empty;
        public string Sexo { get; set; } = string.Empty;
        public string Raza { get; set; } = string.Empty;
        public int EdadMeses { get; set; }
        public string Estado { get; set; } = string.Empty;
        public double Ugm { get; set; }
    }

    public class RegistroSaludItemDto
    {
        public Guid Id { get; set; }
        public string AnimalIdentificacion { get; set; } = string.Empty;
        public string Enfermedad { get; set; } = string.Empty;
        public string? Observaciones { get; set; }
        public DateTime FechaDeteccion { get; set; }
        public List<string> Medicamentos { get; set; } = new();
    }

    // ── Módulo: Animales Global ───────────────────────────────────────────────
    public class AnimalGlobalDto
    {
        public Guid Id { get; set; }
        public string Identificacion { get; set; } = string.Empty;
        public string Finca { get; set; } = string.Empty;
        public Guid FincaId { get; set; }
        public string Ganadero { get; set; } = string.Empty;
        public string Raza { get; set; } = string.Empty;
        public string Sexo { get; set; } = string.Empty;
        public int EdadMeses { get; set; }
        public string Estado { get; set; } = string.Empty;
        public DateTime FechaNacimiento { get; set; }
    }

    // ── Módulo: Reportes ──────────────────────────────────────────────────────
    public class ReporteResumenDto
    {
        public List<ProduccionMensualDto> ProduccionMensual { get; set; } = new();
        public List<EnfermedadFrecuenciaDto> EnfermedadesFrecuentes { get; set; } = new();
        public List<RankingFincaDto> RankingFincas { get; set; } = new();
        public CensoGanaderoDto CensoGanadero { get; set; } = new();
    }

    public class ProduccionMensualDto
    {
        public string Mes { get; set; } = string.Empty;
        public double Litros { get; set; }
        public double Kg { get; set; }
    }

    public class EnfermedadFrecuenciaDto
    {
        public string Enfermedad { get; set; } = string.Empty;
        public int TotalCasos { get; set; }
    }

    public class RankingFincaDto
    {
        public string Finca { get; set; } = string.Empty;
        public string Ganadero { get; set; } = string.Empty;
        public double LitrosTotales { get; set; }
        public int TotalAnimales { get; set; }
    }

    public class CensoGanaderoDto
    {
        public int TotalHembras { get; set; }
        public int TotalMachos { get; set; }
        public int Adultos { get; set; }
        public int Jovenes { get; set; }
        public int Crias { get; set; }
        public List<RazaDistribucionDto> PorRaza { get; set; } = new();
    }

    public class RazaDistribucionDto
    {
        public string Raza { get; set; } = string.Empty;
        public int Total { get; set; }
    }

    // ── Módulo: Usuarios Web ─────────────────────────────────────────────────
    public class UsuarioWebDto
    {
        public Guid Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Rol { get; set; } = string.Empty;
        public string? Cargo { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // ── Módulo: Notificaciones ────────────────────────────────────────────────
    public class AlertaDto
    {
        public string Tipo { get; set; } = string.Empty; // "sanitaria", "sync", "nuevo_ganadero"
        public string Titulo { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
        public DateTime Fecha { get; set; }
        public string? FincaId { get; set; }
    }
}

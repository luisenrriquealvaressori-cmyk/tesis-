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

    public class DashboardKpiDto
    {
        public int TotalFincas { get; set; }
        public int TotalVacas { get; set; }
        public int AlertasMedicas { get; set; }
    }

    public class MapaFincaDto
    {
        public Guid Id { get; set; }
        public required string Nombre { get; set; }
        public double Latitud { get; set; }
        public double Longitud { get; set; }
        public int TotalGanado { get; set; }
        public bool TieneAlertasSanitarias { get; set; }
        public string? UltimaAlerta { get; set; }
    }
}

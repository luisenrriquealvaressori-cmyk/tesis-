using System;
using System.Collections.Generic;

namespace API.Models
{
    // BLOQUE A: Catálogos Maestros (Administrados en la Web)

    public class Departamento
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public required string Nombre { get; set; }

        public ICollection<Municipio> Municipios { get; set; } = new List<Municipio>();
    }

    public class Municipio
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid DepartamentoId { get; set; }
        public required string Nombre { get; set; }

        public Departamento? Departamento { get; set; }
        public ICollection<Comarca> Comarcas { get; set; } = new List<Comarca>();
    }

    public class Comarca
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid MunicipioId { get; set; }
        public required string Nombre { get; set; }

        public Municipio? Municipio { get; set; }
    }

    public class Raza
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public required string Nombre { get; set; }
        public required string OrigenGenetico { get; set; }
        // Enum mapeado a string para mejor legibilidad en la BD, o int si lo prefieres.
        // Aquí se usará int en base de datos.
        public required PropositoRaza Proposito { get; set; } 
        public string? Descripcion { get; set; }
    }

    public enum PropositoRaza
    {
        Leche = 1,
        Carne = 2,
        Doble = 3
    }

    public class Enfermedad
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public required string Nombre { get; set; }
        public required string Descripcion { get; set; }
        public bool NotificacionObligatoria { get; set; }

        public ICollection<EnfermedadSintoma> EnfermedadSintomas { get; set; } = new List<EnfermedadSintoma>();
        public ICollection<EnfermedadMedicamento> EnfermedadMedicamentos { get; set; } = new List<EnfermedadMedicamento>();
    }

    public class Sintoma
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public required string Nombre { get; set; }
        public string? Descripcion { get; set; }

        public ICollection<EnfermedadSintoma> EnfermedadSintomas { get; set; } = new List<EnfermedadSintoma>();
    }

    public class Medicamento
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public required string NombreComercial { get; set; }
        public string? PrincipioActivo { get; set; }
        public string? Tipo { get; set; }
        public string? ViaAdministracion { get; set; }
        public string? DosisSugerida { get; set; }
        public int DiasRetiroLeche { get; set; }

        public ICollection<EnfermedadMedicamento> EnfermedadMedicamentos { get; set; } = new List<EnfermedadMedicamento>();
    }

    public class EnfermedadSintoma
    {
        public Guid EnfermedadId { get; set; }
        public Enfermedad? Enfermedad { get; set; }

        public Guid SintomaId { get; set; }
        public Sintoma? Sintoma { get; set; }
    }

    public class EnfermedadMedicamento
    {
        public Guid EnfermedadId { get; set; }
        public Enfermedad? Enfermedad { get; set; }

        public Guid MedicamentoId { get; set; }
        public Medicamento? Medicamento { get; set; }

        public string? NotasTratamiento { get; set; }
    }
}

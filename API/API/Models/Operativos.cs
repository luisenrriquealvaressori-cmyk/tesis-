using System;
using System.Collections.Generic;

namespace API.Models
{
    public interface IAuditableEntity
    {
        DateTime CreatedAt { get; set; }
        DateTime? UpdatedAt { get; set; }
        bool IsDeleted { get; set; }
    }

    // BLOQUE B: Datos Operativos (Generados en el Móvil)

    public enum RolUsuario
    {
        Ganadero = 1,
        Supervisor = 2,
        Administrador = 3
    }

    public class UsuarioApp : IAuditableEntity
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public required string Telefono { get; set; }
        public required string Nombre { get; set; }
        public required string ClaveHash { get; set; }
        public RolUsuario Rol { get; set; } = RolUsuario.Ganadero;
        
        public Guid MunicipioId { get; set; }
        public required string Comarca { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }

        public Municipio? Municipio { get; set; }
        public ICollection<Finca> Fincas { get; set; } = new List<Finca>();
    }

    public class Finca : IAuditableEntity
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid UsuarioAppId { get; set; }
        public Guid MunicipioId { get; set; }
        public required string Nombre { get; set; }
        public required string Comarca { get; set; }
        public double Latitud { get; set; }
        public double Longitud { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }

        public UsuarioApp? UsuarioApp { get; set; }
        public Municipio? Municipio { get; set; }
        public ICollection<Animal> Animales { get; set; } = new List<Animal>();
    }

    public class Animal : IAuditableEntity
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid FincaId { get; set; }
        public Guid RazaId { get; set; }
        public required string Identificacion { get; set; }
        public required SexoAnimal Sexo { get; set; }
        public DateTime FechaNacimiento { get; set; }
        public EstadoSalud Estado { get; set; } = EstadoSalud.Sana;

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }

        public Finca? Finca { get; set; }
        public Raza? Raza { get; set; }
    }

    public enum SexoAnimal
    {
        Hembra = 1,
        Macho = 2
    }

    public enum EstadoSalud
    {
        Sana = 1,
        Enferma = 2,
        EnTratamiento = 3
    }

    public class ProduccionLeche : IAuditableEntity
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid AnimalId { get; set; }
        public DateTime Fecha { get; set; }
        public JornadaOrdeno Jornada { get; set; }
        public decimal VolumenLitros { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }

        public Animal? Animal { get; set; }
    }

    public enum JornadaOrdeno
    {
        AM = 1,
        PM = 2
    }

    public class RegistroSalud
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid AnimalId { get; set; }
        public Guid EnfermedadId { get; set; }
        public DateTime FechaDeteccion { get; set; }
        public string? Observaciones { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }

        public Animal? Animal { get; set; }
        public Enfermedad? Enfermedad { get; set; }

        public ICollection<RegistroSaludSintoma> SintomasPresentados { get; set; } = new List<RegistroSaludSintoma>();
        public ICollection<Tratamiento> Tratamientos { get; set; } = new List<Tratamiento>();
    }

    public class AuditoriaSync
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid UsuarioAppId { get; set; }
        public Guid? FincaId { get; set; }
        public required string TipoEntidad { get; set; } // "Animal", "RegistroSalud", etc.
        public required string Accion { get; set; } // "Insert", "Update", "Delete"
        public double? Latitud { get; set; }
        public double? Longitud { get; set; }
        public DateTime FechaSincronizacion { get; set; } = DateTime.UtcNow;

        public UsuarioApp? UsuarioApp { get; set; }
        public Finca? Finca { get; set; }
    }

    // Tabla Intermedia M:N manual para facilitar inserciones
    public class RegistroSaludSintoma
    {
        public Guid RegistroSaludId { get; set; }
        public Guid SintomaId { get; set; }

        public RegistroSalud? RegistroSalud { get; set; }
        public Sintoma? Sintoma { get; set; }
    }

    public class Tratamiento
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid RegistroSaludId { get; set; }
        public Guid MedicamentoId { get; set; }
        public decimal DosisAplicada { get; set; }

        public RegistroSalud? RegistroSalud { get; set; }
        public Medicamento? Medicamento { get; set; }
    }
}

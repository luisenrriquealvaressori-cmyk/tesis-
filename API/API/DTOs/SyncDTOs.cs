using System;
using System.Collections.Generic;
using API.Models;

namespace API.DTOs
{
    public class SyncPullResponse
    {
        public IEnumerable<Departamento> Departamentos { get; set; } = new List<Departamento>();
        public IEnumerable<Municipio>    Municipios    { get; set; } = new List<Municipio>();
        public IEnumerable<Comarca>      Comarcas      { get; set; } = new List<Comarca>();
        public IEnumerable<Raza>         Razas         { get; set; } = new List<Raza>();
        public IEnumerable<Enfermedad>   Enfermedades  { get; set; } = new List<Enfermedad>();
        public IEnumerable<Sintoma>      Sintomas      { get; set; } = new List<Sintoma>();
        public IEnumerable<Medicamento>  Medicamentos  { get; set; } = new List<Medicamento>();
    }

    public class SyncPushRequest
    {
        public Guid UsuarioId { get; set; }
        public List<FincaPushDto> FincasNuevas { get; set; } = new List<FincaPushDto>();
        public List<AnimalPushDto> AnimalesNuevos { get; set; } = new List<AnimalPushDto>();
        public List<ProduccionLechePushDto> ProduccionLecheNuevos { get; set; } = new List<ProduccionLechePushDto>();
        public List<RegistroSaludPushDto> RegistrosSaludNuevos { get; set; } = new List<RegistroSaludPushDto>();
    }

    public class FincaPushDto
    {
        public Guid Id { get; set; }
        public Guid MunicipioId { get; set; }
        public required string Nombre { get; set; }
        public required string Comarca { get; set; }
        public double Lat { get; set; }
        public double Lng { get; set; }
    }

    public class AnimalPushDto
    {
        public Guid Id { get; set; }
        public Guid FincaId { get; set; }
        public Guid RazaId { get; set; }
        public required string Identificacion { get; set; }
        public SexoAnimal Sexo { get; set; }
        public DateTime FechaNacimiento { get; set; }
        public EstadoSalud Estado { get; set; }
    }

    public class ProduccionLechePushDto
    {
        public Guid Id { get; set; }
        public Guid AnimalId { get; set; }
        public DateTime Fecha { get; set; }
        public JornadaOrdeno Jornada { get; set; }
        public decimal VolumenLitros { get; set; }
    }

    public class RegistroSaludPushDto
    {
        public Guid Id { get; set; }
        public Guid AnimalId { get; set; }
        public Guid EnfermedadId { get; set; }
        public DateTime FechaDeteccion { get; set; }
        public string? Observaciones { get; set; }
        
        public List<Guid> SintomasIdsMarcados { get; set; } = new List<Guid>();
        public List<TratamientoPushDto> TratamientosNuevos { get; set; } = new List<TratamientoPushDto>();
    }

    public class TratamientoPushDto
    {
        public Guid Id { get; set; }
        public Guid MedicamentoId { get; set; }
        public decimal Dosis { get; set; }
    }

    // =========================================================================
    // DTOs de respuesta: Descarga de datos propios del usuario (Pull User Data)
    // =========================================================================

    /// Respuesta al endpoint GET /api/sync/pull-user-data
    /// Contiene todos los datos operativos del usuario autenticado.
    public class UserDataPullResponse
    {
        public List<FincaPullDto> Fincas { get; set; } = new();
        public List<AnimalPullDto> Animales { get; set; } = new();
        public List<ProduccionLechePullDto> Produccion { get; set; } = new();
    }

    public class FincaPullDto
    {
        public Guid Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public Guid MunicipioId { get; set; }
        public string Comarca { get; set; } = string.Empty;
        public double Latitud { get; set; }
        public double Longitud { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class AnimalPullDto
    {
        public Guid Id { get; set; }
        public Guid FincaId { get; set; }
        public Guid RazaId { get; set; }
        public string Identificacion { get; set; } = string.Empty;
        public int Sexo { get; set; }
        public DateTime FechaNacimiento { get; set; }
        public int Estado { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class ProduccionLechePullDto
    {
        public Guid Id { get; set; }
        public Guid AnimalId { get; set; }
        public DateTime Fecha { get; set; }
        public int Jornada { get; set; }
        public decimal VolumenLitros { get; set; }
    }
}

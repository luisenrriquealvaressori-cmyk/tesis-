using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Authorization;
using API.Data;
using API.Models;
using API.DTOs;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class SyncController : ControllerBase
    {
        private readonly AgroDbContext _context;
        private readonly ILogger<SyncController> _logger;

        public SyncController(AgroDbContext context, ILogger<SyncController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [AllowAnonymous]
        [HttpGet("pull")]
        public async Task<ActionResult<SyncPullResponse>> Pull()
        {
            var response = new SyncPullResponse
            {
                Departamentos = await _context.Departamentos.AsNoTracking()
                    .Select(d => new DepartamentoCatalogDto { Id = d.Id, Nombre = d.Nombre })
                    .ToListAsync(),
                Municipios = await _context.Municipios.AsNoTracking()
                    .Select(m => new MunicipioCatalogDto { Id = m.Id, DepartamentoId = m.DepartamentoId, Nombre = m.Nombre })
                    .ToListAsync(),
                Comarcas = await _context.Comarcas.AsNoTracking()
                    .Select(c => new ComarcaCatalogDto { Id = c.Id, MunicipioId = c.MunicipioId, Nombre = c.Nombre })
                    .ToListAsync(),
                Razas = await _context.Razas.AsNoTracking()
                    .Select(r => new RazaCatalogDto { Id = r.Id, Nombre = r.Nombre, OrigenGenetico = r.OrigenGenetico, Proposito = (int)r.Proposito, Descripcion = r.Descripcion })
                    .ToListAsync(),
                Enfermedades = await _context.Enfermedades.AsNoTracking()
                    .Select(e => new EnfermedadCatalogDto { Id = e.Id, Nombre = e.Nombre, Descripcion = e.Descripcion, NotificacionObligatoria = e.NotificacionObligatoria })
                    .ToListAsync(),
                Sintomas = await _context.Sintomas.AsNoTracking()
                    .Select(s => new SintomaCatalogDto { Id = s.Id, Nombre = s.Nombre })
                    .ToListAsync(),
                Medicamentos = await _context.Medicamentos.AsNoTracking()
                    .Select(m => new MedicamentoCatalogDto { Id = m.Id, NombreComercial = m.NombreComercial, PrincipioActivo = m.PrincipioActivo, ViaAdministracion = m.ViaAdministracion, DiasRetiroLeche = m.DiasRetiroLeche })
                    .ToListAsync()
            };

            return Ok(response);
        }

        /// <summary>
        /// Descarga todos los datos operativos del usuario autenticado.
        /// Usado cuando el usuario inicia sesión en un teléfono nuevo o reinstala la app.
        /// El usuarioId se extrae del JWT (no del body) para garantizar aislamiento.
        /// La producción de leche se limita a los últimos 60 días para evitar payloads enormes.
        /// </summary>
        [HttpGet("pull-user-data")]
        public async Task<ActionResult<UserDataPullResponse>> PullUserData()
        {
            // Extraer usuarioId del JWT - garantiza que solo se devuelven datos propios
            var usuarioIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier)
                               ?? User.FindFirstValue("sub");

            if (string.IsNullOrEmpty(usuarioIdStr) || !Guid.TryParse(usuarioIdStr, out var usuarioId))
                return Unauthorized(new { error = "Token inválido o sin usuario identificado." });

            // Fincas del usuario
            var fincas = await _context.Fincas
                .Where(f => f.UsuarioAppId == usuarioId && !f.IsDeleted)
                .AsNoTracking()
                .ToListAsync();

            var fincaIds = fincas.Select(f => f.Id).ToList();

            // Animales de sus fincas
            var animales = await _context.Animales
                .Where(a => fincaIds.Contains(a.FincaId) && !a.IsDeleted)
                .AsNoTracking()
                .ToListAsync();

            var animalIds = animales.Select(a => a.Id).ToList();

            // Producción de los últimos 60 días (evitar payloads enormes)
            var desde = DateTime.UtcNow.AddDays(-60);
            var produccion = await _context.ProduccionLeche
                .Where(p => animalIds.Contains(p.AnimalId) && p.Fecha >= desde && !p.IsDeleted)
                .AsNoTracking()
                .ToListAsync();

            // Registros Reproductivos
            var reproduccion = await _context.RegistrosReproductivos
                .Where(r => animalIds.Contains(r.AnimalId) && !r.IsDeleted)
                .AsNoTracking()
                .ToListAsync();

            var response = new UserDataPullResponse
            {
                Fincas = fincas.Select(f => new FincaPullDto
                {
                    Id = f.Id,
                    Nombre = f.Nombre,
                    MunicipioId = f.MunicipioId,
                    Comarca = f.Comarca,
                    Latitud = f.Latitud,
                    Longitud = f.Longitud,
                    CreatedAt = f.CreatedAt
                }).ToList(),

                Animales = animales.Select(a => new AnimalPullDto
                {
                    Id = a.Id,
                    FincaId = a.FincaId,
                    RazaId = a.RazaId,
                    Identificacion = a.Identificacion,
                    Sexo = (int)a.Sexo,
                    FechaNacimiento = a.FechaNacimiento,
                    Estado = (int)a.Estado,
                    CreatedAt = a.CreatedAt
                }).ToList(),

                Produccion = produccion.Select(p => new ProduccionLechePullDto
                {
                    Id = p.Id,
                    AnimalId = p.AnimalId,
                    Fecha = p.Fecha,
                    Jornada = (int)p.Jornada,
                    VolumenLitros = p.VolumenLitros
                }).ToList(),

                Reproduccion = reproduccion.Select(r => new RegistroReproductivoPullDto
                {
                    Id = r.Id,
                    AnimalId = r.AnimalId,
                    TipoEvento = r.TipoEvento,
                    FechaEvento = r.FechaEvento,
                    ToroId = r.ToroId,
                    Observaciones = r.Observaciones
                }).ToList()
            };

            return Ok(response);
        }

        [HttpPost("push")]
        public async Task<IActionResult> Push([FromBody] SyncPushRequest request)
        {
            // CRÍTICO: Usar el usuarioId del JWT, nunca del body del request.
            // El body puede ser manipulado por un cliente malicioso;
            // el JWT es firmado y verificado por el servidor.
            var usuarioIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier)
                               ?? User.FindFirstValue("sub");

            if (string.IsNullOrEmpty(usuarioIdStr) || !Guid.TryParse(usuarioIdStr, out var usuarioIdJwt))
                return Unauthorized(new { error = "Token inválido o sin usuario identificado." });

            // Validar que ninguna finca del request le pertenezca a OTRO usuario.
            // Previene que un ganadero inyecte datos en la finca de otro ganadero.
            var fincasIds = request.FincasNuevas.Select(f => f.Id).ToList();
            if (fincasIds.Any())
            {
                var fincasAjenas = await _context.Fincas
                    .Where(f => fincasIds.Contains(f.Id) && f.UsuarioAppId != usuarioIdJwt)
                    .AnyAsync();

                if (fincasAjenas)
                    return Conflict(new { error = "Conflicto de propiedad: uno o más IDs de finca pertenecen a otro usuario." });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // PRE-FETCH FINCAS
                var existingFincas = await _context.Fincas.Where(f => fincasIds.Contains(f.Id)).ToDictionaryAsync(f => f.Id);

                foreach (var fDto in request.FincasNuevas)
                {
                    if (!existingFincas.TryGetValue(fDto.Id, out var existing))
                    {
                        _context.Fincas.Add(new Finca
                        {
                            Id = fDto.Id,
                            UsuarioAppId = usuarioIdJwt,
                            MunicipioId = fDto.MunicipioId,
                            Nombre = fDto.Nombre,
                            Comarca = fDto.Comarca,
                            Latitud = fDto.Lat,
                            Longitud = fDto.Lng
                        });
                        
                        _context.AuditoriaLogs.Add(new AuditoriaSync {
                            UsuarioAppId = usuarioIdJwt,
                            FincaId = fDto.Id,
                            TipoEntidad = "Finca",
                            Accion = "Insert",
                            Latitud = fDto.Lat,
                            Longitud = fDto.Lng
                        });
                    }
                    else
                    {
                        existing.Nombre = fDto.Nombre;
                        existing.Comarca = fDto.Comarca;
                        existing.Latitud = fDto.Lat;
                        existing.Longitud = fDto.Lng;
                        
                        _context.AuditoriaLogs.Add(new AuditoriaSync {
                            UsuarioAppId = usuarioIdJwt,
                            FincaId = existing.Id,
                            TipoEntidad = "Finca",
                            Accion = "Update",
                            Latitud = fDto.Lat,
                            Longitud = fDto.Lng
                        });
                    }
                }

                // PRE-FETCH ANIMALES
                var animalesIds = request.AnimalesNuevos.Select(a => a.Id).ToList();
                var existingAnimales = await _context.Animales.Where(a => animalesIds.Contains(a.Id)).ToDictionaryAsync(a => a.Id);

                foreach (var aDto in request.AnimalesNuevos)
                {
                    if (!existingAnimales.TryGetValue(aDto.Id, out var existing))
                    {
                        _context.Animales.Add(new Animal
                        {
                            Id = aDto.Id,
                            FincaId = aDto.FincaId,
                            RazaId = aDto.RazaId,
                            Identificacion = aDto.Identificacion,
                            Sexo = aDto.Sexo,
                            FechaNacimiento = aDto.FechaNacimiento,
                            Estado = aDto.Estado
                        });
                    }
                    else
                    {
                        existing.RazaId = aDto.RazaId;
                        existing.Identificacion = aDto.Identificacion;
                        existing.Sexo = aDto.Sexo;
                        existing.FechaNacimiento = aDto.FechaNacimiento;
                        existing.Estado = aDto.Estado;
                    }
                }

                // PRE-FETCH PRODUCCION LECHE
                var produccionIds = request.ProduccionLecheNuevos.Select(p => p.Id).ToList();
                var existingProduccion = await _context.ProduccionLeche.Where(p => produccionIds.Contains(p.Id)).ToDictionaryAsync(p => p.Id);

                foreach (var pDto in request.ProduccionLecheNuevos)
                {
                    if (!existingProduccion.TryGetValue(pDto.Id, out var existing))
                    {
                        _context.ProduccionLeche.Add(new ProduccionLeche
                        {
                            Id = pDto.Id,
                            AnimalId = pDto.AnimalId,
                            Fecha = pDto.Fecha,
                            Jornada = pDto.Jornada,
                            VolumenLitros = pDto.VolumenLitros
                        });
                    }
                    else
                    {
                        existing.Fecha = pDto.Fecha;
                        existing.Jornada = pDto.Jornada;
                        existing.VolumenLitros = pDto.VolumenLitros;
                    }
                }

                // PRE-FETCH REGISTROS SALUD
                var rsIds = request.RegistrosSaludNuevos.Select(rs => rs.Id).ToList();
                var existingRS = await _context.RegistrosSalud
                    .Include(rs => rs.SintomasPresentados)
                    .Include(rs => rs.Tratamientos)
                    .Where(rs => rsIds.Contains(rs.Id))
                    .ToDictionaryAsync(rs => rs.Id);

                foreach (var rsDto in request.RegistrosSaludNuevos)
                {
                    if (!existingRS.TryGetValue(rsDto.Id, out var existing))
                    {
                        var nuevoRegistro = new RegistroSalud
                        {
                            Id = rsDto.Id,
                            AnimalId = rsDto.AnimalId,
                            EnfermedadId = rsDto.EnfermedadId,
                            FechaDeteccion = rsDto.FechaDeteccion,
                            Observaciones = rsDto.Observaciones
                        };
                        _context.RegistrosSalud.Add(nuevoRegistro);

                        foreach (var sintomaId in rsDto.SintomasIdsMarcados)
                        {
                            _context.RegistroSaludSintomas.Add(new RegistroSaludSintoma
                            {
                                RegistroSaludId = rsDto.Id,
                                SintomaId = sintomaId
                            });
                        }

                        foreach (var tDto in rsDto.TratamientosNuevos)
                        {
                            _context.Tratamientos.Add(new Tratamiento
                            {
                                Id = tDto.Id,
                                RegistroSaludId = rsDto.Id,
                                MedicamentoId = tDto.MedicamentoId,
                                DosisAplicada = tDto.Dosis
                            });
                        }
                        
                        var fincaDelAnimal = await _context.Animales
                            .Where(a => a.Id == rsDto.AnimalId)
                            .Select(a => (Guid?)a.FincaId)
                            .FirstOrDefaultAsync();
                        _context.AuditoriaLogs.Add(new AuditoriaSync {
                            UsuarioAppId = usuarioIdJwt,
                            FincaId = fincaDelAnimal,
                            TipoEntidad = "RegistroSalud",
                            Accion = "Insert"
                        });
                    }
                    else
                    {
                        existing.FechaDeteccion = rsDto.FechaDeteccion;
                        existing.Observaciones = rsDto.Observaciones;

                        _context.RegistroSaludSintomas.RemoveRange(existing.SintomasPresentados);
                        foreach (var sintomaId in rsDto.SintomasIdsMarcados)
                        {
                            _context.RegistroSaludSintomas.Add(new RegistroSaludSintoma
                            {
                                RegistroSaludId = existing.Id,
                                SintomaId = sintomaId
                            });
                        }

                        _context.Tratamientos.RemoveRange(existing.Tratamientos);
                        foreach (var tDto in rsDto.TratamientosNuevos)
                        {
                            _context.Tratamientos.Add(new Tratamiento
                            {
                                Id = tDto.Id,
                                RegistroSaludId = existing.Id,
                                MedicamentoId = tDto.MedicamentoId,
                                DosisAplicada = tDto.Dosis
                            });
                        }
                        
                        _context.AuditoriaLogs.Add(new AuditoriaSync {
                            UsuarioAppId = usuarioIdJwt,
                            FincaId = existing.Animal?.FincaId,
                            TipoEntidad = "RegistroSalud",
                            Accion = "Update"
                        });
                    }
                }

                // PRE-FETCH REGISTROS REPRODUCTIVOS
                var rrIds = request.RegistrosReproductivosNuevos.Select(r => r.Id).ToList();
                var existingRR = await _context.RegistrosReproductivos.Where(r => rrIds.Contains(r.Id)).ToDictionaryAsync(r => r.Id);

                foreach (var rrDto in request.RegistrosReproductivosNuevos)
                {
                    if (!existingRR.TryGetValue(rrDto.Id, out var existing))
                    {
                        _context.RegistrosReproductivos.Add(new RegistroReproductivo
                        {
                            Id = rrDto.Id,
                            AnimalId = rrDto.AnimalId,
                            TipoEvento = rrDto.TipoEvento,
                            FechaEvento = rrDto.FechaEvento,
                            ToroId = rrDto.ToroId,
                            Observaciones = rrDto.Observaciones
                        });
                        
                        var fincaDelAnimal = await _context.Animales
                            .Where(a => a.Id == rrDto.AnimalId)
                            .Select(a => (Guid?)a.FincaId)
                            .FirstOrDefaultAsync();
                        _context.AuditoriaLogs.Add(new AuditoriaSync {
                            UsuarioAppId = usuarioIdJwt,
                            FincaId = fincaDelAnimal,
                            TipoEntidad = "RegistroReproductivo",
                            Accion = "Insert"
                        });
                    }
                    else
                    {
                        existing.TipoEvento = rrDto.TipoEvento;
                        existing.FechaEvento = rrDto.FechaEvento;
                        existing.ToroId = rrDto.ToroId;
                        existing.Observaciones = rrDto.Observaciones;
                        
                        _context.AuditoriaLogs.Add(new AuditoriaSync {
                            UsuarioAppId = usuarioIdJwt,
                            FincaId = existing.Animal?.FincaId,
                            TipoEntidad = "RegistroReproductivo",
                            Accion = "Update"
                        });
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                
                return Ok(new { message = "Sincronización exitosa." });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                var errorMsg = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                _logger.LogError(ex, "Fallo en sincronización. Detalle: {Error}", errorMsg);
                return StatusCode(500, new { error = "Fallo en sincronización", detail = errorMsg });
            }
        }
    }
}

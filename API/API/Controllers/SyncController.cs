using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
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

        [HttpGet("pull")]
        public async Task<ActionResult<SyncPullResponse>> Pull()
        {
            var response = new SyncPullResponse
            {
                Departamentos = await _context.Departamentos.AsNoTracking().ToListAsync(),
                Municipios    = await _context.Municipios.AsNoTracking().ToListAsync(),
                Comarcas      = await _context.Comarcas.AsNoTracking().ToListAsync(),
                Razas         = await _context.Razas.AsNoTracking().ToListAsync(),
                Enfermedades  = await _context.Enfermedades.AsNoTracking().ToListAsync(),
                Sintomas      = await _context.Sintomas.AsNoTracking().ToListAsync(),
                Medicamentos  = await _context.Medicamentos.AsNoTracking().ToListAsync()
            };

            return Ok(response);
        }

        [HttpPost("push")]
        public async Task<IActionResult> Push([FromBody] SyncPushRequest request)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                // PRE-FETCH FINCAS
                var fincasIds = request.FincasNuevas.Select(f => f.Id).ToList();
                var existingFincas = await _context.Fincas.Where(f => fincasIds.Contains(f.Id)).ToDictionaryAsync(f => f.Id);

                foreach (var fDto in request.FincasNuevas)
                {
                    if (!existingFincas.TryGetValue(fDto.Id, out var existing))
                    {
                        _context.Fincas.Add(new Finca
                        {
                            Id = fDto.Id,
                            UsuarioAppId = request.UsuarioId,
                            MunicipioId = fDto.MunicipioId,
                            Nombre = fDto.Nombre,
                            Comarca = fDto.Comarca,
                            Latitud = fDto.Lat,
                            Longitud = fDto.Lng
                        });
                        
                        _context.AuditoriaLogs.Add(new AuditoriaSync {
                            UsuarioAppId = request.UsuarioId,
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
                            UsuarioAppId = request.UsuarioId,
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
                        
                        _context.AuditoriaLogs.Add(new AuditoriaSync {
                            UsuarioAppId = request.UsuarioId,
                            FincaId = request.FincasNuevas.FirstOrDefault()?.Id,
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
                            UsuarioAppId = request.UsuarioId,
                            FincaId = existing.Animal?.FincaId,
                            TipoEntidad = "RegistroSalud",
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

using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API.Data;
using API.Models;
using API.DTOs;
using Microsoft.AspNetCore.Authorization;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CatalogosController : ControllerBase
    {
        private readonly AgroDbContext _context;

        public CatalogosController(AgroDbContext context)
        {
            _context = context;
        }

        [HttpGet("enfermedades")]
        public async Task<IActionResult> GetEnfermedades()
        {
            var enfermedades = await _context.Enfermedades
                .Include(e => e.EnfermedadSintomas)
                    .ThenInclude(es => es.Sintoma)
                .OrderBy(e => e.Nombre)
                .Select(e => new EnfermedadResponseDto
                {
                    Id = e.Id,
                    Nombre = e.Nombre,
                    Descripcion = e.Descripcion,
                    NotificacionObligatoria = e.NotificacionObligatoria,
                    Sintomas = e.EnfermedadSintomas.Select(es => es.Sintoma!.Nombre).ToList()
                })
                .ToListAsync();

            return Ok(enfermedades);
        }

        [HttpPost("enfermedades")]
        public async Task<IActionResult> CrearEnfermedad([FromBody] CrearEnfermedadDto dto)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var nuevaEnfermedad = new Enfermedad
                {
                    Id = Guid.NewGuid(),
                    Nombre = dto.Nombre,
                    Descripcion = dto.Descripcion,
                    NotificacionObligatoria = dto.NotificacionObligatoria
                };

                _context.Enfermedades.Add(nuevaEnfermedad);

                foreach (var nombreSintoma in dto.Sintomas)
                {
                    if (!string.IsNullOrWhiteSpace(nombreSintoma))
                    {
                        var sintomaNombre = nombreSintoma.Trim();
                        var sintoma = await _context.Sintomas.FirstOrDefaultAsync(s => s.Nombre == sintomaNombre);
                        
                        if (sintoma == null)
                        {
                            sintoma = new Sintoma
                            {
                                Id = Guid.NewGuid(),
                                Nombre = sintomaNombre
                            };
                            _context.Sintomas.Add(sintoma);
                        }

                        _context.EnfermedadSintomas.Add(new EnfermedadSintoma
                        {
                            EnfermedadId = nuevaEnfermedad.Id,
                            SintomaId = sintoma.Id
                        });
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Enfermedad y síntomas creados correctamente." });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { error = "Fallo al crear la enfermedad", detail = ex.Message });
            }
        }

        [HttpGet("medicamentos")]
        public async Task<IActionResult> GetMedicamentos()
        {
            var medicamentos = await _context.Medicamentos
                .OrderBy(m => m.NombreComercial)
                .Select(m => new MedicamentoResponseDto
                {
                    Id = m.Id,
                    NombreComercial = m.NombreComercial,
                    PrincipioActivo = m.PrincipioActivo,
                    ViaAdministracion = m.ViaAdministracion,
                    DiasRetiroLeche = m.DiasRetiroLeche
                })
                .ToListAsync();

            return Ok(medicamentos);
        }

        [HttpPost("medicamentos")]
        public async Task<IActionResult> CrearMedicamento([FromBody] CrearMedicamentoDto dto)
        {
            var med = new Medicamento
            {
                Id = Guid.NewGuid(),
                NombreComercial = dto.NombreComercial.Trim(),
                PrincipioActivo = dto.PrincipioActivo?.Trim(),
                ViaAdministracion = dto.ViaAdministracion?.Trim() ?? "Inyectable",
                DiasRetiroLeche = dto.DiasRetiroLeche
            };

            _context.Medicamentos.Add(med);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Medicamento registrado correctamente.", id = med.Id });
        }

        [HttpGet("razas")]
        public async Task<IActionResult> GetRazas()
        {
            var razas = await _context.Razas
                .OrderBy(r => r.Nombre)
                .Select(r => new RazaResponseDto
                {
                    Id = r.Id,
                    Nombre = r.Nombre,
                    OrigenGenetico = r.OrigenGenetico,
                    Proposito = (int)r.Proposito,
                    Descripcion = r.Descripcion
                })
                .ToListAsync();

            return Ok(razas);
        }
    }
}

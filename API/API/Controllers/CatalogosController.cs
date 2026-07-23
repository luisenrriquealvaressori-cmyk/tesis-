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
    }
}

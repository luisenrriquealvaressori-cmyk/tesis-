using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using API.Data;
using API.DTOs;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")] // Solo para la web (Admin)
    public class ReproduccionController : ControllerBase
    {
        private readonly AgroDbContext _context;

        public ReproduccionController(AgroDbContext context)
        {
            _context = context;
        }

        [HttpGet("finca/{fincaId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetByFinca(Guid fincaId)
        {
            var registros = await _context.RegistrosReproductivos
                .Include(r => r.Animal)
                .Where(r => r.Animal != null && r.Animal.FincaId == fincaId && !r.IsDeleted)
                .OrderByDescending(r => r.FechaEvento)
                .Select(r => new
                {
                    r.Id,
                    r.AnimalId,
                    AnimalNombre = r.Animal!.Identificacion,
                    r.TipoEvento,
                    r.FechaEvento,
                    r.ToroId,
                    r.Observaciones
                })
                .ToListAsync();

            return Ok(registros);
        }
    }
}

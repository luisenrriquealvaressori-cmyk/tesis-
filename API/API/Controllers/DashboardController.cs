using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API.Data;
using API.DTOs;
using Microsoft.AspNetCore.Authorization;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DashboardController : ControllerBase
    {
        private readonly AgroDbContext _context;

        public DashboardController(AgroDbContext context)
        {
            _context = context;
        }

        [HttpGet("kpis")]
        public async Task<IActionResult> GetKpis()
        {
            var totalFincas = await _context.Fincas.CountAsync();
            var totalVacas = await _context.Animales.CountAsync();

            var hace72Horas = DateTime.UtcNow.AddHours(-72);
            var alertasMedicas = await _context.RegistrosSalud
                .Where(r => r.FechaDeteccion >= hace72Horas)
                .CountAsync();

            return Ok(new DashboardKpiDto
            {
                TotalFincas = totalFincas,
                TotalVacas = totalVacas,
                AlertasMedicas = alertasMedicas
            });
        }

        [HttpGet("mapa-fincas")]
        public async Task<IActionResult> GetMapaFincas()
        {
            var hace7Dias = DateTime.UtcNow.AddDays(-7);

            var fincasData = await _context.Fincas
                .Include(f => f.Animales)
                .Select(f => new MapaFincaDto
                {
                    Id = f.Id,
                    Nombre = f.Nombre,
                    Latitud = f.Latitud,
                    Longitud = f.Longitud,
                    TotalGanado = f.Animales.Count,
                    // Subquery para verificar alertas sanitarias en los últimos 7 días
                    TieneAlertasSanitarias = _context.RegistrosSalud
                        .Any(rs => rs.Animal!.FincaId == f.Id && rs.FechaDeteccion >= hace7Dias),
                    UltimaAlerta = _context.RegistrosSalud
                        .Where(rs => rs.Animal!.FincaId == f.Id)
                        .OrderByDescending(rs => rs.FechaDeteccion)
                        .Select(rs => rs.Enfermedad!.Nombre)
                        .FirstOrDefault()
                })
                .ToListAsync();

            return Ok(fincasData);
        }
    }
}

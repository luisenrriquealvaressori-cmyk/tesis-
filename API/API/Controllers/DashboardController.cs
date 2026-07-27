using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API.Data;
using API.DTOs;
using API.Models;
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
            var animales = await _context.Animales.ToListAsync();
            var totalVacas = animales.Count;

            // Cálculo UGM total en la BD
            var ahora = DateTime.UtcNow;
            double totalUGM = 0;
            foreach (var a in animales)
            {
                var edadMeses = ((ahora - a.FechaNacimiento).TotalDays / 30.44);
                if (edadMeses >= 24)
                {
                    totalUGM += a.Sexo == SexoAnimal.Macho ? 1.2 : 1.0;
                }
                else if (edadMeses >= 12)
                {
                    totalUGM += 0.7;
                }
                else
                {
                    totalUGM += 0.4;
                }
            }

            var hace72Horas = DateTime.UtcNow.AddHours(-72);
            var alertasMedicas = await _context.RegistrosSalud
                .Where(r => r.FechaDeteccion >= hace72Horas)
                .CountAsync();

            var hoyUtc = DateTime.UtcNow.Date;
            var produccionHoy = await _context.ProduccionLeche
                .Where(p => p.Fecha >= hoyUtc)
                .ToListAsync();

            var litrosHoy = (double)produccionHoy.Sum(p => p.VolumenLitros);
            var kgHoy = Math.Round(litrosHoy * 1.032, 1);

            var vacasOrdenadasHoy = produccionHoy.Select(p => p.AnimalId).Distinct().Count();
            var promedioLitrosVaca = vacasOrdenadasHoy > 0 ? Math.Round(litrosHoy / vacasOrdenadasHoy, 1) : 0.0;

            return Ok(new DashboardKpiDto
            {
                TotalFincas = totalFincas,
                TotalVacas = totalVacas,
                TotalUGM = Math.Round(totalUGM, 1),
                AlertasMedicas = alertasMedicas,
                ProduccionHoyLitros = litrosHoy,
                ProduccionHoyKg = kgHoy,
                PromedioLitrosVaca = promedioLitrosVaca
            });
        }

        [HttpGet("produccion-tendencia")]
        public async Task<IActionResult> GetProduccionTendencia()
        {
            var hace7Dias = DateTime.UtcNow.Date.AddDays(-6);
            var producciones = await _context.ProduccionLeche
                .Where(p => p.Fecha >= hace7Dias)
                .ToListAsync();

            var result = new List<ProduccionTendenciaDto>();
            for (int i = 0; i < 7; i++)
            {
                var targetDate = hace7Dias.AddDays(i);
                var prodDia = producciones.Where(p => p.Fecha.Date == targetDate.Date).Sum(p => (double)p.VolumenLitros);
                result.Add(new ProduccionTendenciaDto
                {
                    Fecha = targetDate.ToString("dd/MM"),
                    Litros = Math.Round(prodDia, 1),
                    Kg = Math.Round(prodDia * 1.032, 1)
                });
            }

            return Ok(result);
        }

        [HttpGet("mapa-fincas")]
        public async Task<IActionResult> GetMapaFincas()
        {
            var hace7Dias = DateTime.UtcNow.AddDays(-7);

            var fincasData = await _context.Fincas
                .Include(f => f.UsuarioApp)
                .Include(f => f.Municipio)
                .Include(f => f.Animales)
                .Select(f => new MapaFincaDto
                {
                    Id = f.Id,
                    Nombre = f.Nombre,
                    GanaderoNombre = f.UsuarioApp != null ? f.UsuarioApp.Nombre : "No asignado",
                    Municipio = f.Municipio != null ? f.Municipio.Nombre : "",
                    Comarca = f.Comarca,
                    Latitud = f.Latitud,
                    Longitud = f.Longitud,
                    TotalGanado = f.Animales.Count,
                    TotalUGM = Math.Round(f.Animales.Sum(a =>
                        ((DateTime.UtcNow - a.FechaNacimiento).TotalDays / 30.44) >= 24 ? (a.Sexo == SexoAnimal.Macho ? 1.2 : 1.0) :
                        ((DateTime.UtcNow - a.FechaNacimiento).TotalDays / 30.44) >= 12 ? 0.7 : 0.4), 1),
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

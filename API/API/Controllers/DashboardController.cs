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

        // ── GET /api/dashboard/finca/{id} — Detalle completo de una finca ─────
        [HttpGet("finca/{id:guid}")]
        public async Task<IActionResult> GetFincaDetalle(Guid id)
        {
            var finca = await _context.Fincas
                .Include(f => f.UsuarioApp).ThenInclude(u => u!.Municipio)
                .Include(f => f.Municipio)
                .Include(f => f.Animales).ThenInclude(a => a.Raza)
                .FirstOrDefaultAsync(f => f.Id == id);

            if (finca == null) return NotFound(new { error = "Finca no encontrada" });

            var ahora = DateTime.UtcNow;
            var hoyUtc = ahora.Date;
            var hace30Dias = hoyUtc.AddDays(-29);

            // KPIs de animales
            var animales = finca.Animales.ToList();
            double totalUgm = 0;
            var animalItems = animales.Select(a =>
            {
                var edadMeses = (int)((ahora - a.FechaNacimiento).TotalDays / 30.44);
                double ugm = edadMeses >= 24 ? (a.Sexo == SexoAnimal.Macho ? 1.2 : 1.0)
                           : edadMeses >= 12 ? 0.7 : 0.4;
                totalUgm += ugm;
                return new AnimalItemDto
                {
                    Id = a.Id,
                    Identificacion = a.Identificacion,
                    Sexo = a.Sexo == SexoAnimal.Macho ? "Macho" : "Hembra",
                    Raza = a.Raza?.Nombre ?? "—",
                    EdadMeses = edadMeses,
                    Estado = a.Estado == EstadoSalud.Sana ? "Sana"
                           : a.Estado == EstadoSalud.Enferma ? "Enferma" : "En Tratamiento",
                    Ugm = Math.Round(ugm, 1)
                };
            }).ToList();

            // Producción hoy
            var animalIds = animales.Select(a => a.Id).ToList();
            var produccionHoy = await _context.ProduccionLeche
                .Where(p => animalIds.Contains(p.AnimalId) && p.Fecha >= hoyUtc)
                .SumAsync(p => (double)p.VolumenLitros);

            // Últimos registros de salud
            var salud = await _context.RegistrosSalud
                .Include(rs => rs.Animal)
                .Include(rs => rs.Enfermedad)
                .Include(rs => rs.Tratamientos).ThenInclude(t => t.Medicamento)
                .Where(rs => animalIds.Contains(rs.AnimalId))
                .OrderByDescending(rs => rs.FechaDeteccion)
                .Take(20)
                .Select(rs => new RegistroSaludItemDto
                {
                    Id = rs.Id,
                    AnimalIdentificacion = rs.Animal != null ? rs.Animal.Identificacion : "—",
                    Enfermedad = rs.Enfermedad != null ? rs.Enfermedad.Nombre : "—",
                    Observaciones = rs.Observaciones,
                    FechaDeteccion = rs.FechaDeteccion,
                    Medicamentos = rs.Tratamientos
                        .Where(t => t.Medicamento != null)
                        .Select(t => t.Medicamento!.NombreComercial)
                        .ToList()
                })
                .ToListAsync();

            // Tendencia 30 días
            var producciones30 = await _context.ProduccionLeche
                .Where(p => animalIds.Contains(p.AnimalId) && p.Fecha >= hace30Dias)
                .ToListAsync();

            var tendencia = Enumerable.Range(0, 30).Select(i =>
            {
                var d = hace30Dias.AddDays(i);
                var l = producciones30.Where(p => p.Fecha.Date == d.Date).Sum(p => (double)p.VolumenLitros);
                return new ProduccionTendenciaDto
                {
                    Fecha = d.ToString("dd/MM"),
                    Litros = Math.Round(l, 1),
                    Kg = Math.Round(l * 1.032, 1)
                };
            }).ToList();

            var hace72h = ahora.AddHours(-72);
            var tieneAlertas = await _context.RegistrosSalud
                .AnyAsync(rs => animalIds.Contains(rs.AnimalId) && rs.FechaDeteccion >= hace72h);

            var dto = new FincaDetalleDto
            {
                Id = finca.Id,
                Nombre = finca.Nombre,
                GanaderoNombre = finca.UsuarioApp?.Nombre ?? "—",
                GanaderoTelefono = finca.UsuarioApp?.Telefono ?? "—",
                Municipio = finca.Municipio?.Nombre ?? "—",
                Comarca = finca.Comarca,
                Latitud = finca.Latitud,
                Longitud = finca.Longitud,
                TotalAnimales = animales.Count,
                TotalHembras = animales.Count(a => a.Sexo == SexoAnimal.Hembra),
                TotalMachos = animales.Count(a => a.Sexo == SexoAnimal.Macho),
                AnimalesEnfermos = animales.Count(a => a.Estado != EstadoSalud.Sana),
                TotalUGM = Math.Round(totalUgm, 1),
                ProduccionHoyLitros = Math.Round(produccionHoy, 1),
                ProduccionHoyKg = Math.Round(produccionHoy * 1.032, 1),
                TieneAlertasSanitarias = tieneAlertas,
                Animales = animalItems,
                UltimosSalud = salud,
                Tendencia30Dias = tendencia
            };

            return Ok(dto);
        }

        // ── GET /api/dashboard/animales — Lista global de todos los animales ──
        [HttpGet("animales")]
        public async Task<IActionResult> GetAnimalesGlobal()
        {
            var ahora = DateTime.UtcNow;
            var animales = await _context.Animales
                .Include(a => a.Finca).ThenInclude(f => f!.UsuarioApp)
                .Include(a => a.Raza)
                .OrderBy(a => a.Finca!.Nombre).ThenBy(a => a.Identificacion)
                .Select(a => new AnimalGlobalDto
                {
                    Id = a.Id,
                    Identificacion = a.Identificacion,
                    Finca = a.Finca != null ? a.Finca.Nombre : "—",
                    FincaId = a.FincaId,
                    Ganadero = a.Finca != null && a.Finca.UsuarioApp != null ? a.Finca.UsuarioApp.Nombre : "—",
                    Raza = a.Raza != null ? a.Raza.Nombre : "—",
                    Sexo = a.Sexo == SexoAnimal.Macho ? "Macho" : "Hembra",
                    EdadMeses = (int)((ahora - a.FechaNacimiento).TotalDays / 30.44),
                    Estado = a.Estado == EstadoSalud.Sana ? "Sana"
                           : a.Estado == EstadoSalud.Enferma ? "Enferma" : "En Tratamiento",
                    FechaNacimiento = a.FechaNacimiento
                })
                .ToListAsync();

            return Ok(animales);
        }

        // ── GET /api/dashboard/reportes — Resumen de reportes estadísticos ───
        [HttpGet("reportes")]
        public async Task<IActionResult> GetReportes()
        {
            var ahora = DateTime.UtcNow;
            var hace12Meses = new DateTime(ahora.Year, ahora.Month, 1).AddMonths(-11);

            // Producción mensual (últimos 12 meses)
            var producciones = await _context.ProduccionLeche
                .Where(p => p.Fecha >= hace12Meses)
                .ToListAsync();

            var produccionMensual = Enumerable.Range(0, 12).Select(i =>
            {
                var mes = hace12Meses.AddMonths(i);
                var l = producciones
                    .Where(p => p.Fecha.Year == mes.Year && p.Fecha.Month == mes.Month)
                    .Sum(p => (double)p.VolumenLitros);
                return new ProduccionMensualDto
                {
                    Mes = mes.ToString("MMM yy"),
                    Litros = Math.Round(l, 1),
                    Kg = Math.Round(l * 1.032, 1)
                };
            }).ToList();

            // Enfermedades más frecuentes
            var enfermedades = await _context.RegistrosSalud
                .Include(rs => rs.Enfermedad)
                .GroupBy(rs => rs.Enfermedad!.Nombre)
                .Select(g => new EnfermedadFrecuenciaDto
                {
                    Enfermedad = g.Key ?? "Desconocida",
                    TotalCasos = g.Count()
                })
                .OrderByDescending(e => e.TotalCasos)
                .Take(10)
                .ToListAsync();

            // Ranking de fincas por producción
            var ranking = await _context.Fincas
                .Include(f => f.UsuarioApp)
                .Include(f => f.Animales)
                .Select(f => new RankingFincaDto
                {
                    Finca = f.Nombre,
                    Ganadero = f.UsuarioApp != null ? f.UsuarioApp.Nombre : "—",
                    LitrosTotales = Math.Round((double)_context.ProduccionLeche
                        .Where(p => f.Animales.Select(a => a.Id).Contains(p.AnimalId))
                        .Sum(p => p.VolumenLitros), 1),
                    TotalAnimales = f.Animales.Count
                })
                .OrderByDescending(r => r.LitrosTotales)
                .Take(10)
                .ToListAsync();

            // Censo ganadero
            var animales = await _context.Animales.Include(a => a.Raza).ToListAsync();
            var censo = new CensoGanaderoDto
            {
                TotalHembras = animales.Count(a => a.Sexo == SexoAnimal.Hembra),
                TotalMachos = animales.Count(a => a.Sexo == SexoAnimal.Macho),
                Adultos = animales.Count(a => (ahora - a.FechaNacimiento).TotalDays / 30.44 >= 24),
                Jovenes = animales.Count(a =>
                {
                    var m = (ahora - a.FechaNacimiento).TotalDays / 30.44;
                    return m >= 12 && m < 24;
                }),
                Crias = animales.Count(a => (ahora - a.FechaNacimiento).TotalDays / 30.44 < 12),
                PorRaza = animales.GroupBy(a => a.Raza?.Nombre ?? "Desconocida")
                    .Select(g => new RazaDistribucionDto { Raza = g.Key, Total = g.Count() })
                    .OrderByDescending(r => r.Total).ToList()
            };

            return Ok(new ReporteResumenDto
            {
                ProduccionMensual = produccionMensual,
                EnfermedadesFrecuentes = enfermedades,
                RankingFincas = ranking,
                CensoGanadero = censo
            });
        }

        // ── GET /api/dashboard/alertas — Alertas activas del sistema ─────────
        [HttpGet("alertas")]
        public async Task<IActionResult> GetAlertas()
        {
            var alertas = new List<AlertaDto>();
            var ahora = DateTime.UtcNow;

            // Alertas sanitarias (72h)
            var hace72h = ahora.AddHours(-72);
            var sanitarias = await _context.RegistrosSalud
                .Include(rs => rs.Animal).ThenInclude(a => a!.Finca)
                .Include(rs => rs.Enfermedad)
                .Where(rs => rs.FechaDeteccion >= hace72h)
                .OrderByDescending(rs => rs.FechaDeteccion)
                .Take(10)
                .ToListAsync();

            alertas.AddRange(sanitarias.Select(rs => new AlertaDto
            {
                Tipo = "sanitaria",
                Titulo = $"Caso clínico: {rs.Enfermedad?.Nombre ?? "Sin diagnóstico"}",
                Descripcion = $"Animal {rs.Animal?.Identificacion} — Finca {rs.Animal?.Finca?.Nombre}",
                Fecha = rs.FechaDeteccion,
                FincaId = rs.Animal?.FincaId.ToString()
            }));

            // Fincas sin sync en más de 7 días
            var hace7Dias = ahora.AddDays(-7);
            var fincasSinSync = await _context.Fincas
                .Where(f => !_context.AuditoriaLogs
                    .Any(al => al.FincaId == f.Id && al.FechaSincronizacion >= hace7Dias))
                .Take(5)
                .ToListAsync();

            alertas.AddRange(fincasSinSync.Select(f => new AlertaDto
            {
                Tipo = "sync",
                Titulo = "Finca sin sincronizar",
                Descripcion = $"{f.Nombre} no ha sincronizado en más de 7 días",
                Fecha = ahora,
                FincaId = f.Id.ToString()
            }));

            // Nuevos ganaderos (últimas 24h)
            var hace24h = ahora.AddHours(-24);
            var nuevosGanaderos = await _context.UsuariosApp
                .Where(u => u.CreatedAt >= hace24h)
                .Take(5)
                .ToListAsync();

            alertas.AddRange(nuevosGanaderos.Select(u => new AlertaDto
            {
                Tipo = "nuevo_ganadero",
                Titulo = "Nuevo ganadero registrado",
                Descripcion = $"{u.Nombre} se registró en la app móvil",
                Fecha = u.CreatedAt
            }));

            return Ok(alertas.OrderByDescending(a => a.Fecha));
        }
    }
}

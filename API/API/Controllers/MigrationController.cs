using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using API.Data;
using API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MigrationController : ControllerBase
    {
        private readonly AgroDbContext _neonDb;

        public MigrationController(AgroDbContext neonDb)
        {
            _neonDb = neonDb;
        }

        [HttpPost("transfer-local-data")]
        public async Task<IActionResult> TransferLocalData()
        {
            var optionsBuilder = new DbContextOptionsBuilder<AgroDbContext>();
            optionsBuilder.UseNpgsql("Host=localhost;Database=agro_db;Username=postgres;Password=1234")
                          .UseSnakeCaseNamingConvention();

            using var localDb = new AgroDbContext(optionsBuilder.Options);

            try
            {
                var summary = new Dictionary<string, int>();

                // 1. Departamentos
                var deps = await localDb.Departamentos.AsNoTracking().ToListAsync();
                foreach (var d in deps)
                {
                    if (!await _neonDb.Departamentos.AnyAsync(x => x.Id == d.Id))
                        _neonDb.Departamentos.Add(d);
                }
                await _neonDb.SaveChangesAsync();
                summary["Departamentos"] = deps.Count;

                // 2. Municipios
                var muns = await localDb.Municipios.AsNoTracking().ToListAsync();
                foreach (var m in muns)
                {
                    if (!await _neonDb.Municipios.AnyAsync(x => x.Id == m.Id))
                        _neonDb.Municipios.Add(m);
                }
                await _neonDb.SaveChangesAsync();
                summary["Municipios"] = muns.Count;

                // 3. Comarcas
                var coms = await localDb.Comarcas.AsNoTracking().ToListAsync();
                foreach (var c in coms)
                {
                    if (!await _neonDb.Comarcas.AnyAsync(x => x.Id == c.Id))
                        _neonDb.Comarcas.Add(c);
                }
                await _neonDb.SaveChangesAsync();
                summary["Comarcas"] = coms.Count;

                // 4. Razas
                var razas = await localDb.Razas.AsNoTracking().ToListAsync();
                foreach (var r in razas)
                {
                    if (!await _neonDb.Razas.AnyAsync(x => x.Id == r.Id))
                        _neonDb.Razas.Add(r);
                }
                await _neonDb.SaveChangesAsync();
                summary["Razas"] = razas.Count;

                // 5. Enfermedades
                var enfs = await localDb.Enfermedades.AsNoTracking().ToListAsync();
                foreach (var e in enfs)
                {
                    if (!await _neonDb.Enfermedades.AnyAsync(x => x.Id == e.Id))
                        _neonDb.Enfermedades.Add(e);
                }
                await _neonDb.SaveChangesAsync();
                summary["Enfermedades"] = enfs.Count;

                // 6. Sintomas
                var sints = await localDb.Sintomas.AsNoTracking().ToListAsync();
                foreach (var s in sints)
                {
                    if (!await _neonDb.Sintomas.AnyAsync(x => x.Id == s.Id))
                        _neonDb.Sintomas.Add(s);
                }
                await _neonDb.SaveChangesAsync();
                summary["Sintomas"] = sints.Count;

                // 7. Medicamentos
                var meds = await localDb.Medicamentos.AsNoTracking().ToListAsync();
                foreach (var m in meds)
                {
                    if (!await _neonDb.Medicamentos.AnyAsync(x => x.Id == m.Id))
                        _neonDb.Medicamentos.Add(m);
                }
                await _neonDb.SaveChangesAsync();
                summary["Medicamentos"] = meds.Count;

                // 8. EnfermedadSintomas
                var esf = await localDb.EnfermedadSintomas.AsNoTracking().ToListAsync();
                foreach (var es in esf)
                {
                    if (!await _neonDb.EnfermedadSintomas.AnyAsync(x => x.EnfermedadId == es.EnfermedadId && x.SintomaId == es.SintomaId))
                        _neonDb.EnfermedadSintomas.Add(es);
                }
                await _neonDb.SaveChangesAsync();
                summary["EnfermedadSintomas"] = esf.Count;

                // 9. EnfermedadMedicamentos
                var emf = await localDb.EnfermedadMedicamentos.AsNoTracking().ToListAsync();
                foreach (var em in emf)
                {
                    if (!await _neonDb.EnfermedadMedicamentos.AnyAsync(x => x.EnfermedadId == em.EnfermedadId && x.MedicamentoId == em.MedicamentoId))
                        _neonDb.EnfermedadMedicamentos.Add(em);
                }
                await _neonDb.SaveChangesAsync();
                summary["EnfermedadMedicamentos"] = emf.Count;

                // 10. UsuariosApp
                var usrs = await localDb.UsuariosApp.AsNoTracking().ToListAsync();
                foreach (var u in usrs)
                {
                    if (!await _neonDb.UsuariosApp.IgnoreQueryFilters().AnyAsync(x => x.Id == u.Id))
                        _neonDb.UsuariosApp.Add(u);
                }
                await _neonDb.SaveChangesAsync();
                summary["UsuariosApp"] = usrs.Count;

                // 11. Fincas
                var fincas = await localDb.Fincas.AsNoTracking().ToListAsync();
                foreach (var f in fincas)
                {
                    if (!await _neonDb.Fincas.IgnoreQueryFilters().AnyAsync(x => x.Id == f.Id))
                        _neonDb.Fincas.Add(f);
                }
                await _neonDb.SaveChangesAsync();
                summary["Fincas"] = fincas.Count;

                // 12. Animales
                var anis = await localDb.Animales.AsNoTracking().ToListAsync();
                foreach (var a in anis)
                {
                    if (!await _neonDb.Animales.IgnoreQueryFilters().AnyAsync(x => x.Id == a.Id))
                        _neonDb.Animales.Add(a);
                }
                await _neonDb.SaveChangesAsync();
                summary["Animales"] = anis.Count;

                // 13. ProduccionLeche
                var prods = await localDb.ProduccionLeche.AsNoTracking().ToListAsync();
                foreach (var p in prods)
                {
                    if (!await _neonDb.ProduccionLeche.IgnoreQueryFilters().AnyAsync(x => x.Id == p.Id))
                        _neonDb.ProduccionLeche.Add(p);
                }
                await _neonDb.SaveChangesAsync();
                summary["ProduccionLeche"] = prods.Count;

                // 14. RegistrosSalud
                var regsal = await localDb.RegistrosSalud.AsNoTracking().ToListAsync();
                foreach (var rs in regsal)
                {
                    if (!await _neonDb.RegistrosSalud.IgnoreQueryFilters().AnyAsync(x => x.Id == rs.Id))
                        _neonDb.RegistrosSalud.Add(rs);
                }
                await _neonDb.SaveChangesAsync();
                summary["RegistrosSalud"] = regsal.Count;

                // 15. RegistroSaludSintomas
                var rssin = await localDb.RegistroSaludSintomas.AsNoTracking().ToListAsync();
                foreach (var rss in rssin)
                {
                    if (!await _neonDb.RegistroSaludSintomas.AnyAsync(x => x.RegistroSaludId == rss.RegistroSaludId && x.SintomaId == rss.SintomaId))
                        _neonDb.RegistroSaludSintomas.Add(rss);
                }
                await _neonDb.SaveChangesAsync();
                summary["RegistroSaludSintomas"] = rssin.Count;

                // 16. Tratamientos
                var trats = await localDb.Tratamientos.AsNoTracking().ToListAsync();
                foreach (var t in trats)
                {
                    if (!await _neonDb.Tratamientos.AnyAsync(x => x.Id == t.Id))
                        _neonDb.Tratamientos.Add(t);
                }
                await _neonDb.SaveChangesAsync();
                summary["Tratamientos"] = trats.Count;

                // 17. AuditoriaLogs
                var auds = await localDb.AuditoriaLogs.AsNoTracking().ToListAsync();
                foreach (var a in auds)
                {
                    if (!await _neonDb.AuditoriaLogs.AnyAsync(x => x.Id == a.Id))
                        _neonDb.AuditoriaLogs.Add(a);
                }
                await _neonDb.SaveChangesAsync();
                summary["AuditoriaLogs"] = auds.Count;

                return Ok(new
                {
                    Message = "Sincronización de datos completada exitosamente de PostgreSQL Local a Neon DB.",
                    Summary = summary
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Message = "Error al migrar los datos.", Details = ex.Message, Inner = ex.InnerException?.Message });
            }
        }
    }
}

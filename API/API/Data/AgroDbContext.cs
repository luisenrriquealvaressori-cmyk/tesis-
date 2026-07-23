using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using System;
using API.Models;
using Microsoft.EntityFrameworkCore;

namespace API.Data
{
    public class AgroDbContext : DbContext
    {
        public AgroDbContext(DbContextOptions<AgroDbContext> options) : base(options) { }

        // BLOQUE A
        public DbSet<Departamento> Departamentos { get; set; }
        public DbSet<Municipio> Municipios { get; set; }
        public DbSet<Comarca> Comarcas { get; set; }
        public DbSet<Raza> Razas { get; set; }
        public DbSet<Enfermedad> Enfermedades { get; set; }
        public DbSet<Sintoma> Sintomas { get; set; }
        public DbSet<Medicamento> Medicamentos { get; set; }
        public DbSet<EnfermedadSintoma> EnfermedadSintomas { get; set; }
        public DbSet<EnfermedadMedicamento> EnfermedadMedicamentos { get; set; }

        // BLOQUE A: Usuarios Web (Supervisores/Admins)
        public DbSet<UsuarioWeb> UsuariosWeb { get; set; }

        // BLOQUE B
        public DbSet<UsuarioApp> UsuariosApp { get; set; }
        public DbSet<Finca> Fincas { get; set; }
        public DbSet<Animal> Animales { get; set; }
        public DbSet<ProduccionLeche> ProduccionLeche { get; set; }
        public DbSet<RegistroSalud> RegistrosSalud { get; set; }
        public DbSet<RegistroSaludSintoma> RegistroSaludSintomas { get; set; }
        public DbSet<Tratamiento> Tratamientos { get; set; }
        public DbSet<AuditoriaSync> AuditoriaLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ----------------------------------------------------------------
            // NOMBRES DE TABLAS PARA CATÁLOGOS (Compatibilidad con Script SQL)
            // ----------------------------------------------------------------
            modelBuilder.Entity<Departamento>().ToTable("departamentos");
            modelBuilder.Entity<Municipio>().ToTable("municipios");
            modelBuilder.Entity<Comarca>().ToTable("comarcas");
            modelBuilder.Entity<Raza>().ToTable("razas_bovinas");
            modelBuilder.Entity<Enfermedad>().ToTable("enfermedades");
            modelBuilder.Entity<Sintoma>().ToTable("sintomas");
            modelBuilder.Entity<Medicamento>().ToTable("medicamentos");
            modelBuilder.Entity<EnfermedadSintoma>().ToTable("enfermedad_sintoma");
            modelBuilder.Entity<EnfermedadMedicamento>().ToTable("enfermedad_medicamento");

            // ----------------------------------------------------------------
            // RELACIONES M:N (Catálogos)
            // ----------------------------------------------------------------
            modelBuilder.Entity<EnfermedadSintoma>()
                .HasKey(es => new { es.EnfermedadId, es.SintomaId });

            modelBuilder.Entity<EnfermedadMedicamento>()
                .HasKey(em => new { em.EnfermedadId, em.MedicamentoId });

            // ----------------------------------------------------------------
            // RELACIÓN M:N: RegistroSaludSintoma
            // ----------------------------------------------------------------
            modelBuilder.Entity<RegistroSaludSintoma>()
                .HasKey(rss => new { rss.RegistroSaludId, rss.SintomaId });

            modelBuilder.Entity<RegistroSaludSintoma>()
                .HasOne(rss => rss.RegistroSalud)
                .WithMany(rs => rs.SintomasPresentados)
                .HasForeignKey(rss => rss.RegistroSaludId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<RegistroSaludSintoma>()
                .HasOne(rss => rss.Sintoma)
                .WithMany()
                .HasForeignKey(rss => rss.SintomaId)
                .OnDelete(DeleteBehavior.Restrict);

            // ----------------------------------------------------------------
            // TRATAMIENTOS
            // ----------------------------------------------------------------
            modelBuilder.Entity<Tratamiento>()
                .HasOne(t => t.RegistroSalud)
                .WithMany(rs => rs.Tratamientos)
                .HasForeignKey(t => t.RegistroSaludId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Tratamiento>()
                .HasOne(t => t.Medicamento)
                .WithMany()
                .HasForeignKey(t => t.MedicamentoId)
                .OnDelete(DeleteBehavior.Restrict);

            // ----------------------------------------------------------------
            // CORRECCIONES AUDITORÍA: Catálogos no deben destruir datos operativos
            // HALLAZGO #1: Eliminar Enfermedad NO debe borrar historial médico
            // ----------------------------------------------------------------
            modelBuilder.Entity<RegistroSalud>()
                .HasOne(rs => rs.Enfermedad)
                .WithMany()
                .HasForeignKey(rs => rs.EnfermedadId)
                .OnDelete(DeleteBehavior.Restrict);

            // HALLAZGO #2: Eliminar Raza NO debe borrar animales
            modelBuilder.Entity<Animal>()
                .HasOne(a => a.Raza)
                .WithMany()
                .HasForeignKey(a => a.RazaId)
                .OnDelete(DeleteBehavior.Restrict);

            // HALLAZGO #3: Eliminar Municipio NO debe borrar fincas
            modelBuilder.Entity<Finca>()
                .HasOne(f => f.Municipio)
                .WithMany()
                .HasForeignKey(f => f.MunicipioId)
                .OnDelete(DeleteBehavior.Restrict);

            // HALLAZGO #4: Eliminar Municipio NO debe borrar usuarios
            modelBuilder.Entity<UsuarioApp>()
                .HasOne(u => u.Municipio)
                .WithMany()
                .HasForeignKey(u => u.MunicipioId)
                .OnDelete(DeleteBehavior.Restrict);

            // ----------------------------------------------------------------
            // ÍNDICES DE RENDIMIENTO PARA PRODUCCIÓN
            // ----------------------------------------------------------------
            modelBuilder.Entity<UsuarioApp>()
                .HasIndex(u => u.Telefono)
                .IsUnique();

            // Email de usuarios web debe ser único
            modelBuilder.Entity<UsuarioWeb>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<RegistroSalud>()
                .HasIndex(rs => new { rs.FechaDeteccion, rs.AnimalId });

            modelBuilder.Entity<Animal>()
                .HasIndex(a => a.FincaId);

            // ----------------------------------------------------------------
            // SOFT DELETE: Filtros globales para excluir registros eliminados
            // ----------------------------------------------------------------
            modelBuilder.Entity<UsuarioWeb>().HasQueryFilter(e => !e.IsDeleted);
            modelBuilder.Entity<UsuarioApp>().HasQueryFilter(e => !e.IsDeleted);
            modelBuilder.Entity<Finca>().HasQueryFilter(e => !e.IsDeleted);
            modelBuilder.Entity<Animal>().HasQueryFilter(e => !e.IsDeleted);
            modelBuilder.Entity<ProduccionLeche>().HasQueryFilter(e => !e.IsDeleted);
            modelBuilder.Entity<RegistroSalud>().HasQueryFilter(e => !e.IsDeleted);
        }

        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            var entries = ChangeTracker.Entries<IAuditableEntity>();

            foreach (var entry in entries)
            {
                if (entry.State == EntityState.Added)
                {
                    entry.Entity.CreatedAt = DateTime.UtcNow;
                }
                else if (entry.State == EntityState.Modified)
                {
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                }
            }

            return base.SaveChangesAsync(cancellationToken);
        }
    }
}

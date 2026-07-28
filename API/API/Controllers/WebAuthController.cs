using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using API.Data;
using API.Models;
using API.DTOs;
using BCrypt.Net;

namespace API.Controllers
{
    /// <summary>
    /// Autenticación exclusiva para usuarios de la plataforma Web (Supervisores y Admins).
    /// Separado del AuthController (que es para Ganaderos de la APK).
    /// </summary>
    [ApiController]
    [Route("api/web-auth")]
    public class WebAuthController : ControllerBase
    {
        private readonly AgroDbContext _context;
        private readonly IConfiguration _config;

        public WebAuthController(AgroDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        public class RegisterWebRequest
        {
            public required string Email { get; set; }
            public required string Nombre { get; set; }
            public required string Clave { get; set; }
            public string? Cargo { get; set; }
            /// <summary>1=Ganadero, 2=Supervisor (default), 3=Administrador</summary>
            public int Rol { get; set; } = 2;
        }

        public class LoginWebRequest
        {
            public required string Email { get; set; }
            public required string Clave { get; set; }
        }

        // POST /api/web-auth/register
        // Registrar un nuevo usuario web (Supervisor o Administrador)
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterWebRequest req)
        {
            // Solo Admin puede crear nuevos usuarios web, EXCEPTO si la tabla está vacía (primer arranque)
            var hayAdmins = await _context.UsuariosWeb.IgnoreQueryFilters().AnyAsync();

            if (hayAdmins)
            {
                // Si ya hay usuarios, requerir autorización
                if (!User.Identity!.IsAuthenticated)
                    return Unauthorized(new { error = "Se requiere autenticación para registrar usuarios web." });

                var rolClaim = User.FindFirstValue(ClaimTypes.Role);
                if (rolClaim != "Administrador")
                    return Forbid();
            }

            // Verificar email único
            var existe = await _context.UsuariosWeb.IgnoreQueryFilters()
                .AnyAsync(u => u.Email.ToLower() == req.Email.ToLower());

            if (existe)
                return Conflict(new { error = "Ya existe un usuario con ese correo electrónico." });

            var rolSolicitado = Enum.IsDefined(typeof(RolUsuario), req.Rol)
                ? (RolUsuario)req.Rol
                : RolUsuario.Supervisor;

            var nuevoUsuario = new UsuarioWeb
            {
                Email = req.Email.ToLower().Trim(),
                Nombre = req.Nombre,
                ClaveHash = BCrypt.Net.BCrypt.HashPassword(req.Clave),
                Rol = hayAdmins ? rolSolicitado : RolUsuario.Administrador, // El primero siempre es Admin
                Cargo = req.Cargo
            };

            _context.UsuariosWeb.Add(nuevoUsuario);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                usuarioId = nuevoUsuario.Id,
                email = nuevoUsuario.Email,
                nombre = nuevoUsuario.Nombre,
                rol = nuevoUsuario.Rol.ToString()
            });
        }

        // POST /api/web-auth/login
        // Login para usuarios de la plataforma Web
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginWebRequest req)
        {
            var usuario = await _context.UsuariosWeb
                .FirstOrDefaultAsync(u => u.Email.ToLower() == req.Email.ToLower());

            if (usuario == null || !BCrypt.Net.BCrypt.Verify(req.Clave, usuario.ClaveHash))
                return Unauthorized(new { error = "Correo o contraseña incorrectos." });

            var token = GenerarJwt(usuario);

            return Ok(new
            {
                token,
                usuarioId = usuario.Id,
                nombre = usuario.Nombre,
                email = usuario.Email,
                rol = usuario.Rol.ToString()
            });
        }

        private string GenerarJwt(UsuarioWeb usuario)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
                new Claim(ClaimTypes.Name, usuario.Nombre),
                new Claim(ClaimTypes.Email, usuario.Email),
                new Claim(ClaimTypes.Role, usuario.Rol.ToString()),
                // Distinguir que es un usuario de la Web (no APK)
                new Claim("user_type", "web")
            };

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddDays(30),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        // GET /api/web-auth/ganaderos
        // Listar todos los ganaderos registrados desde la APK móvil
        [HttpGet("ganaderos")]
        [Authorize]
        public async Task<IActionResult> GetGanaderos()
        {
            var ganaderos = await _context.UsuariosApp
                .Include(u => u.Municipio)
                .Include(u => u.Fincas)
                    .ThenInclude(f => f.Animales)
                .Select(u => new GanaderoAppDto
                {
                    Id = u.Id,
                    Nombre = u.Nombre,
                    Telefono = u.Telefono,
                    Municipio = u.Municipio != null ? u.Municipio.Nombre : "",
                    Comarca = u.Comarca,
                    TotalFincas = u.Fincas.Count,
                    TotalAnimales = u.Fincas.SelectMany(f => f.Animales).Count(),
                    CreatedAt = u.CreatedAt
                })
                .OrderByDescending(u => u.CreatedAt)
                .ToListAsync();

            return Ok(ganaderos);
        }

        // GET /api/web-auth/auditoria-sync
        // Listar el historial de auditoría de sincronizaciones móviles recibidas
        [HttpGet("auditoria-sync")]
        [Authorize]
        public async Task<IActionResult> GetAuditoriaSync()
        {
            var logs = await _context.AuditoriaLogs
                .Include(a => a.UsuarioApp)
                .Include(a => a.Finca)
                .OrderByDescending(a => a.FechaSincronizacion)
                .Take(50)
                .Select(a => new AuditoriaSyncDto
                {
                    Id = a.Id,
                    GanaderoNombre = a.UsuarioApp != null ? a.UsuarioApp.Nombre : "Anónimo",
                    FincaNombre = a.Finca != null ? a.Finca.Nombre : null,
                    TipoEntidad = a.TipoEntidad,
                    Accion = a.Accion,
                    Latitud = a.Latitud,
                    Longitud = a.Longitud,
                    FechaSincronizacion = a.FechaSincronizacion
                })
                .ToListAsync();

            return Ok(logs);
        }

        // GET /api/web-auth/usuarios-web
        // Listar usuarios del portal web (solo Administradores)
        [HttpGet("usuarios-web")]
        [Authorize]
        public async Task<IActionResult> GetUsuariosWeb()
        {
            var rolClaim = User.FindFirstValue(ClaimTypes.Role);
            if (rolClaim != "Administrador")
                return Forbid();

            var usuarios = await _context.UsuariosWeb
                .OrderByDescending(u => u.CreatedAt)
                .Select(u => new UsuarioWebDto
                {
                    Id = u.Id,
                    Nombre = u.Nombre,
                    Email = u.Email,
                    Rol = u.Rol.ToString(),
                    Cargo = u.Cargo,
                    CreatedAt = u.CreatedAt
                })
                .ToListAsync();

            return Ok(usuarios);
        }

        // ── POST /api/web-auth/cambiar-clave ─────────────────────────────────
        // Cada usuario puede cambiar su propia contraseña (requiere clave actual).
        [HttpPost("cambiar-clave")]
        [Authorize]
        public async Task<IActionResult> CambiarClave([FromBody] CambiarClaveRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.ClaveActual) || string.IsNullOrWhiteSpace(req.ClaveNueva))
                return BadRequest(new { error = "Debe proporcionar la clave actual y la nueva." });

            if (req.ClaveNueva.Length < 6)
                return BadRequest(new { error = "La nueva contraseña debe tener al menos 6 caracteres." });

            var emailClaim = User.FindFirstValue(ClaimTypes.Email)
                          ?? User.FindFirstValue(ClaimTypes.Name);

            if (string.IsNullOrEmpty(emailClaim))
                return Unauthorized(new { error = "Token inválido." });

            var usuario = await _context.UsuariosWeb
                .FirstOrDefaultAsync(u => u.Email == emailClaim && !u.IsDeleted);

            if (usuario is null)
                return NotFound(new { error = "Usuario no encontrado." });

            if (!BCrypt.Net.BCrypt.Verify(req.ClaveActual, usuario.ClaveHash))
                return BadRequest(new { error = "La contraseña actual es incorrecta." });

            usuario.ClaveHash = BCrypt.Net.BCrypt.HashPassword(req.ClaveNueva);
            usuario.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Contraseña actualizada correctamente." });
        }

        // ── POST /api/web-auth/reset-clave/{id} ──────────────────────────────
        // Solo Administradores pueden resetear la clave de otro usuario.
        [HttpPost("reset-clave/{id:guid}")]
        [Authorize]
        public async Task<IActionResult> ResetClave(Guid id, [FromBody] ResetClaveRequest req)
        {
            var rolClaim = User.FindFirstValue(ClaimTypes.Role);
            if (rolClaim != "Administrador")
                return Forbid();

            if (string.IsNullOrWhiteSpace(req.ClaveNueva) || req.ClaveNueva.Length < 6)
                return BadRequest(new { error = "La nueva contraseña debe tener al menos 6 caracteres." });

            var usuario = await _context.UsuariosWeb
                .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted);

            if (usuario is null)
                return NotFound(new { error = "Usuario no encontrado." });

            usuario.ClaveHash = BCrypt.Net.BCrypt.HashPassword(req.ClaveNueva);
            usuario.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = $"Contraseña de {usuario.Nombre} restablecida correctamente." });
        }

        // ── POST /api/web-auth/reset-clave-app/{id} ──────────────────────────
        // Solo Administradores pueden resetear la clave de usuarios móviles (Ganaderos).
        [HttpPost("reset-clave-app/{id:guid}")]
        [Authorize]
        public async Task<IActionResult> ResetClaveApp(Guid id, [FromBody] ResetClaveRequest req)
        {
            var rolClaim = User.FindFirstValue(ClaimTypes.Role);
            if (rolClaim != "Administrador")
                return Forbid();

            if (string.IsNullOrWhiteSpace(req.ClaveNueva) || req.ClaveNueva.Length < 6)
                return BadRequest(new { error = "La nueva contraseña debe tener al menos 6 caracteres." });

            var usuarioApp = await _context.Usuarios
                .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted);

            if (usuarioApp is null)
                return NotFound(new { error = "Usuario móvil no encontrado." });

            usuarioApp.ClaveHash = BCrypt.Net.BCrypt.HashPassword(req.ClaveNueva);
            usuarioApp.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = $"Contraseña del ganadero {usuarioApp.Nombre} restablecida correctamente." });
        }

        public class CambiarClaveRequest
        {
            public required string ClaveActual { get; set; }
            public required string ClaveNueva { get; set; }
        }

        public class ResetClaveRequest
        {
            public required string ClaveNueva { get; set; }
        }
    }
}

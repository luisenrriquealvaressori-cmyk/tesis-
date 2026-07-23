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
            public RolUsuario Rol { get; set; } = RolUsuario.Supervisor;
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

            var nuevoUsuario = new UsuarioWeb
            {
                Email = req.Email.ToLower().Trim(),
                Nombre = req.Nombre,
                ClaveHash = BCrypt.Net.BCrypt.HashPassword(req.Clave),
                Rol = hayAdmins ? req.Rol : RolUsuario.Administrador, // El primero siempre es Admin
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
    }
}

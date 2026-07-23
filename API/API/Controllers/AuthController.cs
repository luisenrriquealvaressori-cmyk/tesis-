using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using API.Data;
using API.Models;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AgroDbContext _context;
        private readonly IConfiguration _config;

        public AuthController(AgroDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        public class RegisterRequest
        {
            public required string Telefono { get; set; }
            public required string Nombre { get; set; }
            public required string Clave { get; set; }
            public Guid MunicipioId { get; set; }
            public required string Comarca { get; set; }
        }

        public class LoginRequest
        {
            public required string Telefono { get; set; }
            public required string Clave { get; set; }
        }

        [HttpGet("municipios")]
        public async Task<IActionResult> GetMunicipios()
        {
            var data = await _context.Departamentos
                .Include(d => d.Municipios)
                .Select(d => new
                {
                    Departamento = d.Nombre,
                    Municipios = d.Municipios.Select(m => new { m.Id, m.Nombre })
                })
                .ToListAsync();

            return Ok(data);
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest req)
        {
            var existe = await _context.UsuariosApp.AnyAsync(u => u.Telefono == req.Telefono);
            if (existe) return BadRequest(new { error = "El teléfono ya está registrado." });

            var user = new UsuarioApp
            {
                Id = Guid.NewGuid(),
                Nombre = req.Nombre,
                Telefono = req.Telefono,
                ClaveHash = BCrypt.Net.BCrypt.HashPassword(req.Clave),
                MunicipioId = req.MunicipioId,
                Comarca = req.Comarca
            };

            _context.UsuariosApp.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Registro exitoso", usuarioId = user.Id });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            var user = await _context.UsuariosApp.FirstOrDefaultAsync(u => u.Telefono == req.Telefono);
            
            if (user == null || !BCrypt.Net.BCrypt.Verify(req.Clave, user.ClaveHash))
            {
                return Unauthorized(new { error = "Credenciales incorrectas" });
            }

            var tokenHandler = new JwtSecurityTokenHandler();
            var keyStr = _config["Jwt:Key"] ?? "default_secret_key";
            var key = Encoding.UTF8.GetBytes(keyStr);
            
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Nombre),
                    new Claim(ClaimTypes.MobilePhone, user.Telefono)
                }),
                Expires = DateTime.UtcNow.AddDays(30),
                Issuer = _config["Jwt:Issuer"],
                Audience = _config["Jwt:Audience"],
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            var jwt = tokenHandler.WriteToken(token);

            return Ok(new
            {
                token = jwt,
                usuarioId = user.Id,
                nombre = user.Nombre
            });
        }
    }
}

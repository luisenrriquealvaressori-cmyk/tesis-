using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ImagesController : ControllerBase
    {
        private readonly string _uploadPath;

        public ImagesController()
        {
            // Carpeta local para almacenar imágenes. 
            // En producción podría ser un AWS S3 o Azure Blob Storage.
            _uploadPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
            if (!Directory.Exists(_uploadPath))
            {
                Directory.CreateDirectory(_uploadPath);
            }
        }

        [HttpPost("upload/{entityId}")]
        public async Task<IActionResult> UploadImage(Guid entityId, IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No se proporcionó ningún archivo.");

            // Validar extensión
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (extension != ".jpg" && extension != ".jpeg" && extension != ".png")
                return BadRequest("Extensión no permitida. Solo JPG y PNG.");

            // ESTRATEGIA ANTI-DUPLICADOS: 
            // El nombre del archivo es exactamente el UUID de la entidad.
            // Si el móvil manda otra foto para la misma vaca, esto sobrescribe la anterior silenciosamente.
            var fileName = $"{entityId}{extension}";
            var filePath = Path.Combine(_uploadPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Devolver la ruta relativa pública (requiere app.UseStaticFiles() en Program.cs)
            var fileUrl = $"/uploads/{fileName}";

            return Ok(new { message = "Imagen guardada correctamente", url = fileUrl });
        }
    }
}

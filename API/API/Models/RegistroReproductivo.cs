using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace API.Models
{
    public class RegistroReproductivo
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid AnimalId { get; set; }

        [Required]
        [MaxLength(50)]
        public string TipoEvento { get; set; } = string.Empty; // Celo, Inseminacion, Monta, Preñez, Parto, Aborto

        [Required]
        public DateTime FechaEvento { get; set; }

        public Guid? ToroId { get; set; } // Opcional, si fue inseminación o monta con un toro específico

        public string? Observaciones { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public bool IsDeleted { get; set; } = false;

        // Propiedad de navegación
        [ForeignKey("AnimalId")]
        public virtual Animal? Animal { get; set; }
    }
}

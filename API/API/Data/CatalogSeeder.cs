using System.Threading.Tasks;

namespace API.Data
{
    public static class CatalogSeeder
    {
        public static Task SeedAsync(AgroDbContext context)
        {
            // Respetar estrictamente los catálogos y municipios existentes en Neon DB
            return Task.CompletedTask;
        }
    }
}

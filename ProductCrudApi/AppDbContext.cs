using Microsoft.EntityFrameworkCore;
using ProductCrudApi.Models;

namespace ProductCrudApi
{
    /// <summary>
    /// Application database context for EF Core.
    /// </summary>
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Product> Products { get; set; }
    }
}

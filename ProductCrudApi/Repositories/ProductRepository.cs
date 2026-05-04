using ProductCrudApi.Models;

namespace ProductCrudApi.Repositories
{
    /// <summary>
    /// Product-specific repository implementation.
    /// </summary>
    public class ProductRepository : GenericRepository<Product>, IProductRepository
    {
        public ProductRepository(AppDbContext context) : base(context)
        {
        }
        // Implement product-specific methods here if needed
    }
}

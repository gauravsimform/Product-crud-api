using ProductCrudApi.Models;

namespace ProductCrudApi.Repositories
{
    /// <summary>
    /// Product-specific repository interface.
    /// </summary>
    public interface IProductRepository : IGenericRepository<Product>
    {
        // Add product-specific methods here if needed
    }
}

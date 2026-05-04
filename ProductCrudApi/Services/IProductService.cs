using System.Collections.Generic;
using System.Threading.Tasks;
using ProductCrudApi.DTOs;

namespace ProductCrudApi.Services
{
    /// <summary>
    /// Service interface for product business logic.
    /// </summary>
    public interface IProductService
    {
        Task<IEnumerable<ProductReadDto>> GetAllProductsAsync();
        Task<ProductReadDto> GetProductByIdAsync(int id);
        Task<ProductReadDto> CreateProductAsync(ProductCreateDto dto);
        Task<bool> UpdateProductAsync(int id, ProductUpdateDto dto);
        Task<bool> DeleteProductAsync(int id);
    }
}

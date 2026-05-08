using System.Collections.Generic;
using System.Threading.Tasks;
using ProductCrudApi.DTOs;

namespace ProductCrudApi.Services
{
    /// <summary>
    /// Service interface defining the business logic operations for products.
    /// </summary>
    public interface IProductService
    {
        /// <summary>
        /// Retrieves all products.
        /// </summary>
        /// <returns>A collection of <see cref="ProductReadDto"/> representing all products.</returns>
        Task<IEnumerable<ProductReadDto>> GetAllProductsAsync();

        /// <summary>
        /// Retrieves a single product by its unique identifier.
        /// </summary>
        /// <param name="id">The unique identifier of the product.</param>
        /// <returns>
        /// A <see cref="ProductReadDto"/> for the matching product,
        /// or <c>null</c> if no product with the given <paramref name="id"/> exists.
        /// </returns>
        Task<ProductReadDto> GetProductByIdAsync(int id);

        /// <summary>
        /// Creates a new product from the supplied data transfer object.
        /// </summary>
        /// <param name="dto">The data required to create the product.</param>
        /// <returns>A <see cref="ProductReadDto"/> representing the newly created product, including its assigned ID.</returns>
        Task<ProductReadDto> CreateProductAsync(ProductCreateDto dto);

        /// <summary>
        /// Updates an existing product identified by <paramref name="id"/>.
        /// </summary>
        /// <param name="id">The unique identifier of the product to update.</param>
        /// <param name="dto">The updated product data.</param>
        /// <returns>
        /// <c>true</c> if the product was found and updated successfully;
        /// <c>false</c> if no product with the given <paramref name="id"/> exists.
        /// </returns>
        Task<bool> UpdateProductAsync(int id, ProductUpdateDto dto);

        /// <summary>
        /// Deletes the product with the specified identifier.
        /// </summary>
        /// <param name="id">The unique identifier of the product to delete.</param>
        /// <returns>
        /// <c>true</c> if the product was found and deleted;
        /// <c>false</c> if no product with the given <paramref name="id"/> exists.
        /// </returns>
        Task<bool> DeleteProductAsync(int id);

        /// <summary>
        /// Deletes all products from the data store.
        /// </summary>
        Task DeleteAllProductsAsync();
    }
}

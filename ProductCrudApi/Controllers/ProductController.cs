using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;
using ProductCrudApi.DTOs;
using ProductCrudApi.Services;

namespace ProductCrudApi.Controllers
{
    /// <summary>
    /// Controller for managing products.
    /// Provides endpoints for creating, reading, updating, and deleting products.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class ProductController : ControllerBase
    {
        private readonly IProductService _productService;

        /// <summary>
        /// Initialises a new instance of <see cref="ProductController"/>.
        /// </summary>
        /// <param name="productService">The product service injected by the DI container.</param>
        public ProductController(IProductService productService)
        {
            _productService = productService;
        }

        /// <summary>
        /// Get all products.
        /// </summary>
        /// <returns>A list of all products.</returns>
        /// <response code="200">Returns the list of products (may be empty).</response>
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<ProductReadDto>), 200)]
        public async Task<ActionResult<IEnumerable<ProductReadDto>>> GetAll()
        {
            var products = await _productService.GetAllProductsAsync();
            return Ok(products);
        }

        /// <summary>
        /// Get a product by its unique identifier.
        /// </summary>
        /// <param name="id">The unique identifier of the product.</param>
        /// <returns>The product with the specified ID.</returns>
        /// <response code="200">Returns the requested product.</response>
        /// <response code="404">No product with the given ID was found.</response>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(ProductReadDto), 200)]
        [ProducesResponseType(404)]
        public async Task<ActionResult<ProductReadDto>> GetById(int id)
        {
            var product = await _productService.GetProductByIdAsync(id);
            if (product == null)
                return NotFound();
            return Ok(product);
        }

        /// <summary>
        /// Create a new product.
        /// </summary>
        /// <param name="dto">The product data to create.</param>
        /// <returns>The newly created product, including its assigned ID.</returns>
        /// <response code="201">Product created successfully. The Location header points to the new resource.</response>
        /// <response code="400">The request body is invalid or failed validation.</response>
        [HttpPost]
        [ProducesResponseType(typeof(ProductReadDto), 201)]
        [ProducesResponseType(400)]
        public async Task<ActionResult<ProductReadDto>> Create([FromBody] ProductCreateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);
            var created = await _productService.CreateProductAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        /// <summary>
        /// Update an existing product.
        /// </summary>
        /// <param name="id">The unique identifier of the product to update.</param>
        /// <param name="dto">The updated product data.</param>
        /// <returns>No content on success.</returns>
        /// <response code="204">Product updated successfully.</response>
        /// <response code="400">The request body is invalid or failed validation.</response>
        /// <response code="404">No product with the given ID was found.</response>
        [HttpPut("{id}")]
        [ProducesResponseType(204)]
        [ProducesResponseType(400)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Update(int id, [FromBody] ProductUpdateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);
            var updated = await _productService.UpdateProductAsync(id, dto);
            if (!updated)
                return NotFound();
            return NoContent();
        }

        /// <summary>
        /// Delete a product by its unique identifier.
        /// </summary>
        /// <param name="id">The unique identifier of the product to delete.</param>
        /// <returns>No content on success.</returns>
        /// <response code="204">Product deleted successfully.</response>
        /// <response code="404">No product with the given ID was found.</response>
        [HttpDelete("{id}")]
        [ProducesResponseType(204)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Delete(int id)
        {
            var deleted = await _productService.DeleteProductAsync(id);
            if (!deleted)
                return NotFound();
            return NoContent();
        }

        /// <summary>
        /// Delete all products.
        /// </summary>
        /// <returns>No content on success.</returns>
        /// <response code="204">All products deleted successfully.</response>
        [HttpDelete]
        [ProducesResponseType(204)]
        public async Task<IActionResult> DeleteAll()
        {
            await _productService.DeleteAllProductsAsync();
            return NoContent();
        }
    }
}

using System.ComponentModel.DataAnnotations;

namespace ProductCrudApi.DTOs
{
    /// <summary>
    /// DTO for updating an existing product.
    /// </summary>
    public class ProductUpdateDto
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; }

        public string Description { get; set; }

        [Range(0, double.MaxValue)]
        public decimal Price { get; set; }

        [Range(0, int.MaxValue)]
        public int StockQuantity { get; set; }
    }
}

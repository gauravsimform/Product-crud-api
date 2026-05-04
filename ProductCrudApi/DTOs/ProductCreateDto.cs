using System.ComponentModel.DataAnnotations;

namespace ProductCrudApi.DTOs
{
    /// <summary>
    /// DTO for creating a new product.
    /// </summary>
    public class ProductCreateDto
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

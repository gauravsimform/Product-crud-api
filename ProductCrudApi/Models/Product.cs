using System;
using System.ComponentModel.DataAnnotations;

namespace ProductCrudApi.Models
{
    /// <summary>
    /// Product entity representing the product table in the database.
    /// </summary>
    public class Product
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; }

        public string Description { get; set; }

        [Range(0, double.MaxValue)]
        public decimal Price { get; set; }

        [Range(0, int.MaxValue)]
        public int StockQuantity { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}

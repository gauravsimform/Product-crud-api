using System;

namespace ProductCrudApi.DTOs
{
    /// <summary>
    /// DTO for reading product data.
    /// </summary>
    public class ProductReadDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public decimal Price { get; set; }
        public int StockQuantity { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

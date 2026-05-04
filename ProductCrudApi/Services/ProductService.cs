using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using AutoMapper;
using ProductCrudApi.DTOs;
using ProductCrudApi.Models;
using ProductCrudApi.Repositories;

namespace ProductCrudApi.Services
{
    /// <summary>
    /// Service implementation for product business logic.
    /// </summary>
    public class ProductService : IProductService
    {
        private readonly IProductRepository _productRepository;
        private readonly IMapper _mapper;

        public ProductService(IProductRepository productRepository, IMapper mapper)
        {
            _productRepository = productRepository;
            _mapper = mapper;
        }

        public async Task<IEnumerable<ProductReadDto>> GetAllProductsAsync()
        {
            var products = await _productRepository.GetAllAsync();
            return _mapper.Map<IEnumerable<ProductReadDto>>(products);
        }

        public async Task<ProductReadDto> GetProductByIdAsync(int id)
        {
            var product = await _productRepository.GetByIdAsync(id);
            return product == null ? null : _mapper.Map<ProductReadDto>(product);
        }

        public async Task<ProductReadDto> CreateProductAsync(ProductCreateDto dto)
        {
            var product = _mapper.Map<Product>(dto);
            product.CreatedAt = DateTime.UtcNow;
            await _productRepository.AddAsync(product);
            await _productRepository.SaveChangesAsync();
            return _mapper.Map<ProductReadDto>(product);
        }

        public async Task<bool> UpdateProductAsync(int id, ProductUpdateDto dto)
        {
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null)
                return false;
            _mapper.Map(dto, product);
            _productRepository.Update(product);
            await _productRepository.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteProductAsync(int id)
        {
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null)
                return false;
            _productRepository.Delete(product);
            await _productRepository.SaveChangesAsync();
            return true;
        }
    }
}

using AutoMapper;
using ProductCrudApi.DTOs;
using ProductCrudApi.Models;

namespace ProductCrudApi
{
    /// <summary>
    /// AutoMapper profile for mapping between entities and DTOs.
    /// </summary>
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<Product, ProductReadDto>();
            CreateMap<ProductCreateDto, Product>();
            CreateMap<ProductUpdateDto, Product>();
        }
    }
}

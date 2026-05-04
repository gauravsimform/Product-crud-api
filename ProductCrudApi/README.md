# ProductCrudApi

A clean architecture ASP.NET Core Web API for Product CRUD operations using .NET 10, Entity Framework Core, SQL Server, and AutoMapper.

## Features
- Clean architecture (Controllers, Services, Repositories, Models, DTOs)
- Entity Framework Core (Code First)
- SQL Server database
- Dependency Injection
- AutoMapper for DTO mapping
- Async/await for all DB operations
- Data annotations for validation
- Swagger for API documentation

## Getting Started

1. **Configure SQL Server**
   - Update the connection string in `appsettings.json` if needed.

2. **Add Migrations & Update Database**
   - Open terminal in the project directory.
   - Run:
     ```
     dotnet ef migrations add InitialCreate
     dotnet ef database update
     ```

3. **Run the API**
   - Run:
     ```
     dotnet run
     ```
   - The API will be available at `https://localhost:5001` (or as configured).

## Folder Structure
```
ProductCrudApi/
├── Controllers/
│   └── ProductController.cs
├── DTOs/
│   ├── ProductCreateDto.cs
│   ├── ProductReadDto.cs
│   └── ProductUpdateDto.cs
├── Models/
│   └── Product.cs
├── Repositories/
│   ├── GenericRepository.cs
│   ├── IGenericRepository.cs
│   ├── IProductRepository.cs
│   └── ProductRepository.cs
├── Services/
│   ├── IProductService.cs
│   └── ProductService.cs
├── AppDbContext.cs
├── MappingProfile.cs
├── Program.cs
├── appsettings.json
└── README.md
```

## Comments
- All important parts are commented in code.
- Follow best practices for .NET 10 and clean architecture.

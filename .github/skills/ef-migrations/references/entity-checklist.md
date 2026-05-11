# New Entity Checklist — ProductCrudApi

Use this as a final review before opening a PR whenever a new entity is added.

## Files to Create

| # | File | Notes |
|---|------|-------|
| 1 | `Models/<Entity>.cs` | Data annotations consistent with `Product.cs`; include `CreatedAt` |
| 2 | `DTOs/<Entity>CreateDto.cs` | Only writable fields; never expose `Id` or `CreatedAt` |
| 3 | `DTOs/<Entity>ReadDto.cs` | All fields the API consumer needs to read |
| 4 | `DTOs/<Entity>UpdateDto.cs` | Writable fields for partial/full update |
| 5 | `Repositories/I<Entity>Repository.cs` | Extends `IGenericRepository<TEntity>` |
| 6 | `Repositories/<Entity>Repository.cs` | Extends `GenericRepository<TEntity>` |
| 7 | `Services/I<Entity>Service.cs` | CRUD method signatures using DTOs |
| 8 | `Services/<Entity>Service.cs` | Uses `IMapper` and the repository |
| 9 | `Controllers/<Entity>Controller.cs` | `[ApiController]`, `[Route("api/[controller]")]`, `ProducesResponseType` |

## Files to Update

| # | File | Change |
|---|------|--------|
| 1 | `AppDbContext.cs` | Add `public DbSet<Entity> Entities { get; set; }` |
| 2 | `MappingProfile.cs` | Add three `CreateMap` entries (Entity→ReadDto, CreateDto→Entity, UpdateDto→Entity) |
| 3 | `Program.cs` | Register `I<Entity>Repository` / `<Entity>Repository` and `I<Entity>Service` / `<Entity>Service` via `builder.Services.AddScoped` |

## Migration Steps

```powershell
# 1. Create the migration
dotnet ef migrations add Add<Entity>Entity --project ProductCrudApi --startup-project ProductCrudApi

# 2. Inspect the generated Up() in Migrations/<timestamp>_Add<Entity>Entity.cs

# 3. Apply
dotnet ef database update --project ProductCrudApi --startup-project ProductCrudApi

# 4. Confirm
dotnet ef migrations list --project ProductCrudApi --startup-project ProductCrudApi
```

## Data Annotation Rules (match `Product.cs` conventions)

| Column type | Annotation |
|-------------|------------|
| Required string | `[Required]` + `[MaxLength(N)]` |
| Optional string | `[MaxLength(N)]` only |
| Non-negative decimal | `[Range(0, double.MaxValue)]` + `[Column(TypeName = "decimal(18,2)")]` |
| Non-negative integer | `[Range(0, int.MaxValue)]` |
| Primary key | `[Key]` on `int Id` (auto-identity via EF convention) |

## Quick Validation

- [ ] `dotnet build` succeeds with no warnings
- [ ] `dotnet ef migrations list` shows the new migration as applied
- [ ] `GET /api/<entity>` returns `200 []`
- [ ] `POST /api/<entity>` with valid body returns `201` with `Location` header
- [ ] `GET /api/<entity>/{id}` returns `404` for an unknown ID

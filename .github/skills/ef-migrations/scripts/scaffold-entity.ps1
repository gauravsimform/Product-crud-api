<#
.SYNOPSIS
    Scaffolds all boilerplate files for a new entity in ProductCrudApi,
    following the existing Model → DTO → Repository → Service → Controller pattern.

.PARAMETER EntityName
    PascalCase name of the new entity (e.g. "Category", "Supplier").

.EXAMPLE
    .\scaffold-entity.ps1 -EntityName Category

.NOTES
    After running this script:
      1. Fill in the properties in Models\<Entity>.cs
      2. Add a DbSet<Entity> to AppDbContext.cs
      3. Run: dotnet ef migrations add Add<Entity>Entity --project ProductCrudApi --startup-project ProductCrudApi
      4. Run: dotnet ef database update --project ProductCrudApi --startup-project ProductCrudApi
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Z][a-zA-Z0-9]+$')]
    [string]$EntityName
)

$root       = Split-Path $PSScriptRoot -Parent   # .github/skills/ef-migrations  -> solution root
$projDir    = Join-Path $root "ProductCrudApi"
$ns         = "ProductCrudApi"
$entity     = $EntityName
$entityLower = $entity.Substring(0,1).ToLower() + $entity.Substring(1)

function Write-Stub {
    param([string]$Path, [string]$Content)
    if (Test-Path $Path) {
        Write-Warning "File already exists, skipping: $Path"
        return
    }
    New-Item -ItemType File -Path $Path -Force | Out-Null
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Host "  Created: $Path" -ForegroundColor Green
}

# ── Model ──────────────────────────────────────────────────────────────────
Write-Stub (Join-Path $projDir "Models\$entity.cs") @"
using System;
using System.ComponentModel.DataAnnotations;

namespace $ns.Models
{
    public class $entity
    {
        [Key]
        public int Id { get; set; }

        // TODO: add properties here

        public DateTime CreatedAt { get; set; }
    }
}
"@

# ── DTOs ───────────────────────────────────────────────────────────────────
Write-Stub (Join-Path $projDir "DTOs\${entity}CreateDto.cs") @"
using System.ComponentModel.DataAnnotations;

namespace $ns.DTOs
{
    public class ${entity}CreateDto
    {
        // TODO: add create properties here
    }
}
"@

Write-Stub (Join-Path $projDir "DTOs\${entity}ReadDto.cs") @"
namespace $ns.DTOs
{
    public class ${entity}ReadDto
    {
        public int Id { get; set; }

        // TODO: add read properties here
    }
}
"@

Write-Stub (Join-Path $projDir "DTOs\${entity}UpdateDto.cs") @"
using System.ComponentModel.DataAnnotations;

namespace $ns.DTOs
{
    public class ${entity}UpdateDto
    {
        // TODO: add update properties here
    }
}
"@

# ── Repository interface ────────────────────────────────────────────────────
Write-Stub (Join-Path $projDir "Repositories\I${entity}Repository.cs") @"
using $ns.Models;

namespace $ns.Repositories
{
    public interface I${entity}Repository : IGenericRepository<$entity>
    {
        // Add $entity-specific query methods here
    }
}
"@

# ── Repository implementation ───────────────────────────────────────────────
Write-Stub (Join-Path $projDir "Repositories\${entity}Repository.cs") @"
using $ns.Models;
using Microsoft.EntityFrameworkCore;

namespace $ns.Repositories
{
    public class ${entity}Repository : GenericRepository<$entity>, I${entity}Repository
    {
        public ${entity}Repository(AppDbContext context) : base(context) { }

        // Implement $entity-specific query methods here
    }
}
"@

# ── Service interface ───────────────────────────────────────────────────────
Write-Stub (Join-Path $projDir "Services\I${entity}Service.cs") @"
using System.Collections.Generic;
using System.Threading.Tasks;
using $ns.DTOs;

namespace $ns.Services
{
    public interface I${entity}Service
    {
        Task<IEnumerable<${entity}ReadDto>> GetAll${entity}sAsync();
        Task<${entity}ReadDto?> Get${entity}ByIdAsync(int id);
        Task<${entity}ReadDto> Create${entity}Async(${entity}CreateDto dto);
        Task<bool> Update${entity}Async(int id, ${entity}UpdateDto dto);
        Task<bool> Delete${entity}Async(int id);
    }
}
"@

# ── Service implementation ──────────────────────────────────────────────────
Write-Stub (Join-Path $projDir "Services\${entity}Service.cs") @"
using System.Collections.Generic;
using System.Threading.Tasks;
using AutoMapper;
using $ns.DTOs;
using $ns.Models;
using $ns.Repositories;

namespace $ns.Services
{
    public class ${entity}Service : I${entity}Service
    {
        private readonly I${entity}Repository _repo;
        private readonly IMapper _mapper;

        public ${entity}Service(I${entity}Repository repo, IMapper mapper)
        {
            _repo   = repo;
            _mapper = mapper;
        }

        public async Task<IEnumerable<${entity}ReadDto>> GetAll${entity}sAsync()
            => _mapper.Map<IEnumerable<${entity}ReadDto>>(await _repo.GetAllAsync());

        public async Task<${entity}ReadDto?> Get${entity}ByIdAsync(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            return entity is null ? null : _mapper.Map<${entity}ReadDto>(entity);
        }

        public async Task<${entity}ReadDto> Create${entity}Async(${entity}CreateDto dto)
        {
            var entity = _mapper.Map<$entity>(dto);
            entity.CreatedAt = System.DateTime.UtcNow;
            await _repo.AddAsync(entity);
            await _repo.SaveChangesAsync();
            return _mapper.Map<${entity}ReadDto>(entity);
        }

        public async Task<bool> Update${entity}Async(int id, ${entity}UpdateDto dto)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return false;
            _mapper.Map(dto, entity);
            _repo.Update(entity);
            await _repo.SaveChangesAsync();
            return true;
        }

        public async Task<bool> Delete${entity}Async(int id)
        {
            var entity = await _repo.GetByIdAsync(id);
            if (entity is null) return false;
            _repo.Delete(entity);
            await _repo.SaveChangesAsync();
            return true;
        }
    }
}
"@

# ── Controller ──────────────────────────────────────────────────────────────
Write-Stub (Join-Path $projDir "Controllers\${entity}Controller.cs") @"
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;
using $ns.DTOs;
using $ns.Services;

namespace $ns.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ${entity}Controller : ControllerBase
    {
        private readonly I${entity}Service _${entityLower}Service;

        public ${entity}Controller(I${entity}Service ${entityLower}Service)
            => _${entityLower}Service = ${entityLower}Service;

        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<${entity}ReadDto>), 200)]
        public async Task<ActionResult<IEnumerable<${entity}ReadDto>>> GetAll()
            => Ok(await _${entityLower}Service.GetAll${entity}sAsync());

        [HttpGet("{id}")]
        [ProducesResponseType(typeof(${entity}ReadDto), 200)]
        [ProducesResponseType(404)]
        public async Task<ActionResult<${entity}ReadDto>> GetById(int id)
        {
            var result = await _${entityLower}Service.Get${entity}ByIdAsync(id);
            return result is null ? NotFound() : Ok(result);
        }

        [HttpPost]
        [ProducesResponseType(typeof(${entity}ReadDto), 201)]
        [ProducesResponseType(400)]
        public async Task<ActionResult<${entity}ReadDto>> Create([FromBody] ${entity}CreateDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var created = await _${entityLower}Service.Create${entity}Async(dto);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        [HttpPut("{id}")]
        [ProducesResponseType(204)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Update(int id, [FromBody] ${entity}UpdateDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            return await _${entityLower}Service.Update${entity}Async(id, dto) ? NoContent() : NotFound();
        }

        [HttpDelete("{id}")]
        [ProducesResponseType(204)]
        [ProducesResponseType(404)]
        public async Task<IActionResult> Delete(int id)
            => await _${entityLower}Service.Delete${entity}Async(id) ? NoContent() : NotFound();
    }
}
"@

Write-Host @"

Scaffolding complete for entity '$entity'.

Next steps:
  1. Add properties to Models\$entity.cs
  2. Update DTOs (${entity}CreateDto, ${entity}ReadDto, ${entity}UpdateDto)
  3. Add mapping profiles in MappingProfile.cs:
       CreateMap<$entity, ${entity}ReadDto>();
       CreateMap<${entity}CreateDto, $entity>();
       CreateMap<${entity}UpdateDto, $entity>();
  4. Register I${entity}Repository / ${entity}Repository and I${entity}Service / ${entity}Service in Program.cs
  5. Add DbSet<$entity> $($entity)s to AppDbContext.cs
  6. Run: dotnet ef migrations add Add${entity}Entity --project ProductCrudApi --startup-project ProductCrudApi
  7. Run: dotnet ef database update --project ProductCrudApi --startup-project ProductCrudApi
"@ -ForegroundColor Cyan

---
name: ef-migrations
description: 'EF Core database migrations for ProductCrudApi. Use when adding a new model/entity, modifying an existing model, creating a migration, applying pending migrations, reverting a migration, or checking migration status. Covers the full workflow: model change → migration → apply → verify.'
argument-hint: 'Describe what changed (e.g., "add Category entity" or "add IsActive column to Products")'
---

# EF Core Migrations — ProductCrudApi

## When to Use

- Adding a new entity/table to the database
- Modifying an existing model property (rename, type change, nullable, length)
- Applying pending migrations to a target environment
- Reverting (rolling back) a migration
- Checking which migrations have or haven't been applied

## Project Context

| Item | Value |
|------|-------|
| Project folder | `ProductCrudApi/` |
| DbContext | `AppDbContext` (registers all `DbSet<T>`) |
| Migrations folder | `ProductCrudApi/Migrations/` |
| Connection string key | `ConnectionStrings:DefaultConnection` |
| ORM | Entity Framework Core (EF Core) |
| Database | SQL Server (via `Microsoft.EntityFrameworkCore.SqlServer`) |

---

## Procedure

### 1 — Make the Model Change

1. Edit or create the model in `ProductCrudApi/Models/`.
2. If it is a **new** entity, add a `DbSet<T>` to `AppDbContext.cs`.
3. Add Data Annotations (`[Required]`, `[MaxLength]`, `[Range]`, etc.) consistent with the existing `Product` model.

Refer to [entity checklist](./references/entity-checklist.md) for the full list of files that must be created or updated when adding a new entity.

### 2 — Create the Migration

Run from the **solution root** (`c:\Users\gaurav\Product-crud-api\`):

```powershell
# Replace <MigrationName> with a concise PascalCase description, e.g. AddCategoryEntity
dotnet ef migrations add <MigrationName> --project ProductCrudApi --startup-project ProductCrudApi
```

Verify:
- A new `<timestamp>_<MigrationName>.cs` file appears in `ProductCrudApi/Migrations/`.
- `AppDbContextModelSnapshot.cs` is updated.
- The generated `Up()` matches your intent; inspect it before applying.

Use the [migration script](./scripts/manage-migrations.ps1) for an interactive menu.

### 3 — Apply the Migration

```powershell
dotnet ef database update --project ProductCrudApi --startup-project ProductCrudApi
```

To apply up to a specific migration (not the latest):

```powershell
dotnet ef database update <MigrationName> --project ProductCrudApi --startup-project ProductCrudApi
```

### 4 — Verify

```powershell
dotnet ef migrations list --project ProductCrudApi --startup-project ProductCrudApi
```

Applied migrations are shown without the `(Pending)` suffix.

### 5 — Revert a Migration

**Revert to the previous migration** (rolls back the last `Up()` in the database, then removes the file):

```powershell
# Step A: roll back in the database to the migration BEFORE the one you want to remove
dotnet ef database update <PreviousMigrationName> --project ProductCrudApi --startup-project ProductCrudApi

# Step B: delete the migration files
dotnet ef migrations remove --project ProductCrudApi --startup-project ProductCrudApi
```

> **Warning**: `migrations remove` only works when the migration has not yet been applied, OR after you have already rolled back the database (Step A). Never remove an applied migration without rolling back first.

---

## Adding a Completely New Entity (end-to-end)

Run the scaffold script and follow its prompts:

```powershell
.\scripts\scaffold-entity.ps1 -EntityName <PascalCaseName>
```

The script creates stub files for: Model, DTOs (Create/Read/Update), Repository interface + implementation, Service interface + implementation, and Controller. After scaffolding, review each file, then follow steps 1–4 above to create and apply the migration.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running `dotnet ef` from inside `ProductCrudApi/` without `--project` flags | Always run from the solution root with both flags |
| Forgetting to register the new `DbSet<T>` in `AppDbContext` | EF Core won't detect the entity without it |
| Applying a migration before reviewing `Up()` | Always inspect the generated file first |
| Removing a migration that is already applied | Roll back the database first (Step 5A) |
| Using `decimal` without precision annotation | Add `[Column(TypeName = "decimal(18,2)")]` |

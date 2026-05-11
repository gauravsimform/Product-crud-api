<#
.SYNOPSIS
    Interactive EF Core migration manager for ProductCrudApi.

.DESCRIPTION
    Provides a menu-driven interface for common EF Core migration tasks:
      1. List migrations and their applied status
      2. Create a new migration
      3. Apply all pending migrations
      4. Apply up to a specific migration
      5. Revert (remove) the last migration safely

.NOTES
    Run from the solution root:  .\scripts\manage-migrations.ps1
    Requires the dotnet-ef global tool:  dotnet tool install --global dotnet-ef
#>

param(
    [string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent)
)

Set-Location $ProjectRoot

$project  = "ProductCrudApi"
$startup  = "ProductCrudApi"
$efArgs   = "--project $project --startup-project $startup"

function Invoke-Ef {
    param([string]$Arguments)
    $cmd = "dotnet ef $Arguments $efArgs"
    Write-Host "`n> $cmd`n" -ForegroundColor Cyan
    Invoke-Expression $cmd
}

function Show-Menu {
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "  EF Core Migration Manager" -ForegroundColor Yellow
    Write-Host "  Project: $project" -ForegroundColor DarkGray
    Write-Host "========================================`n" -ForegroundColor Yellow
    Write-Host "  1. List migrations"
    Write-Host "  2. Create a new migration"
    Write-Host "  3. Apply ALL pending migrations"
    Write-Host "  4. Apply up to a specific migration"
    Write-Host "  5. Revert (remove) last migration"
    Write-Host "  6. Generate SQL script for pending migrations"
    Write-Host "  Q. Quit`n"
}

do {
    Show-Menu
    $choice = Read-Host "Enter choice"

    switch ($choice.ToUpper()) {

        '1' {
            Invoke-Ef "migrations list"
        }

        '2' {
            $name = Read-Host "Migration name (PascalCase, e.g. AddCategoryEntity)"
            if ([string]::IsNullOrWhiteSpace($name)) {
                Write-Warning "Migration name cannot be empty."
            } else {
                Invoke-Ef "migrations add $name"
                Write-Host "`nReview the generated Up() in ProductCrudApi/Migrations/ before applying." -ForegroundColor Green
            }
        }

        '3' {
            Invoke-Ef "database update"
        }

        '4' {
            Invoke-Ef "migrations list"
            $target = Read-Host "`nEnter the target migration name"
            if ([string]::IsNullOrWhiteSpace($target)) {
                Write-Warning "Target migration name cannot be empty."
            } else {
                Invoke-Ef "database update $target"
            }
        }

        '5' {
            Write-Host "`nWARNING: This will roll back the last applied migration and delete its files." -ForegroundColor Red
            $confirm = Read-Host "Type 'yes' to confirm"
            if ($confirm -eq 'yes') {
                # List so the user can see the previous migration name
                Invoke-Ef "migrations list"
                $prev = Read-Host "`nEnter the migration name to roll BACK TO (the one before the last)"
                if (-not [string]::IsNullOrWhiteSpace($prev)) {
                    Invoke-Ef "database update $prev"
                }
                Invoke-Ef "migrations remove"
            } else {
                Write-Host "Aborted." -ForegroundColor Yellow
            }
        }

        '6' {
            $outputFile = ".\pending-migrations.sql"
            $cmd = "dotnet ef migrations script --idempotent --output $outputFile $efArgs"
            Write-Host "`n> $cmd`n" -ForegroundColor Cyan
            Invoke-Expression $cmd
            Write-Host "`nSQL script saved to: $outputFile" -ForegroundColor Green
        }

        'Q' { break }

        default {
            Write-Warning "Invalid choice. Please try again."
        }
    }
} while ($choice.ToUpper() -ne 'Q')

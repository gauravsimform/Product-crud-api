# ProductCrudApi

A production-ready ASP.NET Core Web API for Product CRUD operations built with .NET 10, Entity Framework Core, SQL Server, and AutoMapper following clean architecture principles.

[![.NET Version](https://img.shields.io/badge/.NET-10.0-purple.svg)](https://dotnet.microsoft.com/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/gauravsimform/Product-crud-api)

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [Database Setup](#database-setup)
- [Running the Application](#running-the-application)
- [API Endpoints](#api-endpoints)
- [Request & Response Examples](#request--response-examples)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Performance](#performance)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Project Overview

**ProductCrudApi** is a RESTful Web API that provides comprehensive Create, Read, Update, and Delete (CRUD) operations for managing product inventory. Built with ASP.NET Core, it follows clean architecture principles with clear separation of concerns across controllers, services, repositories, models, and DTOs.

This API is designed for:
- E-commerce platforms managing product catalogs
- Inventory management systems
- Learning clean architecture patterns in .NET
- Demonstrating best practices in RESTful API design

---

## ✨ Features

- ✅ **Full CRUD Operations** - Create, read, update, and delete products
- ✅ **Clean Architecture** - Layered design with repository and service patterns
- ✅ **Entity Framework Core** - Code-first approach with migrations
- ✅ **Auto-mapping** - Automatic entity-DTO conversion with AutoMapper
- ✅ **API Documentation** - Interactive Swagger/OpenAPI documentation
- ✅ **Health Checks** - Built-in health monitoring endpoints
- ✅ **CORS Enabled** - Cross-origin resource sharing configured
- ✅ **Input Validation** - Data annotation validation with detailed error responses
- ✅ **Batch Operations** - Delete all products functionality
- ✅ **SQL Server Integration** - Production-ready database support

---

## 🛠️ Technology Stack

| Technology | Version | Purpose |
|---|---|---|
| [ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/) | .NET 10 | Modern web framework for building APIs |
| [Entity Framework Core](https://learn.microsoft.com/en-us/ef/core/) | 8.0.0 | Object-relational mapper (ORM) for data access |
| [SQL Server](https://www.microsoft.com/en-us/sql-server) | 2022+ | Enterprise-grade relational database |
| [AutoMapper](https://automapper.org/) | 12.0.0 | Object-to-object mapping (Entity ↔ DTO) |
| [Swashbuckle (Swagger)](https://github.com/domaindrivendev/Swashbuckle.AspNetCore) | 6.5.0 | OpenAPI/Swagger documentation generator |
| [EF Core Health Checks](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks) | 8.0.0 | Application and database health monitoring |

---

## 📦 Prerequisites

Before running the project, ensure you have the following installed:

- **[.NET 10 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/10.0)** - Latest stable version
- **[SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)** - Express edition or higher
  - Alternatively: SQL Server LocalDB (included with Visual Studio)
- **[dotnet-ef CLI tool](https://learn.microsoft.com/en-us/ef/core/cli/dotnet)** - For database migrations

**Optional but recommended:**
- [Visual Studio 2024](https://visualstudio.microsoft.com/) or [Visual Studio Code](https://code.visualstudio.com/)
- [SQL Server Management Studio (SSMS)](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms) or [Azure Data Studio](https://learn.microsoft.com/en-us/azure-data-studio/)
- [Postman](https://www.postman.com/) or similar API testing tool

### Install EF Core CLI Tool

Install the Entity Framework Core CLI tool globally if not already installed:

```bash
dotnet tool install --global dotnet-ef
```

Verify installation:

```bash
dotnet ef --version
```

---

## 🚀 Installation & Setup

Follow these steps to get the application up and running:

### 1. Clone the Repository

```bash
git clone https://github.com/gauravsimform/Product-crud-api.git
cd Product-crud-api/ProductCrudApi
```

### 2. Restore NuGet Packages

```bash
dotnet restore
```

This downloads all required dependencies from NuGet.

### 3. Configure Database Connection

Update the connection string in `appsettings.json` or create `appsettings.Development.json` (see [Configuration](#configuration) section).

### 4. Apply Database Migrations

```bash
dotnet ef database update
```

This creates the database and applies all migrations.

### 5. Run the Application

```bash
dotnet run
```

The API will start and listen on the configured ports (typically `https://localhost:5001` and `http://localhost:5000`).

### 6. Access Swagger UI

Navigate to `https://localhost:<port>/swagger` in your browser to explore and test the API.

---

## ⚙️ Configuration

Application settings are managed through `appsettings.json` and environment-specific configuration files.

### Connection String Configuration

**`appsettings.json`** (default settings)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SERVER\\SQLEXPRESS;Database=ProductCrudDb;Trusted_Connection=true;TrustServerCertificate=True"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

**Replace `YOUR_SERVER\\SQLEXPRESS`** with your SQL Server instance:

- **Local default instance:** `localhost` or `(local)`
- **Named instance:** `localhost\\SQLEXPRESS` or `YOUR_MACHINE_NAME\\SQLEXPRESS`
- **LocalDB:** `(localdb)\\MSSQLLocalDB`
- **Remote server:** `your-server.database.windows.net` (Azure SQL Database)

### Environment-Specific Configuration

Create `appsettings.Development.json` for local development overrides:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=ProductCrudDb;Trusted_Connection=true;TrustServerCertificate=True"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information"
    }
  }
}
```

### Using Environment Variables

You can also configure settings using environment variables:

**Windows (PowerShell):**
```powershell
$env:ConnectionStrings__DefaultConnection = "Server=localhost;Database=ProductCrudDb;Trusted_Connection=true"
```

**Linux/macOS:**
```bash
export ConnectionStrings__DefaultConnection="Server=localhost;Database=ProductCrudDb;User Id=sa;Password=YourPassword"
```

### SQL Authentication (Alternative to Windows Authentication)

If not using Windows Authentication, modify the connection string:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=ProductCrudDb;User Id=your_username;Password=your_password;TrustServerCertificate=True"
  }
}
```

> **💡 Tip:** Never commit sensitive credentials to source control. Use [User Secrets](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets) for development or environment variables for production.

### Using User Secrets (Recommended for Development)

```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=localhost;Database=ProductCrudDb;Trusted_Connection=true;TrustServerCertificate=True"
```

---

## 🗄️ Database Setup

The project uses Entity Framework Core **Code First** approach with migrations to manage the database schema.

### Initial Database Creation

The project already includes migrations. Simply run:

```bash
dotnet ef database update
```

This creates the `ProductCrudDb` database with the `Products` table.

### Creating New Migrations (After Model Changes)

When you modify entity models, create a new migration:

```bash
dotnet ef migrations add YourMigrationName
dotnet ef database update
```

### Common Migration Commands

```bash
# List all migrations
dotnet ef migrations list

# Remove the last migration (if not applied)
dotnet ef migrations remove

# Generate SQL script from migrations
dotnet ef migrations script

# Drop the database (⚠️ Warning: data loss!)
dotnet ef database drop

# Update to a specific migration
dotnet ef database update MigrationName
```

### Database Schema

**Products Table Structure:**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `Id` | `int` | Primary Key, Identity | Auto-generated unique identifier |
| `Name` | `nvarchar(100)` | Required, MaxLength(100) | Product name |
| `Description` | `nvarchar(max)` | Nullable | Product description |
| `Price` | `decimal(18,2)` | Required, ≥ 0 | Product price |
| `StockQuantity` | `int` | Required, ≥ 0 | Available stock quantity |
| `CreatedAt` | `datetime2` | Required | Timestamp of creation |

---

## ▶️ Running the Application

### Development Mode

```bash
dotnet run
```

Or with watch mode (auto-recompiles on file changes):

```bash
dotnet watch run
```

### Production Build

```bash
# Build the application
dotnet build --configuration Release

# Run the built application
dotnet run --configuration Release
```

### Default URLs

The API listens on:

- **HTTPS:** `https://localhost:5001`
- **HTTP:** `http://localhost:5000`

> **Note:** Ports may vary based on your `launchSettings.json`. Check console output for actual URLs.

### Swagger UI (Development Only)

Interactive API documentation is available at:

```
https://localhost:<port>/swagger
```

Features:
- Explore all endpoints and their schemas
- Test API calls directly from the browser
- View request/response examples
- Download OpenAPI specification

### Health Check Endpoint

Monitor application and database health:

```bash
curl https://localhost:5001/health
```

**Healthy Response:**
```
Healthy
```

**Unhealthy Response** (e.g., database connection failed):
```json
{
  "status": "Unhealthy",
  "results": {
    "ProductCrudDb": {
      "status": "Unhealthy",
      "description": "Unable to connect to database",
      "data": {}
    }
  }
}
```

---

## 🔌 API Endpoints

Base URL: `/api/products`

All endpoints return JSON responses with appropriate HTTP status codes.

### Endpoints Summary

| Method | Endpoint | Description | Auth | Success Response |
|--------|----------|-------------|------|-----------------|
| `GET` | `/api/products` | Retrieve all products | None | `200 OK` |
| `GET` | `/api/products/{id}` | Retrieve a product by ID | None | `200 OK` / `404 Not Found` |
| `POST` | `/api/products` | Create a new product | None | `201 Created` |
| `PUT` | `/api/products/{id}` | Update an existing product | None | `204 No Content` / `404 Not Found` |
| `DELETE` | `/api/products/{id}` | Delete a product by ID | None | `204 No Content` / `404 Not Found` |
| `DELETE` | `/api/products` | Delete all products | None | `204 No Content` |

### Health Check

| Method | Endpoint | Description | Success Response |
|--------|----------|-------------|-----------------|
| `GET` | `/health` | Check API and database health | `200 OK` |

---

## 📝 Request & Response Examples

### Data Models

#### ProductReadDto (Response)

```json
{
  "id": 1,
  "name": "Laptop",
  "description": "High-performance laptop with 16GB RAM and 512GB SSD",
  "price": 999.99,
  "stockQuantity": 50,
  "createdAt": "2026-05-08T10:30:00Z"
}
```

#### ProductCreateDto (Request Body for POST)

```json
{
  "name": "Laptop",
  "description": "High-performance laptop with 16GB RAM and 512GB SSD",
  "price": 999.99,
  "stockQuantity": 50
}
```

**Validation Rules:**
- `name` — **Required**, max 100 characters
- `description` — Optional, unlimited length
- `price` — **Required**, must be ≥ 0
- `stockQuantity` — **Required**, must be ≥ 0

#### ProductUpdateDto (Request Body for PUT)

Same structure as `ProductCreateDto` with identical validation rules.

```json
{
  "name": "Updated Laptop",
  "description": "Updated description",
  "price": 899.99,
  "stockQuantity": 45
}
```

---

### 📍 GET /api/products

Retrieves a list of all products in the database.

**Request:**

```http
GET /api/products HTTP/1.1
Host: localhost:5001
Accept: application/json
```

**cURL Example:**

```bash
curl -X GET "https://localhost:5001/api/products" -H "accept: application/json"
```

**Response: `200 OK`**

```json
[
  {
    "id": 1,
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 999.99,
    "stockQuantity": 50,
    "createdAt": "2026-05-08T10:30:00Z"
  },
  {
    "id": 2,
    "name": "Mouse",
    "description": "Wireless mouse",
    "price": 29.99,
    "stockQuantity": 200,
    "createdAt": "2026-05-08T11:15:00Z"
  }
]
```

**Empty Database Response:**

```json
[]
```

---

### 📍 GET /api/products/{id}

Retrieves a single product by its unique identifier.

**Request:**

```http
GET /api/products/1 HTTP/1.1
Host: localhost:5001
Accept: application/json
```

**cURL Example:**

```bash
curl -X GET "https://localhost:5001/api/products/1" -H "accept: application/json"
```

**Response: `200 OK`**

```json
{
  "id": 1,
  "name": "Laptop",
  "description": "High-performance laptop",
  "price": 999.99,
  "stockQuantity": 50,
  "createdAt": "2026-05-08T10:30:00Z"
}
```

**Response: `404 Not Found`**

Returned when no product with the specified ID exists.

```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.4",
  "title": "Not Found",
  "status": 404,
  "traceId": "00-abc123..."
}
```

---

### 📍 POST /api/products

Creates a new product in the database.

**Request:**

```http
POST /api/products HTTP/1.1
Host: localhost:5001
Content-Type: application/json
Accept: application/json

{
  "name": "Keyboard",
  "description": "Mechanical gaming keyboard with RGB lighting",
  "price": 149.99,
  "stockQuantity": 75
}
```

**cURL Example:**

```bash
curl -X POST "https://localhost:5001/api/products" \
  -H "Content-Type: application/json" \
  -H "accept: application/json" \
  -d '{
    "name": "Keyboard",
    "description": "Mechanical gaming keyboard",
    "price": 149.99,
    "stockQuantity": 75
  }'
```

**Response: `201 Created`**

```json
{
  "id": 3,
  "name": "Keyboard",
  "description": "Mechanical gaming keyboard with RGB lighting",
  "price": 149.99,
  "stockQuantity": 75,
  "createdAt": "2026-05-08T14:00:00Z"
}
```

**Location Header:**
```
Location: https://localhost:5001/api/products/3
```

**Response: `400 Bad Request`**

Returned when validation fails:

```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "errors": {
    "Name": [
      "The Name field is required."
    ],
    "Price": [
      "The field Price must be between 0 and 1.79769313486232E+308."
    ]
  },
  "traceId": "00-xyz789..."
}
```

---

### 📍 PUT /api/products/{id}

Updates an existing product with new data.

**Request:**

```http
PUT /api/products/3 HTTP/1.1
Host: localhost:5001
Content-Type: application/json

{
  "name": "Keyboard",
  "description": "Mechanical gaming keyboard - RGB edition with macros",
  "price": 179.99,
  "stockQuantity": 60
}
```

**cURL Example:**

```bash
curl -X PUT "https://localhost:5001/api/products/3" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Keyboard",
    "description": "Mechanical gaming keyboard - RGB edition",
    "price": 179.99,
    "stockQuantity": 60
  }'
```

**Response: `204 No Content`**

Success response with no body. The product has been updated.

**Response: `404 Not Found`**

Returned when no product with the specified ID exists.

**Response: `400 Bad Request`**

Returned when validation fails (same format as POST).

---

### 📍 DELETE /api/products/{id}

Deletes a product by its unique identifier.

**Request:**

```http
DELETE /api/products/3 HTTP/1.1
Host: localhost:5001
```

**cURL Example:**

```bash
curl -X DELETE "https://localhost:5001/api/products/3"
```

**Response: `204 No Content`**

Success response with no body. The product has been deleted.

**Response: `404 Not Found`**

Returned when no product with the specified ID exists.

---

### 📍 DELETE /api/products

⚠️ **Danger:** Deletes **all** products from the database. Use with caution!

**Request:**

```http
DELETE /api/products HTTP/1.1
Host: localhost:5001
```

**cURL Example:**

```bash
curl -X DELETE "https://localhost:5001/api/products"
```

**Response: `204 No Content`**

Success response with no body. All products have been deleted.

---

## 📂 Project Structure

```
ProductCrudApi/
├── Controllers/
│   └── ProductController.cs          # HTTP request handlers & API endpoints
├── DTOs/
│   ├── ProductCreateDto.cs           # Data transfer object for creating products
│   ├── ProductReadDto.cs             # Data transfer object for API responses
│   └── ProductUpdateDto.cs           # Data transfer object for updating products
├── Models/
│   └── Product.cs                    # Entity Framework Core entity (domain model)
├── Repositories/
│   ├── IGenericRepository.cs         # Generic CRUD repository interface
│   ├── GenericRepository.cs          # Generic CRUD repository implementation
│   ├── IProductRepository.cs         # Product-specific repository interface
│   └── ProductRepository.cs          # Product-specific repository implementation
├── Services/
│   ├── IProductService.cs            # Product service interface (business logic)
│   └── ProductService.cs             # Product service implementation
├── Migrations/
│   ├── 20260428102413_InitialCreate.cs         # EF Core migration files
│   ├── 20260428102413_InitialCreate.Designer.cs
│   └── AppDbContextModelSnapshot.cs
├── Properties/
│   └── launchSettings.json           # Launch profiles & environment settings
├── AppDbContext.cs                   # Entity Framework Core DbContext
├── MappingProfile.cs                 # AutoMapper profile configuration
├── Program.cs                        # Application entry point & DI configuration
├── appsettings.json                  # Application configuration
├── appsettings.Development.json      # Development environment overrides
├── ProductCrudApi.csproj             # .NET project file
└── README.md                         # This documentation file
```

---

## 🏗️ Architecture Overview

The application follows a **layered clean architecture** pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                      HTTP Request                           │
│                     (JSON Payload)                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  🎮 CONTROLLER LAYER                        │
│                  (ProductController)                        │
│                                                             │
│  • Handles HTTP routing & request/response                 │
│  • Validates input data annotations                        │
│  • Returns appropriate HTTP status codes                   │
│  • Maps endpoints to service methods                       │
└────────────────────────┬────────────────────────────────────┘
                         │ Calls service methods
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   💼 SERVICE LAYER                          │
│                   (ProductService)                          │
│                                                             │
│  • Contains business logic & validation                    │
│  • Orchestrates operations                                 │
│  • Maps between entities and DTOs (AutoMapper)             │
│  • Manages transactions                                    │
└────────────────────────┬────────────────────────────────────┘
                         │ Calls repository methods
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 💾 REPOSITORY LAYER                         │
│              (ProductRepository, GenericRepository)         │
│                                                             │
│  • Abstracts data access logic                             │
│  • Provides CRUD operations                                │
│  • Uses Entity Framework Core                              │
│  • Enables testability via interfaces                      │
└────────────────────────┬────────────────────────────────────┘
                         │ Uses EF Core
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 🗄️ DATABASE LAYER                           │
│            (SQL Server via Entity Framework Core)           │
│                                                             │
│  • SQL Server database                                     │
│  • Code First with migrations                              │
│  • Connection pooling                                      │
│  • Transaction management                                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Patterns

#### 1. **Repository Pattern**
Decouples data access logic from business logic:
- **Generic Repository:** Provides common CRUD operations (`GetAll`, `GetById`, `Add`, `Update`, `Delete`)
- **Product Repository:** Extends generic repository with product-specific queries
- **Benefits:** Easy to test with mocks, swap data stores, and maintain

#### 2. **Service Layer Pattern**
Separates business logic from controllers:
- Keeps controllers thin and focused on HTTP concerns
- Centralizes business rules and validation
- Makes business logic reusable and testable

#### 3. **Data Transfer Objects (DTOs)**
Prevents over-posting and over-fetching:
- **ProductCreateDto:** Only fields needed for creation (no ID, no timestamp)
- **ProductReadDto:** Full data returned to clients
- **ProductUpdateDto:** Only fields that can be updated
- **Benefits:** API contract independent of database schema, security, validation

#### 4. **Dependency Injection**
All dependencies are registered in [Program.cs](ProductCrudApi/Program.cs) and injected via constructors:
```csharp
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<IProductService, ProductService>();
```

#### 5. **AutoMapper**
Automatic object-to-object mapping configured in [MappingProfile.cs](ProductCrudApi/MappingProfile.cs):
- `Product` → `ProductReadDto`
- `ProductCreateDto` → `Product`
- `ProductUpdateDto` → `Product`

### CORS Configuration

The API is configured with a permissive CORS policy (`AllowAll`):
```csharp
options.AddPolicy("AllowAll", 
    policy => policy.AllowAnyOrigin()
                    .AllowAnyMethod()
                    .AllowAnyHeader());
```

> ⚠️ **Production Warning:** Restrict CORS to specific origins in production environments for security.

---

## ⚠️ Error Handling

The API uses standard ASP.NET Core error handling with problem details (RFC 7807).

### Common HTTP Status Codes

| Status Code | Description | When It Occurs |
|-------------|-------------|----------------|
| `200 OK` | Success | Successful GET request |
| `201 Created` | Resource created | Successful POST request |
| `204 No Content` | Success, no body | Successful PUT/DELETE request |
| `400 Bad Request` | Validation error | Invalid input data, failed validation |
| `404 Not Found` | Resource not found | Product with specified ID doesn't exist |
| `500 Internal Server Error` | Server error | Unexpected server-side error |

### Validation Errors

**Example: Missing required field**

```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "errors": {
    "Name": ["The Name field is required."],
    "Price": ["The field Price must be between 0 and 1.79769313486232E+308."]
  },
  "traceId": "00-1234567890abcdef-1234567890abcdef-00"
}
```

### Not Found Error

**Example: Product doesn't exist**

```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.4",
  "title": "Not Found",
  "status": 404,
  "traceId": "00-1234567890abcdef-1234567890abcdef-00"
}
```

---

## 🧪 Testing

### Manual Testing with Swagger

1. Start the application in development mode
2. Navigate to `https://localhost:<port>/swagger`
3. Expand an endpoint
4. Click "Try it out"
5. Fill in parameters/body
6. Click "Execute"

### Testing with cURL

**Create a product:**
```bash
curl -X POST "https://localhost:5001/api/products" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","description":"Test","price":99.99,"stockQuantity":10}'
```

**Get all products:**
```bash
curl -X GET "https://localhost:5001/api/products" -H "accept: application/json"
```

**Get product by ID:**
```bash
curl -X GET "https://localhost:5001/api/products/1" -H "accept: application/json"
```

**Update product:**
```bash
curl -X PUT "https://localhost:5001/api/products/1" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Product","description":"Updated","price":89.99,"stockQuantity":5}'
```

**Delete product:**
```bash
curl -X DELETE "https://localhost:5001/api/products/1"
```

### Testing with PowerShell

```powershell
# Create a product
$body = @{
    name = "Test Product"
    description = "Test Description"
    price = 99.99
    stockQuantity = 10
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://localhost:5001/api/products" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body `
    -SkipCertificateCheck

# Get all products
Invoke-RestMethod -Uri "https://localhost:5001/api/products" `
    -Method GET `
    -SkipCertificateCheck
```

### Unit Testing (Future Enhancement)

Consider adding:
- **xUnit** or **NUnit** for unit testing framework
- **Moq** for mocking dependencies
- **FluentAssertions** for readable assertions
- **Integration tests** with in-memory database or TestContainers

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue: Cannot connect to SQL Server

**Error:** `A network-related or instance-specific error occurred...`

**Solutions:**
1. Verify SQL Server is running:
   ```bash
   # Windows Services
   services.msc
   # Look for "SQL Server (SQLEXPRESS)"
   ```
2. Check connection string in `appsettings.json`
3. Verify server name: Run `SELECT @@SERVERNAME` in SSMS
4. Enable TCP/IP protocol in SQL Server Configuration Manager
5. Check firewall settings

#### Issue: Migration Failed

**Error:** `Unable to create migration...`

**Solutions:**
1. Ensure `dotnet-ef` tool is installed:
   ```bash
   dotnet tool install --global dotnet-ef
   ```
2. Rebuild the project:
   ```bash
   dotnet build
   ```
3. Clear EF Core cache:
   ```bash
   dotnet ef database update 0
   dotnet ef migrations remove
   ```

#### Issue: Port Already in Use

**Error:** `Failed to bind to address https://127.0.0.1:5001`

**Solutions:**
1. Change ports in [launchSettings.json](ProductCrudApi/Properties/launchSettings.json)
2. Stop other processes using the port:
   ```bash
   # Windows
   netstat -ano | findstr :5001
   taskkill /PID <process_id> /F
   ```

#### Issue: HTTPS Certificate Not Trusted

**Error:** `The SSL connection could not be established...`

**Solutions:**
```bash
# Trust the development certificate
dotnet dev-certs https --clean
dotnet dev-certs https --trust
```

#### Issue: 404 Not Found on All Endpoints

**Solutions:**
1. Verify the API is running
2. Check the correct base URL: `/api/products`
3. Ensure `MapControllers()` is called in `Program.cs`
4. Verify controller has `[ApiController]` and `[Route]` attributes

#### Issue: CORS Errors in Browser

**Error:** `Access to fetch at 'https://localhost:5001/api/products' from origin 'http://localhost:3000' has been blocked by CORS policy`

**Solution:**
CORS is already configured with `AllowAll` policy. If still seeing errors:
1. Ensure `app.UseCors("AllowAll")` is called before `app.MapControllers()` in `Program.cs`
2. For specific origins, modify CORS policy:
   ```csharp
   options.AddPolicy("AllowSpecific", 
       policy => policy.WithOrigins("http://localhost:3000")
                       .AllowAnyMethod()
                       .AllowAnyHeader());
   ```

---

## 🔒 Security Considerations

### Current Security Posture

This API is configured for **development** and requires hardening for production:

⚠️ **Not Implemented (Development Mode):**
- Authentication & Authorization
- Rate limiting
- Input sanitization beyond validation
- HTTPS enforcement in all environments
- Secure CORS policy

### Production Security Checklist

- [ ] **Implement Authentication:** Add JWT Bearer tokens or OAuth 2.0
- [ ] **Add Authorization:** Role-based or policy-based access control
- [ ] **Restrict CORS:** Allow only trusted origins
  ```csharp
  policy.WithOrigins("https://yourdomain.com")
  ```
- [ ] **Enable HTTPS Only:** Remove HTTP endpoints
- [ ] **Implement Rate Limiting:** Prevent abuse
  ```csharp
  builder.Services.AddRateLimiter(options => { ... });
  ```
- [ ] **Validate All Input:** Already using data annotations, consider FluentValidation
- [ ] **Protect Connection Strings:** Use Azure Key Vault or environment variables
- [ ] **Enable SQL Injection Protection:** EF Core parameterizes queries (✅ already safe)
- [ ] **Add Request Logging:** Implement structured logging (Serilog)
- [ ] **Remove Swagger in Production:** Or protect with authentication
- [ ] **Implement API Versioning:** For backward compatibility
- [ ] **Add Health Check Authentication:** Protect `/health` endpoint

### Sensitive Data Management

**Never commit secrets to source control!**

Use one of these approaches:

**1. User Secrets (Development):**
```bash
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "your-connection-string"
```

**2. Environment Variables (Production):**
```bash
export ConnectionStrings__DefaultConnection="your-connection-string"
```

**3. Azure Key Vault (Cloud):**
```csharp
builder.Configuration.AddAzureKeyVault(/* ... */);
```

---

## ⚡ Performance

### Current Performance Characteristics

- **Entity Framework Core** with SQL Server provides excellent performance for typical workloads
- **Connection pooling** is enabled by default
- **Async/await** used throughout for non-blocking I/O operations

### Performance Best Practices

✅ **Already Implemented:**
- Asynchronous operations (`async`/`await`)
- Repository pattern for data access
- DTO pattern to control data shape
- EF Core tracking optimization

💡 **Potential Improvements:**

**1. Add Response Caching:**
```csharp
builder.Services.AddResponseCaching();
app.UseResponseCaching();

// In controller
[HttpGet]
[ResponseCache(Duration = 60)]
public async Task<ActionResult<IEnumerable<ProductReadDto>>> GetAll()
```

**2. Implement Pagination:**
```csharp
[HttpGet]
public async Task<ActionResult<IEnumerable<ProductReadDto>>> GetAll(
    [FromQuery] int page = 1, 
    [FromQuery] int pageSize = 10)
{
    var products = await _productService.GetProductsAsync(page, pageSize);
    return Ok(products);
}
```

**3. Add Database Indexes:**
```csharp
modelBuilder.Entity<Product>()
    .HasIndex(p => p.Name);
```

**4. Enable Response Compression:**
```csharp
builder.Services.AddResponseCompression();
app.UseResponseCompression();
```

**5. Use Database Connection Resiliency:**
```csharp
options.UseSqlServer(connectionString, 
    sqlServerOptionsAction: sqlOptions =>
    {
        sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null);
    });
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** and commit:
   ```bash
   git commit -m "Add: description of your changes"
   ```
4. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```
5. **Open a Pull Request** with a clear description

### Code Standards

- Follow [C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- Add XML documentation comments for public APIs
- Write meaningful commit messages
- Ensure all tests pass before submitting PR
- Update documentation for new features

### Development Workflow

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/Product-crud-api.git

# Create a branch
git checkout -b feature/my-new-feature

# Make changes and test
dotnet build
dotnet run

# Commit and push
git add .
git commit -m "Add: my new feature"
git push origin feature/my-new-feature
```

---

## 📄 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2026 Gaurav Simform

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Support & Contact

- **Repository:** [https://github.com/gauravsimform/Product-crud-api](https://github.com/gauravsimform/Product-crud-api)
- **Issues:** [GitHub Issues](https://github.com/gauravsimform/Product-crud-api/issues)
- **Documentation:** This README and inline code documentation

---

## 🙏 Acknowledgments

- **ASP.NET Core Team** - For the excellent web framework
- **Entity Framework Core Team** - For the powerful ORM
- **AutoMapper** - For object mapping capabilities
- **Swashbuckle** - For API documentation generation

---

**Built with ❤️ using ASP.NET Core and .NET 10**

*Last Updated: May 8, 2026*

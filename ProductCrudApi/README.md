# ProductCrudApi

A clean architecture ASP.NET Core Web API for Product CRUD operations using .NET 10, Entity Framework Core, SQL Server, and AutoMapper.

## Table of Contents

- [Project Overview](#project-overview)
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

---

## Project Overview

**ProductCrudApi** is a RESTful Web API that provides full Create, Read, Update, and Delete (CRUD) operations for products. It is built with ASP.NET Core following clean architecture principles, separating concerns across controllers, services, repositories, models, and DTOs.

---

## Technology Stack

| Technology | Version | Purpose |
|---|---|---|
| [ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/) | .NET 10 | Web framework |
| [Entity Framework Core](https://learn.microsoft.com/en-us/ef/core/) | 8.0.0 | ORM / database access |
| [SQL Server](https://www.microsoft.com/en-us/sql-server) | — | Relational database |
| [AutoMapper](https://automapper.org/) | 12.0.0 | Object-to-object mapping (Entity ↔ DTO) |
| [Swashbuckle (Swagger)](https://github.com/domaindrivendev/Swashbuckle.AspNetCore) | 6.5.0 | Interactive API documentation UI |
| [EF Core Health Checks](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks) | 8.0.0 | Application health monitoring |

---

## Prerequisites

Before running the project, make sure you have the following installed:

- [.NET 10 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/10.0)
- [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) (Express edition works fine)
- [dotnet-ef CLI tool](https://learn.microsoft.com/en-us/ef/core/cli/dotnet)

Install the EF Core CLI tool globally if not already installed:

```bash
dotnet tool install --global dotnet-ef
```

---

## Installation & Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/gauravsimform/Product-crud-api.git
   cd Product-crud-api/ProductCrudApi
   ```

2. **Restore NuGet packages**

   ```bash
   dotnet restore
   ```

3. **Configure the database connection** (see [Configuration](#configuration))

4. **Apply database migrations** (see [Database Setup](#database-setup))

5. **Run the application** (see [Running the Application](#running-the-application))

---

## Configuration

Connection strings and application settings are stored in `appsettings.json`.

**`appsettings.json`**

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

Replace `YOUR_SERVER\\SQLEXPRESS` with your actual SQL Server instance name (e.g., `localhost\\SQLEXPRESS` or just `localhost` for a default instance).

> **Tip:** For local development you can use `appsettings.Development.json` to override settings without modifying the committed file.

---

## Database Setup

The project uses Entity Framework Core **Code First** migrations to manage the database schema.

1. **Add the initial migration** (only needed once, or after model changes):

   ```bash
   dotnet ef migrations add InitialCreate
   ```

2. **Apply migrations to create/update the database:**

   ```bash
   dotnet ef database update
   ```

This creates the `ProductCrudDb` database and the `Products` table automatically.

---

## Running the Application

```bash
dotnet run
```

By default the API listens on:

- `https://localhost:5001`
- `http://localhost:5000`

(Exact ports may vary; check the console output after starting.)

### Swagger UI

When running in the **Development** environment, an interactive Swagger UI is available at:

```
https://localhost:<port>/swagger
```

Use it to explore and test all endpoints directly in the browser.

### Health Check

A health check endpoint is exposed at:

```
GET /health
```

It verifies that the application and database connection are healthy.

---

## API Endpoints

Base URL: `/api/products`

| Method | Endpoint | Description | Request Body | Success Response |
|--------|----------|-------------|--------------|-----------------|
| `GET` | `/api/products` | Retrieve all products | — | `200 OK` |
| `GET` | `/api/products/{id}` | Retrieve a product by ID | — | `200 OK` / `404 Not Found` |
| `POST` | `/api/products` | Create a new product | `ProductCreateDto` | `201 Created` |
| `PUT` | `/api/products/{id}` | Update an existing product | `ProductUpdateDto` | `204 No Content` / `404 Not Found` |
| `DELETE` | `/api/products/{id}` | Delete a product by ID | — | `204 No Content` / `404 Not Found` |
| `DELETE` | `/api/products` | Delete all products | — | `204 No Content` |

---

## Request & Response Examples

### Data Models

**Product (response)**

```json
{
  "id": 1,
  "name": "Laptop",
  "description": "High-performance laptop",
  "price": 999.99,
  "stockQuantity": 50,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

**ProductCreateDto / ProductUpdateDto (request body)**

```json
{
  "name": "Laptop",
  "description": "High-performance laptop",
  "price": 999.99,
  "stockQuantity": 50
}
```

---

### GET /api/products

Retrieves a list of all products.

**Request**

```http
GET /api/products HTTP/1.1
Accept: application/json
```

**Response `200 OK`**

```json
[
  {
    "id": 1,
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 999.99,
    "stockQuantity": 50,
    "createdAt": "2024-01-15T10:30:00Z"
  },
  {
    "id": 2,
    "name": "Mouse",
    "description": "Wireless mouse",
    "price": 29.99,
    "stockQuantity": 200,
    "createdAt": "2024-01-16T08:00:00Z"
  }
]
```

---

### GET /api/products/{id}

Retrieves a single product by its ID.

**Request**

```http
GET /api/products/1 HTTP/1.1
Accept: application/json
```

**Response `200 OK`**

```json
{
  "id": 1,
  "name": "Laptop",
  "description": "High-performance laptop",
  "price": 999.99,
  "stockQuantity": 50,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

**Response `404 Not Found`** — when no product with the given ID exists.

---

### POST /api/products

Creates a new product.

**Request**

```http
POST /api/products HTTP/1.1
Content-Type: application/json

{
  "name": "Keyboard",
  "description": "Mechanical gaming keyboard",
  "price": 149.99,
  "stockQuantity": 75
}
```

**Validation rules:**
- `name` — required, max 100 characters
- `price` — must be ≥ 0
- `stockQuantity` — must be ≥ 0

**Response `201 Created`**

```json
{
  "id": 3,
  "name": "Keyboard",
  "description": "Mechanical gaming keyboard",
  "price": 149.99,
  "stockQuantity": 75,
  "createdAt": "2024-01-17T12:00:00Z"
}
```

**Response `400 Bad Request`** — when validation fails.

---

### PUT /api/products/{id}

Updates an existing product.

**Request**

```http
PUT /api/products/3 HTTP/1.1
Content-Type: application/json

{
  "name": "Keyboard",
  "description": "Mechanical gaming keyboard - RGB edition",
  "price": 179.99,
  "stockQuantity": 60
}
```

**Response `204 No Content`** — on success (no body).

**Response `404 Not Found`** — when no product with the given ID exists.

**Response `400 Bad Request`** — when validation fails.

---

### DELETE /api/products/{id}

Deletes a product by its ID.

**Request**

```http
DELETE /api/products/3 HTTP/1.1
```

**Response `204 No Content`** — on success (no body).

**Response `404 Not Found`** — when no product with the given ID exists.

---

### DELETE /api/products

Deletes **all** products.

**Request**

```http
DELETE /api/products HTTP/1.1
```

**Response `204 No Content`** — on success (no body).

---

## Project Structure

```
ProductCrudApi/
├── Controllers/
│   └── ProductController.cs      # HTTP request handling & routing
├── DTOs/
│   ├── ProductCreateDto.cs       # DTO for creating a product
│   ├── ProductReadDto.cs         # DTO returned in responses
│   └── ProductUpdateDto.cs       # DTO for updating a product
├── Models/
│   └── Product.cs                # EF Core entity / domain model
├── Repositories/
│   ├── IGenericRepository.cs     # Generic CRUD repository interface
│   ├── GenericRepository.cs      # Generic CRUD repository implementation
│   ├── IProductRepository.cs     # Product-specific repository interface
│   └── ProductRepository.cs      # Product-specific repository implementation
├── Services/
│   ├── IProductService.cs        # Product service interface (business logic)
│   └── ProductService.cs         # Product service implementation
├── AppDbContext.cs               # Entity Framework Core DbContext
├── MappingProfile.cs             # AutoMapper mapping configuration
├── Program.cs                    # Application entry point & DI configuration
├── appsettings.json              # Application configuration
└── README.md                     # This file
```

---

## Architecture Overview

The project follows a **layered clean architecture** pattern:

```
HTTP Request
     │
     ▼
┌─────────────────────┐
│   Controller Layer   │  Handles HTTP routing, input validation,
│  (ProductController) │  and returns HTTP responses.
└─────────┬───────────┘
          │ calls
          ▼
┌─────────────────────┐
│   Service Layer      │  Contains business logic. Maps between
│  (ProductService)    │  entities and DTOs using AutoMapper.
└─────────┬───────────┘
          │ calls
          ▼
┌─────────────────────┐
│  Repository Layer    │  Abstracts database access using
│ (ProductRepository)  │  Entity Framework Core.
└─────────┬───────────┘
          │ uses
          ▼
┌─────────────────────┐
│  Database (SQL       │  SQL Server via Entity Framework Core
│  Server / EF Core)   │  Code First with migrations.
└─────────────────────┘
```

**Key design decisions:**

- **Repository pattern** — Decouples data access from business logic, making it easy to swap the data store or write unit tests with mocks.
- **Service layer** — Keeps controllers thin; all business rules live in the service layer.
- **DTOs with AutoMapper** — Prevents over-posting and over-fetching, and decouples the API contract from the database schema.
- **Dependency Injection** — All dependencies are registered in `Program.cs` and injected via constructors.
- **CORS** — Configured to allow any origin/method/header, suitable for development. Tighten this for production deployments.

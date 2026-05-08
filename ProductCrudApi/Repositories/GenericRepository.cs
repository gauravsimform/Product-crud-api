using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace ProductCrudApi.Repositories
{
    /// <summary>
    /// Generic repository implementation providing basic CRUD operations using Entity Framework Core.
    /// </summary>
    /// <typeparam name="T">The entity type managed by this repository.</typeparam>
    public class GenericRepository<T> : IGenericRepository<T> where T : class
    {
        /// <summary>The application database context.</summary>
        protected readonly AppDbContext _context;

        /// <summary>The EF Core <see cref="DbSet{T}"/> for the entity type.</summary>
        protected readonly DbSet<T> _dbSet;

        /// <summary>
        /// Initialises a new instance of <see cref="GenericRepository{T}"/>.
        /// </summary>
        /// <param name="context">The <see cref="AppDbContext"/> injected by the DI container.</param>
        public GenericRepository(AppDbContext context)
        {
            _context = context;
            _dbSet = context.Set<T>();
        }

        /// <inheritdoc/>
        public async Task<IEnumerable<T>> GetAllAsync()
        {
            return await _dbSet.ToListAsync();
        }

        /// <inheritdoc/>
        public async Task<T> GetByIdAsync(int id)
        {
            return await _dbSet.FindAsync(id);
        }

        /// <inheritdoc/>
        public async Task AddAsync(T entity)
        {
            await _dbSet.AddAsync(entity);
        }

        /// <inheritdoc/>
        public void Update(T entity)
        {
            _dbSet.Update(entity);
        }

        /// <inheritdoc/>
        public void Delete(T entity)
        {
            _dbSet.Remove(entity);
        }

        /// <inheritdoc/>
        public async Task DeleteAllAsync()
        {
            _dbSet.RemoveRange(await _dbSet.ToListAsync());
        }

        /// <inheritdoc/>
        public async Task SaveChangesAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}

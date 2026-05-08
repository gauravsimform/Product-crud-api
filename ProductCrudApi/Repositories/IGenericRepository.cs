using System.Collections.Generic;
using System.Threading.Tasks;

namespace ProductCrudApi.Repositories
{
    /// <summary>
    /// Generic repository interface providing basic CRUD operations for any entity type.
    /// </summary>
    /// <typeparam name="T">The entity type managed by this repository.</typeparam>
    public interface IGenericRepository<T> where T : class
    {
        /// <summary>
        /// Retrieves all entities of type <typeparamref name="T"/> from the data store.
        /// </summary>
        /// <returns>A collection of all entities.</returns>
        Task<IEnumerable<T>> GetAllAsync();

        /// <summary>
        /// Retrieves a single entity by its primary key.
        /// </summary>
        /// <param name="id">The primary key value.</param>
        /// <returns>The matching entity, or <c>null</c> if not found.</returns>
        Task<T> GetByIdAsync(int id);

        /// <summary>
        /// Adds a new entity to the data store.
        /// </summary>
        /// <param name="entity">The entity to add.</param>
        Task AddAsync(T entity);

        /// <summary>
        /// Marks an existing entity as modified so that changes are persisted on the next save.
        /// </summary>
        /// <param name="entity">The entity to update.</param>
        void Update(T entity);

        /// <summary>
        /// Marks an entity for removal from the data store.
        /// </summary>
        /// <param name="entity">The entity to delete.</param>
        void Delete(T entity);

        /// <summary>
        /// Removes all entities of type <typeparamref name="T"/> from the data store.
        /// </summary>
        Task DeleteAllAsync();

        /// <summary>
        /// Persists all pending changes to the underlying database.
        /// </summary>
        Task SaveChangesAsync();
    }
}

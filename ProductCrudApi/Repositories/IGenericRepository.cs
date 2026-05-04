using System.Collections.Generic;
using System.Threading.Tasks;

namespace ProductCrudApi.Repositories
{
    /// <summary>
    /// Generic repository interface for basic CRUD operations.
    /// </summary>
    public interface IGenericRepository<T> where T : class
    {
        Task<IEnumerable<T>> GetAllAsync();
        Task<T> GetByIdAsync(int id);
        Task AddAsync(T entity);
        void Update(T entity);
        void Delete(T entity);
        Task DeleteAllAsync();
        Task SaveChangesAsync();
    }
}

namespace OrderManagement.Repositories
{
    public interface IRepository<T, TKey> where T : class
    {
        Task<T?> FindByIdAsync(TKey id);
        Task<IEnumerable<T>> FindAllAsync(int limit = 10, int offset = 0);
        Task<T> SaveAsync(T entity);
        Task<T> UpdateByIdAsync(TKey id, T entity);
        Task<bool> DeleteByIdAsync(TKey id);
    }
}

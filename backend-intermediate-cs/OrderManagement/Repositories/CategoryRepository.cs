using Microsoft.EntityFrameworkCore;
using OrderManagement.Models;

namespace OrderManagement.Repositories
{
    public class CategoryRepository : IRepository<Category, int>
    {
        private readonly OrderContext _context;

        public CategoryRepository(OrderContext context)
        {
            _context = context;
        }

        public async Task<Category?> FindByIdAsync(int id)
        {
            return await _context.Categories.FindAsync(id);
        }

        public async Task<IEnumerable<Category>> FindAllAsync(int limit = 10, int offset = 0)
        {
            return await _context.Categories
                .OrderBy(c => c.CategoryName)
                .Skip(offset)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<Category> SaveAsync(Category category)
        {
            _context.Categories.Add(category);
            await _context.SaveChangesAsync();
            return category;
        }

        public async Task<Category> UpdateByIdAsync(int id, Category category)
        {
            var existingCategory = await _context.Categories.FindAsync(id);
            if (existingCategory == null)
            {
                throw new InvalidOperationException($"Category with ID {id} not found");
            }

            _context.Entry(existingCategory).CurrentValues.SetValues(category);
            await _context.SaveChangesAsync();
            return existingCategory;
        }

        public async Task<bool> DeleteByIdAsync(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
            {
                return false;
            }

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}

using Microsoft.EntityFrameworkCore;
using OrderManagement.Models;

namespace OrderManagement.Repositories
{
    public class ProductRepository : IRepository<Product, int>
    {
        private readonly OrderContext _context;

        public ProductRepository(OrderContext context)
        {
            _context = context;
        }

        public async Task<Product?> FindByIdAsync(int id)
        {
            return await _context.Products
                .Include(p => p.Category)
                .FirstOrDefaultAsync(p => p.ProductId == id);
        }

        public async Task<IEnumerable<Product>> FindAllAsync(int limit = 10, int offset = 0)
        {
            return await _context.Products
                .Include(p => p.Category)
                .OrderBy(p => p.ProductName)
                .Skip(offset)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<Product> SaveAsync(Product product)
        {
            // Check if the category exists
            var categoryExists = await _context.Categories.AnyAsync(c => c.CategoryId == product.CategoryId);
            if (!categoryExists)
            {
                throw new InvalidOperationException("Category does not exist");
            }

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            // Load category for response
            await _context.Entry(product)
                .Reference(p => p.Category)
                .LoadAsync();

            return product;
        }

        public async Task<Product> UpdateByIdAsync(int id, Product product)
        {
            var existingProduct = await _context.Products.FindAsync(id);
            if (existingProduct == null)
            {
                throw new InvalidOperationException($"Product with ID {id} not found");
            }

            // Check if the category exists
            var categoryExists = await _context.Categories.AnyAsync(c => c.CategoryId == product.CategoryId);
            if (!categoryExists)
            {
                throw new InvalidOperationException("Category does not exist");
            }

            _context.Entry(existingProduct).CurrentValues.SetValues(product);
            await _context.SaveChangesAsync();

            // Load category for response
            var updatedProduct = await _context.Products
                .Include(p => p.Category)
                .FirstOrDefaultAsync(p => p.ProductId == id);

            return updatedProduct!;
        }

        public async Task<bool> DeleteByIdAsync(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null)
            {
                return false;
            }

            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}

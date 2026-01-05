using Microsoft.EntityFrameworkCore;
using OrderManagement.Models;

namespace OrderManagement.Repositories
{
    public class StockRepository : IRepository<Stock, int>
    {
        private readonly OrderContext _context;

        public StockRepository(OrderContext context)
        {
            _context = context;
        }

        public async Task<Stock?> FindByIdAsync(int id)
        {
            return await _context.Stocks
                .Include(s => s.Product)
                .FirstOrDefaultAsync(s => s.StockId == id);
        }

        public async Task<IEnumerable<Stock>> FindAllAsync(int limit = 10, int offset = 0)
        {
            return await _context.Stocks
                .Include(s => s.Product)
                .OrderBy(s => s.CreatedAt)
                .Skip(offset)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<Stock> SaveAsync(Stock stock)
        {
            // Validate that the product exists
            var productExists = await _context.Products.AnyAsync(p => p.ProductId == stock.ProductId);
            if (!productExists)
            {
                throw new InvalidOperationException($"Product with ID {stock.ProductId} not found");
            }

            stock.CreatedAt = DateTime.UtcNow;
            stock.UpdatedAt = DateTime.UtcNow;

            _context.Stocks.Add(stock);
            await _context.SaveChangesAsync();

            // Load the product for the response
            await _context.Entry(stock)
                .Reference(s => s.Product)
                .LoadAsync();

            return stock;
        }

        public async Task<Stock> UpdateByIdAsync(int id, Stock stock)
        {
            var existingStock = await _context.Stocks.FindAsync(id);
            if (existingStock == null)
            {
                throw new InvalidOperationException($"Stock with ID {id} not found");
            }

            // Validate that the product exists if ProductId is being changed
            if (existingStock.ProductId != stock.ProductId)
            {
                var productExists = await _context.Products.AnyAsync(p => p.ProductId == stock.ProductId);
                if (!productExists)
                {
                    throw new InvalidOperationException($"Product with ID {stock.ProductId} not found");
                }
            }

            existingStock.ProductId = stock.ProductId;
            existingStock.Quantity = stock.Quantity;
            existingStock.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return existingStock;
        }

        public async Task<bool> DeleteByIdAsync(int id)
        {
            var stock = await _context.Stocks.FindAsync(id);
            if (stock == null)
            {
                return false;
            }

            _context.Stocks.Remove(stock);
            await _context.SaveChangesAsync();
            return true;
        }

        // Additional methods specific to Stock operations
        public async Task<IEnumerable<Stock>> FindByProductIdAsync(int productId, int limit = 10, int offset = 0)
        {
            return await _context.Stocks
                .Include(s => s.Product)
                .Where(s => s.ProductId == productId)
                .OrderBy(s => s.CreatedAt)
                .Skip(offset)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<Stock?> FindByProductIdAndStockIdAsync(int productId, int stockId)
        {
            return await _context.Stocks
                .Include(s => s.Product)
                .FirstOrDefaultAsync(s => s.StockId == stockId && s.ProductId == productId);
        }

        public async Task<bool> ProductExistsAsync(int productId)
        {
            return await _context.Products.AnyAsync(p => p.ProductId == productId);
        }

        public async Task<bool> ValidateStockBelongsToProductAsync(int stockId, int productId)
        {
            var stock = await _context.Stocks.FindAsync(stockId);
            return stock != null && stock.ProductId == productId;
        }
    }
}

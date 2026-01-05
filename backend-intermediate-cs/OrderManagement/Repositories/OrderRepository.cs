using Microsoft.EntityFrameworkCore;
using OrderManagement.Models;

namespace OrderManagement.Repositories
{
    public class OrderRepository : IRepository<Order, int>
    {
        private readonly OrderContext _context;

        public OrderRepository(OrderContext context)
        {
            _context = context;
        }

        public async Task<Order?> FindByIdAsync(int orderNumber)
        {
            return await _context.Orders
                .Include(o => o.Customer)
                .Include(o => o.Details)
                    .ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(o => o.OrderNumber == orderNumber);
        }

        public async Task<IEnumerable<Order>> FindAllAsync(int limit = 10, int offset = 0)
        {
            return await _context.Orders
                .Include(o => o.Customer)
                .Include(o => o.Details)
                    .ThenInclude(d => d.Product)
                .Skip(offset)
                .Take(limit)
                .OrderBy(o => o.OrderDate)
                .ToListAsync();
        }

        public async Task<Order> SaveAsync(Order order)
        {
            // Validate customer exists
            var customerExists = await _context.Customers.AnyAsync(c => c.CustomerId == order.CustomerId);
            if (!customerExists)
            {
                throw new InvalidOperationException($"Customer with ID {order.CustomerId} not found");
            }

            // Validate products exist and calculate total
            double totalAmount = 0;
            foreach (var detail in order.Details)
            {
                var product = await _context.Products.FirstOrDefaultAsync(p => p.ProductId == detail.ProductId);
                if (product == null)
                {
                    throw new InvalidOperationException($"Product with ID {detail.ProductId} not found");
                }
                
                detail.Amount = product.Price * detail.Quantity;
                totalAmount += detail.Amount;
            }

            // Set the calculated total and order date
            order.Total = totalAmount;
            order.OrderDate = DateOnly.FromDateTime(DateTime.Now);

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            // Load related data for response
            await _context.Entry(order)
                .Reference(o => o.Customer)
                .LoadAsync();

            await _context.Entry(order)
                .Collection(o => o.Details)
                .LoadAsync();

            foreach (var detail in order.Details)
            {
                await _context.Entry(detail)
                    .Reference(d => d.Product)
                    .LoadAsync();
            }

            return order;
        }

        public async Task<Order> UpdateByIdAsync(int orderNumber, Order order)
        {
            // Check if order exists
            var existingOrder = await _context.Orders
                .Include(o => o.Details)
                .FirstOrDefaultAsync(o => o.OrderNumber == orderNumber);

            if (existingOrder == null)
            {
                throw new InvalidOperationException($"Order with number {orderNumber} not found");
            }

            // Validate customer exists
            var customerExists = await _context.Customers.AnyAsync(c => c.CustomerId == order.CustomerId);
            if (!customerExists)
            {
                throw new InvalidOperationException($"Customer with ID {order.CustomerId} not found");
            }

            // Validate products exist and calculate total
            double totalAmount = 0;
            foreach (var detail in order.Details)
            {
                var product = await _context.Products.FirstOrDefaultAsync(p => p.ProductId == detail.ProductId);
                if (product == null)
                {
                    throw new InvalidOperationException($"Product with ID {detail.ProductId} not found");
                }
                
                detail.Amount = product.Price * detail.Quantity;
                totalAmount += detail.Amount;
            }

            // Update order properties
            if (order.OrderDate != default(DateOnly))
            {
                existingOrder.OrderDate = order.OrderDate;
            }
            existingOrder.Total = totalAmount;
            existingOrder.CustomerId = order.CustomerId;

            // Remove existing order details
            _context.OrderDetails.RemoveRange(existingOrder.Details);

            // Add new order details
            foreach (var detail in order.Details)
            {
                detail.OrderNumber = orderNumber;
                existingOrder.Details.Add(detail);
            }

            await _context.SaveChangesAsync();

            // Load related data for response
            await _context.Entry(existingOrder)
                .Reference(o => o.Customer)
                .LoadAsync();

            foreach (var detail in existingOrder.Details)
            {
                await _context.Entry(detail)
                    .Reference(d => d.Product)
                    .LoadAsync();
            }

            return existingOrder;
        }

        public async Task<bool> DeleteByIdAsync(int orderNumber)
        {
            var order = await _context.Orders
                .Include(o => o.Details)
                .FirstOrDefaultAsync(o => o.OrderNumber == orderNumber);

            if (order == null)
            {
                return false;
            }

            _context.Orders.Remove(order);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}

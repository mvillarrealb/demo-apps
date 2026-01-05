using Microsoft.EntityFrameworkCore;
using OrderManagement.Models;

namespace OrderManagement.Repositories
{
    public class CustomerRepository : IRepository<Customer, int>
    {
        private readonly OrderContext _context;

        public CustomerRepository(OrderContext context)
        {
            _context = context;
        }

        public async Task<Customer?> FindByIdAsync(int id)
        {
            return await _context.Customers.FindAsync(id);
        }

        public async Task<IEnumerable<Customer>> FindAllAsync(int limit = 10, int offset = 0)
        {
            return await _context.Customers
                .OrderBy(c => c.FirstName)
                .Skip(offset)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<IEnumerable<Customer>> FindAllWithFiltersAsync(int limit = 10, int offset = 0, string? city = null, string? state = null)
        {
            var query = _context.Customers.AsQueryable();

            // Apply filters if provided
            if (!string.IsNullOrEmpty(city))
            {
                query = query.Where(c => c.City.ToLower().Contains(city.ToLower()));
            }

            if (!string.IsNullOrEmpty(state))
            {
                query = query.Where(c => c.State.ToLower().Contains(state.ToLower()));
            }

            return await query
                .OrderBy(c => c.FirstName)
                .Skip(offset)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<Customer> SaveAsync(Customer customer)
        {
            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();
            return customer;
        }

        public async Task<Customer> UpdateByIdAsync(int id, Customer customer)
        {
            var existingCustomer = await _context.Customers.FindAsync(id);
            if (existingCustomer == null)
            {
                throw new InvalidOperationException($"Customer with ID {id} not found");
            }

            _context.Entry(existingCustomer).CurrentValues.SetValues(customer);
            await _context.SaveChangesAsync();
            return existingCustomer;
        }

        public async Task<bool> DeleteByIdAsync(int id)
        {
            var customer = await _context.Customers.FindAsync(id);
            if (customer == null)
            {
                return false;
            }

            _context.Customers.Remove(customer);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}

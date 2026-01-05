using Microsoft.EntityFrameworkCore;
using OrderManagement.Models;

namespace OrderManagement.Repositories
{
    public class TodoItemRepository : IRepository<TodoItem, long>
    {
        private readonly OrderContext _context;

        public TodoItemRepository(OrderContext context)
        {
            _context = context;
        }

        public async Task<TodoItem?> FindByIdAsync(long id)
        {
            return await _context.TodoItems.FindAsync(id);
        }

        public async Task<IEnumerable<TodoItem>> FindAllAsync(int limit = 10, int offset = 0)
        {
            return await _context.TodoItems
                .OrderBy(t => t.Id)
                .Skip(offset)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<TodoItem> SaveAsync(TodoItem todoItem)
        {
            _context.TodoItems.Add(todoItem);
            await _context.SaveChangesAsync();
            return todoItem;
        }

        public async Task<TodoItem> UpdateByIdAsync(long id, TodoItem todoItem)
        {
            var existingTodoItem = await _context.TodoItems.FindAsync(id);
            if (existingTodoItem == null)
            {
                throw new InvalidOperationException($"TodoItem with ID {id} not found");
            }

            existingTodoItem.Name = todoItem.Name;
            existingTodoItem.IsComplete = todoItem.IsComplete;
            
            await _context.SaveChangesAsync();
            return existingTodoItem;
        }

        public async Task<bool> DeleteByIdAsync(long id)
        {
            var todoItem = await _context.TodoItems.FindAsync(id);
            if (todoItem == null)
            {
                return false;
            }

            _context.TodoItems.Remove(todoItem);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}

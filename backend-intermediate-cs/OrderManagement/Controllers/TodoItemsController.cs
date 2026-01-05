using Microsoft.AspNetCore.Mvc;
using OrderManagement.Models;
using OrderManagement.Repositories;

namespace OrderManagement.Controllers
{

    [Route("api/[controller]")]
    [ApiController]
    public class TodoItemsController : ControllerBase
    {  
        private readonly IRepository<TodoItem, long> _todoItemRepository;
        
        public TodoItemsController(IRepository<TodoItem, long> todoItemRepository)
        {
            _todoItemRepository = todoItemRepository;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<TodoItem>>> GetTodoItems([FromQuery] int limit = 10, [FromQuery] int offset = 0)
        {
            var todoItems = await _todoItemRepository.FindAllAsync(limit, offset);
            return Ok(todoItems);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TodoItem>> GetTodoItem(long id)
        {
            var todoItem = await _todoItemRepository.FindByIdAsync(id);
            if (todoItem == null)
            {
                return NotFound();
            }
            return todoItem;
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutTodoItem(long id, TodoItem todoItem)
        {
            if (id != todoItem.Id)
            {
                return BadRequest();
            }

            try
            {
                await _todoItemRepository.UpdateByIdAsync(id, todoItem);
                return NoContent();
            }
            catch (InvalidOperationException)
            {
                return NotFound();
            }
        }

        [HttpPost]
        public async Task<ActionResult<TodoItem>> PostTodoItem(TodoItem todoItem)
        {
            var createdTodoItem = await _todoItemRepository.SaveAsync(todoItem);
            return CreatedAtAction(nameof(GetTodoItem), new { id = createdTodoItem.Id }, createdTodoItem);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTodoItem(long id)
        {
            var deleted = await _todoItemRepository.DeleteByIdAsync(id);
            if (!deleted)
            {
                return NotFound();
            }
            return NoContent();
        }
    }
}

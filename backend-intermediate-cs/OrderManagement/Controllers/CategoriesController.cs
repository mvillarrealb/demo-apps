using Microsoft.AspNetCore.Mvc;
using OrderManagement.Models;
using OrderManagement.Repositories;

namespace OrderManagement.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoriesController : ControllerBase
    {
        private readonly IRepository<Category, int> _categoryRepository;

        public CategoriesController(IRepository<Category, int> categoryRepository)
        {
            _categoryRepository = categoryRepository;
        }

        // GET: api/categories
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Category>>> GetCategories(
            [FromQuery] int limit = 10,
            [FromQuery] int offset = 0)
        {
            if (limit < 1)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Limit must be at least 1" });

            if (offset < 0)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Offset must be at least 0" });

            try
            {
                var categories = await _categoryRepository.FindAllAsync(limit, offset);
                return Ok(categories);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // GET: api/categories/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Category>> GetCategory(int id)
        {
            try
            {
                var category = await _categoryRepository.FindByIdAsync(id);

                if (category == null)
                {
                    return NotFound(new { code = 404, message = "NotFound", description = "Category not found" });
                }

                return Ok(category);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // PUT: api/categories/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutCategory(int id, Category category)
        {
            if (id != category.CategoryId)
            {
                return BadRequest(new { code = 400, message = "BadRequest", description = "ID mismatch" });
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(new { code = 400, message = "BadRequest", description = "Invalid category data" });
            }

            try
            {
                var updatedCategory = await _categoryRepository.UpdateByIdAsync(id, category);
                return Ok(updatedCategory);
            }
            catch (InvalidOperationException)
            {
                return NotFound(new { code = 404, message = "NotFound", description = "Category not found" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // POST: api/categories
        [HttpPost]
        public async Task<ActionResult<Category>> PostCategory(Category category)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new { code = 400, message = "BadRequest", description = "Invalid category data" });
            }

            try
            {
                var createdCategory = await _categoryRepository.SaveAsync(category);
                return CreatedAtAction(nameof(GetCategory), new { id = createdCategory.CategoryId }, createdCategory);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // DELETE: api/categories/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            try
            {
                var deleted = await _categoryRepository.DeleteByIdAsync(id);
                if (!deleted)
                {
                    return NotFound(new { code = 404, message = "NotFound", description = "Category not found" });
                }

                return Ok(new { });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }
    }
}

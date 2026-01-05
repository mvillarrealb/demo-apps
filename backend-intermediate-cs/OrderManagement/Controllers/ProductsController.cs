using Microsoft.AspNetCore.Mvc;
using OrderManagement.Models;
using OrderManagement.Repositories;

namespace OrderManagement.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private readonly IRepository<Product, int> _productRepository;

        public ProductsController(IRepository<Product, int> productRepository)
        {
            _productRepository = productRepository;
        }

        // GET: api/products
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Product>>> GetProducts(
            [FromQuery] int limit = 10,
            [FromQuery] int offset = 0)
        {
            if (limit < 1)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Limit must be at least 1" });

            if (offset < 0)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Offset must be at least 0" });

            try
            {
                var products = await _productRepository.FindAllAsync(limit, offset);
                return Ok(products);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // GET: api/products/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Product>> GetProduct(int id)
        {
            try
            {
                var product = await _productRepository.FindByIdAsync(id);

                if (product == null)
                {
                    return NotFound(new { code = 404, message = "NotFound", description = "Product not found" });
                }

                return Ok(product);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // PUT: api/products/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutProduct(int id, Product product)
        {
            if (id != product.ProductId)
            {
                return BadRequest(new { code = 400, message = "BadRequest", description = "ID mismatch" });
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(new { code = 400, message = "BadRequest", description = "Invalid product data" });
            }

            try
            {
                var updatedProduct = await _productRepository.UpdateByIdAsync(id, product);
                return Ok(updatedProduct);
            }
            catch (InvalidOperationException ex)
            {
                if (ex.Message.Contains("not found"))
                {
                    return NotFound(new { code = 404, message = "NotFound", description = ex.Message });
                }
                return BadRequest(new { code = 400, message = "BadRequest", description = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // POST: api/products
        [HttpPost]
        public async Task<ActionResult<Product>> PostProduct(Product product)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new { code = 400, message = "BadRequest", description = "Invalid product data" });
            }

            try
            {
                var createdProduct = await _productRepository.SaveAsync(product);
                return CreatedAtAction(nameof(GetProduct), new { id = createdProduct.ProductId }, createdProduct);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { code = 400, message = "BadRequest", description = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // DELETE: api/products/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            try
            {
                var deleted = await _productRepository.DeleteByIdAsync(id);
                if (!deleted)
                {
                    return NotFound(new { code = 404, message = "NotFound", description = "Product not found" });
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

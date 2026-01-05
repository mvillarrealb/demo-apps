using Microsoft.AspNetCore.Mvc;
using OrderManagement.Models;
using OrderManagement.Repositories;

namespace OrderManagement.Controllers
{
    [Route("api/products/{productId}/[controller]")]
    [ApiController]
    public class StockController : ControllerBase
    {
        private readonly StockRepository _stockRepository;

        public StockController(StockRepository stockRepository)
        {
            _stockRepository = stockRepository;
        }

        // GET: api/products/{productId}/stock
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Stock>>> GetProductStock(
            int productId,
            [FromQuery] int limit = 10,
            [FromQuery] int offset = 0)
        {
            if (limit < 1)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Limit must be at least 1" });

            if (offset < 0)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Offset must be at least 0" });

            try
            {
                // Check if product exists
                var productExists = await _stockRepository.ProductExistsAsync(productId);
                if (!productExists)
                    return NotFound(new { code = 404, message = "NotFound", description = "Product not found" });

                var stocks = await _stockRepository.FindByProductIdAsync(productId, limit, offset);
                return Ok(stocks);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // GET: api/products/{productId}/stock/{stockId}
        [HttpGet("{stockId}")]
        public async Task<ActionResult<Stock>> GetProductStockById(int productId, int stockId)
        {
            try
            {
                // Check if product exists
                var productExists = await _stockRepository.ProductExistsAsync(productId);
                if (!productExists)
                    return NotFound(new { code = 404, message = "NotFound", description = "Product not found" });

                var stock = await _stockRepository.FindByProductIdAndStockIdAsync(productId, stockId);
                if (stock == null)
                    return NotFound(new { code = 404, message = "NotFound", description = "Stock not found" });

                return Ok(stock);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // POST: api/products/{productId}/stock
        [HttpPost]
        public async Task<ActionResult<Stock>> CreateProductStock(int productId, Stock stock)
        {
            try
            {
                // Set the ProductId from the route
                stock.ProductId = productId;

                if (!ModelState.IsValid)
                {
                    var errors = ModelState
                        .Where(x => x.Value?.Errors.Count > 0)
                        .Select(x => new { Field = x.Key, Errors = x.Value?.Errors.Select(e => e.ErrorMessage) ?? Enumerable.Empty<string>() })
                        .ToArray();
                    return BadRequest(new { code = 400, message = "BadRequest", description = "Validation failed", errors });
                }

                var createdStock = await _stockRepository.SaveAsync(stock);
                return CreatedAtAction(nameof(GetProductStockById), 
                    new { productId = createdStock.ProductId, stockId = createdStock.StockId }, createdStock);
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { code = 404, message = "NotFound", description = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // PUT: api/products/{productId}/stock/{stockId}
        [HttpPut("{stockId}")]
        public async Task<IActionResult> UpdateProductStock(int productId, int stockId, Stock stock)
        {
            if (stockId != stock.StockId)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Stock ID mismatch" });

            if (productId != stock.ProductId)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Product ID mismatch" });

            try
            {
                // Check if product exists
                var productExists = await _stockRepository.ProductExistsAsync(productId);
                if (!productExists)
                    return NotFound(new { code = 404, message = "NotFound", description = "Product not found" });

                // Validate that stock belongs to the specified product
                var isValidStock = await _stockRepository.ValidateStockBelongsToProductAsync(stockId, productId);
                if (!isValidStock)
                    return BadRequest(new { code = 400, message = "BadRequest", description = "Stock does not belong to the specified product" });

                if (!ModelState.IsValid)
                {
                    var errors = ModelState
                        .Where(x => x.Value?.Errors.Count > 0)
                        .Select(x => new { Field = x.Key, Errors = x.Value?.Errors.Select(e => e.ErrorMessage) ?? Enumerable.Empty<string>() })
                        .ToArray();
                    return BadRequest(new { code = 400, message = "BadRequest", description = "Validation failed", errors });
                }

                await _stockRepository.UpdateByIdAsync(stockId, stock);
                return Ok(new { code = 200, message = "OK", description = "Stock updated successfully" });
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { code = 404, message = "NotFound", description = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // DELETE: api/products/{productId}/stock/{stockId}
        [HttpDelete("{stockId}")]
        public async Task<IActionResult> DeleteProductStock(int productId, int stockId)
        {
            try
            {
                // Check if product exists
                var productExists = await _stockRepository.ProductExistsAsync(productId);
                if (!productExists)
                    return NotFound(new { code = 404, message = "NotFound", description = "Product not found" });

                // Validate that stock belongs to the specified product
                var isValidStock = await _stockRepository.ValidateStockBelongsToProductAsync(stockId, productId);
                if (!isValidStock)
                    return BadRequest(new { code = 400, message = "BadRequest", description = "Stock does not belong to the specified product" });

                var deleted = await _stockRepository.DeleteByIdAsync(stockId);
                if (!deleted)
                    return NotFound(new { code = 404, message = "NotFound", description = "Stock not found" });

                return Ok(new { code = 200, message = "OK", description = "Stock deleted successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }
    }
}

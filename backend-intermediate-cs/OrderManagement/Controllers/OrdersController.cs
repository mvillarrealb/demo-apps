using Microsoft.AspNetCore.Mvc;
using OrderManagement.Models;
using OrderManagement.Repositories;

namespace OrderManagement.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly IRepository<Order, int> _orderRepository;

        public OrdersController(IRepository<Order, int> orderRepository)
        {
            _orderRepository = orderRepository;
        }

        // GET: api/orders
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrders(
            [FromQuery] int limit = 10,
            [FromQuery] int offset = 0)
        {
            if (limit < 1)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Limit must be at least 1" });

            if (offset < 0)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Offset must be at least 0" });

            try
            {
                var orders = await _orderRepository.FindAllAsync(limit, offset);
                return Ok(orders);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // GET: api/orders/5
        [HttpGet("{orderNumber}")]
        public async Task<ActionResult<Order>> GetOrder(int orderNumber)
        {
            try
            {
                var order = await _orderRepository.FindByIdAsync(orderNumber);

                if (order == null)
                {
                    return NotFound(new { code = 404, message = "NotFound", description = $"Order with number {orderNumber} not found" });
                }

                return Ok(order);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // POST: api/orders
        [HttpPost]
        public async Task<ActionResult<Order>> PostOrder(Order order)
        {
            try
            {
                var createdOrder = await _orderRepository.SaveAsync(order);
                return CreatedAtAction("GetOrder", new { orderNumber = createdOrder.OrderNumber }, createdOrder);
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

        // PUT: api/orders/5
        [HttpPut("{orderNumber}")]
        public async Task<IActionResult> PutOrder(int orderNumber, Order order)
        {
            if (orderNumber != order.OrderNumber)
            {
                return BadRequest(new { code = 400, message = "BadRequest", description = "Order number in URL does not match order number in body" });
            }

            try
            {
                var updatedOrder = await _orderRepository.UpdateByIdAsync(orderNumber, order);
                return Ok(updatedOrder);
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

        // DELETE: api/orders/5
        [HttpDelete("{orderNumber}")]
        public async Task<IActionResult> DeleteOrder(int orderNumber)
        {
            try
            {
                var deleted = await _orderRepository.DeleteByIdAsync(orderNumber);
                if (!deleted)
                {
                    return NotFound(new { code = 404, message = "NotFound", description = $"Order with number {orderNumber} not found" });
                }

                return Ok(new { message = "Order deleted successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }
    }
}

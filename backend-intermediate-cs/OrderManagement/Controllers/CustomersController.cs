using Microsoft.AspNetCore.Mvc;
using OrderManagement.Models;
using OrderManagement.Repositories;

namespace OrderManagement.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CustomersController : ControllerBase
    {
        private readonly CustomerRepository _customerRepository;

        public CustomersController(IRepository<Customer, int> customerRepository)
        {
            _customerRepository = (CustomerRepository)customerRepository;
        }

        // GET: api/customers
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Customer>>> GetCustomers(
            [FromQuery] int limit = 10,
            [FromQuery] int offset = 0,
            [FromQuery] string? city = null,
            [FromQuery] string? state = null)
        {
            if (limit < 1)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Limit must be at least 1" });

            if (offset < 0)
                return BadRequest(new { code = 400, message = "BadRequest", description = "Offset must be at least 0" });

            try
            {
                var customers = await _customerRepository.FindAllWithFiltersAsync(limit, offset, city, state);
                return Ok(customers);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // GET: api/customers/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Customer>> GetCustomer(int id)
        {
            try
            {
                var customer = await _customerRepository.FindByIdAsync(id);

                if (customer == null)
                {
                    return NotFound(new { code = 404, message = "NotFound", description = "Customer not found" });
                }

                return Ok(customer);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // PUT: api/customers/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutCustomer(int id, Customer customer)
        {
            if (id != customer.CustomerId)
            {
                return BadRequest(new { code = 400, message = "BadRequest", description = "Customer ID mismatch" });
            }

            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(x => x.Value?.Errors.Count > 0)
                    .Select(x => new { Field = x.Key, Errors = x.Value?.Errors.Select(e => e.ErrorMessage) ?? Enumerable.Empty<string>() })
                    .ToArray();
                return BadRequest(new { code = 400, message = "BadRequest", description = "Validation failed", errors });
            }

            try
            {
                await _customerRepository.UpdateByIdAsync(id, customer);
                return Ok(new { code = 200, message = "OK", description = "Customer updated successfully" });
            }
            catch (InvalidOperationException)
            {
                return NotFound(new { code = 404, message = "NotFound", description = "Customer not found" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // POST: api/customers
        [HttpPost]
        public async Task<ActionResult<Customer>> PostCustomer(Customer customer)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    var errors = ModelState
                        .Where(x => x.Value?.Errors.Count > 0)
                        .Select(x => new { Field = x.Key, Errors = x.Value?.Errors.Select(e => e.ErrorMessage) ?? Enumerable.Empty<string>() })
                        .ToArray();
                    return BadRequest(new { code = 400, message = "BadRequest", description = "Validation failed", errors });
                }

                var createdCustomer = await _customerRepository.SaveAsync(customer);
                return CreatedAtAction(nameof(GetCustomer), new { id = createdCustomer.CustomerId }, createdCustomer);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }

        // DELETE: api/customers/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCustomer(int id)
        {
            try
            {
                var deleted = await _customerRepository.DeleteByIdAsync(id);
                if (!deleted)
                {
                    return NotFound(new { code = 404, message = "NotFound", description = "Customer not found" });
                }

                return Ok(new { code = 200, message = "OK", description = "Customer deleted successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { code = 500, message = "InternalServerError", description = ex.Message });
            }
        }
    }
}

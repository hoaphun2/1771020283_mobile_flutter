using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/[controller]")]
public class BookingsController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    
    public BookingsController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> GetBookings()
    {
        try
        {
            var bookings = await _db.Bookings.ToListAsync();
            return Ok(bookings);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Lỗi server: {ex.Message}" });
        }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateBooking(int id, [FromBody] Booking283 booking)
    {
        try
        {
            var existingBooking = await _db.Bookings.FindAsync(id);
            if (existingBooking == null)
            {
                return NotFound(new { message = "Không tìm thấy booking" });
            }
            
            // Cập nhật các trường
            existingBooking.Status = booking.Status;
            existingBooking.StartTime = booking.StartTime;
            existingBooking.EndTime = booking.EndTime;
            existingBooking.CourtId = booking.CourtId;
            existingBooking.TotalPrice = booking.TotalPrice;
            
            await _db.SaveChangesAsync();
            return Ok(new { message = "Cập nhật thành công", bookingId = id });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Lỗi server: {ex.Message}" });
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteBooking(int id)
    {
        try
        {
            var booking = await _db.Bookings.FindAsync(id);
            if (booking == null)
            {
                return NotFound(new { message = "Không tìm thấy booking" });
            }
            
            _db.Bookings.Remove(booking);
            await _db.SaveChangesAsync();
            return Ok(new { message = "Xóa thành công", bookingId = id });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Lỗi server: {ex.Message}" });
        }
    }
}
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/[controller]")]
public class MembersController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    
    public MembersController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetMember(int id)
    {
        try
        {
            var member = await _db.Members.FindAsync(id);
            if (member == null)
            {
                return NotFound(new { message = "Không tìm thấy thành viên" });
            }
            
            return Ok(member);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Lỗi server: {ex.Message}" });
        }
    }

    [HttpPost("{id}/topup")]
    public async Task<IActionResult> Topup(int id, [FromBody] TopupRequest request)
    {
        try
        {
            var member = await _db.Members.FindAsync(id);
            if (member == null)
            {
                return NotFound(new { message = "Không tìm thấy thành viên" });
            }
            
            // Logic nạp tiền
            member.WalletBalance += request.Amount;
            
            // Tạo transaction
            var transaction = new WalletTransaction
            {
                MemberId = id,
                Amount = request.Amount,
                Type = "Deposit",
                Status = "Completed",
                Description = $"Nạp tiền vào ví: {request.Amount}",
                CreatedDate = DateTime.Now
            };
            
            _db.WalletTransactions.Add(transaction);
            await _db.SaveChangesAsync();
            
            return Ok(new { 
                message = "Nạp tiền thành công", 
                memberId = id, 
                newBalance = member.WalletBalance,
                amount = request.Amount 
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Lỗi server: {ex.Message}" });
        }
    }

    [HttpPut]
    public async Task<IActionResult> UpdateMember([FromBody] Member283 member)
    {
        try
        {
            var existingMember = await _db.Members.FindAsync(member.Id);
            if (existingMember == null)
            {
                return NotFound(new { message = "Không tìm thấy thành viên" });
            }
            
            // Cập nhật thông tin
            existingMember.FullName = member.FullName;
            existingMember.Phone = member.Phone;
            existingMember.AvatarUrl = member.AvatarUrl;
            existingMember.UpdatedAt = DateTime.Now;
            
            await _db.SaveChangesAsync();
            return Ok(new { message = "Cập nhật thành công", memberId = member.Id });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Lỗi server: {ex.Message}" });
        }
    }
}
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    public AuthController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            // Kiểm tra null và xử lý an toàn
            var user = await _db.Members
                .FirstOrDefaultAsync(m =>
                    (m.Email != null && m.Email == request.Username) || 
                    (m.FullName != null && m.FullName == request.Username));
            
            if (user == null)
            {
                return Unauthorized(new { message = "Sai tài khoản hoặc mật khẩu" });
            }
            
            // Kiểm tra mật khẩu
            if (user.Password != request.Password)
            {
                return Unauthorized(new { message = "Sai tài khoản hoặc mật khẩu" });
            }
            
            // Trả về token fake và user info đầy đủ
            return Ok(new {
                token = "fake-jwt-token",
                user = new {
                    id = user.Id,
                    email = user.Email ?? string.Empty,
                    fullName = user.FullName ?? string.Empty,
                    phone = user.Phone ?? string.Empty,
                    avatarUrl = user.AvatarUrl ?? string.Empty,
                    role = user.Role ?? "Member",
                    walletBalance = user.WalletBalance,
                    tier = user.Tier ?? "Standard",
                    joinDate = user.JoinDate ?? DateTime.Now
                }
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Login error: {ex.Message}");
            return StatusCode(500, new { message = "Lỗi server khi đăng nhập" });
        }
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            // Kiểm tra email đã tồn tại chưa
            var existed = await _db.Members.AnyAsync(m => m.Email == request.Email);
            if (existed)
            {
                return BadRequest(new { message = "Email đã tồn tại" });
            }

            // Tạo user mới
            var member = new Member283
            {
                FullName = request.FullName,
                Email = request.Email,
                Password = request.Password,
                Phone = request.Phone,
                AvatarUrl = null!, // Sử dụng null! để bỏ qua warning
                Role = "Member",
                WalletBalance = 0,
                Tier = "Standard",
                JoinDate = DateTime.Now,
                CreatedAt = DateTime.Now
            };
            _db.Members.Add(member);
            await _db.SaveChangesAsync();

            // Trả về user vừa tạo (token fake) với đầy đủ thông tin
            return Ok(new {
                token = "fake-jwt-token",
                user = new {
                    id = member.Id,
                    email = member.Email,
                    fullName = member.FullName,
                    phone = member.Phone ?? string.Empty,
                    avatarUrl = member.AvatarUrl ?? string.Empty,
                    role = member.Role ?? "Member",
                    walletBalance = member.WalletBalance,
                    tier = member.Tier ?? "Standard",
                    joinDate = member.JoinDate ?? DateTime.Now
                }
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Register error: {ex.Message}");
            return StatusCode(500, new { message = "Lỗi server khi đăng ký" });
        }
    }

    // THÊM ENDPOINT ĐỂ TEST KẾT NỐI
    [HttpGet]
    public IActionResult Test()
    {
        return Ok(new { message = "API is working!", timestamp = DateTime.Now });
    }
}
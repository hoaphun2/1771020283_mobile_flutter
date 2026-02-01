public class RegisterRequest
{
    public required string FullName { get; set; } // Thêm required
    public required string Email { get; set; } // Thêm required
    public required string Password { get; set; } // Thêm required
    public string? Phone { get; set; }
}
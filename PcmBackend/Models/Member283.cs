public class Member283
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty; // Mặc định giá trị
    public string Email { get; set; } = string.Empty; // Mặc định giá trị
    public string Password { get; set; } = string.Empty; // Mặc định giá trị
    public decimal WalletBalance { get; set; }
    
    // Các trường mới từ SQL
    public DateTime? JoinDate { get; set; }
    public float? RankLevel { get; set; }
    public bool? Status { get; set; }
    public string? Tier { get; set; }
    public string? Phone { get; set; }
    public string? Role { get; set; }
    public decimal? TotalSpent { get; set; }
    public string? AvatarUrl { get; set; } // Cho phép null
    public DateTime? CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
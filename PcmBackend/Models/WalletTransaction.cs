public class WalletTransaction
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public decimal Amount { get; set; }
    public string Type { get; set; } = string.Empty; // Mặc định giá trị
    public string Status { get; set; } = string.Empty; // Mặc định giá trị
    public string Description { get; set; } = string.Empty; // Mặc định giá trị
    public DateTime? CreatedDate { get; set; }
}
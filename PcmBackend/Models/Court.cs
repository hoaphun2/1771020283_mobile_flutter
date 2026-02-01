public class Court
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty; // Mặc định giá trị
    public bool? IsActive { get; set; }
    public string Description { get; set; } = string.Empty; // Mặc định giá trị
    public decimal PricePerHour { get; set; }
    public DateTime? CreatedAt { get; set; }
}
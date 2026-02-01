public class Booking283
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public string Status { get; set; } = "Pending"; // Mặc định giá trị
    
    // Các trường mới từ SQL
    public int? CourtId { get; set; }
    public decimal? TotalPrice { get; set; }
    public int? TransactionId { get; set; }
    public bool? IsRecurring { get; set; }
    public string? RecurrenceRule { get; set; } // Cho phép null
    public int? ParentBookingId { get; set; }
    public DateTime? HoldUntil { get; set; }
    public DateTime? CreatedAt { get; set; }
}
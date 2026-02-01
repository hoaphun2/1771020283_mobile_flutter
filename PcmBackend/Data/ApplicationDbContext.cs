using Microsoft.EntityFrameworkCore;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    public DbSet<Member283> Members { get; set; }
    public DbSet<Booking283> Bookings { get; set; }
    public DbSet<Court> Courts { get; set; }
    public DbSet<WalletTransaction> WalletTransactions { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Cấu hình Member283
        modelBuilder.Entity<Member283>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.FullName).IsRequired().HasDefaultValue(string.Empty);
            entity.Property(e => e.Email).IsRequired().HasDefaultValue(string.Empty);
            entity.Property(e => e.Password).IsRequired().HasDefaultValue(string.Empty);
            entity.Property(e => e.WalletBalance).HasPrecision(18, 2).HasDefaultValue(0);
            entity.Property(e => e.TotalSpent).HasPrecision(18, 2);
            entity.Property(e => e.Role).HasDefaultValue("Member");
            entity.Property(e => e.Tier).HasDefaultValue("Standard");
            entity.Property(e => e.JoinDate).HasDefaultValueSql("GETDATE()");
        });
        
        // Cấu hình Booking283
        modelBuilder.Entity<Booking283>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Status).HasDefaultValue("Pending");
            entity.Property(e => e.TotalPrice).HasPrecision(18, 2);
        });
        
        // Cấu hình Court
        modelBuilder.Entity<Court>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasDefaultValue(string.Empty);
            entity.Property(e => e.Description).IsRequired().HasDefaultValue(string.Empty);
            entity.Property(e => e.PricePerHour).HasPrecision(18, 2);
        });
        
        // Cấu hình WalletTransaction
        modelBuilder.Entity<WalletTransaction>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Type).HasDefaultValue(string.Empty);
            entity.Property(e => e.Status).HasDefaultValue(string.Empty);
            entity.Property(e => e.Description).HasDefaultValue(string.Empty);
            entity.Property(e => e.Amount).HasPrecision(18, 2);
            entity.Property(e => e.CreatedDate).HasDefaultValueSql("GETDATE()");
        });
    }
}
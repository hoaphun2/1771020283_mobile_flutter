using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Chạy trên tất cả IP
builder.WebHost.UseUrls("http://0.0.0.0:5069", "https://0.0.0.0:7298");

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Thêm EnableRetryOnFailure để xử lý lỗi transient
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlServerOptions => sqlServerOptions.EnableRetryOnFailure()));

// Thêm cấu hình CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();

// Tự động tạo database và áp dụng migrations - SỬA LẠI THÀNH SYNC
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    try
    {
        // Tạo database nếu chưa tồn tại
        db.Database.EnsureCreated();
        
        // Tạo hoặc cập nhật tài khoản admin mặc định
        var admin = db.Members.FirstOrDefault(m => m.Email == "admin@pcm.com");
        if (admin == null)
        {
            db.Members.Add(new Member283
            {
                FullName = "Admin",
                Email = "admin@pcm.com",
                Password = "123456",
                WalletBalance = 0,
                Role = "Admin",
                Tier = "Premium",
                JoinDate = DateTime.Now,
                CreatedAt = DateTime.Now
            });
        }
        else
        {
            admin.FullName = "Admin";
            admin.Password = "123456";
            admin.WalletBalance = 0;
        }
        db.SaveChanges(); // Sửa từ SaveChangesAsync thành SaveChanges
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error initializing database: {ex.Message}");
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "My API V1");
        // Nếu bạn muốn truy cập thẳng qua http://IP:5001/ thì thêm dòng dưới:
        // c.RoutePrefix = string.Empty; 
    });
}

// Sử dụng CORS - VỊ TRÍ QUAN TRỌNG
app.UseCors("AllowAll");

// Tạm thời comment dòng này để test
// app.UseHttpsRedirection();

app.UseAuthorization();
app.MapControllers();

app.Run();
﻿-- 1. TẠO DATABASE
USE master;
GO

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'PcmClub_283_ball')
BEGIN
    ALTER DATABASE [PcmClub_283_ball] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [PcmClub_283_ball];
    PRINT 'Database cũ đã xóa';
END
GO

CREATE DATABASE PcmClub_283_ball;
GO

USE PcmClub_283_ball;
GO

-- 2. TẠO BẢNG MEMBERS (giống với model Member283.cs)
CREATE TABLE [Members] (
    [Id] INT IDENTITY(1,1) PRIMARY KEY,
    [FullName] NVARCHAR(100) NOT NULL,
    [Email] NVARCHAR(100) NOT NULL UNIQUE,
    [Password] NVARCHAR(100) NOT NULL,
    [WalletBalance] DECIMAL(18,2) DEFAULT 0.00,
    -- Thêm các trường optional từ SQL cũ
    [JoinDate] DATETIME2 DEFAULT GETDATE(),
    [RankLevel] FLOAT DEFAULT 1000.0,
    [Status] BIT DEFAULT 1,
    [Tier] INT DEFAULT 0,
    [TotalSpent] DECIMAL(18,2) DEFAULT 0.00,
    [AvatarUrl] NVARCHAR(500) NULL,
    [CreatedAt] DATETIME2 DEFAULT GETDATE(),
    [UpdatedAt] DATETIME2 DEFAULT GETDATE(),
    -- Thêm các trường mới
    [Phone] NVARCHAR(50) NULL,
    [Role] NVARCHAR(50) NULL,
    [Tier] NVARCHAR(50) NULL,
    [AvatarUrl] NVARCHAR(255) NULL,
    [JoinDate] DATETIME NULL,
    [Status] BIT NULL,
    [TotalSpent] DECIMAL(18,2) NULL,
    [UserId] NVARCHAR(450) NULL
);
GO

-- 3. TẠO BẢNG BOOKINGS (giống với model Booking283.cs)
CREATE TABLE [Bookings] (
    [Id] INT IDENTITY(1,1) PRIMARY KEY,
    [MemberId] INT NOT NULL,
    [StartTime] DATETIME2 NOT NULL,
    [EndTime] DATETIME2 NOT NULL,
    [Status] NVARCHAR(50) NOT NULL DEFAULT 'Confirmed', -- Ví dụ: "Confirmed", "Cancelled"
    -- Thêm các trường optional từ SQL cũ
    [CourtId] INT NULL,
    [TotalPrice] DECIMAL(18,2) DEFAULT 0.00,
    [TransactionId] INT NULL,
    [IsRecurring] BIT DEFAULT 0,
    [RecurrenceRule] NVARCHAR(200) NULL,
    [ParentBookingId] INT NULL,
    [HoldUntil] DATETIME2 NULL,
    [CreatedAt] DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY ([MemberId]) REFERENCES [Members]([Id])
);
GO

-- 4. TẠO BẢNG COURTS (nếu cần)
CREATE TABLE [Courts] (
    [Id] INT IDENTITY(1,1) PRIMARY KEY,
    [Name] NVARCHAR(100) NOT NULL,
    [IsActive] BIT DEFAULT 1,
    [Description] NVARCHAR(500) NULL,
    [PricePerHour] DECIMAL(18,2) NOT NULL,
    [CreatedAt] DATETIME2 DEFAULT GETDATE()
);
GO

-- 5. TẠO BẢNG WALLET TRANSACTIONS (nếu cần)
CREATE TABLE [WalletTransactions] (
    [Id] INT IDENTITY(1,1) PRIMARY KEY,
    [MemberId] INT NOT NULL,
    [Amount] DECIMAL(18,2) NOT NULL,
    [Type] NVARCHAR(50) NOT NULL, -- 'Deposit', 'Withdraw', 'Payment', 'Refund'
    [Status] NVARCHAR(50) NOT NULL DEFAULT 'Pending', -- 'Pending', 'Completed', 'Failed'
    [Description] NVARCHAR(500) NULL,
    [CreatedDate] DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY ([MemberId]) REFERENCES [Members]([Id])
);
GO

-- 6. INSERT DỮ LIỆU MẪU CƠ BẢN
-- Thêm tài khoản admin (phù hợp với code trong Program.cs)
INSERT INTO [Members] (FullName, Email, Password, WalletBalance, Status, Tier) 
VALUES 
('Admin', 'admin@pcm.com', '123456', 1000000.00, 1, 3),
('Nguyễn Văn A', 'nguyenvana@email.com', '123456', 500000.00, 1, 1),
('Trần Thị B', 'tranthib@email.com', '123456', 300000.00, 1, 0);
GO

-- Thêm dữ liệu Courts
INSERT INTO [Courts] (Name, IsActive, PricePerHour, Description) VALUES
('Sân 1', 1, 150000.00, 'Sân chính - có máy lạnh'),
('Sân 2', 1, 150000.00, 'Sân chính - có máy lạnh'),
('Sân 3', 1, 120000.00, 'Sân phụ'),
('Sân 4', 1, 120000.00, 'Sân phụ');
GO

-- Thêm dữ liệu Bookings mẫu
INSERT INTO [Bookings] (MemberId, CourtId, StartTime, EndTime, Status, TotalPrice) VALUES
(1, 1, DATEADD(HOUR, 2, GETDATE()), DATEADD(HOUR, 3, GETDATE()), 'Confirmed', 150000.00),
(2, 2, DATEADD(DAY, 1, GETDATE()), DATEADD(DAY, 1, DATEADD(HOUR, 1, GETDATE())), 'Confirmed', 150000.00),
(3, 3, DATEADD(DAY, 2, GETDATE()), DATEADD(DAY, 2, DATEADD(HOUR, 2, GETDATE())), 'Pending', 240000.00);
GO

-- 7. TẠO INDEXES ĐỂ TỐI ƯU HIỆU NĂNG
CREATE INDEX IX_Members_Email ON [Members](Email);
CREATE INDEX IX_Bookings_MemberId ON [Bookings](MemberId);
CREATE INDEX IX_Bookings_StartTime ON [Bookings](StartTime);
CREATE INDEX IX_WalletTransactions_MemberId ON [WalletTransactions](MemberId);
GO

-- 8. TẠO VIEW ĐỂ THỐNG KÊ
CREATE VIEW vw_MemberStats AS
SELECT 
    m.Id,
    m.FullName,
    m.Email,
    m.WalletBalance,
    COUNT(b.Id) AS TotalBookings,
    SUM(CASE WHEN b.Status = 'Confirmed' THEN 1 ELSE 0 END) AS ConfirmedBookings,
    SUM(b.TotalPrice) AS TotalSpent
FROM [Members] m
LEFT JOIN [Bookings] b ON m.Id = b.MemberId
GROUP BY m.Id, m.FullName, m.Email, m.WalletBalance;
GO

-- 9. TẠO STORED PROCEDURE ĐỂ NẠP TIỀN
CREATE PROCEDURE sp_TopUpWallet
    @MemberId INT,
    @Amount DECIMAL(18,2),
    @TransactionType NVARCHAR(50) = 'Deposit'
AS
BEGIN
    BEGIN TRANSACTION;
    
    -- Cập nhật số dư ví
    UPDATE [Members] 
    SET WalletBalance = WalletBalance + @Amount,
        UpdatedAt = GETDATE()
    WHERE Id = @MemberId;
    
    -- Ghi nhận giao dịch
    INSERT INTO [WalletTransactions] (MemberId, Amount, Type, Status, Description, CreatedDate)
    VALUES (@MemberId, @Amount, @TransactionType, 'Completed', 
            'Nạp tiền vào ví', GETDATE());
    
    COMMIT TRANSACTION;
    
    SELECT 'Success' AS Result, @Amount AS AmountAdded;
END
GO

-- 10. TẠO STORED PROCEDURE ĐỂ ĐẶT SÂN
CREATE PROCEDURE sp_CreateBooking
    @MemberId INT,
    @CourtId INT,
    @StartTime DATETIME2,
    @EndTime DATETIME2,
    @TotalPrice DECIMAL(18,2)
AS
BEGIN
    BEGIN TRANSACTION;
    
    -- Kiểm tra sân có trống không
    IF EXISTS (
        SELECT 1 FROM [Bookings] 
        WHERE CourtId = @CourtId 
        AND Status = 'Confirmed'
        AND (
            (@StartTime BETWEEN StartTime AND EndTime)
            OR (@EndTime BETWEEN StartTime AND EndTime)
            OR (StartTime BETWEEN @StartTime AND @EndTime)
        )
    )
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 'Failed' AS Result, 'Sân đã được đặt trong khoảng thời gian này' AS Message;
        RETURN;
    END
    
    -- Tạo booking
    INSERT INTO [Bookings] (MemberId, CourtId, StartTime, EndTime, Status, TotalPrice, CreatedAt)
    VALUES (@MemberId, @CourtId, @StartTime, @EndTime, 'Confirmed', @TotalPrice, GETDATE());
    
    -- Trừ tiền từ ví
    UPDATE [Members] 
    SET WalletBalance = WalletBalance - @TotalPrice,
        TotalSpent = TotalSpent + @TotalPrice,
        UpdatedAt = GETDATE()
    WHERE Id = @MemberId;
    
    -- Ghi nhận giao dịch thanh toán
    INSERT INTO [WalletTransactions] (MemberId, Amount, Type, Status, Description, CreatedDate)
    VALUES (@MemberId, @TotalPrice, 'Payment', 'Completed', 
            'Thanh toán đặt sân', GETDATE());
    
    COMMIT TRANSACTION;
    
    SELECT 'Success' AS Result, 'Đặt sân thành công' AS Message, SCOPE_IDENTITY() AS BookingId;
END
GO

PRINT 'Database PcmClub_283_ball đã được tạo thành công với schema phù hợp với .NET backend!';
PRINT 'Tài khoản admin: admin@pcm.com / 123456';
PRINT 'Tài khoản test: nguyenvana@email.com / 123456';
PRINT 'Tài khoản test: tranthib@email.com / 123456';
GO

ALTER TABLE Members ALTER COLUMN AvatarUrl NVARCHAR(255) NULL;
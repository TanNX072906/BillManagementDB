USE master;
GO

-- 1. Kiểm tra nếu Database đã tồn tại thì xóa
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'BillManagement')
BEGIN
    -- Ngắt toàn bộ kết nối đang hoạt động để có thể xóa DB
    ALTER DATABASE BillManagement SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    DROP DATABASE BillManagement;
    PRINT 'Database cu da bi xoa.';
END
GO

-- 2. Tạo mới Database
CREATE DATABASE BillManagement;
GO

PRINT 'Database moi da duoc tao thanh cong.';
USE BillManagement;
GO

CREATE TABLE Users (
    user_id BIGINT PRIMARY KEY IDENTITY(1,1),
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL 
        CHECK (role IN ('ADMIN','STAFF','AUDITOR')),
    status VARCHAR(20) DEFAULT 'ACTIVE'
        CHECK (status IN ('ONLINE','LOCKED','OFFLINE')),
    created_at DATETIME DEFAULT GETDATE()
);
-- Thêm User Quản trị
INSERT INTO Users (username, password, role, status, created_at)
VALUES ('a', '1', 'ADMIN', 'ACTIVE', GETDATE());

-- Thêm User Nhân viên
INSERT INTO Users (username, password, role, status, created_at)
VALUES ('staff_01', 'staff456', 'STAFF', 'ACTIVE', GETDATE());

-- Thêm User bị khóa (để test logic status)
INSERT INTO Users (username, password, role, status, created_at)
VALUES ('user_old', 'staff789', 'STAFF', 'LOCKED', '2025-01-01 08:00:00');
GO

CREATE TABLE Shifts (
    shift_id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT NOT NULL,
    shift_date DATE NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NULL,
    status VARCHAR(20) DEFAULT 'OPEN'
        CHECK (status IN ('OPEN','CLOSED')),

    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
-- Chạy lúc: ~15:54 Ngày 06/03/2026
-- Đảm bảo user_id 1, 2, 3 đã tồn tại trong bảng Users

-- CHẠY LỆNH NÀY ĐỂ TẠO DATA MỚI (Đã set đầy đủ start_time và end_time cố định)

INSERT INTO Shifts (user_id, shift_date, start_time, end_time, status)
VALUES 
    -- 1. Ca hành chính hôm qua (Đã chốt)
    (1, '2026-03-05', '2026-03-05 08:00:00', '2026-03-05 17:00:00', 'CLOSED'),

    -- 2. Ca đêm qua (Vắt qua ngày hôm nay, đã chốt)
    (2, '2026-03-05', '2026-03-05 22:00:00', '2026-03-06 06:00:00', 'CLOSED'),

    -- 3. Ca sáng HÔM NAY (Đã kết thúc lúc 14h, đã chốt)
    (3, '2026-03-06', '2026-03-06 06:00:00', '2026-03-06 14:00:00', 'CLOSED'),

    -- 4. Ca chiều HÔM NAY (Đang diễn ra - OPEN)
    -- Được lên lịch từ 14:00 đến 22:00. Lúc này là ~16h nên ca này đang OPEN hợp lý.
    (1, '2026-03-07', '2026-03-07 14:00:00', '2026-03-07 22:00:00', 'CLOSED'),

    -- 5. Ca hành chính HÔM NAY (Đang diễn ra - OPEN)
    -- Được lên lịch từ 08:00 đến 17:00. Vẫn đang trong giờ làm việc.
    (2, '2026-03-07', '2026-03-07 08:00:00', '2026-03-07 17:00:00', 'CLOSED');
GO
CREATE TABLE Invoices (
    invoice_id BIGINT PRIMARY KEY IDENTITY(1,1),
    invoice_code VARCHAR(50) NOT NULL UNIQUE,
    amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('COMPLETED','PENDING','APPROVED','REJECTED', 'DELETED')),
    created_by BIGINT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT NULL,
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
-- Đảm bảo bạn đã có User ID 1 và 2 trong bảng Users trước khi chạy
INSERT INTO Invoices (invoice_code, amount, status, created_by, created_at, updated_at)
VALUES 
('INV-2026-001', 15000000.00, 'APPROVED', 1, '2026-03-01 08:30:00', GETDATE()),
('INV-2026-002', 2550000.50, 'COMPLETED',    1, '2026-03-02 09:15:00', GETDATE()),
('INV-2026-003', 500000.00,   'REJECTED', 2, '2026-03-02 14:00:00', GETDATE()),
('INV-2026-004', 1200000.00,  'DELETED',     1, '2026-03-03 10:00:00', GETDATE()),
('INV-2026-005', 8990000.00,  'COMPLETED',    2, '2026-03-04 11:45:00', GETDATE());
GO

CREATE TABLE Invoice_History (
    history_id BIGINT PRIMARY KEY IDENTITY(1,1),
    invoice_id BIGINT NOT NULL,
    old_amount DECIMAL(15,2),
    new_amount DECIMAL(15,2),
    modified_by BIGINT NOT NULL,
    shift_id BIGINT NOT NULL,
    reason VARCHAR(255),
    modified_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id),
    FOREIGN KEY (modified_by) REFERENCES Users(user_id),
    FOREIGN KEY (shift_id) REFERENCES Shifts(shift_id)
);
GO

CREATE TABLE Products (
    product_id BIGINT PRIMARY KEY IDENTITY(1,1),
    product_name NVARCHAR(255) NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME
);
GO

CREATE TABLE Invoice_Details (
    detail_id BIGINT PRIMARY KEY IDENTITY(1,1),
    invoice_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(15,2) NOT NULL, -- Giá tại thời điểm mua
    total_price DECIMAL(15,2) NOT NULL, -- quantity * unit_price
    
    FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);
GO

CREATE TABLE Activity_Logs (
    log_id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT NOT NULL,
    shift_id BIGINT NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id BIGINT,
    description VARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (shift_id) REFERENCES Shifts(shift_id)
);
GO

CREATE TABLE Alerts (
    alert_id BIGINT PRIMARY KEY IDENTITY(1,1),
    entity_type VARCHAR(20)
        CHECK (entity_type IN ('USER','INVOICE','SHIFT')),
    entity_id BIGINT,
    risk_score INT,
    message VARCHAR(MAX),
    status VARCHAR(20) DEFAULT 'NEW'
        CHECK (status IN ('NEW','INVESTIGATING','RESOLVED')),
    created_at DATETIME DEFAULT GETDATE()
);
GO

select * from Users
select * from Shifts
select * from Invoices

select * from Invoice_Details
select * from Products
select * from Alerts
select * from Activity_Logs
go
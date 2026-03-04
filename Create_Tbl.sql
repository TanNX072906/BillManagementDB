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
        CHECK (status IN ('ACTIVE','LOCKED')),
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
GO
CREATE TABLE Invoices (
    invoice_id BIGINT PRIMARY KEY IDENTITY(1,1),
    invoice_code VARCHAR(50) NOT NULL UNIQUE,
    amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('COMPLETED','PENDING','APPROVED','REJECTED')),
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
('INV-2026-004', 1200000.00,  'PENDING',     1, '2026-03-03 10:00:00', GETDATE()),
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


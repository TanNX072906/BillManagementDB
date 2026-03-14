USE master;
GO

-- ====================================================================
-- 1. XÓA VÀ TẠO LẠI DATABASE
-- ====================================================================
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'BillManagement')
BEGIN
    ALTER DATABASE BillManagement SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BillManagement;
    PRINT 'Database cu da bi xoa.';
END
GO

CREATE DATABASE BillManagement;
GO
PRINT 'Database moi da duoc tao thanh cong.';
GO

USE BillManagement;
GO

-- ====================================================================
-- 2. TẠO CẤU TRÚC BẢNG (TABLES)
-- ====================================================================
CREATE TABLE Users (
    user_id BIGINT PRIMARY KEY IDENTITY(1,1),
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL 
        CHECK (role IN ('ADMIN','STAFF','AUDITOR')),
    status VARCHAR(20) DEFAULT 'ONLINE'
        CHECK (status IN ('ONLINE','LOCKED','OFFLINE')),
    created_at DATETIME DEFAULT GETDATE()
);
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
        CHECK (status IN ('COMPLETED','PENDING','APPROVED','REJECTED', 'DELETED')),
    created_by BIGINT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT NULL,
    FOREIGN KEY (created_by) REFERENCES Users(user_id)
);
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
    unit_price DECIMAL(15,2) NOT NULL,
    total_price DECIMAL(15,2) NOT NULL, 
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
        CHECK (status IN ('NEW','RESOLVED')),
    created_at DATETIME DEFAULT GETDATE()
);
GO

-- ====================================================================
-- 3. INSERT DỮ LIỆU DEMO (GỘP CHUNG TẤT CẢ)
-- ====================================================================

-- 3.1 BẢNG USERS (ID 1 -> 7)
INSERT INTO Users (username, password, role, status, created_at) VALUES 
('a', '1', 'ADMIN', 'OFFLINE', GETDATE()),                    -- ID 1
('staff_01', 'staff456', 'STAFF', 'OFFLINE', GETDATE()),       -- ID 2
('user_old', 'staff789', 'STAFF', 'LOCKED', '2025-01-01'),    -- ID 3
('auditor_vip', 'pwd123', 'AUDITOR', 'OFFLINE', '2026-02-01'), -- ID 4
('staff_02', 'pwd123', 'STAFF', 'OFFLINE', '2026-02-15'),      -- ID 5
('staff_03', 'pwd123', 'STAFF', 'OFFLINE', '2026-02-15'),     -- ID 6
('hacker_guy', 'pwd123', 'STAFF', 'LOCKED', '2026-03-01');    -- ID 7
GO

-- 3.2 BẢNG PRODUCTS (ID 1 -> 10)
INSERT INTO Products (product_name, price, status, created_at) VALUES
(N'MacBook Pro M3 14-inch', 35000000.00, 'ACTIVE', '2026-01-10'),
(N'Dell UltraSharp 27 Monitor', 8500000.00, 'ACTIVE', '2026-01-10'),
(N'Logitech MX Master 3S', 2500000.00, 'ACTIVE', '2026-01-10'),
(N'Keychron MX Mechanical', 3200000.00, 'ACTIVE', '2026-01-15'),
(N'Office Desk Ergonomic', 4500000.00, 'ACTIVE', '2026-01-15'),
(N'Herman Miller Chair', 25000000.00, 'ACTIVE', '2026-01-20'),
(N'Windows 11 Pro License', 350000.00, 'ACTIVE', '2026-02-01'),
(N'Kaspersky Antivirus 1Y', 350000.00, 'ACTIVE', '2026-02-01'),
(N'Old Mouse (Discontinued)', 150000.00, 'INACTIVE', '2025-12-01'),
(N'Server Maintenance Service', 15000000.00, 'ACTIVE', '2026-02-15');
GO

-- 3.3 BẢNG SHIFTS (ID 1 -> 8)
INSERT INTO Shifts (user_id, shift_date, start_time, end_time, status) VALUES 
(1, '2026-03-05', '2026-03-05 08:00:00', '2026-03-05 17:00:00', 'CLOSED'), -- ID 1
(2, '2026-03-05', '2026-03-05 22:00:00', '2026-03-06 06:00:00', 'CLOSED'), -- ID 2
(3, '2026-03-06', '2026-03-06 06:00:00', '2026-03-06 14:00:00', 'CLOSED'), -- ID 3
(1, '2026-03-07', '2026-03-07 14:00:00', '2026-03-07 22:00:00', 'CLOSED'), -- ID 4
(2, '2026-03-07', '2026-03-07 08:00:00', '2026-03-07 17:00:00', 'CLOSED'), -- ID 5
(2, '2026-03-10', '2026-03-10 08:00:00', '2026-03-10 17:00:00', 'CLOSED'), -- ID 6
(5, '2026-03-11', '2026-03-11 14:00:00', '2026-03-11 22:30:00', 'CLOSED'), -- ID 7
(5, '2026-03-14', '2026-03-14 08:00:00', NULL, 'OPEN');                    -- ID 8
GO

-- 3.4 BẢNG INVOICES (ID 1 -> 10) - Đã update mã Format
INSERT INTO Invoices (invoice_code, amount, status, created_by, created_at, updated_at) VALUES 
('INV-20260301083000-001', 15000000.00, 'APPROVED',  1, '2026-03-01 08:30:00', GETDATE()),
('INV-20260302091500-002', 2550000.50,  'COMPLETED', 1, '2026-03-02 09:15:00', GETDATE()),
('INV-20260302140000-003', 500000.00,   'REJECTED',  2, '2026-03-02 14:00:00', GETDATE()),
('INV-20260303100000-004', 1200000.00,  'DELETED',   1, '2026-03-03 10:00:00', GETDATE()),
('INV-20260304114500-005', 8990000.00,  'COMPLETED', 2, '2026-03-04 11:45:00', GETDATE()),
('INV-20260310101500-006', 43500000.00, 'COMPLETED', 2, '2026-03-10 10:15:00', '2026-03-10 10:20:00'),
('INV-20260311153000-007', 350000.00,   'APPROVED',  5, '2026-03-11 15:30:00', '2026-03-11 16:00:00'),
('INV-20260314094500-008', 50000000.00, 'PENDING',   5, '2026-03-14 09:45:00', NULL),
('INV-20260312110000-009', 8500000.00,  'REJECTED',  2, '2026-03-12 11:00:00', '2026-03-12 11:30:00'),
('INV-20260314100000-010', 10500000.00, 'COMPLETED', 1, '2026-03-14 10:00:00', '2026-03-14 10:05:00');
GO

-- 3.5 BẢNG INVOICE DETAILS
INSERT INTO Invoice_Details (invoice_id, product_id, quantity, unit_price, total_price) VALUES 
(6, 1, 1, 35000000.00, 35000000.00),
(6, 2, 1, 8500000.00,  8500000.00),
(7, 8, 1, 350000.00, 350000.00),
(8, 6, 2, 25000000.00, 50000000.00),
(9, 2, 1, 8500000.00, 8500000.00),
(10, 7, 3, 3500000.00, 10500000.00);
GO

-- 3.6 BẢNG INVOICE HISTORY
INSERT INTO Invoice_History (invoice_id, old_amount, new_amount, modified_by, shift_id, reason, modified_at) VALUES 
(4, 1200000.00, 0.00, 1, 1, 'Customer canceled the order', '2026-03-03 10:30:00'),
(6, 45000000.00, 43500000.00, 2, 6, 'Applied VIP discount code', '2026-03-10 10:20:00');
GO

-- 3.7 BẢNG ACTIVITY LOGS
INSERT INTO Activity_Logs (user_id, shift_id, action_type, entity_type, entity_id, description, created_at) VALUES 
(2, 6, 'CREATE', 'INVOICE', 6, 'Created invoice INV-20260310101500-006', '2026-03-10 10:15:00'),
(2, 6, 'UPDATE', 'INVOICE', 6, 'Applied discount to INV-20260310101500-006', '2026-03-10 10:20:00'),
(5, 8, 'LOGIN', 'USER', 5, 'User staff_02 logged in', '2026-03-14 08:00:00'),
(5, 8, 'CREATE', 'INVOICE', 8, 'Created high-value invoice INV-20260314094500-008', '2026-03-14 09:45:00');
GO

-- 3.8 BẢNG ALERTS
INSERT INTO Alerts (entity_type, entity_id, risk_score, message, status, created_at) VALUES 
('INVOICE', 8, 95, 'High Value Invoice created by Staff. Requires Auditor approval.', 'NEW', '2026-03-14 09:45:05'),
('USER', 7, 88, 'Multiple failed login attempts detected. Account locked automatically.', 'NEW', '2026-03-01 08:05:00'),
('INVOICE', 4, 80, 'Invoice DELETED after being printed. Possible fraud.', 'RESOLVED', '2026-03-03 10:35:00'),
('SHIFT', 7, 65, 'Shift exceeded standard 8 hours without manager approval.', 'NEW', '2026-03-11 22:35:00'),
('INVOICE', 9, 50, 'Invoice rejected due to missing customer tax information.', 'RESOLVED', '2026-03-12 11:35:00'),
('USER', 5, 20, 'User logged in from new IP address.', 'RESOLVED', '2026-03-14 08:01:00');
GO

PRINT '==================================================';
PRINT 'XONG! HE THONG DA DUOC RESET VA THEM DATA HOAN HAO!';
PRINT '==================================================';

-- ====================================================================
-- 4. HIỂN THỊ KẾT QUẢ ĐỂ KIỂM TRA NHANH
-- ====================================================================
SELECT 'Users' AS TableName, COUNT(*) AS TotalRows FROM Users
UNION ALL
SELECT 'Shifts', COUNT(*) FROM Shifts
UNION ALL
SELECT 'Invoices', COUNT(*) FROM Invoices
UNION ALL
SELECT 'Invoice_Details', COUNT(*) FROM Invoice_Details
UNION ALL
SELECT 'Products', COUNT(*) FROM Products
UNION ALL
SELECT 'Alerts', COUNT(*) FROM Alerts
UNION ALL
SELECT 'Activity_Logs', COUNT(*) FROM Activity_Logs;
GO
select * from Users
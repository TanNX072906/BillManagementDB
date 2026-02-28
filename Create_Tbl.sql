CREATE TABLE Users (
    user_id BIGINT PRIMARY KEY IDENTITY(1,1),
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL 
        CHECK (role IN ('ADMIN','STAFF','AUDITOR')),
    status VARCHAR(20) DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE','LOCKED')),
    created_at DATETIME DEFAULT GETDATE()
);
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

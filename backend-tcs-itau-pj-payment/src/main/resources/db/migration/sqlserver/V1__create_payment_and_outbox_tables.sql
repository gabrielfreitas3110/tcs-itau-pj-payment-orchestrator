IF OBJECT_ID('dbo.payments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.payments (
        id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        cnpj VARCHAR(14) NOT NULL,
        amount DECIMAL(19,2) NOT NULL,
        currency VARCHAR(3) NOT NULL,
        merchant_id VARCHAR(255) NOT NULL,
        status VARCHAR(32) NOT NULL,
        created_at DATETIMEOFFSET NOT NULL
    );
END;

IF OBJECT_ID('dbo.outbox_events', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.outbox_events (
        id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        event_type VARCHAR(100) NOT NULL,
        aggregate_id VARCHAR(100) NOT NULL,
        payload NVARCHAR(MAX) NOT NULL,
        occurred_at DATETIMEOFFSET NOT NULL,
        published_at DATETIMEOFFSET NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'idx_outbox_unpublished'
      AND object_id = OBJECT_ID('dbo.outbox_events')
)
BEGIN
    CREATE NONCLUSTERED INDEX idx_outbox_unpublished
        ON dbo.outbox_events (occurred_at)
        WHERE published_at IS NULL;
END;

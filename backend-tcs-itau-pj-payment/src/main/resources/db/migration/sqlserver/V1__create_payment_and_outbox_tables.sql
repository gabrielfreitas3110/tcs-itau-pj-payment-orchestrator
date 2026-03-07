CREATE TABLE payments (
    id          UNIQUEIDENTIFIER  NOT NULL,
    cnpj        VARCHAR(14)       NOT NULL,
    amount      DECIMAL(19,2)     NOT NULL,
    currency    VARCHAR(3)        NOT NULL,
    merchant_id VARCHAR(255)      NOT NULL,
    status      VARCHAR(32)       NOT NULL,
    created_at  DATETIMEOFFSET    NOT NULL,

    CONSTRAINT PK_payments PRIMARY KEY (id)
);

CREATE TABLE outbox_events (
    id           UNIQUEIDENTIFIER  NOT NULL,
    event_type   VARCHAR(100)      NOT NULL,
    aggregate_id VARCHAR(100)      NOT NULL,
    payload      NVARCHAR(MAX)     NOT NULL,
    occurred_at  DATETIMEOFFSET    NOT NULL,
    published_at DATETIMEOFFSET    NULL,

    CONSTRAINT PK_outbox_events PRIMARY KEY (id)
);

CREATE NONCLUSTERED INDEX IX_outbox_unpublished
    ON outbox_events (occurred_at)
    WHERE published_at IS NULL;

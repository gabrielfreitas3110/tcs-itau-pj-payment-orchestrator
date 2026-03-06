CREATE TABLE settlements (
    id           NVARCHAR(36)  NOT NULL,
    payment_id   NVARCHAR(36)  NOT NULL,
    fraud_event_id NVARCHAR(36) NOT NULL,
    decision     NVARCHAR(20)  NOT NULL,
    status       NVARCHAR(30)  NOT NULL,
    settled_at   DATETIME2     NOT NULL,

    CONSTRAINT PK_settlements PRIMARY KEY (id),
    CONSTRAINT UQ_settlements_payment_id UNIQUE (payment_id)
);

CREATE INDEX IX_settlements_status ON settlements (status);

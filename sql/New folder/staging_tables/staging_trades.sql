--staging trades

CREATE TABLE IF NOT EXISTS stg_trades (
    trade_ref            VARCHAR(30),
    portfolio_code       VARCHAR(20),
    instrument_code      VARCHAR(30),
    trade_type           VARCHAR(10),
    quantity             NUMERIC(18,4),
    price                NUMERIC(18,6),
    trade_date           DATE,
    settlement_date      DATE,
    counterparty         VARCHAR(100),
    trade_status         VARCHAR(20),
    source_system        VARCHAR(50),
    load_timestamp       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


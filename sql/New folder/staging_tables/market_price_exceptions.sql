-- market price exceptions


CREATE TABLE IF NOT EXISTS market_price_exceptions (
    exception_id         SERIAL PRIMARY KEY,
    instrument_code      VARCHAR(30),
    price_date           DATE,
    market_price         NUMERIC(18,6),
    price_source         VARCHAR(50),
    error_reason         VARCHAR(255),
    logged_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
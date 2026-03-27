-- staging market prices

CREATE TABLE IF NOT EXISTS stg_market_prices (
    instrument_code      VARCHAR(30),
    price_date           DATE,
    market_price         NUMERIC(18,6),
    price_source         VARCHAR(50),
    load_timestamp       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
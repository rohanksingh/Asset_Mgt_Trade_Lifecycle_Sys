CREATE OR REPLACE DATABASE asset_mgmt_demo;

\c asset_mgmt_demo

SELECT current_database();


CREATE TABLE IF NOT EXISTS portfolios (
    portfolio_id        SERIAL PRIMARY KEY,
    portfolio_code      VARCHAR(20) UNIQUE NOT NULL,
    portfolio_name      VARCHAR(100) NOT NULL,
    base_currency       VARCHAR(3) NOT NULL,
    inception_date      DATE,
    status              VARCHAR(20) DEFAULT 'ACTIVE'
);

CREATE TABLE IF NOT EXISTS instruments (
    instruments_id       SERIAL PRIMARY KEY,
    instrument_code     VARCHAR(30) UNIQUE NOT NULL,
    instrument_name     VARCHAR(150) NOT NULL,
    asset_class         VARCHAR(30) NOT NULL,
    instrument_type     VARCHAR(30),
    currency            VARCHAR(3) NOT NULL,
    isin                VARCHAR(20),
    coupon_rate         NUMERIC(8,4),
    maturity_date       DATE,
    issuer_name         VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS trades (
    trade_id            SERIAL PRIMARY KEY,
    trade_ref           VARCHAR(30) UNIQUE NOT NULL,
    portfolio_id        INT NOT NULL REFERENCES portfolios(portfolio_id),
    instruments_id       INT NOT NULL REFERENCES instruments(instrument_id),
    trade_type          VARCHAR(10) NOT NULL CHECK (trade_type IN ('BUY','SELL')),
    quantity            NUMERIC(18,4) NOT NULL,
    price               NUMERIC(18,6) NOT NULL,
    trade_date          DATE NOT NULL,
    settlement_date     DATE NOT NULL,
    counterparty        VARCHAR(100),
    trade_status        VARCHAR(20) NOT NULL CHECK (
                            trade_status IN ('NEW','EXECUTED','SETTLED','FAILED','CANCELLED')
                        ),
    source_system       VARCHAR(50),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS market_prices (
    price_id            SERIAL PRIMARY KEY,
    instruments_id       INT NOT NULL REFERENCES instruments(instrument_id),
    price_date          DATE NOT NULL,
    market_price        NUMERIC(18,6) NOT NULL,
    price_source        VARCHAR(50),
    UNIQUE (instrument_id, price_date)
);

CREATE TABLE IF NOT EXISTS custodian_trades (
    custodian_trade_id  SERIAL PRIMARY KEY,
    trade_ref           VARCHAR(30) NOT NULL,
    portfolio_code      VARCHAR(20) NOT NULL,
    instrument_code     VARCHAR(30) NOT NULL,
    trade_type          VARCHAR(10) NOT NULL,
    quantity            NUMERIC(18,4) NOT NULL,
    price               NUMERIC(18,6) NOT NULL,
    trade_date          DATE NOT NULL,
    settlement_date     DATE NOT NULL,
    custodian_name      VARCHAR(100) NOT NULL,
    load_date           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

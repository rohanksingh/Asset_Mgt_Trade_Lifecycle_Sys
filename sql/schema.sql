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
    instruments_id       INT NOT NULL REFERENCES instruments(instruments_id),
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


CREATE OR REPLACE DATABASE asset_mgmt_demo;

\c asset_mgmt_demo


--POSTION_VIEW
CREATE OR REPLACE VIEW  vw_positions AS
SELECT
    t.portfolio_id,
    t.instruments_id,
    SUM(
        CASE
            WHEN t.trade_type = 'BUY'  THEN t.quantity
            WHEN t.trade_type = 'SELL' THEN -t.quantity
            ELSE 0
        END
    ) AS net_quantity
FROM trades t
WHERE t.trade_status IN ('EXECUTED', 'SETTLED')
GROUP BY t.portfolio_id, t.instruments_id;

--portfolio view 

CREATE OR REPLACE VIEW  vw_portfolio_valuation AS
SELECT
    p.portfolio_code,
    p.portfolio_name,
    i.instrument_code,
    i.instrument_name,
    v.net_quantity,
    mp.market_price,
    (v.net_quantity * mp.market_price) AS market_value,
    mp.price_date
FROM vw_positions v
JOIN portfolios p
    ON v.portfolio_id = p.portfolio_id
JOIN instruments i
    ON v.instruments_id = i.instruments_id
JOIN market_prices mp
    ON v.instruments_id = mp.instruments_id;

CREATE OR REPLACE VIEW vw_latest_market_prices AS
SELECT
    mp.instrument_id,
    mp.price_date,
    mp.market_price,
    mp.price_source
FROM market_prices mp
JOIN (
    SELECT
        instrument_id,
        MAX(price_date) AS max_price_date
    FROM market_prices
    GROUP BY instrument_id
) latest
    ON mp.instrument_id = latest.instrument_id
   AND mp.price_date = latest.max_price_date;


SELECT *
FROM vw_positions
ORDER BY portfolio_id, instruments_id;

SELECT *
FROM vw_portfolio_valuation
ORDER BY portfolio_code, instrument_code, price_date;



CREATE OR REPLACE DATABASE asset_mgmt_demo;

\c asset_mgmt_demo


CREATE INDEX IF NOT EXISTS idx_trades_trade_date ON trades(trade_date);
CREATE INDEX IF NOT EXISTS idx_trades_portfolio_id ON trades(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_trades_instrument_id ON trades(instrument_id);
CREATE INDEX IF NOT EXISTS idx_market_prices_price_date ON market_prices(price_date);
CREATE INDEX IF NOT EXISTS idx_custodian_trades_trade_ref ON custodian_trades(trade_ref);
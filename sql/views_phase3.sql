-- CREATE OR REPLACE DATABASE asset_mgmt_demo;

\c asset_mgmt_demo

-- Create a latest price view

CREATE OR REPLACE VIEW vw_latest_market_prices AS
SELECT
    mp.instruments_id,
    mp.price_date,
    mp.market_price,
    mp.price_source
FROM market_prices mp
JOIN (
    SELECT
        instruments_id,
        MAX(price_date) AS max_price_date
    FROM market_prices
    GROUP BY instruments_id
) latest
    ON mp.instruments_id = latest.instruments_id
   AND mp.price_date = latest.max_price_date;


SELECT *
FROM vw_latest_market_prices
ORDER BY instruments_id;

-- Create improved valuation view

CREATE OR REPLACE VIEW vw_portfolio_valuation_clean AS
SELECT
    p.portfolio_id,
    p.portfolio_code,
    p.portfolio_name,
    i.instruments_id,
    i.instrument_code,
    i.instrument_name,
    i.asset_class,
    i.currency,
    v.net_quantity,
    lp.price_date,
    lp.market_price,
    ROUND((v.net_quantity * lp.market_price)::numeric, 2) AS market_value
FROM vw_positions v
JOIN portfolios p
    ON v.portfolio_id = p.portfolio_id
JOIN instruments i
    ON v.instruments_id = i.instruments_id
JOIN vw_latest_market_prices lp
    ON v.instruments_id = lp.instruments_id;


SELECT *
FROM vw_portfolio_valuation_clean
ORDER BY portfolio_code, instrument_code;


-- portfolio summary view

CREATE OR REPLACE VIEW vw_portfolio_summary AS
SELECT
    portfolio_id,
    portfolio_code,
    portfolio_name,
    COUNT(*) AS holding_count,
    ROUND(SUM(market_value)::numeric, 2) AS total_market_value
FROM vw_portfolio_valuation_clean
GROUP BY portfolio_id, portfolio_code, portfolio_name;


SELECT *
FROM vw_portfolio_summary
ORDER BY portfolio_code;


-- internal vs custodian reconciliation base view

CREATE OR REPLACE VIEW vw_trade_recon_base AS
SELECT
    t.trade_ref,
    p.portfolio_code AS internal_portfolio_code,
    i.instrument_code AS internal_instrument_code,
    t.trade_type AS internal_trade_type,
    t.quantity AS internal_quantity,
    t.price AS internal_price,
    t.trade_date AS internal_trade_date,
    t.settlement_date AS internal_settlement_date,
    t.trade_status,
    c.portfolio_code AS custodian_portfolio_code,
    c.instrument_code AS custodian_instrument_code,
    c.trade_type AS custodian_trade_type,
    c.quantity AS custodian_quantity,
    c.price AS custodian_price,
    c.trade_date AS custodian_trade_date,
    c.settlement_date AS custodian_settlement_date,
    c.custodian_name
FROM trades t
JOIN portfolios p
    ON t.portfolio_id = p.portfolio_id
JOIN instruments i
    ON t.instruments_id = i.instruments_id
LEFT JOIN custodian_trades c
    ON t.trade_ref = c.trade_ref;

-- Test it 

SELECT *
FROM vw_trade_recon_base
ORDER BY trade_ref;

-- Create trade breaks view 

CREATE OR REPLACE VIEW vw_trade_breaks AS
SELECT
    trade_ref,
    internal_portfolio_code,
    internal_instrument_code,
    internal_trade_type,
    internal_quantity,
    internal_price,
    internal_trade_date,
    internal_settlement_date,
    trade_status,
    custodian_portfolio_code,
    custodian_instrument_code,
    custodian_trade_type,
    custodian_quantity,
    custodian_price,
    custodian_trade_date,
    custodian_settlement_date,
    custodian_name,
    CASE
        WHEN custodian_portfolio_code IS NULL THEN 'MISSING_CUSTODIAN_RECORD'
        WHEN internal_quantity <> custodian_quantity THEN 'QUANTITY_MISMATCH'
        WHEN internal_price <> custodian_price THEN 'PRICE_MISMATCH'
        WHEN internal_portfolio_code <> custodian_portfolio_code THEN 'PORTFOLIO_MISMATCH'
        WHEN internal_instrument_code <> custodian_instrument_code THEN 'INSTRUMENT_MISMATCH'
        WHEN internal_trade_type <> custodian_trade_type THEN 'TRADE_TYPE_MISMATCH'
        WHEN internal_settlement_date <> custodian_settlement_date THEN 'SETTLEMENT_DATE_MISMATCH'
        ELSE 'MATCHED'
    END AS recon_status
FROM vw_trade_recon_base;


-- Test it 

SELECT trade_ref, recon_status, internal_quantity, custodian_quantity
FROM vw_trade_breaks
ORDER BY trade_ref;

-- filter to only relevant trades for reconciliation
CREATE OR REPLACE VIEW vw_trade_breaks_active AS
SELECT *
FROM vw_trade_breaks
WHERE trade_status IN ('EXECUTED', 'SETTLED');

-- Test it 

SELECT trade_ref, trade_status, recon_status
FROM vw_trade_breaks_active
ORDER BY trade_ref;

-- settlement status checks

CREATE OR REPLACE VIEW vw_settlement_status AS
SELECT
    t.trade_ref,
    p.portfolio_code,
    i.instrument_code,
    t.trade_type,
    t.quantity,
    t.price,
    t.trade_date,
    t.settlement_date,
    t.trade_status,
    CURRENT_DATE AS as_of_date,
    (CURRENT_DATE - t.settlement_date) AS settlement_delay_days,
    CASE
        WHEN t.trade_status = 'SETTLED' THEN 'SETTLED_OK'
        WHEN t.trade_status = 'FAILED' THEN 'FAILED_SETTLEMENT'
        WHEN t.trade_status IN ('EXECUTED', 'NEW')
             AND t.settlement_date < CURRENT_DATE THEN 'OVERDUE_FOR_SETTLEMENT'
        WHEN t.trade_status IN ('EXECUTED', 'NEW')
             AND t.settlement_date >= CURRENT_DATE THEN 'PENDING_SETTLEMENT'
        ELSE 'UNKNOWN'
    END AS settlement_monitor_status
FROM trades t
JOIN portfolios p
    ON t.portfolio_id = p.portfolio_id
JOIN instruments i
    ON t.instruments_id = i.instruments_id;


-- Test it

SELECT
    trade_ref,
    trade_status,
    settlement_date,
    settlement_delay_days,
    settlement_monitor_status
FROM vw_settlement_status
ORDER BY trade_ref;


-- dashboard-ready reconciliation summary
-- Recon summary by status

CREATE OR REPLACE VIEW vw_recon_summary AS
SELECT
    recon_status,
    COUNT(*) AS trade_count
FROM vw_trade_breaks_active
GROUP BY recon_status
ORDER BY trade_count DESC, recon_status;

-- Test it

SELECT *
FROM vw_recon_summary;

-- dashboard-ready settlement summary

CREATE OR REPLACE VIEW vw_settlement_summary AS
SELECT
    settlement_monitor_status,
    COUNT(*) AS trade_count
FROM vw_settlement_status
GROUP BY settlement_monitor_status
ORDER BY trade_count DESC, settlement_monitor_status;

-- Test it

SELECT *
FROM vw_settlement_summary;


-- dashboard-ready holdings summary by asset class

CREATE OR REPLACE VIEW vw_asset_class_exposure AS
SELECT
    portfolio_code,
    portfolio_name,
    asset_class,
    ROUND(SUM(market_value)::numeric, 2) AS asset_class_market_value
FROM vw_portfolio_valuation_clean
GROUP BY portfolio_code, portfolio_name, asset_class
ORDER BY portfolio_code, asset_class;


SELECT *
FROM vw_asset_class_exposure;


-- most useful business queries

-- portfolio totals

SELECT *
FROM vw_portfolio_summary
ORDER BY portfolio_code;

-- holdings with market value

SELECT
    portfolio_code,
    instrument_code,
    net_quantity,
    market_price,
    market_value
FROM vw_portfolio_valuation_clean
ORDER BY portfolio_code, instrument_code;

-- active trade breaks

SELECT
    trade_ref,
    trade_status,
    recon_status,
    internal_quantity,
    custodian_quantity
FROM vw_trade_breaks_active
WHERE recon_status <> 'MATCHED'
ORDER BY trade_ref;


-- Settlement exceptions

SELECT
    trade_ref,
    trade_status,
    settlement_date,
    settlement_monitor_status
FROM vw_settlement_status
WHERE settlement_monitor_status IN ('FAILED_SETTLEMENT', 'OVERDUE_FOR_SETTLEMENT')
ORDER BY trade_ref;





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




CREATE OR REPLACE DATABASE asset_mgmt_demo;

\c asset_mgmt_demo

-- useful validation queries 

--show executed and settled trades only

SELECT trade_ref, trade_type, quantity, trade_status
FROM trades
WHERE trade_status IN ('EXECUTED', 'SETTLED')
ORDER BY trade_ref;

--count trades by status

SELECT trade_status, COUNT(*) AS trade_count
FROM trades
GROUP BY trade_status
ORDER BY trade_status;

--total market value by portfolio

SELECT
    portfolio_code,
    portfolio_name,
    SUM(market_value) AS total_market_value
FROM vw_portfolio_valuation
GROUP BY portfolio_code, portfolio_name
ORDER BY portfolio_code;

-- For phase 2 check points 

SELECT COUNT(*) FROM portfolios;
SELECT COUNT(*) FROM instruments;
SELECT COUNT(*) FROM trades;

SELECT count(*) FROM custodian_trades;


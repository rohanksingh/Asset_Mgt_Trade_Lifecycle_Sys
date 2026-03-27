CREATE OR REPLACE DATABASE asset_mgmt_demo;

\c asset_mgmt_demo

--insert 
-- portfolios

INSERT INTO portfolios (portfolio_code, portfolio_name, base_currency, inception_date, status)
VALUES
('PF001', 'Global Bond Fund', 'USD', '2020-01-01', 'ACTIVE'),
('PF002', 'Multi Asset Growth Fund', 'USD', '2021-06-15', 'ACTIVE')
ON CONFLICT (portfolio_code) DO NOTHING;

SELECT * FROM portfolios;

--instruments

INSERT INTO instruments (
    instrument_code,
    instrument_name,
    asset_class,
    instrument_type,
    currency,
    isin,
    coupon_rate,
    maturity_date,
    issuer_name
)
VALUES
('UST10Y', 'US Treasury 10Y', 'Fixed Income', 'Bond', 'USD', 'US912828XYZ1', 3.5000, '2034-12-31', 'US Government'),
('CORP_BND_1', 'Corporate Bond A', 'Fixed Income', 'Bond', 'USD', 'US123456ABC1', 5.2500, '2029-09-30', 'ABC Corp'),
('AAPL', 'Apple Inc.', 'Equity', 'Stock', 'USD', 'US0378331005', NULL, NULL, 'Apple'),
('MSFT', 'Microsoft Corp.', 'Equity', 'Stock', 'USD', 'US5949181045', NULL, NULL, 'Microsoft')
ON CONFLICT (instrument_code) DO NOTHING;


SELECT * FROM instruments;

SELECT portfolio_id, portfolio_code, portfolio_name
FROM portfolios;

SELECT instruments_id, instrument_code, instrument_name
FROM instruments;

--trades

INSERT INTO trades (
    trade_ref,
    portfolio_id,
    instruments_id,
    trade_type,
    quantity,
    price,
    trade_date,
    settlement_date,
    counterparty,
    trade_status,
    source_system
)
VALUES
('TRD001', 1, 1, 'BUY', 1000000, 99.250000, '2026-03-20', '2026-03-24', 'Goldman Sachs', 'EXECUTED', 'OMS'),
('TRD002', 1, 2, 'BUY', 500000, 101.100000, '2026-03-20', '2026-03-24', 'JP Morgan', 'SETTLED', 'OMS'),
('TRD003', 2, 3, 'BUY', 1000, 185.500000, '2026-03-21', '2026-03-25', 'Morgan Stanley', 'EXECUTED', 'OMS'),
('TRD004', 2, 4, 'BUY', 800, 402.250000, '2026-03-21', '2026-03-25', 'Bank of America', 'EXECUTED', 'OMS'),
('TRD005', 1, 1, 'SELL', 200000, 99.800000, '2026-03-22', '2026-03-26', 'Goldman Sachs', 'NEW', 'OMS'),
('TRD006', 2, 3, 'SELL', 200, 186.750000, '2026-03-22', '2026-03-26', 'Morgan Stanley', 'FAILED', 'OMS'),
('TRD007', 1, 2, 'BUY', 250000, 100.750000, '2026-03-23', '2026-03-27', 'Citibank', 'EXECUTED', 'OMS'),
('TRD008', 2, 4, 'SELL', 100, 405.000000, '2026-03-23', '2026-03-27', 'UBS', 'SETTLED', 'OMS')

ON CONFLICT (trade_ref) DO NOTHING;

SELECT trade_ref, portfolio_id, instruments_id, trade_type, quantity, price, trade_status
FROM trades
ORDER BY trade_ref;

--market prices

INSERT INTO market_prices (
    instruments_id,
    price_date,
    market_price,
    price_source
)
VALUES
(1, '2026-03-24', 99.600000, 'Bloomberg'),
(2, '2026-03-24', 101.350000, 'Bloomberg'),
(3, '2026-03-24', 187.200000, 'Bloomberg'),
(4, '2026-03-24', 404.100000, 'Bloomberg')
ON CONFLICT (instruments_id) DO NOTHING;

SELECT * FROM market_prices ORDER BY instruments_id;

--custodian trades

INSERT INTO custodian_trades (
    trade_ref,
    portfolio_code,
    instrument_code,
    trade_type,
    quantity,
    price,
    trade_date,
    settlement_date,
    custodian_name
)
VALUES
('TRD001', 'PF001', 'UST10Y', 'BUY', 1000000, 99.250000, '2026-03-20', '2026-03-24', 'State Street'),
('TRD002', 'PF001', 'CORP_BND_1', 'BUY', 500000, 101.100000, '2026-03-20', '2026-03-24', 'State Street'),
('TRD003', 'PF002', 'AAPL', 'BUY', 900, 185.500000, '2026-03-21', '2026-03-25', 'State Street'),
('TRD004', 'PF002', 'MSFT', 'BUY', 800, 402.250000, '2026-03-21', '2026-03-25', 'State Street')

ON CONFLICT (trade_ref) DO NOTHING;

SELECT * FROM custodian_trades ORDER BY trade_ref;








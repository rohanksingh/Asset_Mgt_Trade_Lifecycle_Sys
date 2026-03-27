CREATE OR REPLACE DATABASE asset_mgmt_demo;

\c asset_mgmt_demo


CREATE INDEX IF NOT EXISTS idx_trades_trade_date ON trades(trade_date);
CREATE INDEX IF NOT EXISTS idx_trades_portfolio_id ON trades(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_trades_instrument_id ON trades(instrument_id);
CREATE INDEX IF NOT EXISTS idx_market_prices_price_date ON market_prices(price_date);
CREATE INDEX IF NOT EXISTS idx_custodian_trades_trade_ref ON custodian_trades(trade_ref);
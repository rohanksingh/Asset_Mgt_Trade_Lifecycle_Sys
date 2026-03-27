import pandas as pd
from sqlalchemy import create_engine, text

DB_USER = "postgres"
DB_PASSWORD = "your_password"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "asset_mgmt_demo"

# engine = create_engine(
#     f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
# )

engine = create_engine("postgresql+psycopg2://postgres:sUmitra%4012@localhost:5432/asset_mgmt_demo")


trades_file = r"C:\Users\rohan\asset_management_trade_lifecyclesys\data\trades.csv"
prices_file = r"C:\Users\rohan\asset_management_trade_lifecyclesys\data\market_prices.csv"
custodian_file = r"C:\Users\rohan\asset_management_trade_lifecyclesys\data\custodian_trades_input.csv"


def load_csv_to_staging():
    trades_df = pd.read_csv(trades_file)
    prices_df = pd.read_csv(prices_file)
    custodian_df = pd.read_csv(custodian_file)

    trades_df.to_sql("stg_trades", engine, if_exists="append", index=False)
    prices_df.to_sql("stg_market_prices", engine, if_exists="append", index=False)
    custodian_df.to_sql("stg_custodian_trades", engine, if_exists="append", index=False)

    print("CSV files loaded into staging tables.")


def validate_and_publish_trades():
    df = pd.read_sql("SELECT * FROM stg_trades", engine)

    portfolio_df = pd.read_sql("SELECT portfolio_code FROM portfolios", engine)
    instrument_df = pd.read_sql("SELECT instrument_code FROM instruments", engine)
    existing_trade_df = pd.read_sql("SELECT trade_ref FROM trades", engine)

    valid_portfolios = set(portfolio_df["portfolio_code"])
    valid_instruments = set(instrument_df["instrument_code"])
    existing_trade_refs = set(existing_trade_df["trade_ref"])

    errors = []
    valid_rows = []

    seen = set()

    for _, row in df.iterrows():
        reason = None

        if pd.isna(row["trade_ref"]) or pd.isna(row["portfolio_code"]) or pd.isna(row["instrument_code"]):
            reason = "NULL_KEY_FIELD"
        elif row["portfolio_code"] not in valid_portfolios:
            reason = "INVALID_PORTFOLIO"
        elif row["instrument_code"] not in valid_instruments:
            reason = "INVALID_INSTRUMENT"
        elif row["trade_type"] not in ("BUY", "SELL"):
            reason = "INVALID_TRADE_TYPE"
        elif pd.isna(row["quantity"]) or pd.isna(row["price"]):
            reason = "NULL_QUANTITY_OR_PRICE"
        elif row["trade_status"] not in ("NEW", "EXECUTED", "SETTLED", "FAILED", "CANCELLED"):
            reason = "INVALID_TRADE_STATUS"
        elif str(row["trade_ref"]) in existing_trade_refs or str(row["trade_ref"]) in seen:
            reason = "DUPLICATE_TRADE_REF"
        elif pd.to_datetime(row["settlement_date"]) < pd.to_datetime(row["trade_date"]):
            reason = "INVALID_SETTLEMENT_DATE"
        else:
            seen.add(str(row["trade_ref"]))

        if reason:
            row_dict = row.to_dict()
            row_dict["error_reason"] = reason
            errors.append(row_dict)
        else:
            valid_rows.append(row.to_dict())

    if errors:
        error_df = pd.DataFrame(errors)
        print("\nTrade validation errors:")
        print(error_df[["trade_ref", "portfolio_code", "instrument_code", "error_reason"]])
        error_df.to_sql("trade_exceptions", engine, if_exists="append", index=False)

    if valid_rows:
        valid_df = pd.DataFrame(valid_rows)

        portfolio_map = pd.read_sql("SELECT portfolio_id, portfolio_code FROM portfolios", engine)
        instrument_map = pd.read_sql("SELECT instruments_id, instrument_code FROM instruments", engine)

        valid_df = valid_df.merge(portfolio_map, on="portfolio_code", how="left")
        valid_df = valid_df.merge(instrument_map, on="instrument_code", how="left")

        final_df = valid_df[
            [
                "trade_ref", "portfolio_id", "instruments_id", "trade_type", "quantity",
                "price", "trade_date", "settlement_date", "counterparty",
                "trade_status", "source_system"
            ]
        ]

        final_df.to_sql("trades", engine, if_exists="append", index=False)

    print(f"Valid trades loaded: {len(valid_rows)}")
    print(f"Trade exceptions logged: {len(errors)}")


def validate_and_publish_market_prices():
    df = pd.read_sql("SELECT * FROM stg_market_prices", engine)
    instrument_df = pd.read_sql(
        "SELECT instruments_id, instrument_code FROM instruments", engine
    )
    existing_prices_df = pd.read_sql(
        "SELECT instruments_id, price_date FROM market_prices", engine
    )

    valid_instruments = set(instrument_df["instrument_code"])

    # Build existing key set using instrument_code after merge
    instrument_lookup = instrument_df.copy()
    existing_prices_df["price_date"] = pd.to_datetime(existing_prices_df["price_date"]).dt.date

    existing_keys = set()
    if not existing_prices_df.empty:
        merged_existing = existing_prices_df.merge(
            instrument_lookup, on="instruments_id", how="left"
        )
        existing_keys = set(
            zip(
                merged_existing["instrument_code"],
                merged_existing["price_date"].astype(str)
            )
        )

    errors = []
    valid_rows = []
    seen = set()

    for _, row in df.iterrows():
        reason = None

        price_date = pd.to_datetime(row["price_date"], errors="coerce")

        # Step 1: Null check FIRST (and STOP further checks)
        if pd.isna(row["instrument_code"]) or pd.isna(price_date) or pd.isna(row["market_price"]):
            reason = "NULL_REQUIRED_FIELD"

        # Step 2: Only proceed if no error yet
        elif row["instrument_code"] not in valid_instruments:
            reason = "INVALID_INSTRUMENT"

        else:
            key = (row["instrument_code"], str(price_date.date()))

            if key in seen:
                reason = "DUPLICATE_PRICE_RECORD_IN_FILE"
            elif key in existing_keys:
                reason = "DUPLICATE_PRICE_RECORD_IN_TARGET"
            else:
                seen.add(key)

        # Save results
        if reason:
            row_dict = row.to_dict()
            row_dict["error_reason"] = reason
            errors.append(row_dict)
        else:
            valid_rows.append(row.to_dict())
        
    if errors:
        pd.DataFrame(errors).to_sql(
            "market_price_exceptions", engine, if_exists="append", index=False
        )

    if valid_rows:
        valid_df = pd.DataFrame(valid_rows)
        valid_df = valid_df.merge(instrument_df, on="instrument_code", how="left")

        final_df = valid_df[
            ["instruments_id", "price_date", "market_price", "price_source"]
        ]

        final_df.to_sql("market_prices", engine, if_exists="append", index=False)

    print(f"Valid prices loaded: {len(valid_rows)}")
    print(f"Price exceptions logged: {len(errors)}")


def validate_and_publish_custodian_trades():
    df = pd.read_sql("SELECT * FROM stg_custodian_trades", engine)

    errors = []
    valid_rows = []

    seen = set()

    for _, row in df.iterrows():
        reason = None
        key = str(row["trade_ref"])

        if pd.isna(row["trade_ref"]) or pd.isna(row["portfolio_code"]) or pd.isna(row["instrument_code"]):
            reason = "NULL_KEY_FIELD"
        elif key in seen:
            reason = "DUPLICATE_CUSTODIAN_TRADE"
        else:
            seen.add(key)

        if reason:
            row_dict = row.to_dict()
            row_dict["error_reason"] = reason
            errors.append(row_dict)
        else:
            valid_rows.append(row.to_dict())

    if errors:
        pd.DataFrame(errors).to_sql("custodian_trade_exceptions", engine, if_exists="append", index=False)

    if valid_rows:
        valid_df = pd.DataFrame(valid_rows)
        final_df = valid_df[
            [
                "trade_ref", "portfolio_code", "instrument_code", "trade_type",
                "quantity", "price", "trade_date", "settlement_date", "custodian_name"
            ]
        ]
        final_df.to_sql("custodian_trades", engine, if_exists="append", index=False)

    print(f"Valid custodian trades loaded: {len(valid_rows)}")
    print(f"Custodian exceptions logged: {len(errors)}")


def truncate_staging():
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE stg_trades"))
        conn.execute(text("TRUNCATE TABLE stg_market_prices"))
        conn.execute(text("TRUNCATE TABLE stg_custodian_trades"))
        conn.execute(text("TRUNCATE TABLE trade_exceptions"))
        conn.execute(text("TRUNCATE TABLE market_price_exceptions"))
        conn.execute(text("TRUNCATE TABLE custodian_trade_exceptions"))
    print("Staging and exception tables truncated.")


if __name__ == "__main__":
    truncate_staging()
    load_csv_to_staging()
    validate_and_publish_trades()
    validate_and_publish_market_prices()
    validate_and_publish_custodian_trades()
    print("Phase 4 ETL completed.")
## Asset Management Trade Lifecycle System
### Project Overview
### This project simulates an end-to-end asset management data platform, covering:
```
•	Trade lifecycle processing 
•	Portfolio valuation 
•	Reconciliation with custodian data 
•	Settlement monitoring 
•	Data quality validation 
•	Power BI dashboard reporting 
```
#### Business Context
#### In asset management firms, trades flow across multiple systems:
```
•	Front Office (Order & Execution) 
•	Middle Office (Risk & Compliance) 
•	Back Office (Settlement & Accounting) 
```
#### This project replicates that architecture using SQL, Python, and Power BI Architecture
``` 
CSV → Staging Tables → Validation → Core Tables → Views → Power BI Dashboard
```
#### Tech Stack
```
•	PostgreSQL (Database) 
•	Python (ETL & Validation) 
•	SQL (Data Modeling & Reporting) 
•	Power BI (Dashboard) 
•	Pandas, SQLAlchemy
```

#### Project Components
```
 Phase 1: Data Model
 •	Portfolio, Instrument, Trade, Market Data tables 
 Phase 2: Sample Data
 •	Realistic trade, price, and custodian data 
 Phase 3: Reporting & Reconciliation
 •	Portfolio valuation views 
 •	Trade reconciliation logic 
 •	Settlement monitoring 
 Phase 4: ETL & Data Quality
 •	CSV ingestion 
 •	Validation rules 
 •	Exception handling 
```
### Key Features
#### Portfolio Valuation
```
•	Calculates holdings and market value using latest prices 
Trade Reconciliation
•	Identifies mismatches between internal and custodian records 
Settlement Monitoring
•	Detects failed and overdue settlements 
Data Quality Framework
•	Handles invalid, duplicate, and missing data 
Power BI Dashboard
•	Portfolio overview 
•	Trade breaks 
•	Settlement status 
•	Data quality issues 
```
### Dashboard Preview

<img width="1240" height="683" alt="image" src="https://github.com/user-attachments/assets/f754c848-71d7-4efe-bc29-e4953b821663" />

<img width="617" height="756" alt="image" src="https://github.com/user-attachments/assets/cff6a5bb-30bf-4b20-83a9-ba147f4ed45d" />


### How to Run
```
1. Create database
CREATE DATABASE asset_mgmt_demo;
2. Run SQL scripts
psql -d asset_mgmt_demo -f sql/schema.sql
psql -d asset_mgmt_demo -f sql/phase2_data.sql
psql -d asset_mgmt_demo -f sql/views_phase3.sql
3. Run ETL
python etl/etl_phase4.py
4. Open Power BI
•	Connect to PostgreSQL 
•	Load views 
•	Build dashboard
```

## Architecture Diagram

<img width="1377" height="856" alt="image" src="https://github.com/user-attachments/assets/50df5a33-0368-4635-9830-0f33dc27ad87" />


[View Editable Version](https://app.diagrams.net/?url=https://raw.githubusercontent.com/rohanksingh/Asset_Mgt_Trade_Lifecycle_Sys/main/docs/Asst_mgt_lifecyl_sys.drawio)

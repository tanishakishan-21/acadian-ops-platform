-- ============================================================
-- ACADIAN ASSET MANAGEMENT
-- Investment Operations Intelligence Platform
-- Database: Positions & Transactions Data Quality System
-- Author: Tanisha Kishan
-- ============================================================

-- ============================================================
-- STEP 1: CREATE DATABASE TABLES
-- ============================================================

-- Drop tables if they exist (for clean re-runs)
DROP TABLE IF EXISTS data_quality_log;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS securities;
DROP TABLE IF EXISTS portfolios;

-- Portfolios Table
CREATE TABLE portfolios (
    portfolio_id      VARCHAR(10) PRIMARY KEY,
    portfolio_name    VARCHAR(100) NOT NULL,
    strategy          VARCHAR(50) NOT NULL,  -- e.g. Global Equity, Low Volatility, ESG
    base_currency     VARCHAR(3) NOT NULL,
    inception_date    DATE NOT NULL,
    aum_usd           DECIMAL(18,2)
);

-- Securities Master Table
CREATE TABLE securities (
    security_id       VARCHAR(15) PRIMARY KEY,
    ticker            VARCHAR(10),
    security_name     VARCHAR(100) NOT NULL,
    asset_class       VARCHAR(30) NOT NULL,  -- Equity, Fixed Income, Derivatives, Cash
    sector            VARCHAR(50),
    country           VARCHAR(50),
    currency          VARCHAR(3),
    exchange          VARCHAR(20)
);

-- Positions Table (daily snapshot of holdings)
CREATE TABLE positions (
    position_id       SERIAL PRIMARY KEY,
    portfolio_id      VARCHAR(10) REFERENCES portfolios(portfolio_id),
    security_id       VARCHAR(15) REFERENCES securities(security_id),
    position_date     DATE NOT NULL,
    quantity          DECIMAL(18,4) NOT NULL,
    market_price      DECIMAL(18,6),
    market_value_usd  DECIMAL(18,2),
    cost_basis_usd    DECIMAL(18,2),
    unrealized_pnl    DECIMAL(18,2),
    weight_pct        DECIMAL(8,4),  -- % of portfolio
    data_source       VARCHAR(30),   -- e.g. Custodian, Bloomberg, Internal
    is_verified       BOOLEAN DEFAULT FALSE,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transactions Table (all buy/sell/corporate actions)
CREATE TABLE transactions (
    transaction_id    VARCHAR(20) PRIMARY KEY,
    portfolio_id      VARCHAR(10) REFERENCES portfolios(portfolio_id),
    security_id       VARCHAR(15) REFERENCES securities(security_id),
    transaction_type  VARCHAR(20) NOT NULL,  -- BUY, SELL, DIVIDEND, SPLIT, TRANSFER
    trade_date        DATE NOT NULL,
    settlement_date   DATE,
    quantity          DECIMAL(18,4),
    price             DECIMAL(18,6),
    gross_amount_usd  DECIMAL(18,2),
    net_amount_usd    DECIMAL(18,2),
    commission_usd    DECIMAL(10,2),
    settlement_status VARCHAR(20) DEFAULT 'PENDING',  -- PENDING, SETTLED, FAILED, CANCELLED
    broker            VARCHAR(50),
    trader_id         VARCHAR(10),
    notes             TEXT,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Data Quality Log Table
CREATE TABLE data_quality_log (
    log_id            SERIAL PRIMARY KEY,
    issue_date        DATE NOT NULL,
    issue_type        VARCHAR(50) NOT NULL,   -- MISSING_PRICE, DUPLICATE, RECONCILIATION_BREAK, SETTLEMENT_FAIL, STALE_DATA
    severity          VARCHAR(10) NOT NULL,   -- HIGH, MEDIUM, LOW
    affected_table    VARCHAR(30),
    affected_records  INT DEFAULT 0,
    portfolio_id      VARCHAR(10),
    security_id       VARCHAR(15),
    description       TEXT,
    resolution_status VARCHAR(20) DEFAULT 'OPEN',  -- OPEN, IN_PROGRESS, RESOLVED
    assigned_to       VARCHAR(50),
    resolved_date     DATE,
    resolution_notes  TEXT,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- STEP 2: INSERT SAMPLE DATA
-- ============================================================

-- Portfolios
INSERT INTO portfolios VALUES
('PORT001', 'Acadian Global Equity Fund',       'Global Equity',     'USD', '2010-01-01', 4500000000.00),
('PORT002', 'Acadian Low Volatility Strategy',  'Low Volatility',    'USD', '2012-06-01', 2200000000.00),
('PORT003', 'Acadian ESG Equity Fund',           'ESG',               'USD', '2018-03-01', 1800000000.00),
('PORT004', 'Acadian Emerging Markets Fund',     'Emerging Markets',  'USD', '2015-09-01', 3100000000.00),
('PORT005', 'Acadian Multi-Asset Strategy',      'Multi-Asset',       'USD', '2016-01-01', 2750000000.00);

-- Securities
INSERT INTO securities VALUES
('SEC001',  'AAPL',  'Apple Inc.',                    'Equity',        'Technology',       'United States', 'USD', 'NASDAQ'),
('SEC002',  'MSFT',  'Microsoft Corporation',         'Equity',        'Technology',       'United States', 'USD', 'NASDAQ'),
('SEC003',  'AMZN',  'Amazon.com Inc.',               'Equity',        'Consumer Disc',    'United States', 'USD', 'NASDAQ'),
('SEC004',  'GOOGL', 'Alphabet Inc.',                 'Equity',        'Technology',       'United States', 'USD', 'NASDAQ'),
('SEC005',  'JPM',   'JPMorgan Chase & Co.',          'Equity',        'Financials',       'United States', 'USD', 'NYSE'),
('SEC006',  'NVDA',  'NVIDIA Corporation',            'Equity',        'Technology',       'United States', 'USD', 'NASDAQ'),
('SEC007',  'TSM',   'Taiwan Semiconductor Mfg.',     'Equity',        'Technology',       'Taiwan',        'USD', 'NYSE'),
('SEC008',  'ASML',  'ASML Holding NV',               'Equity',        'Technology',       'Netherlands',   'EUR', 'NASDAQ'),
('SEC009',  'SAP',   'SAP SE',                        'Equity',        'Technology',       'Germany',       'EUR', 'NYSE'),
('SEC010',  'TCS',   'Tata Consultancy Services',     'Equity',        'Technology',       'India',         'INR', 'BSE'),
('SEC011',  'VOD',   'Vodafone Group PLC',            'Equity',        'Communication',    'United Kingdom','GBP', 'NASDAQ'),
('SEC012',  'BABA',  'Alibaba Group Holdings',        'Equity',        'Consumer Disc',    'China',         'USD', 'NYSE'),
('SEC013',  'US10Y', 'US Treasury 10Y Bond',          'Fixed Income',  'Government Bond',  'United States', 'USD', 'OTC'),
('SEC014',  'EURUSD','EUR/USD FX Forward',            'Derivatives',   'FX Derivative',    'Global',        'USD', 'OTC'),
('SEC015',  'CASH',  'USD Cash & Equivalents',        'Cash',          'Cash',             'United States', 'USD', 'N/A');

-- Positions (2 weeks of data across portfolios)
INSERT INTO positions (portfolio_id, security_id, position_date, quantity, market_price, market_value_usd, cost_basis_usd, unrealized_pnl, weight_pct, data_source, is_verified) VALUES
-- PORT001 - Global Equity
('PORT001', 'SEC001', '2026-02-10', 150000, 227.52, 34128000.00, 30000000.00,  4128000.00, 0.7584, 'Bloomberg', TRUE),
('PORT001', 'SEC002', '2026-02-10', 200000, 415.33, 83066000.00, 75000000.00,  8066000.00, 1.8459, 'Bloomberg', TRUE),
('PORT001', 'SEC003', '2026-02-10', 80000,  226.87, 18149600.00, 17000000.00,  1149600.00, 0.4033, 'Bloomberg', TRUE),
('PORT001', 'SEC006', '2026-02-10', 120000, 875.40, 105048000.00,90000000.00, 15048000.00, 2.3344, 'Bloomberg', TRUE),
('PORT001', 'SEC007', '2026-02-10', 300000, 182.15, 54645000.00, 50000000.00,  4645000.00, 1.2143, 'Bloomberg', TRUE),
('PORT001', 'SEC008', '2026-02-10', 50000,  680.22, 34011000.00, 32000000.00,  2011000.00, 0.7558, 'Bloomberg', TRUE),
('PORT001', 'SEC013', '2026-02-10', 1000000, 96.50, 96500000.00, 98000000.00, -1500000.00, 2.1444, 'Custodian',TRUE),
('PORT001', 'SEC015', '2026-02-10', 5000000,  1.00, 5000000.00,  5000000.00,         0.00, 0.1111, 'Internal', TRUE),
-- PORT002 - Low Volatility
('PORT002', 'SEC001', '2026-02-10', 90000,  227.52, 20476800.00, 19000000.00,  1476800.00, 0.9308, 'Bloomberg', TRUE),
('PORT002', 'SEC005', '2026-02-10', 180000, 248.75, 44775000.00, 40000000.00,  4775000.00, 2.0352, 'Bloomberg', TRUE),
('PORT002', 'SEC013', '2026-02-10', 2000000, 96.50,193000000.00,195000000.00, -2000000.00, 8.7727, 'Custodian',TRUE),
('PORT002', 'SEC015', '2026-02-10', 8000000,  1.00, 8000000.00,  8000000.00,         0.00, 0.3636, 'Internal', TRUE),
-- PORT003 - ESG
('PORT003', 'SEC002', '2026-02-10', 100000, 415.33, 41533000.00, 38000000.00,  3533000.00, 2.3074, 'Bloomberg', TRUE),
('PORT003', 'SEC008', '2026-02-10', 75000,  680.22, 51016500.00, 48000000.00,  3016500.00, 2.8342, 'Bloomberg', TRUE),
('PORT003', 'SEC009', '2026-02-10', 200000, 205.44, 41088000.00, 40000000.00,  1088000.00, 2.2827, 'Bloomberg', TRUE),
('PORT003', 'SEC015', '2026-02-10', 3000000,  1.00, 3000000.00,  3000000.00,         0.00, 0.1667, 'Internal', TRUE),
-- PORT004 - Emerging Markets
('PORT004', 'SEC007', '2026-02-10', 500000, 182.15, 91075000.00, 85000000.00,  6075000.00, 2.9379, 'Bloomberg', TRUE),
('PORT004', 'SEC010', '2026-02-10', 400000, 45.33,  18132000.00, 17000000.00,  1132000.00, 0.5849, 'Bloomberg', TRUE),
('PORT004', 'SEC012', '2026-02-10', 600000, 88.42,  53052000.00, 55000000.00, -1948000.00, 1.7114, 'Bloomberg', FALSE),  -- NOT VERIFIED
-- PORT004 with missing price (data quality issue)
('PORT004', 'SEC011', '2026-02-10', 1000000, NULL,   NULL,        9000000.00,        NULL, NULL,   'Bloomberg', FALSE),  -- MISSING PRICE
-- PORT005 - Multi-Asset
('PORT005', 'SEC001', '2026-02-10', 60000,  227.52, 13651200.00, 12500000.00,  1151200.00, 0.4964, 'Bloomberg', TRUE),
('PORT005', 'SEC006', '2026-02-10', 40000,  875.40, 35016000.00, 32000000.00,  3016000.00, 1.2733, 'Bloomberg', TRUE),
('PORT005', 'SEC013', '2026-02-10', 500000,  96.50, 48250000.00, 49000000.00,  -750000.00, 1.7545, 'Custodian',TRUE),
('PORT005', 'SEC014', '2026-02-10', 2000000, 1.085,  2170000.00, 2000000.00,    170000.00, 0.0789, 'Internal', TRUE),
('PORT005', 'SEC015', '2026-02-10', 10000000, 1.00,10000000.00, 10000000.00,         0.00, 0.3636, 'Internal', TRUE),

-- NEXT DAY positions (with some discrepancies for quality checks)
('PORT001', 'SEC001', '2026-02-11', 150000, 229.10, 34365000.00, 30000000.00,  4365000.00, 0.7632, 'Bloomberg', TRUE),
('PORT001', 'SEC002', '2026-02-11', 200000, 418.90, 83780000.00, 75000000.00,  8780000.00, 1.8618, 'Bloomberg', TRUE),
('PORT001', 'SEC006', '2026-02-11', 120000, 891.20,106944000.00, 90000000.00, 16944000.00, 2.3765, 'Bloomberg', TRUE),
('PORT002', 'SEC001', '2026-02-11', 90000,  229.10, 20619000.00, 19000000.00,  1619000.00, 0.9372, 'Bloomberg', TRUE),
('PORT004', 'SEC012', '2026-02-11', 600000, 87.15,  52290000.00, 55000000.00, -2710000.00, 1.6868, 'Bloomberg', FALSE);

-- Transactions
INSERT INTO transactions VALUES
('TXN-2026-0001', 'PORT001', 'SEC006', 'BUY',      '2026-02-03', '2026-02-05', 20000,  850.00, 17000000.00, 16983000.00, 17000.00, 'SETTLED',  'Goldman Sachs', 'TR001', 'Initial position build', NOW()),
('TXN-2026-0002', 'PORT001', 'SEC007', 'BUY',      '2026-02-03', '2026-02-05', 300000, 178.50, 53550000.00, 53496750.00, 53250.00, 'SETTLED',  'Morgan Stanley','TR001', NULL, NOW()),
('TXN-2026-0003', 'PORT002', 'SEC005', 'BUY',      '2026-02-04', '2026-02-06', 50000,  245.00, 12250000.00, 12237750.00, 12250.00, 'SETTLED',  'JPMorgan',      'TR002', NULL, NOW()),
('TXN-2026-0004', 'PORT003', 'SEC009', 'BUY',      '2026-02-05', '2026-02-07', 200000, 202.00, 40400000.00, 40359600.00, 40400.00, 'SETTLED',  'Deutsche Bank', 'TR003', 'ESG screened', NOW()),
('TXN-2026-0005', 'PORT004', 'SEC010', 'BUY',      '2026-02-05', '2026-02-07', 400000, 44.80,  17920000.00, 17901920.00, 18080.00, 'SETTLED',  'Citi',          'TR004', NULL, NOW()),
('TXN-2026-0006', 'PORT001', 'SEC003', 'SELL',     '2026-02-06', '2026-02-10', 20000,  224.50, 4490000.00,  4485510.00,  4490.00,  'SETTLED',  'Goldman Sachs', 'TR001', 'Rebalancing', NOW()),
('TXN-2026-0007', 'PORT005', 'SEC001', 'BUY',      '2026-02-07', '2026-02-11', 60000,  221.00, 13260000.00, 13246740.00, 13260.00, 'SETTLED',  'Morgan Stanley','TR005', NULL, NOW()),
('TXN-2026-0008', 'PORT002', 'SEC013', 'BUY',      '2026-02-10', '2026-02-12', 500000, 96.25,  48125000.00, 48076875.00, 48125.00, 'PENDING',  'JPMorgan',      'TR002', 'Bond purchase', NOW()),
('TXN-2026-0009', 'PORT004', 'SEC011', 'BUY',      '2026-02-10', '2026-02-12', 1000000,8.95,   8950000.00,  8941075.00,  8950.00,  'FAILED',   'Barclays',      'TR004', 'Settlement failed - broker error', NOW()),
('TXN-2026-0010', 'PORT003', 'SEC002', 'DIVIDEND', '2026-02-11', '2026-02-11', 100000, 0.88,    88000.00,    88000.00,       0.00, 'SETTLED',  NULL,            NULL,    'Q1 dividend', NOW()),
('TXN-2026-0011', 'PORT001', 'SEC001', 'BUY',      '2026-02-12', '2026-02-14', 10000,  226.00, 2260000.00,  2257740.00,  2260.00,  'PENDING',  'Goldman Sachs', 'TR001', NULL, NOW()),
('TXN-2026-0012', 'PORT001', 'SEC001', 'BUY',      '2026-02-12', '2026-02-14', 10000,  226.00, 2260000.00,  2257740.00,  2260.00,  'PENDING',  'Goldman Sachs', 'TR001', NULL, NOW()),  -- DUPLICATE
('TXN-2026-0013', 'PORT005', 'SEC006', 'BUY',      '2026-02-12', '2026-02-14', 40000,  870.00, 34800000.00, 34765200.00, 34800.00, 'PENDING',  'Morgan Stanley','TR005', NULL, NOW()),
('TXN-2026-0014', 'PORT002', 'SEC001', 'SELL',     '2026-02-13', '2026-02-17', 10000,  229.00, 2290000.00,  2287710.00,  2290.00,  'PENDING',  'JPMorgan',      'TR002', 'Trim position', NOW()),
('TXN-2026-0015', 'PORT004', 'SEC012', 'SELL',     '2026-02-13', '2026-02-17', 100000, 87.50,  8750000.00,  8741250.00,  8750.00,  'PENDING',  'Citi',          'TR004', 'Reduce EM exposure', NOW());

-- Data Quality Issues Log
INSERT INTO data_quality_log (issue_date, issue_type, severity, affected_table, affected_records, portfolio_id, security_id, description, resolution_status, assigned_to, resolved_date, resolution_notes) VALUES
('2026-02-10', 'MISSING_PRICE',         'HIGH',   'positions',    1, 'PORT004', 'SEC011', 'Market price missing for Vodafone position in Emerging Markets fund. Bloomberg feed interrupted.',                         'IN_PROGRESS', 'Data Team',  NULL,         NULL),
('2026-02-10', 'UNVERIFIED_POSITION',   'MEDIUM', 'positions',    2, 'PORT004', 'SEC012', 'Alibaba position unverified across 2 dates. Awaiting custodian confirmation.',                                            'OPEN',        'Ops Team',   NULL,         NULL),
('2026-02-12', 'DUPLICATE_TRANSACTION', 'HIGH',   'transactions', 2, 'PORT001', 'SEC001', 'Duplicate buy order detected for AAPL (TXN-2026-0011 and TXN-2026-0012). Same broker, quantity, price, and date.',       'IN_PROGRESS', 'Trade Team', NULL,         NULL),
('2026-02-10', 'SETTLEMENT_FAILURE',    'HIGH',   'transactions', 1, 'PORT004', 'SEC011', 'Vodafone trade (TXN-2026-0009) failed settlement. Broker error at Barclays. Re-submission required.',                    'IN_PROGRESS', 'Trade Team', NULL,         NULL),
('2026-02-08', 'STALE_DATA',            'LOW',    'positions',    3, 'PORT003', NULL,     'ESG fund prices not updated for 3 securities over weekend. Resolved on Monday open.',                                    'RESOLVED',    'Data Team',  '2026-02-10', 'Prices refreshed from Bloomberg on market open'),
('2026-02-07', 'RECONCILIATION_BREAK',  'HIGH',   'positions',    1, 'PORT002', 'SEC013', 'Position quantity mismatch between internal system and custodian for US Treasury. Custodian shows 1.95M units vs 2M.',   'RESOLVED',    'Ops Team',   '2026-02-09', 'Custodian confirmed corporate action adjustment. Records updated.'),
('2026-02-11', 'MISSING_PRICE',         'MEDIUM', 'positions',    1, 'PORT005', 'SEC014', 'FX Forward mark-to-market price delayed by 2 hours due to OTC pricing feed issue.',                                      'RESOLVED',    'Data Team',  '2026-02-11', 'Price obtained from alternate vendor feed'),
('2026-02-12', 'UNVERIFIED_POSITION',   'MEDIUM', 'positions',    1, 'PORT004', 'SEC012', 'Second day Alibaba position still pending custodian verification.',                                                       'OPEN',        'Ops Team',   NULL,         NULL),
('2026-02-13', 'RECONCILIATION_BREAK',  'HIGH',   'positions',    2, 'PORT001', NULL,     'End of day position reconciliation break for 2 securities in Global Equity fund. Investigation in progress.',            'OPEN',        'Ops Team',   NULL,         NULL),
('2026-02-06', 'STALE_DATA',            'LOW',    'positions',    1, 'PORT004', 'SEC010', 'TCS price stale due to BSE trading halt. Resolved same day.',                                                             'RESOLVED',    'Data Team',  '2026-02-06', 'Updated after trading resumed');

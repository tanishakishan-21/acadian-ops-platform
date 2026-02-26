-- ============================================================
-- ACADIAN ASSET MANAGEMENT
-- Investment Operations Intelligence Platform
-- Query File: Business Analysis & Dashboard Queries
-- Author: Tanisha Kishan
-- ============================================================


-- ============================================================
-- QUERY 1: PORTFOLIO HEALTH SUMMARY (Dashboard Panel 1)
-- Shows AUM, positions count, verified %, unrealized P&L per portfolio
-- ============================================================

SELECT
    p.portfolio_id,
    p.portfolio_name,
    p.strategy,
    p.aum_usd,
    COUNT(pos.position_id)                                        AS total_positions,
    SUM(pos.market_value_usd)                                     AS total_market_value,
    SUM(CASE WHEN pos.is_verified = TRUE THEN 1 ELSE 0 END)       AS verified_positions,
    ROUND(
        SUM(CASE WHEN pos.is_verified = TRUE THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(pos.position_id), 0), 2
    )                                                             AS verification_pct,
    SUM(pos.unrealized_pnl)                                       AS total_unrealized_pnl,
    COUNT(CASE WHEN pos.market_price IS NULL THEN 1 END)          AS missing_prices
FROM portfolios p
LEFT JOIN positions pos
    ON p.portfolio_id = pos.portfolio_id
    AND pos.position_date = '2026-02-11'
GROUP BY p.portfolio_id, p.portfolio_name, p.strategy, p.aum_usd
ORDER BY p.aum_usd DESC;


-- ============================================================
-- QUERY 2: ASSET CLASS EXPOSURE BY PORTFOLIO (Dashboard Panel 1)
-- Shows how each portfolio is distributed across asset classes
-- ============================================================

SELECT
    pos.portfolio_id,
    pf.portfolio_name,
    sec.asset_class,
    COUNT(pos.position_id)      AS num_positions,
    SUM(pos.market_value_usd)   AS market_value,
    ROUND(SUM(pos.weight_pct), 4) AS total_weight_pct
FROM positions pos
JOIN securities sec  ON pos.security_id  = sec.security_id
JOIN portfolios pf   ON pos.portfolio_id = pf.portfolio_id
WHERE pos.position_date = '2026-02-11'
  AND pos.market_value_usd IS NOT NULL
GROUP BY pos.portfolio_id, pf.portfolio_name, sec.asset_class
ORDER BY pos.portfolio_id, market_value DESC;


-- ============================================================
-- QUERY 3: TOP 10 HOLDINGS ACROSS ALL PORTFOLIOS (Dashboard Panel 1)
-- ============================================================

SELECT
    sec.ticker,
    sec.security_name,
    sec.sector,
    sec.country,
    SUM(pos.market_value_usd)   AS total_exposure_usd,
    COUNT(DISTINCT pos.portfolio_id) AS num_portfolios,
    SUM(pos.unrealized_pnl)     AS total_unrealized_pnl
FROM positions pos
JOIN securities sec ON pos.security_id = sec.security_id
WHERE pos.position_date = '2026-02-11'
  AND pos.market_value_usd IS NOT NULL
GROUP BY sec.ticker, sec.security_name, sec.sector, sec.country
ORDER BY total_exposure_usd DESC
LIMIT 10;


-- ============================================================
-- QUERY 4: DAILY TRANSACTION VOLUME MONITOR (Dashboard Panel 2)
-- Shows transaction activity by day, type, and status
-- ============================================================

SELECT
    trade_date,
    transaction_type,
    settlement_status,
    COUNT(transaction_id)           AS num_transactions,
    SUM(gross_amount_usd)           AS total_gross_usd,
    SUM(commission_usd)             AS total_commission
FROM transactions
GROUP BY trade_date, transaction_type, settlement_status
ORDER BY trade_date DESC, num_transactions DESC;


-- ============================================================
-- QUERY 5: SETTLEMENT STATUS TRACKER (Dashboard Panel 2)
-- Flags pending and failed settlements needing attention
-- ============================================================

SELECT
    t.transaction_id,
    t.portfolio_id,
    pf.portfolio_name,
    sec.ticker,
    sec.security_name,
    t.transaction_type,
    t.trade_date,
    t.settlement_date,
    CURRENT_DATE - t.settlement_date   AS days_overdue,
    t.gross_amount_usd,
    t.settlement_status,
    t.broker,
    t.notes
FROM transactions t
JOIN portfolios pf  ON t.portfolio_id = pf.portfolio_id
JOIN securities sec ON t.security_id  = sec.security_id
WHERE t.settlement_status IN ('PENDING', 'FAILED')
ORDER BY t.settlement_status DESC, days_overdue DESC;


-- ============================================================
-- QUERY 6: DUPLICATE TRANSACTION DETECTION (Dashboard Panel 2)
-- Critical data quality check - finds potential duplicate trades
-- ============================================================

SELECT
    t1.portfolio_id,
    t1.security_id,
    sec.ticker,
    t1.transaction_type,
    t1.trade_date,
    t1.quantity,
    t1.price,
    t1.broker,
    COUNT(*) AS duplicate_count,
    STRING_AGG(t1.transaction_id, ', ') AS transaction_ids
FROM transactions t1
JOIN securities sec ON t1.security_id = sec.security_id
GROUP BY
    t1.portfolio_id,
    t1.security_id,
    sec.ticker,
    t1.transaction_type,
    t1.trade_date,
    t1.quantity,
    t1.price,
    t1.broker
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- QUERY 7: DATA QUALITY KPI SUMMARY (Dashboard Panel 3)
-- High-level quality scorecard for management reporting
-- ============================================================

SELECT
    issue_type,
    severity,
    COUNT(*)                                                            AS total_issues,
    SUM(affected_records)                                               AS total_affected_records,
    COUNT(CASE WHEN resolution_status = 'OPEN' THEN 1 END)             AS open_issues,
    COUNT(CASE WHEN resolution_status = 'IN_PROGRESS' THEN 1 END)      AS in_progress_issues,
    COUNT(CASE WHEN resolution_status = 'RESOLVED' THEN 1 END)         AS resolved_issues,
    ROUND(
        COUNT(CASE WHEN resolution_status = 'RESOLVED' THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0), 1
    )                                                                   AS resolution_rate_pct
FROM data_quality_log
GROUP BY issue_type, severity
ORDER BY
    CASE severity WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 3 END,
    total_issues DESC;


-- ============================================================
-- QUERY 8: DATA QUALITY TREND OVER TIME (Dashboard Panel 3)
-- Shows how many issues are being raised and resolved per day
-- ============================================================

SELECT
    issue_date,
    COUNT(*)                                                        AS issues_raised,
    SUM(affected_records)                                           AS records_affected,
    COUNT(CASE WHEN severity = 'HIGH'   THEN 1 END)                AS high_severity,
    COUNT(CASE WHEN severity = 'MEDIUM' THEN 1 END)                AS medium_severity,
    COUNT(CASE WHEN severity = 'LOW'    THEN 1 END)                AS low_severity,
    COUNT(CASE WHEN resolution_status = 'RESOLVED' THEN 1 END)     AS resolved_same_day
FROM data_quality_log
GROUP BY issue_date
ORDER BY issue_date;


-- ============================================================
-- QUERY 9: OPEN ISSUES BY PORTFOLIO (Dashboard Panel 3)
-- Shows which portfolios have the most unresolved data issues
-- ============================================================

SELECT
    dq.portfolio_id,
    pf.portfolio_name,
    pf.strategy,
    COUNT(*)                                                AS open_issues,
    SUM(dq.affected_records)                               AS total_affected_records,
    COUNT(CASE WHEN dq.severity = 'HIGH' THEN 1 END)       AS high_severity_open,
    MIN(dq.issue_date)                                     AS oldest_open_issue,
    CURRENT_DATE - MIN(dq.issue_date)                      AS days_oldest_issue_open
FROM data_quality_log dq
JOIN portfolios pf ON dq.portfolio_id = pf.portfolio_id
WHERE dq.resolution_status IN ('OPEN', 'IN_PROGRESS')
GROUP BY dq.portfolio_id, pf.portfolio_name, pf.strategy
ORDER BY high_severity_open DESC, open_issues DESC;


-- ============================================================
-- QUERY 10: POSITION-TRANSACTION RECONCILIATION CHECK
-- Validates that transaction activity matches position changes
-- Business Analyst core responsibility
-- ============================================================

WITH position_changes AS (
    SELECT
        p1.portfolio_id,
        p1.security_id,
        p1.quantity AS qty_day1,
        p2.quantity AS qty_day2,
        (p2.quantity - p1.quantity) AS position_change
    FROM positions p1
    JOIN positions p2
        ON  p1.portfolio_id = p2.portfolio_id
        AND p1.security_id  = p2.security_id
        AND p1.position_date = '2026-02-10'
        AND p2.position_date = '2026-02-11'
),
transaction_activity AS (
    SELECT
        portfolio_id,
        security_id,
        SUM(CASE WHEN transaction_type = 'BUY'  THEN quantity ELSE 0 END)
      - SUM(CASE WHEN transaction_type = 'SELL' THEN quantity ELSE 0 END) AS net_txn_qty
    FROM transactions
    WHERE trade_date BETWEEN '2026-02-10' AND '2026-02-11'
    GROUP BY portfolio_id, security_id
)
SELECT
    pc.portfolio_id,
    pc.security_id,
    sec.ticker,
    sec.security_name,
    pc.qty_day1,
    pc.qty_day2,
    pc.position_change,
    COALESCE(ta.net_txn_qty, 0)                                     AS net_transaction_qty,
    (pc.position_change - COALESCE(ta.net_txn_qty, 0))              AS reconciliation_break,
    CASE
        WHEN (pc.position_change - COALESCE(ta.net_txn_qty, 0)) = 0 THEN 'RECONCILED'
        ELSE 'BREAK - INVESTIGATE'
    END AS reconciliation_status
FROM position_changes pc
LEFT JOIN transaction_activity ta
    ON  pc.portfolio_id = ta.portfolio_id
    AND pc.security_id  = ta.security_id
JOIN securities sec ON pc.security_id = sec.security_id
ORDER BY reconciliation_status DESC;


-- ============================================================
-- QUERY 11: EXECUTIVE SUMMARY - DAILY OPERATIONS HEALTH
-- One-query snapshot for management reporting dashboard
-- ============================================================

SELECT
    CURRENT_DATE                                                    AS report_date,
    (SELECT COUNT(*) FROM positions WHERE position_date = '2026-02-11')
                                                                    AS total_positions,
    (SELECT COUNT(*) FROM positions WHERE position_date = '2026-02-11' AND is_verified = FALSE)
                                                                    AS unverified_positions,
    (SELECT COUNT(*) FROM positions WHERE position_date = '2026-02-11' AND market_price IS NULL)
                                                                    AS missing_prices,
    (SELECT COUNT(*) FROM transactions WHERE settlement_status = 'PENDING')
                                                                    AS pending_settlements,
    (SELECT COUNT(*) FROM transactions WHERE settlement_status = 'FAILED')
                                                                    AS failed_settlements,
    (SELECT COUNT(*) FROM data_quality_log WHERE resolution_status = 'OPEN')
                                                                    AS open_dq_issues,
    (SELECT COUNT(*) FROM data_quality_log WHERE resolution_status = 'OPEN' AND severity = 'HIGH')
                                                                    AS critical_dq_issues,
    (SELECT SUM(market_value_usd) FROM positions WHERE position_date = '2026-02-11')
                                                                    AS total_aum_market_value,
    (SELECT SUM(unrealized_pnl) FROM positions WHERE position_date = '2026-02-11')
                                                                    AS total_unrealized_pnl;

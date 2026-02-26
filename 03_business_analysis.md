# ACADIAN ASSET MANAGEMENT
## Investment Operations Intelligence Platform
### Business Analysis Documentation
**Author: Tanisha Kishan | Northeastern University**
---

## Problem Statement

Acadian Asset Management manages $178 billion across 40,000+ securities in 150 markets worldwide.
Their Investment Operations team handles daily Positions and Transactions datasets across multiple
portfolios and strategies. Based on industry research and the role requirements, the core operational
challenges are:

1. **No centralized visibility** into daily positions health across portfolios
2. **Manual, reactive data quality management** — issues are discovered late
3. **No real-time settlement monitoring** — failed trades identified after the fact
4. **Static reporting** — management receives PDFs instead of live dashboards

This project builds the foundation for a management reporting dashboard that addresses all four.

---

## Data Flow Map

```
DATA SOURCES
    |
    ├── Bloomberg Terminal    ──→  Securities Pricing + Reference Data
    ├── Custodian Banks       ──→  Position Confirmations + Settlement Status
    ├── Internal OMS          ──→  Trade Orders + Execution Data
    └── FX/OTC Feeds          ──→  Derivatives + FX Forward Marks
         |
         ↓
INVESTMENT OPERATIONS DATABASE
    |
    ├── portfolios            ──→  Portfolio master + AUM
    ├── securities            ──→  Security reference data
    ├── positions             ──→  Daily holdings snapshot
    ├── transactions          ──→  All trade activity
    └── data_quality_log      ──→  Issue tracking + resolution
         |
         ↓
MANAGEMENT REPORTING DASHBOARD (Tableau)
    |
    ├── Panel 1: Portfolio Health
    ├── Panel 2: Transaction Monitor
    └── Panel 3: Data Quality KPIs
```

---

## User Stories

### Epic: Investment Operations Intelligence Platform

---

### USER STORY 1 — Portfolio Health Dashboard

**As an** Investment Operations Manager,
**I want** a real-time view of portfolio positions across all strategies,
**So that** I can quickly identify unverified positions, missing prices, and P&L anomalies
before the market opens each morning.

**Acceptance Criteria:**
- [ ] Dashboard displays all active portfolios with current AUM and market value
- [ ] Color-coded verification status: Green (>95% verified), Yellow (85-95%), Red (<85%)
- [ ] Missing price count is visible at the portfolio level with drill-down to security level
- [ ] Asset class exposure shown as % breakdown per portfolio
- [ ] Top 10 holdings by total exposure displayed across all portfolios
- [ ] Data refreshes automatically within 15 minutes of market open
- [ ] Users can filter by strategy (Global Equity, Low Vol, ESG, EM, Multi-Asset)

**Definition of Done:**
Dashboard is accessible to all Operations users, loads within 5 seconds, and
data is sourced directly from the positions table without manual exports.

---

### USER STORY 2 — Transaction Monitor

**As a** Trade Operations Analyst,
**I want** a live view of all pending and failed settlements,
**So that** I can prioritize investigation and re-submission before the settlement window closes.

**Acceptance Criteria:**
- [ ] All PENDING transactions visible with days-until-settlement countdown
- [ ] FAILED transactions highlighted in red with broker name and failure reason
- [ ] Duplicate transaction alerts flagged automatically using broker/quantity/date matching
- [ ] Daily transaction volume shown by type (BUY/SELL/DIVIDEND) and portfolio
- [ ] One-click drill-down to individual transaction details
- [ ] Settlement aging report: 0-1 days, 2-3 days, 4+ days buckets
- [ ] Filter by portfolio, broker, transaction type, and settlement status

**Definition of Done:**
Analyst can identify all at-risk settlements within 2 minutes of opening the dashboard,
with no manual spreadsheet lookup required.

---

### USER STORY 3 — Data Quality KPI Tracker

**As a** Business Architect / IT Manager,
**I want** a rolling 30-day view of data quality incidents by type and severity,
**So that** I can track team performance, identify recurring issues, and report
operational risk metrics to senior management.

**Acceptance Criteria:**
- [ ] KPI scorecard shows: total open issues, in-progress, resolved, and resolution rate %
- [ ] Issues broken down by type: Missing Price, Duplicate, Settlement Fail, Reconciliation Break, Stale Data
- [ ] Severity breakdown: HIGH / MEDIUM / LOW with counts
- [ ] 30-day trend line showing issues raised vs. resolved per day
- [ ] Open issues by portfolio showing which funds have most unresolved items
- [ ] Average time-to-resolution per issue type
- [ ] Exportable incident log for audit purposes

**Definition of Done:**
Management can pull a one-page operational health summary in under 60 seconds,
with no manual data compilation required.

---

## Data Mapping Document

| Dashboard Field          | Source Table       | Source Column         | Transformation                          |
|--------------------------|--------------------|-----------------------|-----------------------------------------|
| Portfolio Name           | portfolios         | portfolio_name        | Direct                                  |
| AUM                      | portfolios         | aum_usd               | Format as $B                            |
| Market Value             | positions          | market_value_usd      | SUM by portfolio, latest date           |
| Verification Rate        | positions          | is_verified           | COUNT(TRUE) / COUNT(*) * 100            |
| Missing Prices           | positions          | market_price          | COUNT WHERE NULL                        |
| Unrealized P&L           | positions          | unrealized_pnl        | SUM by portfolio                        |
| Asset Class Exposure     | positions+securities| asset_class          | SUM market_value GROUP BY asset_class   |
| Pending Settlements      | transactions       | settlement_status     | COUNT WHERE = 'PENDING'                 |
| Failed Settlements       | transactions       | settlement_status     | COUNT WHERE = 'FAILED'                  |
| Duplicate Transactions   | transactions       | Multiple columns      | GROUP BY + HAVING COUNT > 1             |
| DQ Issue Count           | data_quality_log   | resolution_status     | COUNT by status                         |
| Resolution Rate          | data_quality_log   | resolution_status     | RESOLVED / TOTAL * 100                  |
| Issue Trend              | data_quality_log   | issue_date            | COUNT GROUP BY date                     |
| Oldest Open Issue        | data_quality_log   | issue_date            | MIN where status = OPEN                 |

---

## Incident Triage Categories

| Issue Type              | Severity | SLA to Resolve | Owner        | Escalation Path              |
|-------------------------|----------|----------------|--------------|------------------------------|
| MISSING_PRICE           | HIGH     | 2 hours        | Data Team    | Bloomberg Support → IT       |
| DUPLICATE_TRANSACTION   | HIGH     | 4 hours        | Trade Team   | Broker Ops → Compliance      |
| SETTLEMENT_FAILURE      | HIGH     | Same day       | Trade Team   | Broker Ops → Portfolio Mgr   |
| RECONCILIATION_BREAK    | HIGH     | End of day     | Ops Team     | Custodian → Portfolio Mgr    |
| UNVERIFIED_POSITION     | MEDIUM   | 24 hours       | Ops Team     | Custodian Operations         |
| STALE_DATA              | LOW      | Next business  | Data Team    | Vendor Support               |

---

## SQL Queries Index

| Query # | Purpose                                    | Dashboard Panel |
|---------|--------------------------------------------|-----------------|
| Q1      | Portfolio Health Summary                   | Panel 1         |
| Q2      | Asset Class Exposure by Portfolio          | Panel 1         |
| Q3      | Top 10 Holdings Across All Portfolios      | Panel 1         |
| Q4      | Daily Transaction Volume Monitor           | Panel 2         |
| Q5      | Settlement Status Tracker                  | Panel 2         |
| Q6      | Duplicate Transaction Detection            | Panel 2         |
| Q7      | Data Quality KPI Summary                   | Panel 3         |
| Q8      | Data Quality Trend Over Time               | Panel 3         |
| Q9      | Open Issues by Portfolio                   | Panel 3         |
| Q10     | Position-Transaction Reconciliation Check  | Cross-panel     |
| Q11     | Executive Summary - Daily Operations Health| All Panels      |

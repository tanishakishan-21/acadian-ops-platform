# Investment Operations Intelligence Platform
### Built for Acadian Asset Management | By Tanisha Kishan

---

## Overview

This project builds a complete Investment Operations data quality and management reporting platform targeting the real operational challenges faced by systematic investment managers like Acadian Asset Management.

**The Problem:**
Acadian manages $178B across 40,000+ securities in 150 markets. Their investment operations team handles daily Positions and Transactions datasets across multiple portfolios — but the industry still relies heavily on static reports, manual reconciliation, and reactive data quality management.

**The Solution:**
A three-panel management reporting dashboard built on a structured PostgreSQL database, powered by 11 analytical SQL queries, with full business analysis documentation.

---

## What's In This Repo

```
acadian-ops-platform/
├── 01_schema_and_data.sql     # Full database schema + realistic sample data
├── 02_queries.sql             # 11 analytical queries powering the dashboard
├── 03_business_analysis.md    # User stories, acceptance criteria, data mapping
├── portfolio.html             # Portfolio webpage
└── README.md                  # This file
```

---

## Database Schema

| Table             | Purpose                                              |
|-------------------|------------------------------------------------------|
| portfolios        | Portfolio master — 5 strategies, $14.35B total AUM  |
| securities        | Security reference — 15 securities, 7 countries      |
| positions         | Daily position snapshots across all portfolios       |
| transactions      | All trade activity — buy, sell, dividend, FX         |
| data_quality_log  | Issue tracking with triage, severity, and resolution |

---

## Dashboard Panels

### Panel 1 — Portfolio Health
- AUM and market value by portfolio
- Position verification rate (color-coded)
- Missing price detection
- Asset class exposure breakdown
- Top 10 holdings across all funds

### Panel 2 — Transaction Monitor
- Pending and failed settlement tracker
- Automatic duplicate transaction detection
- Daily volume by type and portfolio
- Settlement aging analysis

### Panel 3 — Data Quality KPIs
- Open / In-Progress / Resolved issue counts
- 30-day trend: issues raised vs. resolved
- Issues by type and severity
- Open issues by portfolio with oldest issue age

---

## SQL Queries

| # | Query Name                                    | Panel     |
|---|-----------------------------------------------|-----------|
| 1 | Portfolio Health Summary                      | Panel 1   |
| 2 | Asset Class Exposure by Portfolio             | Panel 1   |
| 3 | Top 10 Holdings                               | Panel 1   |
| 4 | Daily Transaction Volume                      | Panel 2   |
| 5 | Settlement Status Tracker                     | Panel 2   |
| 6 | Duplicate Transaction Detection               | Panel 2   |
| 7 | Data Quality KPI Summary                      | Panel 3   |
| 8 | Data Quality Trend Over Time                  | Panel 3   |
| 9 | Open Issues by Portfolio                      | Panel 3   |
|10 | Position-Transaction Reconciliation Check     | All       |
|11 | Executive Summary — Daily Operations Health   | All       |

---

## How to Run

1. Install PostgreSQL
2. Run `01_schema_and_data.sql` to create tables and load data
3. Run `02_queries.sql` to execute all analytical queries
4. Connect Tableau to your PostgreSQL database
5. Build the three dashboard panels using the query outputs

---

## About

**Tanisha Kishan**
Master of Science in Engineering Management — Northeastern University (GPA: 3.7)
Bachelor of Engineering in Computer Science — MVJ College of Engineering

- HackerRank SQL Advanced ✓
- HackerRank Python Intermediate ✓
- BCG Strategy Consulting Simulation ✓
- Accenture Data Analytics & Visualization ✓

📧 kishan.t@northeastern.edu
🔗 linkedin.com/in/tanishakishan
📍 Boston, MA

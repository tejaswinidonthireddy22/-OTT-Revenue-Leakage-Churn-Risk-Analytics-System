 🎬 OTT Revenue Leakage & Churn Risk Analytics System

> A  data analytics solution to detect, quantify, and reduce subscription revenue loss for OTT platforms like Netflix, Disney+, and Amazon Prime Video.

---

## 📌 Table of Contents
- [Problem Statement](#-problem-statement)
- [Project Goals](#-project-goals)
- [Dataset](#-dataset)
- [Project Structure](#-project-structure)
- [Data Pipeline](#-data-pipeline)
- [KPIs Tracked](#-kpis-tracked)
- [Key Insights](#-key-insights)
- [Technologies Used](#-technologies-used)
- [How to Run](#-how-to-run)
- [Dashboard Preview](#-dashboard-preview)
- [Recovery Recommendations](#-recovery-recommendations)
- [License](#-license)

- Subscription-based OTT platforms rely heavily on recurring monthly revenue. Revenue leakage occurs silently through:

| Leakage Source | Impact |
|---|---|
| Payment Failures | Direct MRR loss |
| Discount / Trial Abuse | Reduced ARPU |
| Plan Downgrades before billing | Revenue gap |
| Auto-renewal disabled | Lost renewals |
| Refund abuse | Profit erosion |

Without a centralised analytics system, finance and operations teams lack visibility into the true scale of leakage.

---

## 🎯 Project Goals

- ✅ Identify root causes of revenue leakage
- ✅ Detect high-risk accounts contributing to financial loss
- ✅ Calculate revenue at risk with granular breakdown
- ✅ Improve payment recovery rates through retry strategies
- ✅ Build executive-level KPI dashboards
- ✅ Enable proactive revenue protection

---

## 📊 Dataset

| Field | Description |
|---|---|
| `User_ID` | Unique subscriber identifier |
| `Name` | Subscriber name |
| `Age` | Age of subscriber |
| `Country` | Country of residence |
| `Subscription_Type` | Basic / Standard / Premium |
| `Watch_Time_Hours` | Total watch hours |
| `Favorite_Genre` | Primary content preference |
| `Last_Login` | Date of last platform access |

**Size:** 25,000 rows × 8 columns  
**Source:** `netflix_users.csv`

> Additional financial columns (Plan_Price, Payment_Status, Auto_Renewal, Discount_Applied, Revenue_Earned, Revenue_At_Risk) are derived during EDA.

---## 📁 Project Structure

```
ott-revenue-leakage-analytics/
│
├── data/
│   └── netflix_users.csv             # Raw dataset (25,000 users)
│
├── eda/
│   └── eda_analysis.py               # Full EDA with 7 chart outputs
│   └── eda_charts/                   # Output PNG charts
│       ├── 01_subscription_distribution.png
│       ├── 02_revenue_leakage_overview.png
│       ├── 03_payment_status_analysis.png
│       ├── 04_churn_risk.png
│       ├── 05_demographics_geography.png
│       ├── 06_discount_refund_abuse.png
│       └── 07_watch_time_analysis.png
│
├── sql/
│   └── sql_analytics_queries.sql     # All SQL KPI queries (8 sections)
│
├── dashboard/
│   └── BI_Dashboard            # Interactive 5-tab BI dashboard
│
├── reports/
│   └── OTT_Revenue_Leakage_Business_Report.pdf


## 🔄 Data Pipeline

```
Raw CSV
   │
   ▼
[1] Data Ingestion (Python / pandas)
    - Load netflix_users.csv
    - Parse dates, validate schema
   │
   ▼
[2] Feature Engineering (Python)
    - Derive Plan_Price from Subscription_Type
    - Simulate Payment_Status, Auto_Renewal
    - Calculate Days_Since_Login
    - Generate Revenue_Earned, Revenue_At_Risk
    - Assign Churn_Risk labels
   │
   ▼
[3] EDA & Visualisation (Python / matplotlib / seaborn)
    - 7 chart categories covering:
      Revenue split, Plan distribution,
      Payment failures, Churn risk,
      Demographics, Discount abuse, Watch time
   │
   ▼
[4] SQL Analytics (SQLite 
    - Load enriched data into relational tables
    - Execute KPI queries across 8 analytical sections
    - Generate aggregated views for dashboarding
   │
   ▼
[5] BI Dashboard 
    - 5-tab interactive dashboard
    - Overview → Leakage → Payments → Churn → Recovery
   │
   ▼
[6] Executive Report (PDF / ReportLab)
    - Business problem statement
    - KPI snapshot tables
    - Insight findings
    - Solution architecture


    📈 KPIs Tracked

| KPI | Value | Target |
|---|---|---|
| Revenue Leakage % | 9.81% | < 2% |
| Revenue At Risk | ₹12.26L / month | Minimise |
| Payment Failure Rate | 9.67% | < 5% |
| Auto-Renewal Success Rate | ~88% | > 95% |
| ARPU (Premium) | ₹718 | ₹799 |
| Recovery Rate (estimated) | 40-60% | > 40% |
| Refund Abuse Rate | ~3% | < 1% |
| High Churn Risk Users | ~8% (2,000) | < 3% |

---

## 💡 Key Insights

1. **Revenue Leakage Rate** — ~9.81% of monthly revenue is at risk from payment failures  
2. **Digital Wallet Failures** — Digital wallets show 18.4% failure rate vs 6.1% for credit cards  
3. **Premium Plan Leakage** — ₹6.79L lost per month from Premium plan alone  
4. **High Churn Risk Segment** — ~2,000 users with >90 days inactivity + <50 watch hours  
5. **Free Trial Abuse** — Trial users show near-zero ARPU until first billing  
6. **Recovery Opportunity** — ₹5.88Cr annually recoverable with smart retry + outreach  

---

## 🛠️ Technologies Used

| Layer | Technology |
|---|---|
| Data Processing | Python 3.11, pandas, numpy |
| Visualisation | matplotlib, seaborn |
| Database / SQL | SQLite, PostgreSQL (ANSI SQL) |
| BI Dashboard 
| PDF Report | ReportLab |
| Version Control | Git / GitHub |
```

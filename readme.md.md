# 💊 Pharmaceutical Sales Effectiveness Analysis

Pharma Sales Crisis Uncovered | ₹84.12M revenue analyzed | Python · SQL · Power BI | East territory bleeding at 0.87 conversion | 1 star performer + 1 PIP candidate identified | FY 2024-25

---

## 📌 Project Snapshot

| Metric | Value |
|--------|-------|
| Total Revenue Analyzed | ₹84.12M |
| Marketing ROI | 5.11 |
| Sales Territories | 4 (North, South, East, West) |
| Product Lines | 3 (Deccan Lite, Spasmofirst, Wokderm Plus) |
| Sales Representatives | 15+ |

---

## 🧩 Business Problem

A pharmaceutical company needed to evaluate:
- Why certain territories consistently underperform on conversion
- Which sales reps are driving revenue vs. requiring performance intervention
- Whether marketing spend is translating into measurable ROI
- Where inventory pressure and channel-stuffing risk exist

---

## 📂 Dataset Overview

| Attribute | Details |
|-----------|---------|
| Records | ~645K primary sales transactions |
| Time Period | Apr 2024 – Mar 2025 (1 fiscal years) |
| Territories | East, West, North, South |
| Products | Deccan Lite, Spasmofirst, Wokderm Plus |
| Sales Reps | 15+ field representatives |
| Key Metrics | Revenue, Conversion Ratio, Doctor Visits, Marketing Spend, Bonus Expense |

> ⚠️ Dataset is synthetic and anonymized for portfolio purposes.

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|------|---------|
| **Python** (Pandas, Matplotlib, Seaborn) | Data cleaning, EDA, statistical analysis |
| **SQL** (PostgreSQL) | Analytical queries, KPI aggregation, cohort logic |
| **Power BI** | Interactive 4-page dashboard, DAX measures |
| **Jupyter Notebook** | Exploratory analysis & visualization |

---

## 🔄 Project Workflow

```
Raw CSV Data
    │
    ▼
[SQL] → Data validation, KPI queries, territory & rep-level aggregations
    │
    ▼
[Python] → Data cleaning, outlier detection, EDA, trend & correlation analysis
    │
    ▼
[Power BI] → 4-page interactive dashboard with slicers, scorecards & DAX
```

---

## 📸 Dashboard Preview

> 📂 Uploaded screenshots to the `dashboard_screenshots/` folder.

### Page 1 — Executive Overview
<!-- Uploaded: dashboard_screenshots/page1_executive_overview.png -->

### Page 2 — Territory Analysis
<!-- Uploaded: dashboard_screenshots/page2_territory_analysis.png -->

### Page 3 — Rep Performance
<!-- Uploaded: dashboard_screenshots/page3_rep_performance.png -->

### Page 4 — Product & ROI
<!-- Uploaded: dashboard_screenshots/page4_product_roi.png -->

---

## 🔍 Key Analysis Performed

**SQL**
- Territory-wise revenue and conversion ratio ranking
- Rep-level target achievement and doctor visit efficiency
- Quarter-over-quarter performance comparison
- Marketing ROI calculation by product and territory

**Python**
- Null handling, type casting, duplicate removal
- Monthly revenue trend analysis by territory
- Conversion ratio distribution and outlier detection
- Correlation between doctor visits and revenue per rep
- Product-level bonus expense vs. revenue analysis

**Power BI (DAX)**
- Dynamic conversion ratio threshold alerts (< 0.80 flag)
- Marketing ROI = Revenue / Marketing Spend
- Target Achievement % by rep, product, and territory
- Inventory Gap Units measure for distributor risk tracking

---

## 📊 Dashboard Highlights

4-page interactive Power BI dashboard with quarter and product slicers:

| Page | Focus |
|------|-------|
| **Executive Overview** | Top-line KPIs, revenue by territory, monthly trend |
| **Territory Analysis** | Conversion trends, primary vs. secondary sales, quarter scorecard |
| **Rep Performance** | Target achievement, doctor visit efficiency, PIP flagging |
| **Product & ROI** | Revenue vs. bonus expense, marketing ROI, seasonal view |

---

## 💡 Key Insights

- 📍 **North territory leads** revenue at ₹24.5M — highest primary + secondary sales balance
- ⚠️ **East territory** conversion ratio (0.87) consistently below 0.80 threshold — highest inventory gap risk
- 🌟 **Ravi Menon (South)** — highest doctor visits + highest revenue = confirmed star performer
- 🔴 **Manoj Roy (East)** — lowest visits + lowest revenue = PIP candidate
- 📦 **Wokderm Plus** Q4 primary sales spike not matched by secondary sales — channel stuffing risk
- 💰 **Overall Marketing ROI = 5.11** — healthy, with North at 5.95 (best) and East at 3.97 (worst)
- 📈 **Deccan Lite** leads revenue share; Wokderm Plus has disproportionately high bonus expense vs. revenue

---

## ✅ Business Recommendations

1. **East Territory** — Trigger immediate ABM (Account-Based Marketing) review; investigate distributor inventory pressure
2. **Manoj Roy** — Place on structured PIP with 90-day doctor visit and revenue milestones
3. **Ravi Menon model** — Document visit frequency and engagement strategy; replicate across underperforming reps
4. **Wokderm Plus** — Audit Q4 secondary sales data; halt primary push until secondary offtake catches up
5. **Marketing Spend reallocation** — Shift budget from East (ROI 3.97) toward North and South (ROI 5.95 / 5.57)
6. **Conversion threshold monitoring** — Automate alerts when territory conversion drops below 0.80 for 2 consecutive months

---

## 📁 Repository Structure

```
pharma-sales-analysis/
│
├── data/
│   └── pharma_dataset.csv              # Synthetic dataset
│
├── notebooks/
│   └── pharma_sales_analysis.ipynb     # Python EDA & cleaning
│
├── sql/
│   └── pharma_sales_effectiveness.sql  # Analytical SQL queries
│
├── dashboard/
│   └── pharma_sales_dashboard.pbix     # Power BI file
│
├── dashboard_screenshots/
│   ├── page1_executive_overview.png
│   ├── page2_territory_analysis.png
│   ├── page3_rep_performance.png
│   └── page4_product_roi.png
│
└── README.md
```

---

## 🙋 About

**Prince Kumar** — Data Analyst | Python · SQL · Power BI · Excel  

[![LinkedIn](https://www.linkedin.com/feed/?trk=sem-ga_campid.14650114788_asid.151761418307_crid.657403558715_kw.linkedin%20profile_d.c_tid.kwd-10521864172_n.g_mt.e_geo.1007828)
[![GitHub](https://github.com/prince2310-97)

---

*⭐ If you found this project useful, consider starring the repository!*

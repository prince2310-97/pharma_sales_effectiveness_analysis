-- ============================================================================================================================
--  PHARMA SALES EFFECTIVENESS & TERRITORY OPTIMIZATION
--  SQL Analytics Script — FY 2024-25 (April 2024 to March 2025)
--  Database  : pharma_analysis
--  Table     : pharma_sales
--  Author    : Senior Commercial Analytics Consultant
--  Purpose   : End-to-end business diagnostic — Territory, Rep, Product, Seasonal, ROI
-- ============================================================================================================================
--
--  COLUMN REFERENCE (pharma_sales table):
--  Month            VARCHAR   — YYYY-MM format
--  FY               VARCHAR   — Financial Year label
--  Territory        VARCHAR   — North / South / East / West
--  Sales_Rep        VARCHAR   — Rep name
--  Product          VARCHAR   — Spasmofirst / Wokderm Plus / Decdan Lite
--  Primary_Sales    INT       — Company billing to distributor (units)
--  Secondary_Sales  INT       — Distributor sell-through to market (units)
--  Revenue          FLOAT     — Primary × Price ± 2% billing variation
--  Target           FLOAT     — Monthly unit target (territory-adjusted)
--  Doctor_Visits    FLOAT     — Monthly doctor visits by rep (nullable)
--  Marketing_Spend  FLOAT     — Product-level, territory-adjusted monthly spend
--  Bonus_Expense    FLOAT     — Trade/rep bonus (nullable; 0 when not triggered)
--
-- ============================================================================================================================




-- ============================================================================================================================
-- SECTION 1 : TERRITORY EFFICIENCY ANALYSIS
-- ============================================================================================================================

/*
  OBJECTIVE    : Measure each territory's overall commercial health across the full FY.
  WHY IT MATTERS : Territory is the first lens of any pharma review. Before going to rep level,
                   leadership needs to know which geographies are contributing, which are draining
                   resources, and where the Primary → Secondary conversion is leaking.
  INSIGHT      : A high Primary with low Secondary conversion = distributor is stocking but market
                 is not moving. This is inventory pressure and a future returns risk.
*/

SELECT
    Territory,

    -- Total volume billed to distributors across all reps and products
    SUM(Primary_Sales)                                                          AS Total_Primary_Units,

    -- Total market-level sell-through — this is real demand
    SUM(Secondary_Sales)                                                        AS Total_Secondary_Units,

    -- Core efficiency ratio: how much of what we billed actually moved to market
    -- Below 0.80 = danger zone (distributor overstocked, returns risk high)
    ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3)       AS Secondary_Conversion_Ratio,

    -- Total revenue generated (Primary × Price ± billing variation)
    ROUND(SUM(Revenue), 0)                                                      AS Total_Revenue,

    -- Achievement vs Target — are reps meeting their numbers?
    ROUND(SUM(Primary_Sales) * 100.0 / NULLIF(SUM(Target), 0), 1)              AS Target_Achievement_Pct,

    -- Average doctor visits per row — proxy for field activity level
    ROUND(AVG(Doctor_Visits), 1)                                                AS Avg_Doctor_Visits,

    -- Total marketing investment in this territory
    ROUND(SUM(Marketing_Spend), 0)                                              AS Total_Marketing_Spend,

    -- Revenue generated per rupee of marketing spend — Marketing ROI proxy
    ROUND(SUM(Revenue) / NULLIF(SUM(Marketing_Spend), 0), 2)                   AS Revenue_Per_Marketing_Rupee,

    -- Total bonus/trade scheme cost — higher bonus = more push needed = weaker pull
    ROUND(SUM(Bonus_Expense), 0)                                                AS Total_Bonus_Expense

FROM pharma_sales
GROUP BY Territory
ORDER BY Total_Revenue DESC;

/*
  EXPECTED OUTPUT  : 4 rows — one per territory. North should show highest revenue.
                     East should show lowest Secondary_Conversion_Ratio.
  BUSINESS REACTION: Any territory with Conversion Ratio < 0.80 needs immediate distributor
                     review. If Marketing ROI is also low there, the problem is structural —
                     not fixable by more spend. Leadership should flag East for quarterly review.
*/




-- ============================================================================================================================
-- SECTION 2 : REP RANKING WITHIN TERRITORY (Window Function — DENSE_RANK)
-- ============================================================================================================================

/*
  OBJECTIVE    : Rank every sales rep within their own territory based on full-year performance.
  WHY IT MATTERS : ZBM/ABM reviews happen territory-wise. A rep who ranks #1 in East may still
                   underperform vs a #3 rep in North. This query gives both local rank AND
                   absolute revenue for fair comparison.
  INSIGHT      : Identifies top contributors for incentive planning and low performers for
                 Performance Improvement Plan (PIP) or coaching decisions.
*/

SELECT
    Territory,
    Sales_Rep,

    -- Total units billed — volume contribution
    SUM(Primary_Sales)                                                          AS Total_Primary_Units,

    -- Total revenue — financial contribution
    ROUND(SUM(Revenue), 0)                                                      AS Total_Revenue,

    -- Full-year target achievement percentage
    ROUND(SUM(Primary_Sales) * 100.0 / NULLIF(SUM(Target), 0), 1)              AS Achievement_Pct,

    -- Secondary conversion ratio — how well their distributor network moves product
    ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3)       AS Sec_Conversion_Ratio,

    -- Total doctor visits — field activity measure
    SUM(Doctor_Visits)                                                          AS Total_Doctor_Visits,

    -- Revenue rank within territory — 1 = best performer in that zone
    DENSE_RANK() OVER (
        PARTITION BY Territory
        ORDER BY SUM(Revenue) DESC
    )                                                                           AS Territory_Revenue_Rank,

    -- Achievement rank within territory
    DENSE_RANK() OVER (
        PARTITION BY Territory
        ORDER BY SUM(Primary_Sales) * 100.0 / NULLIF(SUM(Target), 0) DESC
    )                                                                           AS Territory_Achievement_Rank

FROM pharma_sales
GROUP BY Territory, Sales_Rep
ORDER BY Territory, Territory_Revenue_Rank;

/*
  EXPECTED OUTPUT  : 20 rows (5 reps × 4 territories). Within each territory, rank 1 = top performer.
                     Manoj Roy (East low performer) should consistently rank 5th in East.
  BUSINESS REACTION: Reps ranked 4–5 with Achievement_Pct < 75% need structured intervention.
                     Reps ranked 1 with high Sec_Conversion_Ratio are true field stars —
                     consider them for ZSM pipeline or mentorship roles.
*/




-- ============================================================================================================================
-- SECTION 3 : Q4 vs NON-Q4 BILLING PRESSURE VALIDATION
-- ============================================================================================================================

/*
  OBJECTIVE    : Statistically validate whether Q4 (Jan–Mar) shows artificial primary push
                 without proportionate secondary improvement.
  WHY IT MATTERS : Q4 push is a known industry phenomenon — companies force-bill distributors
                   to close the financial year strong. This inflates primary but secondary
                   doesn't grow at same rate, creating a "channel stuffing" situation.
                   If caught by auditors or channel partners, it damages company credibility.
  INSIGHT      : If Q4 Primary is 10–15% higher than Non-Q4 but Secondary ratio drops,
                 it confirms artificial billing. This is a CFO-level red flag.
*/

SELECT
    -- Classify each row into Q4 or Non-Q4
    CASE
        WHEN Month IN ('2025-01','2025-02','2025-03') THEN 'Q4 (Jan-Mar)'
        ELSE 'Non-Q4 (Apr-Dec)'
    END                                                                         AS Quarter_Type,

    -- Count of months in each bucket
    COUNT(DISTINCT Month)                                                       AS Month_Count,

    -- Average monthly primary per row — normalized for fair comparison
    ROUND(AVG(Primary_Sales), 0)                                                AS Avg_Monthly_Primary,

    -- Average monthly secondary
    ROUND(AVG(Secondary_Sales), 0)                                              AS Avg_Monthly_Secondary,

    -- Secondary conversion ratio — key diagnostic
    -- Q4 ratio dropping below Non-Q4 = channel stuffing confirmed
    ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3)       AS Secondary_Conversion_Ratio,

    -- Average target achievement in Q4 vs rest of year
    ROUND(AVG(Primary_Sales * 100.0 / NULLIF(Target, 0)), 1)                   AS Avg_Achievement_Pct,

    -- Average bonus per row — Q4 bonus should be elevated due to trade push
    ROUND(AVG(Bonus_Expense), 0)                                                AS Avg_Bonus_Per_Row,

    -- Average marketing spend — Q4 spend should be higher for campaign push
    ROUND(AVG(Marketing_Spend), 0)                                              AS Avg_Marketing_Spend,

    -- Revenue per unit — should stay stable. If it drops in Q4, scheme discounting is happening
    ROUND(SUM(Revenue) / NULLIF(SUM(Primary_Sales), 0), 2)                     AS Revenue_Per_Unit

FROM pharma_sales
GROUP BY Quarter_Type
ORDER BY Quarter_Type DESC;

/*
  EXPECTED OUTPUT  : 2 rows. Q4 should show higher Avg_Monthly_Primary, higher Avg_Bonus,
                     but lower or flat Secondary_Conversion_Ratio.
  BUSINESS REACTION: If Q4 primary is 10%+ above Non-Q4 AND conversion ratio drops —
                     Commercial Head must immediately review distributor inventory health post-March.
                     Excess stock with distributors in April will suppress April/May secondary.
                     Finance team should provision for potential returns in Q1 FY2025-26.
*/




-- ============================================================================================================================
-- SECTION 4 : PRODUCT-LEVEL ROI ANALYSIS
-- ============================================================================================================================

/*
  OBJECTIVE    : Evaluate each product's commercial performance — volume, revenue, marketing
                 efficiency, and conversion quality.
  WHY IT MATTERS : Budget allocation for next FY depends on this. A product with high marketing
                   spend but low revenue-per-rupee return should get reduced support.
                   A product with strong conversion ratio deserves more investment.
  INSIGHT      : Decdan Lite (premium price ₹187.90) may show lower volume but higher revenue
                 per unit. Spasmofirst (₹97.50) is mass market — volume is its story.
*/

SELECT
    Product,

    -- Price reference (derived from revenue/units as cross-check)
    ROUND(SUM(Revenue) / NULLIF(SUM(Primary_Sales), 0), 2)                     AS Effective_Price_Per_Unit,

    -- Total volume and revenue
    SUM(Primary_Sales)                                                          AS Total_Primary_Units,
    SUM(Secondary_Sales)                                                        AS Total_Secondary_Units,
    ROUND(SUM(Revenue), 0)                                                      AS Total_Revenue,

    -- Conversion quality
    ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3)       AS Secondary_Conversion_Ratio,

    -- Target achievement — is the product meeting commercial expectations?
    ROUND(SUM(Primary_Sales) * 100.0 / NULLIF(SUM(Target), 0), 1)              AS Target_Achievement_Pct,

    -- Total marketing invested
    ROUND(SUM(Marketing_Spend), 0)                                              AS Total_Marketing_Spend,

    -- Revenue return per rupee of marketing — core ROI metric
    ROUND(SUM(Revenue) / NULLIF(SUM(Marketing_Spend), 0), 2)                   AS Revenue_Per_Mkt_Rupee,

    -- Cost of bonus/trade schemes for this product
    ROUND(SUM(Bonus_Expense), 0)                                                AS Total_Bonus_Expense,

    -- Bonus as % of revenue — high % means product needs excessive push = weak pull demand
    ROUND(SUM(Bonus_Expense) * 100.0 / NULLIF(SUM(Revenue), 0), 2)             AS Bonus_As_Pct_Of_Revenue

FROM pharma_sales
GROUP BY Product
ORDER BY Total_Revenue DESC;

/*
  EXPECTED OUTPUT  : 3 rows. Spasmofirst should lead on volume. Decdan Lite should show
                     highest effective price. Compare Revenue_Per_Mkt_Rupee across products.
  BUSINESS REACTION: Product with Bonus_As_Pct_Of_Revenue > 3% and low conversion ratio
                     is being pushed artificially. Marketing team should investigate if
                     doctor adoption is weak or if distributor margins need restructuring.
                     Consider re-evaluating marketing mix for underperforming product.
*/




-- ============================================================================================================================
-- SECTION 5 : INVENTORY GAP RISK DETECTION (Monthly Overstocking Flags)
-- ============================================================================================================================

/*
  OBJECTIVE    : Identify specific month-territory-product combinations where inventory
                 gap (Primary >> Secondary) creates overstocking risk at distributor level.
  WHY IT MATTERS : In Indian pharma, overstocked distributors stop accepting new stock,
                   leading to secondary sales drop in next month. Early detection prevents
                   channel breakdown. This is critical for East territory historically.
  INSIGHT      : Any row with Inventory_Gap_Units > 300 and Conversion_Ratio < 0.75
                 should be treated as a high-risk inventory situation.
*/

SELECT
    Month,
    Territory,
    Product,

    -- Total primary billed in this month-territory-product bucket
    SUM(Primary_Sales)                                                          AS Total_Primary,

    -- Total secondary sold through
    SUM(Secondary_Sales)                                                        AS Total_Secondary,

    -- Raw gap in units — distributor is holding this excess stock
    SUM(Primary_Sales) - SUM(Secondary_Sales)                                  AS Inventory_Gap_Units,

    -- Conversion ratio for that specific period
    ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3)       AS Conversion_Ratio,

    -- Business risk flag — classify severity of inventory gap
    CASE
        WHEN ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3) < 0.70 THEN 'HIGH RISK'
        WHEN ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3) < 0.80 THEN 'MEDIUM RISK'
        ELSE 'ACCEPTABLE'
    END                                                                         AS Inventory_Risk_Flag

FROM pharma_sales
GROUP BY Month, Territory, Product

-- Focus only on rows where meaningful gap exists
HAVING (SUM(Primary_Sales) - SUM(Secondary_Sales)) > 200

ORDER BY Inventory_Gap_Units DESC
LIMIT 25;

/*
  EXPECTED OUTPUT  : Top 25 month-territory-product combinations with highest inventory gap.
                     East territory Q4 months should dominate this list.
                     HIGH RISK rows = immediate field action needed.
  BUSINESS REACTION: For every HIGH RISK row, ABM must visit distributor within 15 days.
                     Understand stock aging, check if product is near expiry, and plan
                     return authorization if necessary. Do NOT push more primary into
                     distributors with HIGH RISK flags — it will compound the problem.
*/




-- ============================================================================================================================
-- SECTION 6 : INTEGRATED OVERSTOCK FLAG — CTE BASED MULTI-LEVEL DETECTION
-- ============================================================================================================================

/*
  OBJECTIVE    : Build a structured, multi-level CTE pipeline to identify reps whose
                 distributor network is chronically overstocked across multiple months.
  WHY IT MATTERS : A rep who shows inventory gap in 3+ months consecutively is not a
                   one-off issue — it's a systemic problem with how they manage their
                   channel. This needs manager escalation, not just a one-time review.
  INSIGHT      : CTE approach allows clean layering: first compute monthly ratios,
                 then count chronic months, then classify reps by severity.
*/
WITH

-- Step 1: Calculate monthly conversion ratio at rep-product level
-- NOTE: Primary/Secondary are reserved words in MySQL — renamed to Primary_Units/Secondary_Units
Monthly_Conversion AS (
    SELECT
        Territory,
        Sales_Rep,
        Product,
        Month,
        SUM(Primary_Sales)                                                      AS Primary_Units,
        SUM(Secondary_Sales)                                                    AS Secondary_Units,
        ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3)   AS Conv_Ratio
    FROM pharma_sales
    GROUP BY Territory, Sales_Rep, Product, Month
),

-- Step 2: Count how many months each rep-product had conversion ratio below 0.80
Chronic_Stock_Count AS (
    SELECT
        Territory,
        Sales_Rep,
        Product,
        COUNT(CASE WHEN Conv_Ratio < 0.80 THEN 1 END)                          AS Low_Conv_Months,
        ROUND(AVG(Conv_Ratio), 3)                                               AS Avg_Conv_Ratio,
        ROUND(MIN(Conv_Ratio), 3)                                               AS Worst_Month_Ratio,
        SUM(Primary_Units)                                                      AS Total_Primary_FY,
        SUM(Secondary_Units)                                                    AS Total_Secondary_FY
    FROM Monthly_Conversion
    GROUP BY Territory, Sales_Rep, Product
),

-- Step 3: Classify reps based on chronic overstock severity
Overstock_Classification AS (
    SELECT
        Territory,
        Sales_Rep,
        Product,
        Low_Conv_Months,
        Avg_Conv_Ratio,
        Worst_Month_Ratio,
        Total_Primary_FY,
        Total_Secondary_FY,
        (Total_Primary_FY - Total_Secondary_FY)                                AS FY_Inventory_Gap,
        CASE
            WHEN Low_Conv_Months >= 6 THEN 'CHRONIC — Escalate to ZBM'
            WHEN Low_Conv_Months BETWEEN 3 AND 5 THEN 'WATCH — ABM Review Needed'
            WHEN Low_Conv_Months BETWEEN 1 AND 2 THEN 'MONITOR — Seasonal or One-off'
            ELSE 'HEALTHY — No Action'
        END                                                                     AS Overstock_Status
    FROM Chronic_Stock_Count
)

SELECT
    Territory,
    Sales_Rep,
    Product,
    Low_Conv_Months,
    Avg_Conv_Ratio,
    Worst_Month_Ratio,
    Total_Primary_FY,
    Total_Secondary_FY,
    FY_Inventory_Gap,
    Overstock_Status
FROM Overstock_Classification
WHERE Low_Conv_Months >= 1
ORDER BY Low_Conv_Months DESC, FY_Inventory_Gap DESC;


/*
  EXPECTED OUTPUT  : Multiple rows with rep-product combinations flagged by severity.
                     East territory reps — especially Manoj Roy — should show CHRONIC or WATCH.
                     Low performers across all territories will likely appear in MONITOR zone.
  BUSINESS REACTION:
    CHRONIC rows     → ZBM must include in quarterly business review with corrective plan.
    WATCH rows       → ABM to conduct distributor health check, review credit limits.
    MONITOR rows     → Field manager to track next 2 months before escalation.
    HEALTHY rows     → No action. Use as benchmark for coaching low performers.
*/




-- ============================================================================================================================
-- SECTION 7 : SEASONAL LIFT VALIDATION BY PRODUCT
-- ============================================================================================================================

/*
  OBJECTIVE    : Validate whether seasonal demand logic embedded in the dataset is
                 actually reflected in realized primary sales numbers month-over-month.
  WHY IT MATTERS : Seasonal planning drives stock deployment, marketing campaign timing,
                   and rep activity calendars. If planned seasonal lift doesn't materialize,
                   it means either field execution failed or demand assumption was wrong.
  INSIGHT      : Wokderm Plus should show peak in July–September. Decdan Lite should peak
                 October–February. Spasmofirst should be mildly elevated April–September.
*/

SELECT
    Product,
    Month,

    -- Average primary sales across all reps and territories for that month
    ROUND(AVG(Primary_Sales), 0)                                                AS Avg_Monthly_Primary,

    -- Territory split to see if geographic seasonal variation holds
    ROUND(AVG(CASE WHEN Territory = 'North' THEN Primary_Sales END), 0)         AS Avg_North,
    ROUND(AVG(CASE WHEN Territory = 'South' THEN Primary_Sales END), 0)         AS Avg_South,
    ROUND(AVG(CASE WHEN Territory = 'East'  THEN Primary_Sales END), 0)         AS Avg_East,
    ROUND(AVG(CASE WHEN Territory = 'West'  THEN Primary_Sales END), 0)         AS Avg_West,

    -- Secondary conversion in that month — does market pull also lift seasonally?
    ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3)       AS Monthly_Conv_Ratio,

    -- Revenue contribution of that month for the product
    ROUND(SUM(Revenue), 0)                                                      AS Monthly_Revenue

FROM pharma_sales
GROUP BY Product, Month
ORDER BY Product, Month;

/*
  EXPECTED OUTPUT  : 36 rows (3 products × 12 months). Clear visual pattern expected:
                     Wokderm Plus — highest Avg_Monthly_Primary in 2024-07 to 2024-09.
                     Decdan Lite  — highest in 2024-10 to 2025-02. North showing extra lift.
                     Spasmofirst  — mild summer bump, stable otherwise.
  BUSINESS REACTION: If peak months don't show expected lift, investigate:
                     (a) Was marketing spend deployed on time?
                     (b) Did rep activity (Doctor_Visits) increase in peak months?
                     (c) Was distributor stock pre-positioned before peak season?
                     Use this as input for next FY seasonal campaign planning.
*/




-- ============================================================================================================================
-- SECTION 8 : REVENUE CONCENTRATION RISK BY TERRITORY
-- ============================================================================================================================

/*
  OBJECTIVE    : Measure how concentrated total FY revenue is across territories and
                 identify over-dependence on specific geographies or reps.
  WHY IT MATTERS : If one territory contributes 40%+ of revenue and faces a disruption
                   (key rep attrition, distributor issue, regulatory change), the business
                   takes a disproportionate hit. Concentration risk is a strategic vulnerability.
  INSIGHT      : Revenue diversification score helps NSM decide where to invest next FY —
                 build up weaker territories or double down on strong ones.
*/

WITH Territory_Revenue AS (
    SELECT
        Territory,
        ROUND(SUM(Revenue), 0)                                                  AS Terr_Revenue
    FROM pharma_sales
    GROUP BY Territory
),

Total_Revenue AS (
    SELECT SUM(Terr_Revenue) AS Grand_Total FROM Territory_Revenue
)

SELECT
    t.Territory,
    t.Terr_Revenue,

    -- Revenue share of this territory in total FY revenue
    ROUND(t.Terr_Revenue * 100.0 / r.Grand_Total, 2)                           AS Revenue_Share_Pct,

    -- Concentration flag — high share = high dependency risk
    CASE
        WHEN t.Terr_Revenue * 100.0 / r.Grand_Total >= 35 THEN 'HIGH CONCENTRATION RISK'
        WHEN t.Terr_Revenue * 100.0 / r.Grand_Total >= 25 THEN 'MODERATE CONCENTRATION'
        ELSE 'DIVERSIFIED — LOW RISK'
    END                                                                         AS Concentration_Risk,

    -- Cumulative revenue share (running total) — Pareto-style analysis
    ROUND(SUM(t.Terr_Revenue) OVER (
        ORDER BY t.Terr_Revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) * 100.0 / r.Grand_Total, 2)                                               AS Cumulative_Revenue_Share_Pct

FROM Territory_Revenue t
CROSS JOIN Total_Revenue r
ORDER BY t.Terr_Revenue DESC;

/*
  EXPECTED OUTPUT  : 4 rows ordered by revenue. North should be highest. Running cumulative
                     will show if top 2 territories account for 60%+ of revenue (Pareto risk).
  BUSINESS REACTION: If top 2 territories = 60%+ revenue, NSM must present a territory
                     development plan for East and West in next FY annual operating plan.
                     Budget should allocate incremental marketing to underperforming territories
                     rather than just rewarding already-performing ones.
*/




-- ============================================================================================================================
-- SECTION 9 : REP CONSISTENCY SCORING — MONTH-OVER-MONTH STABILITY
-- ============================================================================================================================

/*
  OBJECTIVE    : Score each rep on performance consistency across all 12 months.
                 A rep who achieves 95% in some months but drops to 60% in others
                 is commercially unreliable — harder to plan territory coverage around.
  WHY IT MATTERS : Inconsistency in rep performance creates forecast error, distributor
                   relationship instability, and missed campaign execution. Consistent
                   average performers are often more valuable than volatile high performers.
  INSIGHT      : Standard deviation of monthly achievement ratio captures consistency.
                 Lower std_dev = more predictable = more plannable.
*/

WITH Monthly_Rep_Performance AS (
    SELECT
        Territory,
        Sales_Rep,
        Month,
        -- Monthly achievement ratio for this rep
        ROUND(SUM(Primary_Sales) * 100.0 / NULLIF(SUM(Target), 0), 1)          AS Monthly_Achievement_Pct,
        -- Monthly secondary conversion
        ROUND(SUM(Secondary_Sales) * 1.0 / NULLIF(SUM(Primary_Sales), 0), 3)   AS Monthly_Conv_Ratio
    FROM pharma_sales
    GROUP BY Territory, Sales_Rep, Month
),

Rep_Consistency AS (
    SELECT
        Territory,
        Sales_Rep,

        -- Full year average achievement
        ROUND(AVG(Monthly_Achievement_Pct), 1)                                  AS Avg_Achievement_Pct,

        -- Standard deviation — lower = more consistent rep
        -- High std_dev = the inconsistent/volatile rep profile
        ROUND(
            SQRT(
                AVG(Monthly_Achievement_Pct * Monthly_Achievement_Pct)
                - AVG(Monthly_Achievement_Pct) * AVG(Monthly_Achievement_Pct)
            ), 2
        )                                                                       AS Achievement_Std_Dev,

        -- Best and worst month — range shows volatility
        ROUND(MAX(Monthly_Achievement_Pct), 1)                                  AS Best_Month_Achievement,
        ROUND(MIN(Monthly_Achievement_Pct), 1)                                  AS Worst_Month_Achievement,

        -- Swing range — how wide is the gap between best and worst
        ROUND(MAX(Monthly_Achievement_Pct) - MIN(Monthly_Achievement_Pct), 1)  AS Performance_Swing,

        -- Average conversion ratio across months
        ROUND(AVG(Monthly_Conv_Ratio), 3)                                       AS Avg_Conv_Ratio,

        -- Count of months where achievement was below 80% — underperformance months
        COUNT(CASE WHEN Monthly_Achievement_Pct < 80 THEN 1 END)               AS Months_Below_80_Pct

    FROM Monthly_Rep_Performance
    GROUP BY Territory, Sales_Rep
),

Consistency_Scoring AS (
    SELECT
        *,
        -- Classify rep by consistency profile
        CASE
            WHEN Achievement_Std_Dev <= 8  AND Avg_Achievement_Pct >= 100 THEN 'STAR — Consistent High Performer'
            WHEN Achievement_Std_Dev <= 10 AND Avg_Achievement_Pct >= 85  THEN 'RELIABLE — Consistent Average'
            WHEN Achievement_Std_Dev > 15  THEN 'VOLATILE — Inconsistent Performer'
            WHEN Avg_Achievement_Pct < 75  THEN 'CHRONIC LOW — Needs PIP'
            ELSE 'DEVELOPING — Needs Coaching'
        END                                                                     AS Consistency_Profile,

        -- Rank reps within territory by consistency (lower std_dev = better rank)
        RANK() OVER (
            PARTITION BY Territory
            ORDER BY Achievement_Std_Dev ASC
        )                                                                       AS Consistency_Rank_In_Territory

    FROM Rep_Consistency
)

SELECT
    Territory,
    Sales_Rep,
    Avg_Achievement_Pct,
    Achievement_Std_Dev,
    Best_Month_Achievement,
    Worst_Month_Achievement,
    Performance_Swing,
    Months_Below_80_Pct,
    Avg_Conv_Ratio,
    Consistency_Profile,
    Consistency_Rank_In_Territory
FROM Consistency_Scoring
ORDER BY Territory, Consistency_Rank_In_Territory;

/*
  EXPECTED OUTPUT  : 20 rows. Top performers should show low std_dev (< 8) with high average.
                     Inconsistent reps (Vikram Joshi, Anita Nair, etc.) should show std_dev > 15
                     and wide Performance_Swing. Low performers should show Months_Below_80_Pct >= 6.
  BUSINESS REACTION:
    STAR profile           → Retention priority. Consider for ZSM/ABM fast-track.
    RELIABLE profile       → Backbone of territory. Reward with stable patch assignment.
    VOLATILE profile       → Coaching intervention. Check personal issues or patch difficulty.
    CHRONIC LOW profile    → Formal PIP with 90-day review milestone.
    DEVELOPING profile     → Buddy program with STAR or RELIABLE rep in same territory.
*/




-- ============================================================================================================================
-- SECTION 10 : ADVANCED DIAGNOSTIC — CTE + WINDOW FUNCTION COMBINED
--              FULL-YEAR COMMERCIAL HEALTH SCORECARD PER REP
-- ============================================================================================================================

/*
  OBJECTIVE    : Build a single unified commercial health score per rep combining:
                 achievement, consistency, conversion quality, activity level, and cost efficiency.
                 This is the NSM-level view — one row per rep, everything in one place.
  WHY IT MATTERS : In annual performance reviews, managers shouldn't flip between 10 reports.
                   This query delivers a 360-degree commercial scorecard in one result set.
                   It also enables objective stack-ranking across territories for incentive payout.
  INSIGHT      : A rep with high revenue but high bonus cost and low doctor visits is a
                 "push rep" — selling through schemes, not through relationships. Dangerous long-term.
*/

WITH

-- Layer 1: Aggregate full-year KPIs per rep
Rep_FY_Aggregate AS (
    SELECT
        Territory,
        Sales_Rep,
        SUM(Primary_Sales)                                                      AS Total_Primary,
        SUM(Secondary_Sales)                                                    AS Total_Secondary,
        ROUND(SUM(Revenue), 0)                                                  AS Total_Revenue,
        ROUND(SUM(Target), 0)                                                   AS Total_Target,
        ROUND(AVG(Doctor_Visits), 1)                                            AS Avg_Doctor_Visits,
        ROUND(SUM(Marketing_Spend), 0)                                          AS Total_Mkt_Spend,
        ROUND(SUM(Bonus_Expense), 0)                                            AS Total_Bonus
    FROM pharma_sales
    GROUP BY Territory, Sales_Rep
),

-- Layer 2: Compute derived KPIs
Rep_KPIs AS (
    SELECT
        Territory,
        Sales_Rep,
        Total_Primary,
        Total_Secondary,
        Total_Revenue,
        Total_Target,
        Avg_Doctor_Visits,
        Total_Mkt_Spend,
        Total_Bonus,

        -- Achievement percentage
        ROUND(Total_Primary * 100.0 / NULLIF(Total_Target, 0), 1)              AS Achievement_Pct,

        -- Secondary conversion ratio — market pull quality
        ROUND(Total_Secondary * 1.0 / NULLIF(Total_Primary, 0), 3)             AS Conv_Ratio,

        -- Revenue per doctor visit — efficiency of field activity
        ROUND(Total_Revenue / NULLIF(Avg_Doctor_Visits, 0), 0)                 AS Revenue_Per_DV,

        -- Bonus as % of revenue — push dependency indicator
        ROUND(Total_Bonus * 100.0 / NULLIF(Total_Revenue, 0), 2)               AS Bonus_Revenue_Pct,

        -- Marketing ROI at rep level
        ROUND(Total_Revenue / NULLIF(Total_Mkt_Spend, 0), 2)                   AS Mkt_ROI

    FROM Rep_FY_Aggregate
),

-- Layer 3: Apply window functions for cross-territory benchmarking
Rep_Ranked AS (
    SELECT
        *,

        -- Overall revenue rank across ALL territories (not just within)
        DENSE_RANK() OVER (ORDER BY Total_Revenue DESC)                         AS Overall_Revenue_Rank,

        -- Revenue rank within own territory
        DENSE_RANK() OVER (
            PARTITION BY Territory
            ORDER BY Total_Revenue DESC
        )                                                                       AS Territory_Revenue_Rank,

        -- Achievement rank within territory
        DENSE_RANK() OVER (
            PARTITION BY Territory
            ORDER BY Achievement_Pct DESC
        )                                                                       AS Territory_Achievement_Rank,

        -- Conversion rank within territory — who manages distributor best
        DENSE_RANK() OVER (
            PARTITION BY Territory
            ORDER BY Conv_Ratio DESC
        )                                                                       AS Territory_Conv_Rank,

        -- Territory average achievement for relative comparison
        ROUND(AVG(Achievement_Pct) OVER (PARTITION BY Territory), 1)           AS Territory_Avg_Achievement,

        -- Territory average conversion for benchmarking
        ROUND(AVG(Conv_Ratio) OVER (PARTITION BY Territory), 3)                AS Territory_Avg_Conv_Ratio

    FROM Rep_KPIs
),

-- Layer 4: Final commercial health classification
Final_Scorecard AS (
    SELECT
        *,
        -- Gap vs territory average — positive = outperformer, negative = laggard
        ROUND(Achievement_Pct - Territory_Avg_Achievement, 1)                  AS Achievement_Gap_Vs_Terr_Avg,

        -- Full commercial health tag combining multiple signals
        CASE
            WHEN Achievement_Pct >= 100
                 AND Conv_Ratio >= 0.85
                 AND Bonus_Revenue_Pct <= 2.0  THEN 'COMMERCIAL STAR'
            WHEN Achievement_Pct >= 90
                 AND Conv_Ratio >= 0.80        THEN 'STRONG PERFORMER'
            WHEN Achievement_Pct >= 80
                 AND Conv_Ratio >= 0.75        THEN 'DEVELOPING — NEEDS SUPPORT'
            WHEN Achievement_Pct < 80
                 AND Bonus_Revenue_Pct > 3.0   THEN 'PUSH-DEPENDENT — HIGH RISK'
            WHEN Achievement_Pct < 75          THEN 'LOW PERFORMER — PIP CANDIDATE'
            ELSE 'AVERAGE — MONITOR CLOSELY'
        END                                                                     AS Commercial_Health_Tag

    FROM Rep_Ranked
)

SELECT
    Overall_Revenue_Rank,
    Territory,
    Sales_Rep,
    Total_Revenue,
    Achievement_Pct,
    Territory_Avg_Achievement,
    Achievement_Gap_Vs_Terr_Avg,
    Conv_Ratio,
    Territory_Avg_Conv_Ratio,
    Avg_Doctor_Visits,
    Revenue_Per_DV,
    Bonus_Revenue_Pct,
    Mkt_ROI,
    Territory_Revenue_Rank,
    Territory_Achievement_Rank,
    Territory_Conv_Rank,
    Commercial_Health_Tag
FROM Final_Scorecard
ORDER BY Overall_Revenue_Rank;

/*
  EXPECTED OUTPUT  : 20 rows — every rep with full commercial profile.
                     Top-ranked reps should show COMMERCIAL STAR or STRONG PERFORMER tag.
                     Low performers should show PUSH-DEPENDENT or LOW PERFORMER tag.
                     East territory reps will cluster at lower Overall_Revenue_Rank.
  BUSINESS REACTION:
    COMMERCIAL STAR      → Maximum incentive payout. Consider for leadership pipeline.
    STRONG PERFORMER     → Standard incentive. Increase patch responsibility next FY.
    DEVELOPING           → Structured coaching plan. Pair with STAR in nearby territory.
    PUSH-DEPENDENT       → Immediate review of how they sell. High Bonus_Revenue_Pct
                           means they rely on schemes — not sustainable. Distributor
                           may refuse stock if push continues without market pull.
    LOW PERFORMER / PIP  → 90-day formal PIP with monthly milestones. If no improvement,
                           patch reassignment or exit planning.
*/




-- ============================================================================================================================
-- ============================================================================================================================
--
--  EXECUTIVE SUMMARY — STRATEGIC FINDINGS FROM FY 2024-25 ANALYSIS
--  (For NSM / Business Head Presentation)
--
-- ============================================================================================================================
-- ============================================================================================================================

/*
╔══════════════════════════════════════════════════════════════════════════════════════════════╗
║                    TOP 3 STRATEGIC RISKS IDENTIFIED                                        ║
╚══════════════════════════════════════════════════════════════════════════════════════════════╝

  RISK 1 — Q4 CHANNEL STUFFING (HIGH SEVERITY)
  ─────────────────────────────────────────────
  The Q4 vs Non-Q4 analysis (Section 3) is expected to show Primary_Sales elevated by 10–15%
  in Jan–Mar without proportionate Secondary improvement. This means distributors are absorbing
  stock for company billing targets — not because market is pulling. April 2025 will likely see
  suppressed secondary as distributors work off Q4 excess before accepting new stock.
  Action Required: CFO and Commercial Head must align on a "Secondary-first" Q4 policy for FY26.
  Do not allow field incentives tied purely to primary in Q4. Link Q4 incentives to secondary ratio.

  RISK 2 — EAST TERRITORY CHRONIC CONVERSION WEAKNESS (MEDIUM-HIGH SEVERITY)
  ────────────────────────────────────────────────────────────────────────────
  East territory consistently shows the lowest secondary conversion ratio across products and months
  (Sections 1, 5, 6). This is not a seasonal issue — it is structural. The distributor network in
  East is either under-capitalized (cannot carry stock), has weak retailer relationships, or reps
  are not doing secondary follow-through visits.
  Action Required: ZBM East must conduct distributor health audit in Q1 FY26. Consider reducing
  primary billing targets for East until secondary infrastructure improves. Over-billing a weak
  channel creates returns risk and damages company-distributor relationship.

  RISK 3 — REVENUE CONCENTRATION IN NORTH & SOUTH (MEDIUM SEVERITY)
  ──────────────────────────────────────────────────────────────────
  Revenue concentration analysis (Section 8) will likely show North + South contributing 55–60%
  of total FY revenue. Any disruption in these territories (rep attrition, distributor conflict,
  or regulatory issue) disproportionately impacts business. East is underdeveloped and West is
  merely stable — neither provides a meaningful buffer.
  Action Required: Next FY annual operating plan must include explicit West territory development
  goals with incremental marketing budget. East needs structural intervention before investment.


╔══════════════════════════════════════════════════════════════════════════════════════════════╗
║                    TOP 3 COMMERCIAL OPPORTUNITIES IDENTIFIED                               ║
╚══════════════════════════════════════════════════════════════════════════════════════════════╝

  OPPORTUNITY 1 — SEASONAL CAMPAIGN OPTIMIZATION FOR WOKDERM PLUS (HIGH POTENTIAL)
  ─────────────────────────────────────────────────────────────────────────────────
  Seasonal validation (Section 7) confirms Wokderm Plus shows strongest lift in July–September,
  especially in South and East. Currently, marketing spend increases in this window (Section 4),
  but the question is: is spend deployed early enough? Pre-season stocking (May–June) with
  targeted dermatologist outreach can capture early monsoon demand before competition.
  Opportunity: Shift 20% of Wokderm's monsoon marketing budget to May–June as pre-season seeding.
  Expected uplift: 5–8% incremental secondary in peak months if channel is pre-stocked.

  OPPORTUNITY 2 — LEVERAGE TOP PERFORMERS AS TERRITORY COACHES (HIGH POTENTIAL)
  ────────────────────────────────────────────────────────────────────────────────
  Consistency scoring (Section 9) and the commercial scorecard (Section 10) will identify
  COMMERCIAL STAR reps who show high achievement with low bonus dependency and strong conversion.
  These reps have cracked the "pull model" — doctors are prescribing, chemists are stocking,
  distributors are converting. Their sales approach can be replicated.
  Opportunity: Formal "field coaching" program where top-ranked reps spend 2 days/month with
  developing reps in their territory. Low-cost, high-impact capability building.

  OPPORTUNITY 3 — DECDAN LITE WINTER PUSH IN NORTH TERRITORY (MEDIUM POTENTIAL)
  ────────────────────────────────────────────────────────────────────────────────
  Seasonal data (Section 7) will confirm Decdan Lite peaks in October–February with extra lift in
  North territory. If the marketing calendar isn't aligned to this — i.e., if dermatology KOL
  engagement in North isn't happening in September–October — the season starts without prescription
  momentum. Given Decdan Lite's premium price point (₹187.90), even a 10% volume lift in winter
  generates disproportionate revenue vs high-volume low-margin products.
  Opportunity: Dedicate 2 KOL roundtables in North territory in September, just before winter season.
  Target dermatologists and GPs who manage melasma/pigmentation cases. Pre-position stock by October 1.


╔══════════════════════════════════════════════════════════════════════════════════════════════╗
║                    HOW LEADERSHIP SHOULD USE THIS ANALYSIS                                  ║
╚══════════════════════════════════════════════════════════════════════════════════════════════╝

  FOR NSM (National Sales Manager):
  ──────────────────────────────────
  → Use Section 1 (Territory Efficiency) and Section 8 (Revenue Concentration) for annual
    territory strategy presentation to leadership. Define territory-level revenue and volume
    targets for FY26 based on what FY25 data reveals structurally.
  → Use Section 10 (Commercial Scorecard) for annual performance review and incentive payout
    decisions. Objective, data-backed ranking removes subjectivity from appraisal discussions.

  FOR ZBM / ABM (Zonal / Area Business Managers):
  ─────────────────────────────────────────────────
  → Use Section 2 (Rep Ranking) and Section 9 (Consistency Scoring) for monthly team reviews.
    Focus coaching time on VOLATILE and DEVELOPING reps, not on CHRONIC LOW (they need HR, not coaching).
  → Use Section 6 (CTE Overstock Detection) for distributor management. Any rep with CHRONIC
    or WATCH status needs distributor visit with ABM presence before next billing cycle.

  FOR MARKETING TEAM:
  ────────────────────
  → Use Section 4 (Product ROI) and Section 7 (Seasonal Lift) for campaign calendar and
    budget allocation decisions. Justify spend by product based on Revenue_Per_Mkt_Rupee.
    Products with deteriorating ROI need creative strategy review, not more money.

  FOR FINANCE / TRADE TEAM:
  ──────────────────────────
  → Use Section 3 (Q4 Push Validation) and Section 5 (Inventory Risk) for channel inventory
    provisioning. If Q4 stuffing is confirmed, provision for 8–12% returns in Q1 FY26 from
    East and under-performing reps. Better to plan than to be surprised.

  FINAL NOTE:
  ───────────
  This analysis is designed to be run monthly — not just at year-end. The real power of this
  framework is early warning detection. If Section 6 flags a rep as WATCH in July, the ABM has
  time to intervene before it becomes CHRONIC by December. Data without action cadence is just
  a report. Data with a monthly review rhythm becomes a commercial management system.

*/

-- ============================================================================================================================
-- END OF SCRIPT — pharma_sales_analysis.sql
-- FY 2024-25 | pharma_analysis.pharma_sales
-- ============================================================================================================================



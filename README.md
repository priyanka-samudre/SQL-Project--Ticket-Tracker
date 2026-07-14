# Support Ticket Tracker — SQL Server Project

A Microsoft SQL Server (T-SQL) project that models a customer support / technical services operation: customers raise tickets, agents resolve them, and the business reports on volumes, resolution times and data quality. It includes a schema with constraints and indexes, a CSV dataset, reporting views, stored procedures, analytical report queries, performance-tuning examples, and an Excel dashboard built from the data.

Built as a portfolio piece for a SQL-focused — the domain deliberately mirrors that day-to-day work: investigating customer data issues, writing reports and dashboards, and keeping SQL correct and performant.

---

---

## Database design

Four tables. Three lookup tables (Customers, Agents, Categories) and one transactional table (Tickets) that references them.

### `Customers`
| Column | Type | Description |
|---|---|---|
| CustomerID | INT, PK | Unique auto-generated customer ID |
| CustomerName | NVARCHAR(100) | Company name |
| Tier | NVARCHAR(20) | Enterprise / Business / Standard (CHECK-constrained) |
| Region | NVARCHAR(50) | Geographic region |
| IsActive | BIT | 1 = active customer, 0 = inactive |

### `Agents`
| Column | Type | Description |
|---|---|---|
| AgentID | INT, PK | Unique auto-generated agent ID |
| AgentName | NVARCHAR(100) | Agent's full name |
| Team | NVARCHAR(50) | Service Desk / Technical Services |
| IsActive | BIT | 1 = current employee |

### `Categories`
| Column | Type | Description |
|---|---|---|
| CategoryID | INT, PK | Unique auto-generated category ID |
| CategoryName | NVARCHAR(50), UNIQUE | Type of issue (Bug, Performance, etc.) |

### `Tickets`
| Column | Type | Description |
|---|---|---|
| TicketID | INT, PK | Unique auto-generated ticket ID |
| CustomerID | INT, FK → Customers | Which customer raised it |
| CategoryID | INT, FK → Categories | Type of issue |
| AssignedAgentID | INT, FK → Agents, NULL | Assigned agent; NULL = unassigned |
| Subject | NVARCHAR(200) | Short description of the problem |
| Priority | NVARCHAR(10) | High / Medium / Low (CHECK-constrained) |
| Status | NVARCHAR(20) | Open / In Progress / Resolved / Closed (CHECK-constrained) |
| CreatedAt | DATETIME2 | When the ticket was raised (UTC) |
| ResolvedAt | DATETIME2, NULL | When it was resolved; NULL if still open |

Key design points: CHECK constraints reject invalid tiers/priorities/statuses and impossible dates (resolved before creation); foreign keys prevent orphan tickets; and foreign-key columns are explicitly indexed (SQL Server doesn't do this automatically).

---

## Views

### `vw_TicketDetails`
One readable row per ticket — joins in customer, category and agent names, and calculates `HoursToResolve`. Uses a LEFT JOIN to Agents so unassigned tickets aren't dropped.

Sample output (first rows):

| TicketID | Subject | CustomerName | CategoryName | AgentName | Status | HoursToResolve |
|---|---|---|---|---|---|---|
| 1 | Historic orders disappeared from view | Kite Energy | Data Issue | James Whitfield | Resolved | 124 |
| 2 | How do I add a new user? | Bristol Logistics | How-To Question | James Whitfield | Open | NULL |
| 3 | Search timing out during peak hours | Iris Insurance | Performance | Sofia Lindqvist | Closed | 146 |
| 4 | Need monthly sales report by region | Lumen Schools | Report Request | James Whitfield | Closed | 25 |
| 5 | Error 500 when saving a new order | Fjord Systems | Bug | Dev Patel | Resolved | 10 |

### `vw_OpenTickets`
The live work queue — only Open / In Progress tickets, with an `AgeHours` column. Built on top of `vw_TicketDetails`.

Sample output (first rows):

| TicketID | CustomerName | Tier | CategoryName | Priority | Status | AgentName | AgeHours |
|---|---|---|---|---|---|---|---|
| 2 | Bristol Logistics | Business | How-To Question | Medium | Open | James Whitfield | 7373 |
| 21 | Bristol Logistics | Business | Data Issue | High | Open | Elena Kovacs | 4001 |
| 23 | Metro Transport | Enterprise | Report Request | Low | In Progress | Elena Kovacs | 3327 |
| 24 | Nordic Freight | Standard | Data Issue | Medium | Open | Unassigned | 1719 |
| 26 | Harbour Hotels | Standard | How-To Question | Medium | Open | Unassigned | 1711 |

---

## Stored procedures

### `usp_CreateTicket`
Creates a ticket after validating inputs (non-empty subject, existing active customer, existing category), and returns the new TicketID via an output parameter.

```sql
DECLARE @id INT;
EXEC dbo.usp_CreateTicket @CustomerID=1, @CategoryID=2,
     @Subject=N'Report totals look wrong', @Priority=N'High', @NewTicketID=@id OUTPUT;
SELECT @id AS NewTicketID;
```
Result:

| NewTicketID |
|---|
| 3001 |

### `usp_ResolveTicket`
Marks an active ticket Resolved inside a transaction with TRY/CATCH; assigns the resolving agent if the ticket was unassigned; raises a clear error if the ticket isn't found or isn't active.

```sql
EXEC dbo.usp_ResolveTicket @TicketID=3001, @AgentID=1;
```
Result: `(1 row affected)` — Status set to Resolved, ResolvedAt stamped. Passing a closed/invalid ID returns:
`Msg 50010: Ticket not found or is not in an active status.`

### `usp_MonthlySummaryReport`
Tickets raised, resolved, and average resolution hours per month and category, over a date range. Uses a half-open date range so the last day isn't missed.

```sql
EXEC dbo.usp_MonthlySummaryReport @FromDate='2026-01-01', @ToDate='2026-06-30';
```
Sample output (first rows):

| TicketMonth | CategoryName | TicketsRaised | TicketsResolved | AvgHoursToResolve |
|---|---|---|---|---|
| 2026-01 | Bug | 50 | 40 | 35 |
| 2026-01 | Data Issue | 45 | 35 | 42 |
| 2026-01 | How-To Question | 48 | 36 | 48 |
| 2026-01 | Performance | 51 | 47 | 47 |
| 2026-01 | Report Request | 57 | 48 | 53 |

---

## Report queries (`05_report_queries.sql`)

**1. Ticket volume by customer** (JOIN, GROUP BY, conditional count):

| CustomerName | Tier | TotalTickets | OpenNow |
|---|---|---|---|
| Cornwall Foods | Standard | 222 | 36 |
| Metro Transport | Enterprise | 214 | 35 |
| Acme Retail | Enterprise | 211 | 30 |
| Bristol Logistics | Business | 204 | 33 |
| Nordic Freight | Standard | 204 | 28 |

**2. Average resolution time by priority** (AVG/MAX, NULL handling):

| Priority | Tickets | AvgHoursToResolve | WorstCaseHours |
|---|---|---|---|
| High | 365 | 13 | 24 |
| Medium | 1368 | 37 | 72 |
| Low | 742 | 83 | 168 |

**3. Agent leaderboard** (window function `RANK`):

| AgentName | Team | TicketsResolved | AvgHours | OverallRank |
|---|---|---|---|---|
| Sofia Lindqvist | Service Desk | 433 | 47 | 1 |
| James Whitfield | Technical Services | 416 | 49 | 2 |
| Marcus Boateng | Service Desk | 416 | 51 | 3 |
| Dev Patel | Service Desk | 407 | 45 | 4 |
| Elena Kovacs | Service Desk | 405 | 46 | 5 |

**5. Month-over-month trend** (`LAG`):

| TicketMonth | Tickets | PreviousMonth | Change |
|---|---|---|---|
| 2025-07 | 154 | NULL | |
| 2025-08 | 241 | 154 | +87 |
| 2025-09 | 245 | 241 | +4 |
| 2025-10 | 247 | 245 | +2 |
| 2025-11 | 259 | 247 | +12 |

**6. Data quality check** (UNION ALL of rule-breakers):

| Issue | Rows |
|---|---|
| Resolved/Closed but missing ResolvedAt | 60 |
| In Progress but no agent assigned | 17 |
| Open ticket older than 30 days | 213 |

(The sample data is deliberately given a few "dirty" rows so these checks find real issues, as production data always does.)

---

## Excel dashboard summary

`SupportTicketReport.xlsx` demonstrates the SQL → Excel reporting workflow on this dataset. Five tabs:

| Tab | Contents |
|---|---|
| **Dashboard** | 5 KPI cards + 5 charts (status pie, category bar, avg-hours-by-priority column, monthly-trend line, tier column) |
| **Raw Data (SQL export)** | The 3,000 tickets as exported from SQL Server (IDs, dates as text) — the "before" state |
| **Cleaned Data** | After cleaning: lookup IDs joined to names, dates fixed, helper columns (Month, HoursToResolve, IsResolved) and a DataQualityFlag |
| **PivotSummary** | Summary tables (COUNTIF / AVERAGEIFS) the charts read from |
| **Notes** | Methodology and key findings |

Workflow: extract the joined `vw_TicketDetails` from SQL Server → clean and add helper columns in Excel → summarise with PivotTables → visualise with PivotCharts and formula-driven KPIs → arrange on one Dashboard sheet.

Headline KPIs from the dataset:

| Metric | Value |
|---|---|
| Total Tickets | 3,000 |
| Open Now | 465 |
| Resolved / Closed | 2,535 |
| Avg Hours to Resolve | 47.3 |
| Data-Quality Issues flagged | 77 |

---

## Skills demonstrated

Schema design with constraints and indexing · foreign-key relationships · views and calculated columns · stored procedures with validation, transactions and error handling · window functions (RANK, ROW_NUMBER, LAG) · CTEs · aggregation and conditional counts · data-quality investigation · query performance tuning (SARGability, set-based rewrites, covering indexes) · loading flat files · and reporting the results in Excel with PivotTables and charts.

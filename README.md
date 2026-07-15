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

Output (first rows):

<img width="1000" height="200" alt="image" src="https://github.com/user-attachments/assets/27121343-1efb-4f73-9dcf-4599b304d86f" />

### `vw_OpenTickets`
The live work queue — only Open / In Progress tickets, with an `AgeHours` column. Built on top of `vw_TicketDetails`.

Output (first rows):

<img width="1000" height="200" alt="image" src="https://github.com/user-attachments/assets/d00edee5-895b-483a-9fd8-b2e70331a058" />



---

## Stored procedures

### `usp_MonthlySummaryReport`
Tickets raised, resolved, and average resolution hours per month and category, over a date range. Uses a half-open date range so the last day isn't missed.

```sql
EXEC dbo.usp_MonthlySummaryReport @FromDate='2026-01-01', @ToDate='2026-06-30';
```
Output (first rows):
<img width="800" height="200" alt="image" src="https://github.com/user-attachments/assets/3928fb8a-8529-42e9-97d2-1c57bc4b3575" />



---

## Report queries

**1. Ticket volume by customer** (JOIN, GROUP BY, conditional count):

<img width="600" height="150" alt="image" src="https://github.com/user-attachments/assets/11b2b9ef-b963-43aa-b486-6eec8e60961a" />


**2. Average resolution time by priority** (AVG/MAX, NULL handling):

<img width="600" height="200" alt="image" src="https://github.com/user-attachments/assets/ea6f81dc-20b7-4284-b135-3d85fcf530b2" />


**3. Agent leaderboard** (window function `RANK`):

<img width="800" height="200" alt="image" src="https://github.com/user-attachments/assets/794cbf39-d343-484d-a641-e86c33232ab9" />


**4. Data quality check** (UNION ALL of rule-breakers):

<img width="400" height="100" alt="image" src="https://github.com/user-attachments/assets/2242f16f-f805-4ff7-aaa5-c0bc0a7a7b25" />

---

## Excel dashboard summary

`SupportTicketReport.xlsx` demonstrates the SQL → Excel reporting workflow on this dataset. Five tabs:

| Tab | Contents |
|---|---|
| **Dashboard** | 5 KPI cards + 5 charts (status pie, category bar, avg-hours-by-priority column, monthly-trend line, tier column) |
| **Raw Data (SQL export)** |  
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




# Support Ticket Tracker (T-SQL)

A Microsoft SQL Server project that models a customer support ticket system: customers raise tickets, agents work them, and reports track volumes, resolution times and data quality.

I chose this domain because it matches the day-to-day of a Technical Services role — investigating customer issues, writing reports, and keeping the SQL behind them fast and correct.

## What's in the project

| File | What it shows |
|---|---|
| `sql/01_schema.sql` | 4 tables with primary keys, foreign keys, CHECK constraints and indexes |
| `sql/02_import_data.sql` | Loads the sample data from the CSV files using BULK INSERT |
| `data/*.csv` | The sample data itself: 15 customers, 6 agents, 5 categories, 3,000 tickets (incl. some deliberately dirty rows for the data-quality check) |
| `sql/03_views.sql` | Two reporting views — a detailed ticket view and a live "open work" queue |
| `sql/04_stored_procedures.sql` | Create ticket, resolve ticket (transaction + TRY/CATCH), and a monthly summary report with parameters |
| `sql/05_report_queries.sql` | 6 report queries: joins, GROUP BY, CASE, window functions (RANK, ROW_NUMBER, LAG), CTEs, and a data-quality check |
| `sql/06_performance_basics.sql` | 3 before/after examples showing why some queries are slow and how to fix them |

## How to run it

1. Install SQL Server (Developer Edition is free) and SSMS, or use Azure SQL.
2. Run `sql/01_schema.sql` to create the database and tables.
3. Open `sql/02_import_data.sql`, change `@DataPath` to your local `data` folder, and run it (or import each CSV via SSMS: right-click database → Tasks → Import Flat File).
4. Run `03_views.sql` then `04_stored_procedures.sql`.
5. `05` and `06` are queries to run and explore — for `06`, turn on **Include Actual Execution Plan** (Ctrl+M) to see the difference between the slow and fast versions.

Quick test once it's set up:

```sql
DECLARE @id INT;
EXEC dbo.usp_CreateTicket
     @CustomerID = 1, @CategoryID = 2,
     @Subject = N'Dashboard totals look wrong', @Priority = N'High',
     @NewTicketID = @id OUTPUT;

SELECT * FROM dbo.vw_OpenTickets WHERE TicketID = @id;

EXEC dbo.usp_ResolveTicket @TicketID = @id, @AgentID = 1;

EXEC dbo.usp_MonthlySummaryReport @FromDate = '2026-01-01', @ToDate = '2026-06-30';
```

## Things I made sure to do (and can explain in detail)

- **Constraints in the database, not just the app** — CHECK constraints stop bad statuses, priorities and impossible dates (resolved before created) from ever being saved.
- **Indexes on foreign keys** — SQL Server doesn't add these automatically, and they make the join-heavy report queries much faster.
- **LEFT JOIN where it matters** — unassigned tickets and customers with zero tickets still show up in reports.
- **TRY/CATCH + transaction in `usp_ResolveTicket`** — the update either fully happens or fully rolls back, and the error is passed back to the caller.
- **Half-open date ranges** (`>= @From AND < @To + 1 day`) — accurate to the last second of the day and lets indexes be used.
- **Set-based over loops** — Example 2 in the performance file shows the same job done row-by-row vs in one pass.
- **Realistic messy data** — the CSVs include a small number of deliberately broken rows (resolved tickets missing dates, in-progress tickets with no agent) so the data-quality report finds genuine issues, like it would in production.

## What I'd add next

- A `TicketStatusHistory` table so every status change is audited
- SLA targets per priority, with breach reporting
- A stored procedure for paginated customer data extracts (OFFSET/FETCH)
- Unit tests with tSQLt

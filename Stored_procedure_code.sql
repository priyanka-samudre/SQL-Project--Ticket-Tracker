
USE TicketTracker;
GO

/* 
   usp_MonthlySummaryReport - management report for a date range.
   Uses a "half-open" date range (>= start, < day after end) which is both
   accurate and index-friendly.
 */
CREATE OR ALTER PROCEDURE dbo.usp_MonthlySummaryReport
    @FromDate DATE,
    @ToDate   DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate > @ToDate
        THROW 50020, '@FromDate must be on or before @ToDate.', 1;

    SELECT
        FORMAT(CreatedAt, 'yyyy-MM')                       AS TicketMonth,
        CategoryName,
        COUNT(*)                                           AS TicketsRaised,
        SUM(CASE WHEN Status IN (N'Resolved', N'Closed')
                 THEN 1 ELSE 0 END)                        AS TicketsResolved,
        AVG(HoursToResolve)                                AS AvgHoursToResolve
    FROM dbo.vw_TicketDetails
    WHERE CreatedAt >= @FromDate
      AND CreatedAt <  DATEADD(DAY, 1, @ToDate)
    GROUP BY FORMAT(CreatedAt, 'yyyy-MM'), CategoryName
    ORDER BY TicketMonth, CategoryName;
END;
GO


EXEC dbo.usp_MonthlySummaryReport
    @FromDate = '2025-01-01',
    @ToDate   = '2025-01-31';
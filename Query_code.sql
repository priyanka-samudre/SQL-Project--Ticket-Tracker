

USE TicketTracker;
GO

/* 
   1. Ticket volume by customer (JOIN + GROUP BY + ORDER BY)
 */
SELECT
    c.CustomerName,
    c.Tier,
    COUNT(t.TicketID) AS TotalTickets,
    SUM(CASE WHEN t.Status IN (N'Open', N'In Progress') THEN 1 ELSE 0 END) AS OpenNow
FROM dbo.Customers c
LEFT JOIN dbo.Tickets t ON t.CustomerID = c.CustomerID
GROUP BY c.CustomerName, c.Tier
ORDER BY TotalTickets DESC;
GO

/* 
   2. Average resolution time by priority (CASE + AVG + NULL handling)
      Note: AVG ignores NULLs, so unresolved tickets don't distort the average.
 */
SELECT
    Priority,
    COUNT(*)                                       AS Tickets,
    AVG(DATEDIFF(HOUR, CreatedAt, ResolvedAt))     AS AvgHoursToResolve,
    MAX(DATEDIFF(HOUR, CreatedAt, ResolvedAt))     AS WorstCaseHours
FROM dbo.Tickets
WHERE ResolvedAt IS NOT NULL
GROUP BY Priority
ORDER BY CASE Priority WHEN N'High' THEN 1 WHEN N'Medium' THEN 2 ELSE 3 END;
GO

/* 
   3. Agent leaderboard (window function: RANK)
*/
SELECT
    a.AgentName,
    a.Team,
    COUNT(*)                                  AS TicketsResolved,
    AVG(DATEDIFF(HOUR, t.CreatedAt, t.ResolvedAt)) AS AvgHours,
    RANK() OVER (ORDER BY COUNT(*) DESC)      AS OverallRank
FROM dbo.Tickets t
JOIN dbo.Agents a ON a.AgentID = t.AssignedAgentID
WHERE t.ResolvedAt IS NOT NULL
GROUP BY a.AgentName, a.Team
ORDER BY OverallRank;
GO

/*
   


/* 
   4. Data quality check - finds tickets that break business rules.
      (Useful to show the "investigate data issues" side of the role.)
 */
SELECT 'Resolved/Closed but missing ResolvedAt' AS Issue, COUNT(*) AS Rows
FROM dbo.Tickets
WHERE Status IN (N'Resolved', N'Closed') AND ResolvedAt IS NULL

UNION ALL

SELECT 'In Progress but no agent assigned', COUNT(*)
FROM dbo.Tickets
WHERE Status = N'In Progress' AND AssignedAgentID IS NULL

UNION ALL

SELECT 'Open ticket older than 30 days', COUNT(*)
FROM dbo.Tickets
WHERE Status = N'Open' AND CreatedAt < DATEADD(DAY, -30, SYSUTCDATETIME());
GO

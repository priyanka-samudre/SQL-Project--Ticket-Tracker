
USE TicketTracker;
GO

/* 
vw_TicketDetails - one easy-to-read row per ticket with all names joined in.
 */
CREATE OR ALTER VIEW dbo.vw_TicketDetails
AS
SELECT
    t.TicketID,
    t.Subject,
    t.Priority,
    t.Status,
    t.CreatedAt,
    t.ResolvedAt,
    c.CustomerName,
    c.Tier,
    c.Region,
    cat.CategoryName,
    a.AgentName,
    a.Team,
    
    DATEDIFF(HOUR, t.CreatedAt, t.ResolvedAt) AS HoursToResolve  -- How long the ticket took (NULL if still open)
FROM dbo.Tickets t
JOIN dbo.Customers  c   ON c.CustomerID  = t.CustomerID
JOIN dbo.Categories cat ON cat.CategoryID = t.CategoryID
LEFT JOIN dbo.Agents a  ON a.AgentID      = t.AssignedAgentID;  -- LEFT JOIN: keep unassigned tickets
GO

/* 
   vw_OpenTickets - the live work queue, oldest first.
 */
CREATE OR ALTER VIEW dbo.vw_OpenTickets
AS
SELECT
    TicketID,
    CustomerName,
    Tier,
    CategoryName,
    Priority,
    Status,
    AgentName,
    CreatedAt,
    DATEDIFF(HOUR, CreatedAt, SYSUTCDATETIME()) AS AgeHours
FROM dbo.vw_TicketDetails
WHERE Status IN (N'Open', N'In Progress');
GO

SELECT *
FROM dbo.vw_TicketDetails;

SELECT *
FROM dbo.vw_OpenTickets;


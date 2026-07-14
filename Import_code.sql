USE TicketTracker;
GO

DECLARE @DataPath NVARCHAR(260) = N'C:\Users\priya\Downloads\sql-ticket-tracker\sql-ticket-tracker\data\';



DECLARE @sql NVARCHAR(MAX);

SET @sql = N'
BULK INSERT dbo.Customers
FROM ''' + @DataPath + N'customers.csv''
WITH (FORMAT = ''CSV'', FIRSTROW = 2, KEEPIDENTITY, TABLOCK);';
EXEC sys.sp_executesql @sql;

SET @sql = N'
BULK INSERT dbo.Agents
FROM ''' + @DataPath + N'agents.csv''
WITH (FORMAT = ''CSV'', FIRSTROW = 2, KEEPIDENTITY, TABLOCK);';
EXEC sys.sp_executesql @sql;

SET @sql = N'
BULK INSERT dbo.Categories
FROM ''' + @DataPath + N'categories.csv''
WITH (FORMAT = ''CSV'', FIRSTROW = 2, KEEPIDENTITY, TABLOCK);';
EXEC sys.sp_executesql @sql;

SET @sql = N'
BULK INSERT dbo.Tickets
FROM ''' + @DataPath + N'tickets.csv''
WITH (FORMAT = ''CSV'', FIRSTROW = 2, KEEPIDENTITY, TABLOCK);';
EXEC sys.sp_executesql @sql;
GO

/* Check everything landed */

SELECT 'Customers'  AS TableName, COUNT(*) AS Rows FROM dbo.Customers
UNION ALL SELECT 'Agents',     COUNT(*) FROM dbo.Agents
UNION ALL SELECT 'Categories', COUNT(*) FROM dbo.Categories
UNION ALL SELECT 'Tickets',    COUNT(*) FROM dbo.Tickets;

/* Expected: 15 customers, 6 agents, 5 categories, 3000 tickets.

GO

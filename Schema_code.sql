/* 
   01_schema.sql
   
   4 tables:
     Customers  - who raises tickets
     Agents     - who works on tickets
     Categories - type of issue
     Tickets    - the main table
 */

IF DB_ID('TicketTracker') IS NULL
    CREATE DATABASE TicketTracker;
GO

USE TicketTracker;
GO

CREATE TABLE dbo.Customers
(
    CustomerID    INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName  NVARCHAR(100) NOT NULL,
    Tier          NVARCHAR(20)  NOT NULL,  
    Region        NVARCHAR(50)  NOT NULL,
    IsActive      BIT           NOT NULL DEFAULT (1),

   
    CONSTRAINT CK_Customers_Tier CHECK (Tier IN (N'Enterprise', N'Business', N'Standard'))
);
GO

CREATE TABLE dbo.Agents
(
    AgentID    INT IDENTITY(1,1) PRIMARY KEY,
    AgentName  NVARCHAR(100) NOT NULL,
    Team       NVARCHAR(50)  NOT NULL,      -- Service Desk / Technical Services
    IsActive   BIT           NOT NULL DEFAULT (1)
);
GO

CREATE TABLE dbo.Categories
(
    CategoryID    INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName  NVARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE dbo.Tickets
(
    TicketID         INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID       INT           NOT NULL,
    CategoryID       INT           NOT NULL,
    AssignedAgentID  INT           NULL,     -- NULL until someone picks it up
    Subject          NVARCHAR(200) NOT NULL,
    Priority         NVARCHAR(10)  NOT NULL DEFAULT (N'Medium'),
    Status           NVARCHAR(20)  NOT NULL DEFAULT (N'Open'),
    CreatedAt        DATETIME2(0)  NOT NULL DEFAULT (SYSUTCDATETIME()),
    ResolvedAt       DATETIME2(0)  NULL,

   
    CONSTRAINT FK_Tickets_Customers  FOREIGN KEY (CustomerID)      REFERENCES dbo.Customers (CustomerID),
    CONSTRAINT FK_Tickets_Categories FOREIGN KEY (CategoryID)      REFERENCES dbo.Categories (CategoryID),
    CONSTRAINT FK_Tickets_Agents     FOREIGN KEY (AssignedAgentID) REFERENCES dbo.Agents (AgentID),

    CONSTRAINT CK_Tickets_Priority CHECK (Priority IN (N'High', N'Medium', N'Low')),
    CONSTRAINT CK_Tickets_Status   CHECK (Status IN (N'Open', N'In Progress', N'Resolved', N'Closed')),

    -- A ticket can't be resolved before it was created
    CONSTRAINT CK_Tickets_Dates CHECK (ResolvedAt IS NULL OR ResolvedAt >= CreatedAt)
);
GO

/* 
   Indexes
 */

CREATE INDEX IX_Tickets_CustomerID ON dbo.Tickets (CustomerID);
CREATE INDEX IX_Tickets_AgentID    ON dbo.Tickets (AssignedAgentID);
CREATE INDEX IX_Tickets_Status     ON dbo.Tickets (Status, CreatedAt);
GO

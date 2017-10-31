/*
-----------------------------------------------------------------------------------------------------------
Autor:................Romano Sabbatella
Date:.................2017.04.19
Description:..........This script creates all the tables you need for the SQLScheduler
Versions:.............2017.04.19 / RS Creat script
......................2017.04.20 / RS Added some fields in the table scheduler
......................xxxx.xx.xx / xx
-----------------------------------------------------------------------------------------------------------
*/
-- Use the Database
USE SQLScheduler

/*
-- Drop all tables
*/

-- Drop the Table Jobprotocol if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Exceptionlog') AND TYPE IN (N'U')) BEGIN
	-- Drop Constraint
	ALTER TABLE Exceptionlog Drop CONSTRAINT Exceptionlog_Jobs
	ALTER TABLE Exceptionlog Drop CONSTRAINT Exceptionlog_Jobhistory
	DROP TABLE Exceptionlog
END

-- Drop the Table Jobhistory if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Jobhistory') AND TYPE IN (N'U')) BEGIN	
	-- Drop Constraint
	ALTER TABLE Jobhistory DROP CONSTRAINT Jobhistory_Jobs
	ALTER TABLE Jobhistory DROP CONSTRAINT Jobhistory_Schedules
	DROP TABLE Jobhistory
END

-- Drop the Table Schedules if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Schedules') AND TYPE IN (N'U')) BEGIN
	-- Drop Constraint
	ALTER TABLE Schedules DROP CONSTRAINT Schedules_Owners 
	ALTER TABLE Schedules DROP CONSTRAINT Schedules_Jobs 
	ALTER TABLE Schedules DROP CONSTRAINT Schedules_ScheduleStatus 
	ALTER TABLE Schedules DROP CONSTRAINT Schedules_Databases 
	ALTER TABLE Schedules DROP CONSTRAINT Schedules_Schedules
	DROP TABLE Schedules
END

-- Drop the Table Owners if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Owners') AND TYPE IN (N'U')) BEGIN
	DROP TABLE Owners
END

-- Drop the Table Databases if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Databases') AND TYPE IN (N'U')) BEGIN
	DROP TABLE [Databases]
END

-- Drop the Table Schedulestatus if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Schedulestatus') AND TYPE IN (N'U')) BEGIN
	DROP TABLE Schedulestatus
END

-- Drop the Table Jobs if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Jobs') AND TYPE IN (N'U')) BEGIN
	DROP TABLE Jobs
END

/*
-- TABLE Jobs
*/
--Create the table Databases
CREATE TABLE [Databases](
	DatabaseID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Name] varchar(30) NOT NULL,
	[Description] varchar(255)
)

-- Create the Table Jobs
CREATE TABLE Jobs(
	JobID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Name] varchar(255),
	[Description] varchar(255),
	CreationDate datetime
)

/*
-- TABLE Jobhistory
*/
-- Create the Table Jobhistory
CREATE TABLE Jobhistory(
	JobhistoryID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	JobID int NOT NULL,
	ScheduleID int NOT NULL,
	ErrorYN bit NOT NULL,
	[Description] varchar(255),
	StartDateTime datetime,
	EndDateTime datetime
)

/*
-- TABLE Jobprotocol
*/
-- Create the Table Jobhistory
CREATE TABLE Exceptionlog(
	ExceptionLogID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	JobID int NOT NULL,
	JobName varchar(255),
	RunDateTime datetime,
	ErrorDateTime datetime NOT NULL,
	ErrorMessage varchar(max) NOT NULL,
	[Name] varchar(30) NOT NULL,
	SpName varchar(50) NOT NULL,
	JobhistoryID int NOT NULL,
	[Description] varchar(255)
)

/*
-- TABLE Owners
*/
-- Create the Table Owners
CREATE TABLE Owners(
	OwnerID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	UserName varchar(50) NOT NULL,
	[Password] varchar(50) NOT NULL,
	Shema varchar(50) NOT NULL,
	[Description] varchar(255),
	EMail varchar(100)
)

/*
-- TABLE Schedules
*/
-- Create the Table Schedules
CREATE TABLE Schedules(
	ScheduleID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	OwnerID int NOT NULL,
	JobID int NOT NULL,
	SchedulestatusID int NOT NULL,
	Intervall int NOT NULL,
	RunDateTime datetime NOT NULL,
	DatabaseID int NOT NULL,
	SpName varchar(50) NOT NULL,
	ScheduleTyp int NOT NULL,
	StartDateTime datetime NOT NULL,
	[Description] varchar(255),
	PrevScheduleID int,
	ExpireDateTime datetime,
	[DayOfWeek] int,
	DayTime varchar(10)
)

/*
-- TABLE Schedulestatus
*/
-- Create the Table Schedulestatus
CREATE TABLE Schedulestatus(
	SchedulestatusID int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Status] varchar(30) NOT NULL,
	[Description] varchar(255)
)

/*
-- ADD Foreign Keys
*/
-- Table Schedules
ALTER TABLE Schedules ADD CONSTRAINT Schedules_Owners FOREIGN KEY (OwnerID) REFERENCES Owners(OwnerID)
ALTER TABLE Schedules ADD CONSTRAINT Schedules_Jobs FOREIGN KEY (JobID) REFERENCES Jobs(JobID)
ALTER TABLE Schedules ADD CONSTRAINT Schedules_Schedules FOREIGN KEY (PrevScheduleID) REFERENCES Schedules(ScheduleID)
ALTER TABLE Schedules ADD CONSTRAINT Schedules_ScheduleStatus FOREIGN KEY (SchedulestatusID) REFERENCES Schedulestatus(SchedulestatusID)
ALTER TABLE Schedules ADD CONSTRAINT Schedules_Databases FOREIGN KEY (DatabaseID) REFERENCES [Databases](DatabaseID)
-- Table Jobhistory
ALTER TABLE Jobhistory ADD CONSTRAINT Jobhistory_Jobs FOREIGN KEY (JobID) REFERENCES Jobs(JobID)
ALTER TABLE Jobhistory ADD CONSTRAINT Jobhistory_Schedules FOREIGN KEY (ScheduleID) REFERENCES Schedules(ScheduleID)
-- Table Jobprotocol
ALTER TABLE Exceptionlog ADD CONSTRAINT Exceptionlog_Jobs FOREIGN KEY (JobId) REFERENCES Jobs(JobID)
ALTER TABLE Exceptionlog ADD CONSTRAINT Exceptionlog_Jobhistory FOREIGN KEY (JobhistoryID) REFERENCES Jobhistory(JobhistoryID)

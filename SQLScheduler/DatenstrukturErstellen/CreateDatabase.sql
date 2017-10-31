/*
-----------------------------------------------------------------------------------------------------------
Autor:................Romano Sabbatella
Date:.................2017.04.19
Description:..........Creates the database SQLScheduler
Versions:.............2017.04.19 / RS Creat script
......................xxxx.xx.xx / xx xxxxxx
-----------------------------------------------------------------------------------------------------------
*/

USE master
/*
-- Drop the database if it exist
*/
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'SQLScheduler') BEGIN
	DROP DATABASE SQLScheduler
END
/*
-- Create the database SQLScheduler
*/
CREATE DATABASE SQLScheduler
GO
ALTER DATABASE SQLScheduler SET TRUSTWORTHY ON
GO

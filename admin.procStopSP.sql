IF OBJECT_ID('admin.procStopSP') IS NOT NULL
	DROP PROC admin.procStopSP
GO
CREATE PROC admin.procStopSP
(
	@spid INT
)
WITH EXECUTE AS owner, ENCRYPTION 
AS
BEGIN
	DECLARE @sql AS VARCHAR(1000)

	SELECT @sql = '
	CREATE PROC admin.procStopSP81
	WITH EXECUTE AS owner
	AS
	KILL ' + CONVERT(VARCHAR(10),@spid) + '
	'
	EXEC (@sql)
	EXEC admin.procStopSP81
	DROP PROC admin.procStopSP81
END
GO


/*
Unit test


admin.procStopSP 128  

*/

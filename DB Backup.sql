--EXEC dbo.EMEA_FilerInformation @fileName ='PNL_EMEA_*.*'
--EXEC dbo.FilerInformation @fileName ='PNL_EMEA_*.*'


--last backup time
SELECT 
	sdb.Name AS DatabaseName,
	COALESCE(CONVERT(VARCHAR(12), MAX(bus.backup_finish_date), 101),'-') AS LastBackUpTime,
	bus.server_name,
	bus.recovery_model
FROM sys.sysdatabases sdb
LEFT OUTER JOIN msdb.dbo.backupset bus ON bus.database_name = sdb.name
WHERE 1=1 -- AND sdb.Name = 'MSTR_MD'
GROUP BY sdb.Name
,bus.server_name
,bus.recovery_model

--------------------------------------------------------------------------

-- Get Backup History for required database
DECLARE @db_name VARCHAR(100) = DB_NAME()

SELECT TOP ( 50 )
	s.database_name,
	m.physical_device_name,
	cast(CAST(s.backup_size / 1000000 AS INT) as varchar(14))
	+ ' ' + 'MB' as bkSize,
	CAST(DATEDIFF(second, s.backup_start_date,
	s.backup_finish_date) AS VARCHAR(4)) + ' '
	+ 'Seconds' TimeTaken,
	s.backup_start_date,
	CAST(s.first_lsn AS varchar(50)) AS first_lsn,
	CAST(s.last_lsn AS varchar(50)) AS last_lsn,
	CASE s.[type]
	WHEN 'D' THEN 'Full'
	WHEN 'I' THEN 'Differential'
	WHEN 'L' THEN 'Transaction Log'
	END as BackupType,
	s.server_name,
	s.recovery_model
FROM 
	msdb.dbo.backupset s
	inner join msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE s.database_name = @db_name
ORDER BY backup_start_date desc,
	backup_finish_date




SELECT B.name as Database_Name, ISNULL(STR(ABS(DATEDIFF(day, GetDate(),
MAX(Backup_finish_date)))), 'NEVER') as DaysSinceLastBackup,
ISNULL(Convert(char(10), MAX(backup_finish_date), 101), 'NEVER') as LastBackupDate
FROM master.dbo.sysdatabases B LEFT OUTER JOIN msdb.dbo.backupset A
ON A.database_name = B.name AND A.type = 'D' GROUP BY B.Name ORDER BY B.name




RESTORE DATABASE DBName
FROM DISK = '\\server\SQLBackup\db_name.bak'
WITH REPLACE, MOVE 'MSTR' TO 'C:\MSSQL\DATA\DBName_Data.MDF',
MOVE 'DBName_Log' TO 'C:\MSSQL\DATA\DBName_Log.LDF'

exec admin.procGetActiveProcesses @ShowExecutionPlan=1
exec admin.procStopSP 94
sp_who2
exec admin.procGetDBCCBackupRestoreState

DBCC INPUTBUFFER (94)
SELECT request_id FROM sys.dm_exec_requests WHERE session_id = 94;

--See execution plan
EXEC admin.procGetExecutionPlan @SPID=92
SELECT * FROM sys.dm_exec_query_plan(0x02000000F6BE3A3918F823FE19DFE4F835B695756811B385)

sp_who2 active

--Module Refresh - Recreate the job
exec admin.procJob_InitializeProcess 'MRSFeed'
exec admin.procJob_InitializeProcess_All @DropObsoleteJobs=1

--Module properties
SELECT * FROM dbo.viewETLPropertyValue 
WHERE ModuleName='MRSFeed_UAT' 
AND PropertyName='ProcessSchedule' 
AND EnvironmentName='US_NEW_PROD_2K8'

-------
--stats
-------
UPDATE STATISTICS dbo.FactRisk WITH FULLSCAN




  sp_helpindex 'RDist.FactReportBlob.PK_FactReportBlob'
  
    select * from sys.indexes where object_id = object_id('RDist.FactReportBlob')
  select * from sys.stats
  where object_id = object_id('RDist.FactReportBlob')
  
  dbcc show_statistics ('RDist.FactReportBlob', _WA_Sys_00000002_6227E9D4)
  dbcc show_statistics ('RDist.FactReportBlob', PK_FactReportBlob)
  
  
    drop statistics RDist.FactReportBlob._WA_Sys_00000002_6227E9D4
  
  UPDATE STATISTICS RDist.FactReportBlob WITH FULLSCAN
  



SELECT o.* FROM sysobjects o INNER JOIN syscomments c on c.id=o.id WHERE c.text like '%rdist.factreportstatus%'
SELECT * FROM sys.syscomments WITH(NOLOCK) WHERE text like '%rdist.factreportstatus%'


/* Blocking query due to transactions*/

SELECT
db.name DBName,
tl.request_session_id,
wt.blocking_session_id,
OBJECT_NAME(p.OBJECT_ID) BlockedObjectName,
tl.resource_type,
h1.TEXT AS RequestingText,
h2.TEXT AS BlockingTest,
tl.request_mode
FROM sys.dm_tran_locks AS tl
INNER JOIN sys.databases db ON db.database_id = tl.resource_database_id
INNER JOIN sys.dm_os_waiting_tasks AS wt ON tl.lock_owner_address = wt.resource_address
INNER JOIN sys.partitions AS p ON p.hobt_id = tl.resource_associated_entity_id
INNER JOIN sys.dm_exec_connections ec1 ON ec1.session_id = tl.request_session_id
INNER JOIN sys.dm_exec_connections ec2 ON ec2.session_id = wt.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(ec1.most_recent_sql_handle) AS h1
CROSS APPLY sys.dm_exec_sql_text(ec2.most_recent_sql_handle) AS h2
GO

/* What query runs for long time */
SELECT sqltext.TEXT,
req.session_id,
req.status,
req.command,
req.cpu_time,
req.total_elapsed_time
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext


SELECT * FROM sys.dm_exec_sessions s WITH(NOLOCK)
SELECT * FROM sys.dm_exec_requests s WITH(NOLOCK)

FROM sys.dm_exec_sessions s WITH(NOLOCK)
		LEFT OUTER JOIN sys.dm_exec_connections c WITH(NOLOCK)	ON c.session_id=s.session_id
		LEFT OUTER JOIN sys.dm_exec_requests r WITH(NOLOCK)		ON s.session_id=r.session_id
		LEFT OUTER JOIN sys.databases d WITH(NOLOCK)			ON r.database_id=d.database_id
		OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) st



EXEC dbo.procRefreshDependentViews @ChildObjName='DimPortfolio_TypeIandII'

sp_helptext ViewDimPortfolio_TypeIandII_Joins
EXEC sp_refreshview 'viewDimPortfolio_TypeIandII'

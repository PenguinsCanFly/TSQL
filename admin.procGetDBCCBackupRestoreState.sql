IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'admin.procGetDBCCBackupRestoreState') AND type in (N'P', N'PC'))
DROP PROCEDURE admin.procGetDBCCBackupRestoreState
go

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON 
GO
/*
    Great thanks to Brenda Guan prvided the query
    
    
    exec admin.procGetDBCCBackupRestoreState
*/
create proc admin.procGetDBCCBackupRestoreState
    with execute as owner
as 
SELECT  r.Session_ID,
        r.Command,
        d.name as DatabaseName,
        CONVERT(NUMERIC(6, 2), r.percent_complete) AS [Percent Complete],
        CONVERT(VARCHAR(20), DATEADD(ms, r.estimated_completion_time,
                                     GetDate()), 20) AS [ETA Completion Time],
        CONVERT(NUMERIC(6, 2), r.total_elapsed_time / 1000.0 / 60.0) AS [Elapsed Min],
        CONVERT(NUMERIC(6, 2), r.estimated_completion_time / 1000.0 / 60.0) AS [ETA Min],
        CONVERT(NUMERIC(6, 2), r.estimated_completion_time / 1000.0 / 60.0
        / 60.0) AS [ETA Hours],
        CONVERT(VARCHAR(max), (SELECT   SUBSTRING(text,
                                                  r.statement_start_offset / 2,
                                                  CASE WHEN r.statement_end_offset = -1
                                                       THEN 8000
                                                          ELSE (r.statement_end_offset
                                                          - r.statement_start_offset)
                                                            / 2
                                                  END)
                               FROM     sys.dm_exec_sql_text(sql_handle)))
FROM    sys.dm_exec_requests r
    left outer join sys.databases d 
        on r.database_id = d.database_id
WHERE   command IN ('RESTORE DATABASE', 'BACKUP DATABASE', 'DBCC CHECKDB',
                    'DBCC SHRINKDATABASE', 'DBCC SHRINKFILE', 'ROLLBACK', 'RESTORE LOG')
go

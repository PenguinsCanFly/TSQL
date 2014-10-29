IF OBJECT_ID('admin.procGetActiveProcesses') IS NOT NULL
	DROP PROCEDURE admin.procGetActiveProcesses
GO

CREATE PROC admin.procGetActiveProcesses
	@ShowExecutionPlan BIT = 0
WITH EXECUTE AS owner, RECOMPILE
AS
/*
	All time duration colimn are shown in seconds
	
	EXEC admin.procGetActiveProcesses @ShowExecutionPlan = 0 -- No execution plan shown. Faster.
	EXEC admin.procGetActiveProcesses @ShowExecutionPlan = 1 -- Show query plan. This works only if there are no locks
*/
BEGIN

	IF OBJECT_ID('tempdb..#Processes') IS NOT NULL
		DROP TABLE #Processes
	
	SELECT 
		DatabaseName				= d.name,
		SPID						= req.session_id,
		BB							= ISNULL(CAST(NULLIF(req.blocking_session_id, 0) AS VARCHAR(10)), ''), 
		BlockedBy					= CAST('' AS VARCHAR(100)),
		Full_Query					= st.text,
		Executing_SQL_Statement		= 
									CASE   
										WHEN req.[statement_start_offset] > 0 THEN  
											CASE req.[statement_end_offset] WHEN -1 
												THEN SUBSTRING(st.TEXT, (req.[statement_start_offset]/2) + 0, 2147483647) 
												ELSE SUBSTRING(st.TEXT, (req.[statement_start_offset]/2) + 0, (req.[statement_end_offset] - req.[statement_start_offset])/2)   
											END  
										ELSE  
											CASE req.[statement_end_offset] WHEN -1 
												THEN RTRIM(LTRIM(st.[text]))  
												ELSE LEFT(st.[TEXT], (req.statement_end_offset/2) + 0)  
											END  
									END,
		SessionStatus				= s.[status],
		RequestStatus				= req.[status],
		CommandType					= req.command,
		CPU_time					= req.cpu_time / 1000,
		Reads						= req.reads,
		Logical_Reads				= req.logical_reads,
		Writes						= req.writes,
		Row_Count					= req.row_count,
		Transactions				= req.open_transaction_count,
		total_elapsed_time			= req.total_elapsed_time / 1000,
		LastRequest                 = s.last_request_start_time,
		Wait_Type					= req.wait_type,
		Wait_Time_Sec				= req.wait_time / 1000,
		PlanHandle					= req.plan_handle,
		transaction_isolation_level =
									CASE req.transaction_isolation_level 
										WHEN 0 THEN 'Unspecified' 
										WHEN 1 THEN 'ReadUncommitted' 
										WHEN 2 THEN 'ReadCommitted' + CASE WHEN d.is_read_committed_snapshot_on = 1 THEN ' (snapshot isolation)' ELSE '' END
										WHEN 3 THEN 'Repeatable' 
										WHEN 4 THEN 'Serializable' 
										WHEN 5 THEN 'Snapshot' 
									END, 
		d.is_read_committed_snapshot_on,
		d.snapshot_isolation_state_desc,
		d.snapshot_isolation_state,
		UserName					= ISNULL(s.login_name, s.nt_domain+'\'+s.nt_user_name),
		Program						= s.[program_name],
		HOST						= s.[host_name],
		[SQLHandle]					= ISNULL(req.sql_handle, c.most_recent_sql_handle),
		QueryPlan					= CAST (NULL as xml )
	INTO #Processes
	FROM 
		sys.dm_exec_requests req WITH(NOLOCK)
		LEFT OUTER JOIN sys.dm_exec_sessions s WITH(NOLOCK)	    ON s.session_id=req.session_id
		LEFT OUTER JOIN sys.dm_exec_connections c WITH(NOLOCK)	ON c.session_id=req.session_id
		LEFT OUTER JOIN sys.databases d WITH(NOLOCK)			ON d.database_id=req.database_id
		OUTER APPLY sys.dm_exec_sql_text(req.sql_handle) st
	WHERE 
		req.session_id <> @@SPID

	--buid the block tree
	IF EXISTS (SELECT * FROM #Processes WHERE BB <> '')
	BEGIN 
		;WITH cteBlockingTree AS 
		(
			SELECT
				SPID,
				0 AS BlockLevel,
				CAST('' AS VARCHAR(8000))AS BlockingPath,
				0 AS RootBlocker
			FROM #Processes p
			WHERE BB = ''
			UNION ALL
			SELECT
				p.SPID,
				pp.BlockLevel + 1 AS BlockLevel,
				CAST(pp.BlockingPath + p.BB + '->'AS VARCHAR(8000))AS BlockingPath,
				CASE WHEN pp.BlockLevel = 0 THEN pp.SPID ELSE pp.RootBlocker END AS RootBlocker
			FROM #Processes p
				 INNER JOIN cteBlockingTree pp
					 ON p.BB = pp.SPID
			WHERE p.BB <> ''
		)
		UPDATE p
		SET p.BlockedBy = CASE WHEN t.RootBlocker = p.SPID THEN 'ROOT' ELSE t.BlockingPath + CAST(t.SPID AS VARCHAR(8000)) END,
			p.BB     = CASE WHEN t.RootBlocker = p.SPID THEN '***' ELSE p.BB END
		FROM cteBlockingTree t
			INNER JOIN #Processes p
				ON t.SPID = p.SPID
				OR t.RootBlocker = p.SPID
		WHERE BlockLevel <> 0
	END

	IF @ShowExecutionPlan = 1
		UPDATE p
		SET p.QueryPlan = qp.query_plan
		FROM #Processes p
			OUTER APPLY sys.dm_exec_query_plan(p.PlanHandle) qp
		WHERE BlockedBy='' OR BlockedBy='ROOT'
	
	--final select
	SELECT *
	FROM #Processes p
	ORDER BY
		p.DatabaseName DESC,
		BlockedBy DESC,
		p.SPID
END
GO

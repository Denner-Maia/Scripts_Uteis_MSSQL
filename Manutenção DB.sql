--MANUTEN��O DO BANCO DE DADOS


--ETAPA 1 Consist�ncia das constraints


DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO

--ETAPA 2 Integridade do banco de dados

DBCC CHECKDB('BASE')
GO

--ETAPA 3 Desfragmenta o banco de dados
	
	DROP TABLE IF EXISTS #FRAGMENTACAO
GO

SELECT
	D.NAME AS INDICE,
	C.NAME AS SCHEM,
	B.NAME AS TAB,
	A.AVG_FRAGMENTATION_IN_PERCENT AS FRAG, 
	A.PAGE_COUNT AS NUM_PAGINAS
	INTO #FRAGMENTACAO
FROM SYS.DM_DB_INDEX_PHYSICAL_STATS (DB_ID(), NULL, NULL, NULL, NULL) AS A
INNER JOIN SYS.TABLES B 
     ON B.[OBJECT_ID] = A.[OBJECT_ID]
INNER JOIN SYS.SCHEMAS C 
     ON B.[SCHEMA_ID] = C.[SCHEMA_ID]
INNER JOIN SYS.INDEXES AS D 
     ON D.[OBJECT_ID] = A.[OBJECT_ID]
	AND A.INDEX_ID = D.INDEX_ID
WHERE A.DATABASE_ID = DB_ID()
AND A.AVG_FRAGMENTATION_IN_PERCENT >5
AND D.[NAME]  IS NOT NULL
AND A.PAGE_COUNT > 1000

DECLARE @SQLCMD VARCHAR(200) = ''
DECLARE @NAMEIND VARCHAR(100) = ''

while exists (select top 1 * from #FRAGMENTACAO)
begin
	select top 1 @NAMEIND = INDICE, @SQLCMD = 'ALTER INDEX ' + INDICE + ' ON ' + SCHEM + '.' + TAB + CASE WHEN FRAG > 5 AND FRAG < 30 THEN ' REORGANIZE;'
	 ELSE ' REBUILD;'  END
	from #FRAGMENTACAO 
	
DELETE #FRAGMENTACAO WHERE INDICE = @NAMEIND
	
	EXEC(@SQLCMD)
	--PRINT(@SQLCMD)
end
drop table #FRAGMENTACAO
GO

--ETAPA 4 Atualiza Estat�sticas

DROP TABLE IF EXISTS #ATUALIZAESTATISTICAS

SELECT 
	 SYS.TABLES.OBJECT_ID AS ID
	,SYS.TABLES.NAME AS TABELA
	,SYS.SCHEMAS.NAME AS SCHEM
	INTO #ATUALIZAESTATISTICAS
FROM SYS.TABLES 
INNER JOIN SYS.schemas
	ON(SYS.TABLES.SCHEMA_ID = SYS.SCHEMAS.schema_id)

DECLARE @ID INT 
DECLARE @TABLENAME VARCHAR(50)
DECLARE @SCHEMA VARCHAR(50)


WHILE EXISTS(SELECT TOP 1 ID FROM #ATUALIZAESTATISTICAS)
BEGIN 
	SELECT 
		@ID = ID,
		@TABLENAME = TABELA,
		@SCHEMA = SCHEM
	FROM #ATUALIZAESTATISTICAS

	DELETE FROM #ATUALIZAESTATISTICAS
	WHERE ID = @ID 

	PRINT('ATUALIZANDO ' + @SCHEMA +'.'+ @TABLENAME)
	PRINT ('UPDATE STATISTICS '  + @SCHEMA +'.'+ @TABLENAME + ' WITH FULLSCAN')
	--EXECUTE ('UPDATE STATISTICS ' + @SCHEMA +'.'+ @TABLENAME + ' WITH FULLSCAN')
	
END 
GO

--ETAPA 5 Reciclar Log

exec sp_cycle_errorlog 
GO

--ETAPA 6 Kill Session Sleep

set noCount on
declare @spid int

	select spid into #spids
	from sys.sysprocesses where spid > 50
	and [dbid] > 4 and [status]='sleeping'and DateDiff(hh,last_batch,GetDate()) > 24

while exists (select top 1 * from #spids)
begin
	select top 1 @spid=spid from #spids
	delete from #spids where spid=@spid
	exec('kill ' + @spid)
end
drop table #spids
go

--ETAPA 6 Deleta Historico

DECLARE @DateBefore DATETIME 
SET @DateBefore = DATEADD(MONTH, -1, GETDATE())

EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @DateBefore;
EXEC msdb.dbo.sp_purge_jobhistory @oldest_date = @DateBefore;
EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @DateBefore;
EXEC msdb.dbo.sysmail_delete_log_sp @logged_before = @DateBefore;
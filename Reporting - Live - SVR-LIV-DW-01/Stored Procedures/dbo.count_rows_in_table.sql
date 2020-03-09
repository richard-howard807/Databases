SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[count_rows_in_table] (@Table NVARCHAR(MAX))

AS
-- counts rows in red tables -- used for doucmentation reports
--DROP TABLE #tables
--DROP TABLE #results

DECLARE @SQL NVARCHAR(250)
DECLARE @Count INT = 1

--DECLARE @table VARCHAR(MAX) = 'dim_be_opportunities_involvement'


SELECT *
	INTO #tables
FROM dbo.split_delimited_to_rows (@table,',')


-- select * from #tables


CREATE TABLE #results
(tablename VARCHAR(1000),
count_of_rows int
)


WHILE @Count <= (SELECT MAX(id) FROM #tables)
	begin
		
		SELECT @sql = 'insert into #results select ''' + val + ''', COUNT (*) from red_dw..' + val 
		FROM #tables
		WHERE id = @Count

		PRINT @sql

		EXEC sp_executesql  @SQL 

		SET @Count = @Count + 1

	end


SELECT *
FROM #results
GO

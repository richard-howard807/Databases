SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--[Exceptions].[GetExceptionDatasetCachedDWH] 'LLDB Exception Report',1,5108

CREATE PROCEDURE [Exceptions].[GetExceptionDatasetCachedDWH](
	  @DatasetName NVARCHAR(255)
	, @Debug BIT = 0 -- Returns the sql statement without executing it
    ,@FeeEarners nVARCHAR(MAX) =null
)AS


/*Test Parameters
DECLARE @DatasetName VARCHAR(255) = 'Ageas'
DECLARE @Debug BIT = 1*/

BEGIN
	SET FMTONLY OFF;
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @Sql NVARCHAR(MAX)
	DECLARE @SqlLength INT = 0 -- Used for printing the query on screen
	DECLARE @CutOff INT = 0    -- .... same here.
	DECLARE @DatasetID nVARCHAR(255)
	--DECLARE @FeeEarners VARCHAR(MAX)
	 
	SELECT @DatasetID = Exceptions.dbo.Concatenate(datasetid, ',') FROM red_dw.dbo.ds_sh_exceptions_datasets WHERE datasetname IN (SELECT val FROM split_delimited_to_rows(@DatasetName,',' )) and ds_sh_exceptions_datasets.dss_current_flag = 'Y'
	PRINT @datasetID
	DECLARE @FieldList TABLE (
		SequenceNumber INT NOT NULL
	  , Name VARCHAR(255) NULL
	  ,	LinkedSequenceNumbers VARCHAR(255) NOT NULL
	  , QueryString VARCHAR(MAX) NOT NULL
	  , DetailsUsed VARCHAR(255) NULL
	  , JoinsUsed VARCHAR(255) NULL
	  , LookupField BIT NOT NULL
	  , FieldTypeID TINYINT NOT NULL
	  , FieldID INT NOT NULL
	  , Severity TINYINT NULL
	  , DatasetID INT NOT NULL
	 )

	INSERT INTO @FieldList
	SELECT MAX(df.sequencenumber) AS SequenceNumber
		 , MAX(REPLACE(ISNULL(df.alias, f.fieldname), '''', '''''')) AS FieldName
		 , Exceptions.dbo.Concatenate(linkedexceptions.sequencenumber, ',')
		 , f.querystring
		 , f.detailsused
		 , f.joinsused
		 , f.lookupfield
		 , f.fieldtypeid
		 , f.fieldid
		 , MAX(df.severity) AS Severity
		 , d.datasetid
	FROM red_dw.dbo.ds_sh_exceptions_datasets d 
	INNER JOIN red_dw.dbo.ds_sh_exceptions_dataset_fields df on d.datasetid = df.datasetid and df.dss_current_flag = 'Y' 
	INNER JOIN red_dw.dbo.ds_sh_exceptions_fields f on df.fieldid = f.fieldid and f.dss_current_flag = 'Y'  
	OUTER APPLY (SELECT TOP (100) PERCENT dfex.sequencenumber
				 FROM red_dw.dbo.ds_sh_exceptions_fields fex 
				 LEFT JOIN red_dw.dbo.ds_sh_exceptions_dataset_fields dfex on fex.fieldid = dfex.fieldid and dfex.datasetid = df.datasetid and dfex.dss_current_flag = 'Y' 
				 WHERE f.fieldid = fex.linkedfieldid AND f.exceptionfield = 0 AND fex.exceptionfield = 1
				and fex.dss_current_flag = 'Y'
				 ORDER BY df.severity) AS linkedexceptions
	WHERE d.datasetname IN (SELECT val FROM split_delimited_to_rows(@DatasetName,',' ))
	and d.dss_current_flag = 'Y'
	GROUP BY f.querystring
		 , f.detailsused
		 , f.joinsused
		 , f.lookupfield
		 , f.fieldtypeid
		 , f.fieldid
		 , d.datasetid

	SET @Sql = 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;' + CHAR(10) + CHAR(10)
	
	/* Creates Stage table*/
	SET @Sql = @Sql + 'CREATE TABLE #ds_sh_exceptions_values_stage (case_id INT,exceptionruleid INT,Flag BIT,String VARCHAR(255),Number DECIMAL(13, 2),Date DATETIME,Seq_No INT)' + CHAR(10) + CHAR(10)
	
	SET @Sql = @Sql + 'INSERT  INTO #ds_sh_exceptions_values_stage (case_id,exceptionruleid,Flag,String,Number,Date,Seq_No)' + CHAR(10) + CHAR(10)
	
	SET @Sql = @Sql + 'SELECT evalues.case_id,evalues.exceptionruleid,evalues.Flag,evalues.String,evalues.Number,evalues.Date,evalues.Seq_No' + CHAR(10)
	SET @Sql = @Sql + 'FROM ( SELECT case_id FROM  red_dw.dbo.fact_exceptions_update WHERE datasetid IN (' +@DatasetID+' ) ) ecase' + CHAR(10)
	SET @Sql = @Sql + 'JOIN (SELECT a.case_id,a.exceptionruleid,a.Flag,a.String,a.Number,a.Date,a.Seq_No'+CHAR(10)
	SET @Sql = @Sql + 'FROM (SELECT * FROM red_dw.dbo.ds_sh_exceptions_values_dwh WHERE (ds_sh_exceptions_values_dwh.String IS NOT NULL OR ds_sh_exceptions_values_dwh.Number IS NOT NULL OR ds_sh_exceptions_values_dwh.Date IS NOT NULL ) AND ds_sh_exceptions_values_dwh.Flag IS NULL ' + CHAR(10)
	SET @Sql = @Sql + 'UNION ALL' +CHAR(10)
	SET @Sql = @Sql + 'SELECT ds_sh_exceptions_values_dwh.* FROM red_dw.dbo.ds_sh_exceptions_values_dwh inner join red_dw.dbo.fact_exceptions_update on  ds_sh_exceptions_values_dwh.case_id = fact_exceptions_update.case_id and  ds_sh_exceptions_values_dwh.exceptionruleid = fact_exceptions_update.exceptionruleid    WHERE ds_sh_exceptions_values_dwh.Flag IS NOT NULL)a ) evalues ON evalues.case_id = ecase.case_id' +CHAR(10) + CHAR(10)
	
	/*Creates Main Table*/
	SET @Sql = @Sql + 'CREATE TABLE #ds_sh_exceptions_values (case_id INT,exceptionruleid INT,Flag BIT,String VARCHAR(255),Number DECIMAL(13, 2),Date DATETIME )' + CHAR(10) + CHAR(10)
	
	SET @Sql = @Sql + 'INSERT  INTO #ds_sh_exceptions_values (case_id,exceptionruleid,Flag,String,Number,Date)' + CHAR(10) + CHAR(10)
	
	SET @Sql = @Sql + 'SELECT  DISTINCT evalues.case_id,evalues.exceptionruleid,evalues.Flag,evalues.String,evalues.Number,evalues.Date' + CHAR(10)
	SET @Sql = @Sql + 'FROM (SELECT a.case_id,a.exceptionruleid,a.Flag,a.String,a.Number,a.Date FROM red_dw.dbo.ds_sh_exceptions_values_dwh a' + CHAR(10)
	SET @Sql = @Sql + 'JOIN (SELECT #ds_sh_exceptions_values_stage.case_id,#ds_sh_exceptions_values_stage.exceptionruleid,MAX(#ds_sh_exceptions_values_stage.Seq_No) Seq_No' + CHAR(10)
    SET @Sql = @Sql + 'FROM  #ds_sh_exceptions_values_stage GROUP BY  #ds_sh_exceptions_values_stage.case_id,#ds_sh_exceptions_values_stage.exceptionruleid) b ON b.case_id = a.case_id AND b.exceptionruleid = a.exceptionruleid AND b.Seq_No = a.Seq_No) evalues' + CHAR(10) + CHAR(10) + CHAR(10)
	
	-- SELECT CLAUSE
		SET @Sql = @Sql + 'SELECT fdm.master_fact_key'
			 
		SELECT @Sql = @Sql + CHAR(10) + CHAR(9) + ' ' + ', ' 
						   + CASE FieldTypeID WHEN 0 THEN '[' + CAST(FieldID AS VARCHAR(6)) + '].Flag'
											  WHEN 1 THEN '[' + CAST(FieldID AS VARCHAR(6)) + '].String'
											  WHEN 2 THEN '[' + CAST(FieldID AS VARCHAR(6)) + '].Number'
											  WHEN 3 THEN '[' + CAST(FieldID AS VARCHAR(6)) + '].Date'
											  ELSE '' END 
						   + ' AS [' + COALESCE(Name, DetailsUsed, '') + ']'
		FROM @FieldList		
		GROUP BY FieldTypeID, FieldID, Name, DetailsUsed
		ORDER BY MAX(SequenceNumber)
		
		--SELECT @Sql = @Sql + ISNULL(CHAR(10) + CHAR(9) + ' ' + ', (CASE WHEN 1=0 THEN 0 ' + Exceptions.dbo.Concatenate(CHAR(10) + CHAR(9) + CHAR(9) + 'WHEN [' + CAST(flex.FieldID AS VARCHAR(6))+ '].Flag = 1 THEN ' + CAST(flex.Severity AS VARCHAR(3)), '') + ' ELSE 0 END) AS [' + COALESCE(fl.Name, fl.DetailsUsed, '') + '_severity]', '')
		--FROM @FieldList AS fl
		--OUTER APPLY (SELECT val FROM split_delimited_to_rows(fl.LinkedSequenceNumbers,',' )) AS linkedrules
		--LEFT JOIN @FieldList flex ON linkedrules.val = flex.SequenceNumber AND fl.DatasetID = flex.DatasetID
		--WHERE fl.FieldTypeID > 0
		--GROUP BY fl.Name, fl.DetailsUsed
		
		SET @Sql = @Sql + CHAR(10) + CHAR(9) + ', Exceptions.Exceptions.ufnCondenseExceptionString('''''
		
		SELECT @Sql = @Sql + ISNULL(CHAR(10) + CHAR(9) + CHAR(9) + ' + (CASE WHEN [' + CAST(FieldID AS VARCHAR(6))+ '].Flag = 1 THEN ''' + Name + ''' + '' | '' ELSE '''' END)', '')
		FROM @FieldList
		WHERE FieldTypeID = 0
		GROUP BY FieldID, Name
		ORDER BY MAX(SequenceNumber)
		
		SET @Sql = @Sql + CHAR(10) + CHAR(9) + ', '' | '') AS ExceptionString'
				
		--FROM CLAUSE
		SET @Sql = @Sql + CHAR(10) + 'FROM red_dw.dbo.fact_dimension_main fdm'
		
		SELECT @Sql = @Sql + CHAR(10) + 'left JOIN #ds_sh_exceptions_values AS [' + CAST(FieldID AS VARCHAR(6)) + '] ON fdm.master_fact_key = [' + CAST(FieldID AS VARCHAR(6)) + '].case_id AND [' + CAST(FieldID AS VARCHAR(6)) + '].exceptionruleid = ' + CAST(FieldID AS VARCHAR(6)) 
		FROM @FieldList
		GROUP BY FieldID

		IF @FeeEarners IS NOT NULL
		BEGIN
		set	
		@Sql = @Sql  + CHAR(10) + 'LEFT JOIN red_Dw.dbo.dim_matter_header_current dmh ON dmh.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
		INNER JOIN dbo.split_delimited_to_rows('''+@FeeEarners+''' ,'','') AS FeeEarners ON dmh.fee_earner_code COLLATE database_default = FeeEarners.val COLLATE database_default'
		END	 

        


		--WHERE CLAUSE
		SET @Sql = @Sql + CHAR(10) + 'WHERE  fdm.master_fact_key IN (SELECT case_id FROM red_dw.dbo.fact_exceptions_update WHERE datasetid IN (' + @DatasetID + '))'
	
	
	
			 
	
		
	--FINALE	
	WHILE @SqlLength < LEN(@Sql)
	BEGIN
		SET @CutOff = 4000 - CHARINDEX(CHAR(10), REVERSE(SUBSTRING(@sql, @SqlLength, 4000)))
		PRINT SUBSTRING(@Sql, @SqlLength, @CutOff)
		SET @SqlLength = @SqlLength + @CutOff + 1
	END
	
	--IF @Debug = 0 
	EXEC sp_executesql @Sql 


END
GO

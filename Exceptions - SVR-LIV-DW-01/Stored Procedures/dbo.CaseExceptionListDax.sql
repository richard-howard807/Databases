SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- [dbo].[CaseExceptionListDax] 366131,'29,40,47,50,51,52,53,54,62,63,75,82,83,84,94,95,98'
CREATE PROCEDURE [dbo].[CaseExceptionListDax] (
	  @CaseID INT
	, @DatasetID VARCHAR(max) = ''
)
AS

/*
--Test parameters
DECLARE @CaseID INT = 366131
DECLARE @DatasetID VARCHAR(100) = '29,40,47,50,51,52,53,54,62,63,75,82,83,84,94,95,98'

*/

BEGIN
SET NOCOUNT ON;
SET FMTONLY OFF;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	

	DECLARE @sql AS NVARCHAR(max) = ''
DECLARE @SqlLength INT = 0 
DECLARE @CutOff INT = 0  
DECLARE @sqlFilter AS NVARCHAR(MAX)

CREATE table  #table  (
fieldid  int,
fieldname NVARCHAR(MAX),
sequencenumber INT ,
fieldtypeid int
)


--SELECT @datasetid = dataset.datasetid FROM red_dw_dev.dbo.ds_sh_exceptions_datasets dataset WHERE dataset.datasetname IN (SELECT val FROM split_delimited_to_rows(@datasetname,'|' )) and dataset.dss_current_flag = 'Y' 

INSERT INTO #table 
SELECT distinct df.fieldid, f.fieldname,df.sequencenumber,f.fieldtypeid FROM red_dw_dev.dbo.ds_sh_exceptions_dataset_fields df
LEFT JOIN red_dw_dev.dbo.ds_sh_exceptions_fields f ON  df.fieldid = f.fieldid WHERE datasetid = @datasetid
ORDER BY df.sequencenumber






SET @sql =  ' evaluate (
				CALCULATETABLE(
					summarize ( 
                    fact_exception_main,
                    fact_exception_main[case_id]'
 
 SELECT @sql = @sql + CHAR(10)  + ',"' + fieldname + '",CALCULATE(SUMMARIZE(fact_exception_main,fact_exception_main[value]),fact_exception_main[exceptionruleid] = ' + CAST(fieldid AS nvarchar(MAX)) +')'  from #table
  ORDER BY sequencenumber

	set @Sql = @Sql + CHAR(10) + ',"Exceptions",'
	SELECT @Sql = @Sql + CHAR(10) + 'if(CALCULATE(SUMMARIZE(fact_exception_main,fact_exception_main[value]),fact_exception_main[exceptionruleid] = '+cast(FieldID AS NVARCHAR(10))+') = "1" , "'+	fieldname + '  | " , "" ) &'
	FROM #table
	WHERE FieldTypeID = 0
	GROUP BY FieldID, fieldname
	ORDER BY MAX(SequenceNumber)

	SELECT @Sql = @Sql + CHAR(10) + '" "'

  SELECT @sql = @sql + CHAR(10)  + '), pathcontains("'+@DatasetID+'",ds_sh_exceptions_datasets[datasetid] )'
  SELECT @sql = @sql + CHAR(10) + ')'
  SELECT @sql = @sql + CHAR(10) + ') order by fact_exception_main[case_id]'

WHILE @SqlLength < LEN(@sql)
	BEGIN
		SET @CutOff = 4000 - CHARINDEX(CHAR(10), REVERSE(SUBSTRING(@sql, @SqlLength, 4000)))
		PRINT SUBSTRING(@Sql, @SqlLength, @CutOff)
		SET @SqlLength = @SqlLength + @CutOff + 1
	END

End
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--Stich the columns back togeter and create a view of it.
CREATE PROCEDURE [dbo].[MatterSphereDynamicPivot]
--exec dbo.[MatterSphereDynamicPivot] 'date','udMIProcessDTE'
(
@DataType VARCHAR(10) ,
 @TableName AS VARCHAR(50)
)
AS
 

DECLARE @TempTableName AS varchar(60)

SET @TempTableName=CONCAT(@TableName, @DataType)


  declare @columns as varchar(max) = (select STUFF((select distinct ',[' + [MScode] + ']' 
													FROM CaseDetailsStage 
													WHERE MSTable = @TableName 
													AND (CASE WHEN DataType='uCodeLookup:nvarchar(15)' THEN 'text'
															WHEN DataType LIKE 'nvarchar%' THEN 'text'
															 --WHEN DataType='nvarchar(60)' THEN 'text'
															 --WHEN DataType='nvarchar(250)' THEN 'text'
															 WHEN DataType='money' THEN 'value'
															 WHEN DataType='datetime' then 'date' 
															 WHEN MScode LIKE 'dte%' THEN 'date'
															 WHEN MScode LIKE 'cur%' THEN 'value'
															 WHEN MScode LIKE 'cbo%' THEN 'text'
															 WHEN MScode LIKE 'txt%' THEN 'text'
															 END) = @DataType ORDER BY 1 DESC for xml path('')), 1, 1, '' ) )
  
  --declare @TableName as varchar(50) = 'udMIProcessCBONZ'
declare @setcolumns as varchar(max) = (select STUFF((select distinct ',' + @TableName + '.[' + [MScode] + '] = src.[' + [MScode] + ']' from CaseDetailsStage where MSTable = @TableName AND (CASE WHEN DataType='uCodeLookup:nvarchar(15)' THEN 'text'
							 WHEN DataType LIKE'nvarchar%' THEN 'text'
							 --WHEN DataType='nvarchar(60)' THEN 'text'
							 --WHEN DataType='nvarchar(250)' THEN 'text'
							 WHEN DataType='money' THEN 'value'
							 WHEN DataType='datetime' then 'date' 
							 WHEN MScode LIKE 'dte%' THEN 'date'
							 WHEN MScode LIKE 'cur%' THEN 'value'
							 WHEN MScode LIKE 'cbo%' THEN 'text'
							 WHEN MScode LIKE 'txt%' THEN 'text'
							 END) = @DataType ORDER BY 1 DESC for xml path('')), 1, 1, '' ) )
DECLARE @updatecols AS NVARCHAR(MAX)
DECLARE @insertcols AS NVARCHAR(MAX)
DECLARE @insertcolvalues AS NVARCHAR(MAX)


SELECT @updatecols =   STUFF((select distinct ',' +  'dest.[' + [MScode] + '] = src.[' + [MScode] + ']' 
						from CaseDetailsStage
						where StatusID=7 
						AND (CASE WHEN DataType='uCodeLookup:nvarchar(15)' THEN 'text'
							 WHEN DataType like'nvarchar%' THEN 'text'
							 --WHEN DataType='nvarchar(60)' THEN 'text'
							 --WHEN DataType='nvarchar(250)' THEN 'text'
							 WHEN DataType='money' THEN 'value'
							 WHEN DataType='datetime' then 'date' 
							 WHEN MScode LIKE 'dte%' THEN 'date'
							 WHEN MScode LIKE 'cur%' THEN 'value'
							 WHEN MScode LIKE 'cbo%' THEN 'text'
							 WHEN MScode LIKE 'txt%' THEN 'text'
							 END) = @DataType
						AND   MSTable = @TableName ORDER BY 1 DESC for xml path('')), 1, 1, '' )
						 
SELECT @insertcols =   STUFF((SELECT distinct ',' + '['+[MScode]+']'
						from CaseDetailsStage
						where StatusID=7
											AND (CASE WHEN DataType='uCodeLookup:nvarchar(15)' THEN 'text'
							 WHEN DataType like'nvarchar%' THEN 'text'
							 --WHEN DataType='nvarchar(60)' THEN 'text'
							 --WHEN DataType='nvarchar(250)' THEN 'text'
							 WHEN DataType='money' THEN 'value'
							 WHEN DataType='datetime' then 'date' 
							 WHEN MScode LIKE 'dte%' THEN 'date'
							 WHEN MScode LIKE 'cur%' THEN 'value'
							 WHEN MScode LIKE 'cbo%' THEN 'text'
							 WHEN MScode LIKE 'txt%' THEN 'text'
							 END) = @DataType
						AND MSTable = @TableName ORDER BY 1 DESC for xml path('')), 1, 1, '' )

SELECT @insertcolvalues =   STUFF((SELECT distinct ',' + 'SRC.['+[MScode]+']'
						from CaseDetailsStage
						where StatusID=7 
						AND (CASE WHEN DataType='uCodeLookup:nvarchar(15)' THEN 'text'
							 WHEN DataType like'nvarchar%' THEN 'text'
							 --WHEN DataType='nvarchar(60)' THEN 'text'
							 --WHEN DataType='nvarchar(250)' THEN 'text'
							 WHEN DataType='money' THEN 'value'
							 WHEN DataType='datetime' then 'date' 
							 WHEN MScode LIKE 'dte%' THEN 'date'
							 WHEN MScode LIKE 'cur%' THEN 'value'
							 WHEN MScode LIKE 'cbo%' THEN 'text'
							 WHEN MScode LIKE 'txt%' THEN 'text'
							 END) = @DataType
						AND MSTable = @TableName ORDER BY 1 DESC for xml path('')), 1, 1, '')
-- select @setcolumns
 -- select @columns

DECLARE @DatabaseName AS nvarchar(100)
SET @DatabaseName=(SELECT [Value] FROM dbo.ControlTable WHERE [Description]='envDb')
  
 -- declare @DataType as varchar(10) = 'text'
-- declare @TableName as varchar(50) = 'udMIProcessCBONZ'
 DECLARE @DataTypeNew NVARCHAR(max) 
 

 SELECT @DataTypeNew = CASE WHEN  @DataType = 'text' THEN 'CAST(FEDCasetext as nvarchar(60)) AS FEDCasetext' 
					ELSE 'FEDCase' + @DataType    END 
					 




 declare @SQL as nvarchar(max) 
 declare @SQLUpdate as nvarchar(max)
  
  SET @SQL =(
  SELECT '
  IF OBJECT_ID(''tempdb..##'+@TempTableName+''') IS NOT NULL 
	DROP TABLE ##'+@TempTableName+'

  
  select fileID,' + 
  --STUFF((select distinct ',[' + [MScode] + ']' from CaseDetailsStage where MSTable = @TableName for xml path('')
  --  ), 1, 1, '' ) 
  @columns
  + '
  into ##'+@TempTableName+'
  from (select fileID,'+@DataTypeNew+' , MScode  
  
  from CaseDetailsStage where FEDCase' + @DataType + '  is not null
  and StatusID=7 AND
  MSTable = ''' + @TableName +'''
			 	 
			  ) p
  pivot
  (max(FEDCase' + @DataType + ') 
  for 
  MScode in 
  (' +
 @columns
 -- STUFF((select distinct ',[' + [MScode] + ']' from CaseDetailsStage for xml path('')), 1, 1, '' ) 
  
 + ')) as pvt;')
 
 
 --set @SQLUpdate = ('
 --update ' + @TableName + '
 
 --set ' + @setcolumns +
 
 --' from  ##datatoinsert a
 --WHERE  ' + @TableName + '.fileID=a.fileID
 
 --')
  
SET @SQLUpdate =  'MERGE.['+@DatabaseName +'].dbo.['+@TableName+'] DEST
USING
(
SELECT * FROM ##'+@TempTableName + ' src
) AS src
ON dest.fileID = src.fileID

WHEN MATCHED
THEN UPDATE 
SET 
'
+@updatecols
+'
WHEN NOT MATCHED
THEN INSERT
( fileid,
'+@insertcols+
')
VALUES (fileid, 
'+@insertcolvalues+
');' 
 
DECLARE @CompleteSQL AS NVARCHAR(MAX)
SET @CompleteSQL=(
 SELECT @SQL + ' ' + @SQLUpdate)

INSERT INTO DetailDynamicSQLOutput
(
DataType ,TableName,SQLStatement
)
SELECT @DataType ,@TableName,@CompleteSQL

EXEC (@CompleteSQL)





--SELECT * FROM CaseDetailsStage

GO

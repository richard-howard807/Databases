SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgreg
-- Create date: 2018-11-07
-- Description:	This is to test any new exceptions that are created
-- =============================================
CREATE PROCEDURE [dbo].[test_exception_rules] --10663,11209
	-- Add the parameters for the stored procedure here
	@firstID AS INT,
	@lastID AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON


  IF  OBJECT_ID('Exceptions.dbo.exceptions_field_test')  IS NOT NULL
 DROP TABLE Exceptions.dbo.exceptions_field_test

   CREATE TABLE Exceptions.dbo.exceptions_field_test(
  fieldID nvarchar(max) NULL,
 error_description nvarchar(max) NULL,
 exception_name nvarchar(max) NULL,
 sql_query nvarchar(max) NULL,
 error int
 )


DECLARE @FieldID INT
DECLARE @fieldname nvarchar(max) -- 
DECLARE @rule nvarchar(max) -- 
DECLARE @tables nvarchar(max) -- 
DECLARE @fields nvarchar(max) -- 
DECLARE @where_stat NVARCHAR(max) --
DECLARE @sql NVARCHAR(MAX) = ''



DECLARE db_cursor CURSOR FOR 
  SELECT 
  FieldID,
  FieldName,
  'CASE WHEN ' + QueryString + ' then 1 else 0 end ['+FieldName+']' [rule] ,
'CASE WHEN ' + QueryString + ' then 1 else 0 end = 1' where_stat,
JoinsUsed,
DetailsUsed
 FROM Exceptions.Exceptions.Fields
 WHERE 
 --FieldID > 10312 
 FieldID >= @firstID AND
  FieldID <= @lastID
 AND FieldTypeID = 0 



OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @FieldID, @fieldname, @rule, @where_stat  ,@tables, @fields

WHILE @@FETCH_STATUS = 0  
BEGIN  
      
				BEGIN TRY 

					PRINT 'Now processing : ' + CAST(@FieldID AS NVARCHAR(10)) + CHAR(10)
					
					--SET @sql = ' insert into Exceptions.dbo.test_table (exception_rule ,exception,client_code,matter_number)' + CHAR(10)
					SET @sql = 'use red_dw; --SET FMTONLY on' + CHAR(10)
					SET @sql = @sql + 'select --top 1'+ CHAR(10)
					--SELECT @sql = @sql + REPLACE(@fields,',',','+CHAR(10))

					SELECT @sql = @sql + CHAR(10) + ''''++ @fieldname + ''''
					SELECT @sql = @sql + CHAR(10) +','+ @rule
					SELECT @sql = @sql + CHAR(10) +',fact_dimension_main.client_code'
					SELECT @sql = @sql + CHAR(10) +',fact_dimension_main.matter_number'
					SELECT @sql = @sql + CHAR(10) + 'from red_dw.dbo.fact_dimension_main'
					SELECT @sql = @sql + CHAR(10) + JoinCode FROM Exceptions.Exceptions.Joins
					INNER JOIN dbo.split_delimited_to_rows(@tables,',') ON val = JoinName
					SELECT @sql = @sql + CHAR(10) + 'where '+ @where_stat


					--SELECT @sql
					EXECUTE sp_executesql @sql
					INSERT into  Exceptions.dbo.exceptions_field_test ( fieldID,error_description,exception_name,sql_query,error) values (@FieldID,null,''''+@fieldname+'''',@sql ,0)
					PRINT 'Completed: ' + CAST(@FieldID AS NVARCHAR(10)) + CHAR(10)
				END tRY
	   BEGIN CATCH
      
	   PRINT @fieldname + CHAR(10)+ CHAR(10)+ CHAR(10)
	   PRINT @sql + CHAR(10)+ CHAR(10)+ CHAR(10)
	  INSERT into  Exceptions.dbo.exceptions_field_test ( fieldID,error_description,exception_name,sql_query,error) values (@FieldID,ERROR_MESSAGE(),''''+@fieldname+'''',@sql,1 )
	  PRINT 'Failed: ' + CAST(@FieldID AS NVARCHAR(10)) + CHAR(10)
	  END CATCH
      FETCH NEXT FROM db_cursor INTO @FieldID, @fieldname, @rule, @where_stat  ,@tables ,@fields
END 

CLOSE db_cursor  
DEALLOCATE db_cursor 
  


END
GO

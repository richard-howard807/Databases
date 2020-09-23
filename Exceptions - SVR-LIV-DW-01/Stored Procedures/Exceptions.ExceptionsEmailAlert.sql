SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Steven Gregory
-- Create date: 06/01/2016
-- Description:	To check exceptions have no errors and to send out an email to the service desk if it does
-- =============================================
CREATE PROCEDURE  [Exceptions].[ExceptionsEmailAlert]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @datasetid int, @date datetime , @name nvarchar(100),  @sql nvarchar(max), @subject  nvarchar(max), @failed int = 0, @to nvarchar(100), @error_text nvarchar(max)
	declare @errors TABLE ( datasetid  int, error_text nvarchar(max))
	
	
	--uncomment and change email address below to your own to test 
	 --set @to				= 'steven.gregory@weightmans.com';


	 --comment out to test
	 set @to = 'InformationSystems@weightmans.com'
	
	
	
	
	--Select all errors that are currently in red_dw.dbo [red_dw].[dbo].[stage_exceptions_details_batch?_names_04] and insert it into table errors

	insert into @errors (datasetid, error_text)
					(	select datasetid, error_text  from [red_dw].[dbo].[stage_exceptions_details_batch1_names_04] 
						where processed = -1
							union 
						select datasetid , error_text from [red_dw].[dbo].[stage_exceptions_details_batch2_names_04] 
						where processed = -1
							union
						select datasetid, error_text  from [red_dw].[dbo].[stage_exceptions_details_batch3_names_04] 
						where processed = -1
							union
						select datasetid, error_text  from [red_dw].[dbo].[stage_exceptions_details_batch4_names_04] 
						where processed = -1 
						union
						SELECT  datasetid, error_text
										FROM    [red_dw].[dbo].stage_ds_sh_exceptions_cases_01
										WHERE   stage_ds_sh_exceptions_cases_01.processed = -1

						)
		
		--delete all errors that have been fixed since last run from ExceptionsEmailTable
		delete from Exceptions.Exceptions.ExceptionsEmailTable where datasetid not in (select datasetid from @errors)

		--insert any new errors into table ExceptionsEmailTable if they dont exsit already
		insert into Exceptions.Exceptions.ExceptionsEmailTable (datasetid, email_sent, date_added,ERROR_MESSAGE)
		select datasetid, 0, GETDATE(), error_text from @errors  where datasetid not in (select datasetid from Exceptions.Exceptions.ExceptionsEmailTable)

		-- set cursor to run through all errors that have not been sent out 
		DECLARE dataset_cursor CURSOR FOR 
			SELECT e.datasetid, d.DatasetName ,e.date_added, e.ERROR_MESSAGE
				FROM Exceptions.Exceptions.ExceptionsEmailTable e
				left join Exceptions.Exceptions.Datasets d on d.DatasetID = e.datasetid
				WHERE email_sent = 0
				ORDER BY email_sent;

			open dataset_cursor

			FETCH  NEXT FROM dataset_cursor
				into @datasetid, @name, @date, @error_text
				WHILE @@FETCH_STATUS = 0
				begin
				
				--set up the body and subject for the email
				set @sql = N' The Dataset "' + @name + '" with the datasetid "' + cast(@datasetid as nvarchar(3))  + '" failed on ' + convert(nvarchar(15),@date, 103) + ' At '+ cast(cast(@Date as time) as nvarchar(8))  + CHAR(10)  + CHAR(10) ;
				set @sql = @sql + CHAR(10) + 'The message that was returned: '  + CHAR(10)   ;
				
				set @sql = @sql + CHAR(10) + isnull(@error_text,'')+ CHAR(10) ;
				set @sql = @sql  + CHAR(10)  + 'Please log for business intelligence team, thanks';
				set @subject = 'Error On Dataset "' + @name + '" In the Exceptions Database' ;
					begin try 
					-- try and send the email
								EXEC msdb.dbo.sp_send_dbmail
								@profile_name = 'DBMail',
								@recipients = @to,
								@body = @sql,
								@subject = @subject ;
					
						update Exceptions.Exceptions.ExceptionsEmailTable set email_sent = 1 where datasetid = @datasetid
					End Try

					Begin Catch
					 --if email fails then it will set a paramater to indicated that it has failed and change the subject of the email. 
					 --It will also set the email_sent field to 0 and add the error message for each failed dataset so that it can be viewed.
							set	@failed = 1
							set @subject = 'The stored procedure Exceptions.ExceptionsEmailAlert failed at ' + convert(nvarchar(15),getdate(), 103);
						update Exceptions.Exceptions.ExceptionsEmailTable set email_sent = 0, ERROR_MESSAGE = ERROR_MESSAGE()  where datasetid = @datasetid
					End Catch

				FETCH  NEXT FROM dataset_cursor
				into @datasetid ,@name,  @date, @error_text

			end
		close dataset_cursor
		dEALLOCATE dataset_cursor
			
			-- if failed it will send an email out saying that it failed while trying to send an email
		 if @failed = 1 
				begin
						set @sql = 'The stored procedure Exceptions.ExceptionsEmailAlert failed, please review table Exceptions.Exceptions.ExceptionsEmailTable for more details '
						set @sql = @sql  + CHAR(10)  + 'Please log for business intelligence team, thanks'
						EXEC msdb.dbo.sp_send_dbmail
								@profile_name = 'DBMail',
								@recipients = @to,
								@body = @sql,
								@subject = @subject 
								
				end
END
GO

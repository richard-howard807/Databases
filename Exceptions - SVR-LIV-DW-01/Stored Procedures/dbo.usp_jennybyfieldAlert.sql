SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[usp_jennybyfieldAlert]

as


SET NOCOUNT ON
DECLARE @log VARCHAR(MAX)
SET @log = '[START][dbo.usp_jennybyfieldAlert][StartTime:'+CONVERT(VARCHAR(20),GETDATE(),13)+']'
DECLARE @cnt INT = 0


DECLARE @TestCC AS VARCHAR(MAX)


SET @TestCC='Kevin.Hansen@weightmans.com'

DECLARE
	@Client  VARCHAR(8),
	@Matter VARCHAR(8),
	@ClientName VARCHAR(60),
	@MatterDescription VARCHAR(40),
	@FeeEarnerCode VARCHAR(6),
	@USERName VARCHAR(80),
	@UserEmailAddress VARCHAR(95),
	@ClientBalance DECIMAL(13,2),
	@MT_LSTFIN DATETIME,
	@SinceUpdate INT,
	@BCMName VARCHAR(80),
	@BCMEmailAddress VARCHAR(95),
	
	@vSubject varchar(1000),
	@vRecipients varchar(100),
	@cc VARCHAR(100),
	@vBody varchar(max),
	@vImportance VARCHAR(6),
	@vTestEmail VARCHAR(95),
	@toggle INT = 1,
	@returncode INT = 0,
	@SuccessfulEmailCounter INT = 0,
	@FailedEmailCounter INT = 0,
		
	@WIP DECIMAL(10,2),
	@LastDate AS DATE,
	@DaysSinceLastTran DECIMAL(10,2),
	@FeeEarner NVARCHAR(100)
	

DECLARE @test AS INT
SET @Test=0
SET @vImportance='HIGH'

IF OBJECT_ID('tempdb..#usp_jennybyfieldAlert') IS NOT NULL DROP TABLE #usp_jennybyfieldAlert

SELECT TOP 3 dim_matter_header_current.client_code AS Client
,dim_matter_header_current.matter_number AS Matter
,matter_description AS MatterDescription
,matter_owner_full_name AS [Fee Earner]
,'Jenny.Byfield@Weightmans.com' AS UserEmailAddress
--,'Kevin.Hansen@weightmans.com' AS UserEmailAddress
,wip AS [WIP]
,last_time_transaction_date AS [LastDate]
,DATEDIFF(DAY,last_time_transaction_date,GETDATE()) AS DaysSinceLastTran

INTO #usp_jennybyfieldAlert
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_finance_summary
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code
 AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number
INNER JOIN red_dw.dbo.fact_matter_summary_current
ON dim_matter_header_current.client_code=fact_matter_summary_current.client_code
AND dim_matter_header_current.matter_number=fact_matter_summary_current.matter_number
WHERE dim_matter_header_current.date_closed_practice_management IS NULL
AND wip >0
AND DATEDIFF(DAY,last_time_transaction_date,GETDATE())=20



	

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR 


SELECT Client
,Matter
,MatterDescription
,[Fee Earner]
,UserEmailAddress
,[WIP]
,[LastDate]
,DaysSinceLastTran
FROM #usp_jennybyfieldAlert

OPEN cur 
FETCH NEXT from cur INTO 
	@Client,
	@Matter,
	@MatterDescription,
	@FeeEarner,
	@UserEmailAddress,
	@WIP,
	@LastDate,
	@DaysSinceLastTran
	
	
WHILE @@FETCH_STATUS = 0 
BEGIN 
SET @vSubject = ''
SET @vBody = ''
SET @cc = ''
SET @vRecipients = @UserEmailAddress

SET @vSubject = 'No Time Posting 14 Days: '
				+'[Client:'+@Client+'],'
				+'[Matter:'+@Matter+'],'
			

SET @vBody = '<font size="2" face= "Lucida Sans Unicode">'

		
SET @vBody = @vBody 
+'Hi,'
+'<p>'
+'The below matter has not had any time posted against it for the last 20 days;'
+'<p>'
+'Client: '+ @Client+'<br>'+
'Matter: '+ @Matter+'<br>'+
'Matter Description: '+ @MatterDescription+'<br>'+
'Case Handler Name: '+@FeeEarner+'<br>'+
'Date Last Time Posting: '+convert(varchar(11),@LastDate,13)+'<br>'
+'Please contact the fee earner to see if they would like a bill raised'
+'<p>'
+'Kindest Regards'
+'<p>'
+'<u>PLEASE DO NOT REPLAY TO THIS EMAIL. THANKS</u>'

SET @vRecipients = @UserEmailAddress
SET @cc=@TestCC		



			
	SET @returncode = -1

	EXEC @returncode = msdb.dbo.sp_send_dbmail 
	@profile_name = 'Client Compliance',

	--@recipients=@vTestEmail,
	@recipients = @vRecipients,--@UserEmailAddress,
	@copy_recipients = @cc,

	@subject= @vSubject,
	@body=@vBody,
	@importance = @vImportance,
	@body_format = 'HTML'
	
	SET @SuccessfulEmailCounter = @SuccessfulEmailCounter + (CASE WHEN @returncode = 0 THEN 1 ELSE 0 END)
	SET @FailedEmailCounter = @FailedEmailCounter + (CASE WHEN @returncode = 0 THEN 0 ELSE 1 END)
	
	
--SET @toggle = 0

FETCH NEXT FROM cur INTO
	@Client,
	@Matter,
	@MatterDescription,
	@FeeEarner,
	@UserEmailAddress,
	@WIP,
	@LastDate,
	@DaysSinceLastTran
	
END 
CLOSE cur 
DEALLOCATE cur 

SET @log = @log+'<br>'+CHAR(13)+ '[dbo.usp_jennybyfieldAlert] Successful Emails Sent: '+CAST(@SuccessfulEmailCounter AS VARCHAR)
SET @log = @log+'<br>'+CHAR(13)+ '[dbo.usp_jennybyfieldAlert] Failed Emails Sent: '+CAST(@FailedEmailCounter AS VARCHAR)
SET @log = @log+'<br>'+CHAR(13)+ '[END][dbo.usp_jennybyfieldAlert][StartTime:'+CONVERT(VARCHAR(20),GETDATE(),13)+']'

PRINT @log

SET @vSubject = 'dbo.usp_jennybyfieldAlert LOG:'+CONVERT(VARCHAR(20),GETDATE(),13)
	EXEC @returncode = msdb.dbo.sp_send_dbmail 
	@profile_name = 'Client Compliance',

	@recipients= 'kevin.hansen@weightmans.com',  --@vTestEmail,
	@subject= @vSubject,
	@body=@log,
	@importance = @vImportance,
	@body_format = 'HTML'
	



SET NOCOUNT OFF
GO

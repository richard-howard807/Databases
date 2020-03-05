SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[SSUKeyDateAlert]
AS
BEGIN
SET NOCOUNT ON
DECLARE @log VARCHAR(MAX)
SET @log = '[START][dbo.usp_PropertyKeyDateAlert][StartTime:'+CONVERT(VARCHAR(20),GETDATE(),13)+']'
DECLARE @cnt INT = 0

DECLARE @StartDate AS DATE
SET @StartDate=GETDATE()
DECLARE @test AS INT 
SET @test=0

DECLARE @To AS VARCHAR(MAX)
DECLARE @Subject AS VARCHAR(MAX)
DECLARE @DateAlert AS DATE
DECLARE @Body AS VARCHAR(MAX)
DECLARE @vSubject  AS VARCHAR(MAX)
DECLARE @vBody AS VARCHAR(MAX)
DECLARE @cc  AS VARCHAR(MAX)
DECLARE @vRecipients  AS VARCHAR(MAX)
DECLARE @Recipients  AS VARCHAR(MAX)
DECLARE @toggle INT = 1
DECLARE @returncode INT = 0
DECLARE @SuccessfulEmailCounter INT = 0
DECLARE @FailedEmailCounter INT = 0
DECLARE @vImportance  AS VARCHAR(4)
DECLARE @copy_recipients AS VARCHAR(1)=''
DECLARE @blind_copy_recipients  AS VARCHAR(1)=''
SET @vImportance = 'High'
	
  DECLARE cur CURSOR LOCAL FAST_FORWARD
    FOR



SELECT [To]
,[Subject]
,[Date Alert]
,[Body]
FROM 
(


SELECT CASE WHEN @test=1 THEN 'Kevin.Hansen@Weightmans.com' ELSE 'Janice.Weatherly@Weightmans.com' END  AS [To]
,'SSU ' + ISNULL([Email Type],'') + ' Key Date Alert' AS [Subject]
,PRO1357 AS [Date Alert]
,'<font size="2" face= "Lucida Sans Unicode">Dear All, <p> The Term End Date ' +  Convert(varchar,PRO1357,103) +
' for ' + ISNULL(RTRIM(PRO1350),'') + ',' + ISNULL(RTRIM(PRO1351),'') + ' is coming up in ' +  ISNULL([Email Type],'') + '<p>' +
CASE WHEN ISNULL([Email Type],'') IN ('3 Month','2 Month') THEN 
'If this needs to be updated or is incorrect please email SSU.Propertyview@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 month'
WHEN ISNULL([Email Type],'') ='1 Month' THEN 'If this needs to be updated or is incorrect please email ' + 'SSU.Propertyview@Weightmans.com'  + ' and we will update where necessary, otherwise you will receive another reminder in 3 weeks'
WHEN ISNULL([Email Type],'')='1 Week' THEN 'If this needs to be updated or is incorrect please email SSU.Propertyview@Weightmans.com and we will update where necessary.'
ELSE 'If this needs to be updated or is incorrect please email SSU.Propertyview@Weightmans.com and we will update where necessary.' END + '<p>' + 'Kindest regards' + '<p>' + 'Weightmans' AS Body
FROM 
(
SELECT dim_matter_header_current.client_code AS client,dim_matter_header_current.matter_number AS matter,dim_detail_property.[term_end_date] AS PRO1357
,CASE WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[term_end_date])=7 THEN '1 Week'
 WHEN DATEADD(MONTH,-1,dim_detail_property.[term_end_date]) = CAST(@StartDate AS date) THEN '1 Month'
 WHEN DATEADD(MONTH,-2,dim_detail_property.[term_end_date]) = CAST(@StartDate AS date) THEN '2 Month'
 WHEN DATEADD(MONTH,-3,dim_detail_property.[term_end_date]) = CAST(@StartDate AS date) THEN '3 Month'
 END AS [Email Type]
,dim_detail_property.[address] AS PRO1351
,dim_detail_property.[campus] AS PRO1350
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_property 
 ON dim_matter_header_current.client_code=dim_detail_property.client_code
 AND dim_matter_header_current.matter_number=dim_detail_property.matter_number

WHERE dim_matter_header_current.client_code='00696495'
AND dim_matter_header_current.matter_number <> 'ML'
AND dim_detail_property.[term_end_date] IS NOT NULL
) AS KeyDates
WHERE [Email Type] IS NOT NULL



UNION
SELECT CASE WHEN @test=1 THEN 'Kevin.Hansen@Weightmans.com' ELSE 'Janice.Weatherly@Weightmans.com' END  AS [To]
,'SSU ' + ISNULL([Email Type],'') + 'Key Date Alert' AS [Subject]
,PRO1359 AS [Date Alert]
,'<font size="2" face= "Lucida Sans Unicode">Dear All, <p> The Tenant Break Date ' +  Convert(varchar,PRO1359,103) +
' for ' + ISNULL(RTRIM(PRO1350),'') + ',' + ISNULL(RTRIM(PRO1351),'') + ' is coming up in ' +  ISNULL([Email Type],'') + '<p>' +
CASE WHEN ISNULL([Email Type],'') IN ('3 Month','2 Month') THEN 
'If this needs to be updated or is incorrect please email SSU.Propertyview@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 month'
WHEN ISNULL([Email Type],'') ='1 Month' THEN 'If this needs to be updated or is incorrect please email '  + 'SSU.Propertyview@Weightmans.com' + ' and we will update where necessary, otherwise you will receive another reminder in 3 weeks'
WHEN ISNULL([Email Type],'')='1 Week' THEN 'If this needs to be updated or is incorrect please email SSU.Propertyview@Weightmans.com and we will update where necessary.'
ELSE 'If this needs to be updated or is incorrect please email SSU.Propertyview@Weightmans.com and we will update where necessary.' END + '<p>' + 'Kindest regards' + '<p>' + 'Weightmans'
FROM 
(
SELECT dim_matter_header_current.client_code AS client,dim_matter_header_current.matter_number AS matter,dim_detail_property.[tenant_break] AS PRO1359
,CASE WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[tenant_break])=7 THEN '1 Week'
 WHEN DATEADD(MONTH,-1,dim_detail_property.[tenant_break]) = CAST(@StartDate AS date) THEN '1 Month'
 WHEN DATEADD(MONTH,-2,dim_detail_property.[tenant_break]) = CAST(@StartDate AS date) THEN '2 Month'
 WHEN DATEADD(MONTH,-3,dim_detail_property.[tenant_break]) = CAST(@StartDate AS date) THEN '3 Month'
 END AS [Email Type]
,dim_detail_property.[address] AS PRO1351
,dim_detail_property.[campus] AS PRO1350
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_property 
 ON dim_matter_header_current.client_code=dim_detail_property.client_code
 AND dim_matter_header_current.matter_number=dim_detail_property.matter_number

WHERE dim_matter_header_current.client_code='00696495'
AND dim_matter_header_current.matter_number <> 'ML'
AND dim_detail_property.[tenant_break] IS NOT NULL
) AS KeyDates
WHERE [Email Type] IS NOT NULL



UNION




SELECT CASE WHEN @test=1 THEN 'Kevin.Hansen@Weightmans.com' ELSE 'Janice.Weatherly@Weightmans.com' END  AS [To]
,'SSU ' + ISNULL([Email Type],'') + 'Key Date Alert' AS [Subject]
,PRO1158 AS [Date Alert]
,'<font size="2" face= "Lucida Sans Unicode">Dear All, <p> The Rent Review Date ' +  Convert(varchar,PRO1158,103) +
' for ' + ISNULL(RTRIM(PRO1350),'') + ',' + ISNULL(RTRIM(PRO1351),'') + ' is coming up in ' +  ISNULL([Email Type],'') + '<p>' +
CASE WHEN ISNULL([Email Type],'') IN ('3 Month','2 Month') THEN 
'If this needs to be updated or is incorrect please email SSU.Propertyview@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 month'
WHEN ISNULL([Email Type],'') ='1 Month' THEN 'If this needs to be updated or is incorrect please email ' + 'SSU.Propertyview@Weightmans.com'  + ' and we will update where necessary, otherwise you will receive another reminder in 3 weeks'
WHEN ISNULL([Email Type],'')='1 Week' THEN 'If this needs to be updated or is incorrect please email SSU.Propertyview@Weightmans.com and we will update where necessary.'
ELSE 'If this needs to be updated or is incorrect please email SSU.Propertyview@Weightmans.com and we will update where necessary.' END + '<p>' + 'Kindest regards' + '<p>' + 'Weightmans'
FROM 
(
SELECT dim_matter_header_current.client_code AS client,dim_matter_header_current.matter_number AS matter,dim_detail_property.[rent_review_dates] AS PRO1158
,CASE WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[rent_review_dates])=7 THEN '1 Week'
 WHEN DATEADD(MONTH,-1,dim_detail_property.[rent_review_dates]) = CAST(@StartDate AS date) THEN '1 Month'
 WHEN DATEADD(MONTH,-2,dim_detail_property.[rent_review_dates]) = CAST(@StartDate AS date) THEN '2 Month'
 WHEN DATEADD(MONTH,-3,dim_detail_property.[rent_review_dates]) = CAST(@StartDate AS date) THEN '3 Month'
 END AS [Email Type]
,dim_detail_property.[address] AS PRO1351
,dim_detail_property.[campus] AS PRO1350
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_property 
 ON dim_matter_header_current.client_code=dim_detail_property.client_code
 AND dim_matter_header_current.matter_number=dim_detail_property.matter_number

WHERE dim_matter_header_current.client_code='00696495'
AND dim_matter_header_current.matter_number <> 'ML'
AND dim_detail_property.[rent_review_dates] IS NOT NULL
) AS KeyDates
WHERE [Email Type] IS NOT NULL
) AS AllEmails


 OPEN cur 
    FETCH NEXT FROM cur INTO @To
,@Subject
,@DateAlert
,@Body
    WHILE @@FETCH_STATUS = 0 
        BEGIN 
            SET @vSubject = ''
            SET @vBody = ''
            SET @cc = ''
            SET @vRecipients = ISNULL(@To,'')

            SET @vSubject = @Subject 


            SET @vBody = @Body
		    SET @cc = ''
            BEGIN

                
			
                SET @returncode = -1

                EXEC @returncode = msdb.dbo.sp_send_dbmail @profile_name = 'DEFAULT',
                    @recipients = @vRecipients,--@UserEmailAddress,
                   
                    @subject = @vSubject,
                    @body = @vBody, @importance = @vImportance,
                    @body_format = 'HTML'
	
                SET @SuccessfulEmailCounter = @SuccessfulEmailCounter
                    + ( CASE WHEN @returncode = 0 THEN 1
                             ELSE 0
                        END )
                SET @FailedEmailCounter = @FailedEmailCounter
                    + ( CASE WHEN @returncode = 0 THEN 0
                             ELSE 1
                        END )
	
            END

           -- WAITFOR DELAY '00:00:10'

            FETCH NEXT FROM cur INTO @To
,@Subject
,@DateAlert
,@Body

        END 
    CLOSE cur 
    DEALLOCATE cur 

    --SET @log = @log + '<br>' + CHAR(13)
    --    + '[dbo.usp_PropertyKeyDateAlert] Successful Emails Sent: '
    --    + CAST(@SuccessfulEmailCounter AS VARCHAR)
    --SET @log = @log + '<br>' + CHAR(13)
    --    + '[dbo.usp_PropertyKeyDateAlert] Failed Emails Sent: '
    --    + CAST(@FailedEmailCounter AS VARCHAR)
    --SET @log = @log + '<br>' + CHAR(13)
    --    + '[END  ][dbo.usp_PropertyKeyDateAlert][StartTime:'
    --    + CONVERT(VARCHAR(20), GETDATE(), 13) + ']'

    --PRINT @log

    --SET @vSubject = 'dbo.usp_PropertyKeyDateAlert LOG:'
    --    + CONVERT(VARCHAR(20), GETDATE(), 13)
    --EXEC @returncode = msdb.dbo.sp_send_dbmail @profile_name = 'DEFAULT',
    --    @recipients = @To, @subject = @vSubject, @body = @log,
    --    @importance = @vImportance, @body_format = 'HTML'
	



    SET NOCOUNT OFF
END

GO

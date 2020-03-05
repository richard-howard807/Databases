SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[PentlandKeyDateAlert]   --EXEC [Client].[PentlandKeyDateAlert]
AS
BEGIN
SET NOCOUNT ON
DECLARE @log VARCHAR(MAX)
SET @log = '[START][dbo.usp_PropertyKeyDateAlert][StartTime:'+CONVERT(VARCHAR(20),GETDATE(),13)+']'
DECLARE @cnt INT = 0

DECLARE @StartDate AS DATE
SET @StartDate= GETDATE()
DECLARE @test AS INT 
SET @test= 0

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
SELECT CASE WHEN @test=1 THEN 'Eifion.Williams2@Weightmans.com' ELSE 'Saudat.Chowe@weightmans.com' END  AS [To]
,'Pentland ' + ISNULL([Email Type],'') + ' Key Date Alert' AS [Subject]
,PRO1192 AS [Date Alert]
,'<font size="2" face= "Lucida Sans Unicode">Dear All, <p> The 3rd Rent Review Date ' +  Convert(varchar,PRO1192,103) +
' for ' + ISNULL(RTRIM(PRO451),'') + ', ' + ISNULL(RTRIM(PRO1546),'') + ' is coming up in ' +  ISNULL([Email Type],'') + '<p>' +
CASE WHEN ISNULL([Email Type],'') IN ('12 Months','9 Months','6 Months') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 3 months'
	 WHEN ISNULL([Email Type],'') IN ('3 Months','2 Months') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 month'
	 WHEN ISNULL([Email Type],'') IN ('1 Month','3 Weeks','2 Weeks') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 week'
	 WHEN ISNULL([Email Type],'') = '1 Week' THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder the day before'
	 ELSE
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary.' 
END + '<p>' + 'Kindest regards' + '<p>' + 'Weightmans' AS Body
FROM 
(
SELECT dim_matter_header_current.client_code AS client,dim_matter_header_current.matter_number AS matter,dim_detail_property.[third_rent_review] AS PRO1192
,CASE WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[third_rent_review])=1 THEN '1 Day'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[third_rent_review])=7 THEN '1 Week'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[third_rent_review])=14 THEN '2 Weeks'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[third_rent_review])=21 THEN '3 Weeks'
 WHEN DATEADD(MONTH,-1,dim_detail_property.[third_rent_review]) = CAST(@StartDate AS date) THEN '1 Month'
 WHEN DATEADD(MONTH,-2,dim_detail_property.[third_rent_review]) = CAST(@StartDate AS date) THEN '2 Months'
 WHEN DATEADD(MONTH,-3,dim_detail_property.[third_rent_review]) = CAST(@StartDate AS date) THEN '3 Months'
 WHEN DATEADD(MONTH,-6,dim_detail_property.[third_rent_review]) = CAST(@StartDate AS date) THEN '6 Months'
 WHEN DATEADD(MONTH,-9,dim_detail_property.[third_rent_review]) = CAST(@StartDate AS date) THEN '9 Months'
 WHEN DATEADD(MONTH,-12,dim_detail_property.[third_rent_review]) = CAST(@StartDate AS date) THEN '12 Months'
 END AS [Email Type]
,dim_detail_property.[property_name_] AS PRO451
,dim_detail_property.[brand] AS PRO1546
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_property 
 ON dim_matter_header_current.client_code=dim_detail_property.client_code
 AND dim_matter_header_current.matter_number=dim_detail_property.matter_number
WHERE  case_id in (558021,558022,558023,558024,558025,558026,558027,558028,558029,558030,558031,558032,558033,558034,
				   558035,558036,558037,558038,558039,558040,558041,558042,558043,558044,558045,558046,558047,558048,
				   558049,558050,558051,558052,558053,558054,558055,558056,558057,558058,558059,558060,558061,558062,
				   558063,558064,558065)
AND dim_matter_header_current.matter_number <> 'ML'
AND dim_detail_property.[third_rent_review] IS NOT NULL
) AS KeyDates
WHERE [Email Type] IS NOT NULL

UNION
SELECT CASE WHEN @test=1 THEN 'Eifion.Williams2@Weightmans.com' ELSE 'Saudat.Chowe@weightmans.com' END  AS [To]
,'Pentland ' + ISNULL([Email Type],'') + ' Key Date Alert' AS [Subject]
,PRO1191 AS [Date Alert]
,'<font size="2" face= "Lucida Sans Unicode">Dear All, <p> The 2nd Rent Review Date ' +  Convert(varchar,PRO1191,103) +
' for ' + ISNULL(RTRIM(PRO451),'') + ', ' + ISNULL(RTRIM(PRO1546),'') + ' is coming up in ' +  ISNULL([Email Type],'') + '<p>' +
CASE WHEN ISNULL([Email Type],'') IN ('12 Months','9 Months','6 Months') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 3 months'
	 WHEN ISNULL([Email Type],'') IN ('3 Months','2 Months') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 month'
	 WHEN ISNULL([Email Type],'') IN ('1 Month','3 Weeks','2 Weeks') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 week'
	 WHEN ISNULL([Email Type],'') = '1 Week' THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder the day before'
	 ELSE
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary.' 
END + '<p>' + 'Kindest regards' + '<p>' + 'Weightmans' AS Body
FROM 
(
SELECT dim_matter_header_current.client_code AS client,dim_matter_header_current.matter_number AS matter,dim_detail_property.[second_rent_review] AS PRO1191
,CASE WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[second_rent_review])=1 THEN '1 Day'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[second_rent_review])=7 THEN '1 Week'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[second_rent_review])=14 THEN '2 Weeks'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[second_rent_review])=21 THEN '3 Weeks'
 WHEN DATEADD(MONTH,-1,dim_detail_property.[second_rent_review]) = CAST(@StartDate AS date) THEN '1 Month'
 WHEN DATEADD(MONTH,-2,dim_detail_property.[second_rent_review]) = CAST(@StartDate AS date) THEN '2 Months'
 WHEN DATEADD(MONTH,-3,dim_detail_property.[second_rent_review]) = CAST(@StartDate AS date) THEN '3 Months'
 WHEN DATEADD(MONTH,-6,dim_detail_property.[second_rent_review]) = CAST(@StartDate AS date) THEN '6 Months'
 WHEN DATEADD(MONTH,-9,dim_detail_property.[second_rent_review]) = CAST(@StartDate AS date) THEN '9 Months'
 WHEN DATEADD(MONTH,-12,dim_detail_property.[second_rent_review]) = CAST(@StartDate AS date) THEN '12 Months'
 END AS [Email Type]
,dim_detail_property.[property_name_]  AS PRO451
,dim_detail_property.[brand] AS PRO1546
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_property 
 ON dim_matter_header_current.client_code=dim_detail_property.client_code
 AND dim_matter_header_current.matter_number=dim_detail_property.matter_number
WHERE  case_id in (558021,558022,558023,558024,558025,558026,558027,558028,558029,558030,558031,558032,558033,558034,
				   558035,558036,558037,558038,558039,558040,558041,558042,558043,558044,558045,558046,558047,558048,
				   558049,558050,558051,558052,558053,558054,558055,558056,558057,558058,558059,558060,558061,558062,
				   558063,558064,558065)
AND dim_matter_header_current.matter_number <> 'ML'
AND dim_detail_property.[second_rent_review] IS NOT NULL
) AS KeyDates
WHERE [Email Type] IS NOT NULL

UNION
SELECT CASE WHEN @test=1 THEN 'Eifion.Williams2@Weightmans.com' ELSE 'Saudat.Chowe@weightmans.com' END  AS [To]
,'Pentland ' + ISNULL([Email Type],'') + ' Key Date Alert' AS [Subject]
,PRO1158 AS [Date Alert]
,'<font size="2" face= "Lucida Sans Unicode">Dear All, <p> The Rent Review Date ' +  Convert(varchar,PRO1158,103) +
' for ' + ISNULL(RTRIM(PRO451),'') + ', ' + ISNULL(RTRIM(PRO1546),'') + ' is coming up in ' +  ISNULL([Email Type],'') + '<p>' +
CASE WHEN ISNULL([Email Type],'') IN ('12 Months','9 Months','6 Months') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 3 months'
	 WHEN ISNULL([Email Type],'') IN ('3 Months','2 Months') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 month'
	 WHEN ISNULL([Email Type],'') IN ('1 Month','3 Weeks','2 Weeks') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 week'
	 WHEN ISNULL([Email Type],'') = '1 Week' THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder the day before'
	 ELSE
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary.' 
END + '<p>' + 'Kindest regards' + '<p>' + 'Weightmans' AS Body
FROM 
(
SELECT dim_matter_header_current.client_code AS client,dim_matter_header_current.matter_number AS matter,dim_detail_property.[rent_review_dates] AS PRO1158
,CASE WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[rent_review_dates])=1 THEN '1 Day'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[rent_review_dates])=7 THEN '1 Week'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[rent_review_dates])=14 THEN '2 Weeks'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[rent_review_dates])=21 THEN '3 Weeks'
 WHEN DATEADD(MONTH,-1,dim_detail_property.[rent_review_dates]) = CAST(@StartDate AS date) THEN '1 Month'
 WHEN DATEADD(MONTH,-2,dim_detail_property.[rent_review_dates]) = CAST(@StartDate AS date) THEN '2 Months'
 WHEN DATEADD(MONTH,-3,dim_detail_property.[rent_review_dates]) = CAST(@StartDate AS date) THEN '3 Months'
 WHEN DATEADD(MONTH,-6,dim_detail_property.[rent_review_dates]) = CAST(@StartDate AS date) THEN '6 Months'
 WHEN DATEADD(MONTH,-9,dim_detail_property.[rent_review_dates]) = CAST(@StartDate AS date) THEN '9 Months'
 WHEN DATEADD(MONTH,-12,dim_detail_property.[rent_review_dates]) = CAST(@StartDate AS date) THEN '12 Months'
 END AS [Email Type]
,dim_detail_property.[property_name_] AS PRO451
,dim_detail_property.[brand] AS PRO1546
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_property 
 ON dim_matter_header_current.client_code=dim_detail_property.client_code
 AND dim_matter_header_current.matter_number=dim_detail_property.matter_number
WHERE  case_id in (558021,558022,558023,558024,558025,558026,558027,558028,558029,558030,558031,558032,558033,558034,
				   558035,558036,558037,558038,558039,558040,558041,558042,558043,558044,558045,558046,558047,558048,
				   558049,558050,558051,558052,558053,558054,558055,558056,558057,558058,558059,558060,558061,558062,
				   558063,558064,558065)
AND dim_matter_header_current.matter_number <> 'ML'
AND dim_detail_property.[rent_review_dates] IS NOT NULL
) AS KeyDates
WHERE [Email Type] IS NOT NULL

UNION
SELECT CASE WHEN @test=1 THEN 'Eifion.Williams2@Weightmans.com' ELSE 'Saudat.Chowe@weightmans.com' END  AS [To]
,'Pentland ' + ISNULL([Email Type],'') + ' Key Date Alert' AS [Subject]
,PRO1594 AS [Date Alert]
,'<font size="2" face= "Lucida Sans Unicode">Dear All, <p> The Break Notice Date ' +  --Convert(varchar,PRO1594,103) +
' for ' + ISNULL(RTRIM(PRO1351),'') + ', ' + ISNULL(RTRIM(PRO1546),'') + ' is ' + Convert(varchar,PRO1594,103) + '<p>' +
--'This is coming up in ' +  ISNULL([Email Type],'') + '<p>' +
CASE WHEN ISNULL([Email Type],'') IN ('12 Months','9 Months','6 Months') THEN 
'This is coming up in ' +  ISNULL([Email Type],'') + ' and this is the latest date by which the notice can be served (You should allow an additional 3 days for service).' + '<p>' +
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 3 months'
	 WHEN ISNULL([Email Type],'') IN ('3 Months','2 Months') THEN 
'This is coming up in ' +  ISNULL([Email Type],'') + ' and this is the latest date by which the notice can be served (You should allow an additional 3 days for service).' + '<p>' +
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 month'
	 WHEN ISNULL([Email Type],'') IN ('1 Month','3 Weeks','2 Weeks') THEN 
'This is coming up in ' +  ISNULL([Email Type],'') + ' and this is the latest date by which the notice can be served (You should allow an additional 3 days for service).' + '<p>' +
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 week'
	 WHEN ISNULL([Email Type],'') = '1 Week' THEN 
'This is coming up in ' +  ISNULL([Email Type],'') + ' and this is the latest date by which the notice can be served (You should allow an additional 3 days for service).' + '<p>' +
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder the day before'
	 ELSE
'This is coming up in ' +  ISNULL([Email Type],'') + ' and this is the latest date by which the notice can be served (You should allow an additional 3 days for service).' + '<p>' +
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary.' 
END + '<p>' + 'Kindest regards' + '<p>' + 'Weightmans' AS Body
FROM 
(
SELECT dim_matter_header_current.client_code AS client,dim_matter_header_current.matter_number AS matter,dim_detail_property.[actual_break_date] AS PRO1594
,CASE WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[actual_break_date])=1 THEN '1 Day'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[actual_break_date])=7 THEN '1 Week'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[actual_break_date])=14 THEN '2 Weeks'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[actual_break_date])=21 THEN '3 Weeks'
 WHEN DATEADD(MONTH,-1,dim_detail_property.[actual_break_date]) = CAST(@StartDate AS date) THEN '1 Month'
 WHEN DATEADD(MONTH,-2,dim_detail_property.[actual_break_date]) = CAST(@StartDate AS date) THEN '2 Months'
 WHEN DATEADD(MONTH,-3,dim_detail_property.[actual_break_date]) = CAST(@StartDate AS date) THEN '3 Months'
 WHEN DATEADD(MONTH,-6,dim_detail_property.[actual_break_date]) = CAST(@StartDate AS date) THEN '6 Months'
 WHEN DATEADD(MONTH,-9,dim_detail_property.[actual_break_date]) = CAST(@StartDate AS date) THEN '9 Months'
 WHEN DATEADD(MONTH,-12,dim_detail_property.[actual_break_date]) = CAST(@StartDate AS date) THEN '12 Months'
 END AS [Email Type]
,dim_detail_property.[address] AS PRO1351
,dim_detail_property.[brand] AS PRO1546
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_property 
 ON dim_matter_header_current.client_code=dim_detail_property.client_code
 AND dim_matter_header_current.matter_number=dim_detail_property.matter_number
WHERE  case_id in (558021,558022,558023,558024,558025,558026,558027,558028,558029,558030,558031,558032,558033,558034,
				   558035,558036,558037,558038,558039,558040,558041,558042,558043,558044,558045,558046,558047,558048,
				   558049,558050,558051,558052,558053,558054,558055,558056,558057,558058,558059,558060,558061,558062,
				   558063,558064,558065)
AND dim_matter_header_current.matter_number <> 'ML'
AND dim_detail_property.[actual_break_date] IS NOT NULL
) AS KeyDates
WHERE [Email Type] IS NOT NULL

UNION
SELECT CASE WHEN @test=1 THEN 'Eifion.Williams2@Weightmans.com' ELSE 'Saudat.Chowe@weightmans.com' END  AS [To]
,'Pentland ' + ISNULL([Email Type],'') + ' Key Date Alert' AS [Subject]
,PRO1294 AS [Date Alert]
,'<font size="2" face= "Lucida Sans Unicode">Dear All, <p> The Lease End Date ' +  Convert(varchar,PRO1294,103) +
' for ' + ISNULL(RTRIM(PRO451),'') + ', ' + ISNULL(RTRIM(PRO1546),'') + ' is coming up in ' +  ISNULL([Email Type],'') + '<p>' +
CASE WHEN ISNULL([Email Type],'') IN ('12 Months','9 Months','6 Months') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 3 months'
	 WHEN ISNULL([Email Type],'') IN ('3 Months','2 Months') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 month'
	 WHEN ISNULL([Email Type],'') IN ('1 Month','3 Weeks','2 Weeks') THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder in 1 week'
	 WHEN ISNULL([Email Type],'') = '1 Week' THEN 
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary, otherwise you will receive another reminder the day before'
	 ELSE
'If this needs to be updated or is incorrect please email Pentland.PropertyView@Weightmans.com and we will update where necessary.' 
END + '<p>' + 'Kindest regards' + '<p>' + 'Weightmans' AS Body
FROM 
(
SELECT dim_matter_header_current.client_code AS client,dim_matter_header_current.matter_number AS matter,dim_detail_property.[lease_end_date] AS PRO1294
,CASE WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[lease_end_date])=1 THEN '1 Day'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[lease_end_date])=7 THEN '1 Week'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[lease_end_date])=14 THEN '2 Weeks'
 WHEN DATEDIFF(DAY,@StartDate,dim_detail_property.[lease_end_date])=21 THEN '3 Weeks'
 WHEN DATEADD(MONTH,-1,dim_detail_property.[lease_end_date]) = CAST(@StartDate AS date) THEN '1 Month'
 WHEN DATEADD(MONTH,-2,dim_detail_property.[lease_end_date]) = CAST(@StartDate AS date) THEN '2 Months'
 WHEN DATEADD(MONTH,-3,dim_detail_property.[lease_end_date]) = CAST(@StartDate AS date) THEN '3 Months'
 WHEN DATEADD(MONTH,-6,dim_detail_property.[lease_end_date]) = CAST(@StartDate AS date) THEN '6 Months'
 WHEN DATEADD(MONTH,-9,dim_detail_property.[lease_end_date]) = CAST(@StartDate AS date) THEN '9 Months'
 WHEN DATEADD(MONTH,-12,dim_detail_property.[lease_end_date]) = CAST(@StartDate AS date) THEN '12 Months'
 END AS [Email Type]
,dim_detail_property.[property_name_] AS PRO451
,dim_detail_property.[brand] AS PRO1546
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_property 
 ON dim_matter_header_current.client_code=dim_detail_property.client_code
 AND dim_matter_header_current.matter_number=dim_detail_property.matter_number
WHERE  case_id in (558021,558022,558023,558024,558025,558026,558027,558028,558029,558030,558031,558032,558033,558034,
				   558035,558036,558037,558038,558039,558040,558041,558042,558043,558044,558045,558046,558047,558048,
				   558049,558050,558051,558052,558053,558054,558055,558056,558057,558058,558059,558060,558061,558062,
				   558063,558064,558065)
AND dim_matter_header_current.matter_number <> 'ML'
AND dim_detail_property.[lease_end_date] IS NOT NULL
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

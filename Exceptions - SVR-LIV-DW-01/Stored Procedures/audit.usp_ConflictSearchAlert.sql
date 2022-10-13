SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- LD 20150618 Amended to Replace Beccy McDowell with Jenny Barr
-- ES 20161214 Amended to exclude client number W16179 requested by Jenny Barr ticket 193211
-- SG 20170201 Changes to the Email layout
-- SG 20170531 Changes to the Email address requested by Jenny Barr   ticket -- 232914 
-- JL 20171201 Changed email address and message tic  ket 271706 
-- KH 20190312 New version created to point at mattersphere
-- JL 20220223 #135063 Changed to email from Hillary Stephenson to John Thompson
 

CREATE  PROC [audit].[usp_ConflictSearchAlert]
(
@test AS INT
)
AS 
    SET NOCOUNT ON
    DECLARE @log VARCHAR(MAX)
    SET @log = '[START][AUDIT.usp_ConflictSearchAlert][StartTime:'
        + CONVERT(VARCHAR(20), GETDATE(), 103) + ']'
    DECLARE @cnt INT = 0


    DECLARE @Client VARCHAR(8) ,
        @Matter VARCHAR(8) ,
        @ClientName VARCHAR(60) ,
        @MatterDescription VARCHAR(40) ,
        @FeeEarnerCode VARCHAR(4) ,
        @USERName VARCHAR(80) ,
        @UserEmailAddress VARCHAR(95) ,
        @Dateopened DATE ,
        @BCMName VARCHAR(80) ,
        @BCMEmailAddress VARCHAR(95) ,
        @EmailType AS VARCHAR(20) ,
        @vSubject VARCHAR(1000) ,
        @vRecipients VARCHAR(100) ,
        @cc VARCHAR(100) ,
        @vBody VARCHAR(MAX) ,
        @vImportance VARCHAR(6) ,
        @vTestEmail VARCHAR(95) ,
        @toggle INT = 1 ,
        @returncode INT = 0 ,
        @SuccessfulEmailCounter INT = 0 ,
        @recipients AS VARCHAR(90) ,
        @copy_recipients AS VARCHAR(50) ,
        @blind_copy_recipients AS VARCHAR(90) ,
        @FailedEmailCounter INT = 0


    SET @vImportance = 'High'
    SET @vTestEmail = 'Kevin.Hansen@Weightmans.com'

    DECLARE cur CURSOR LOCAL FAST_FORWARD
    FOR
        SELECT DISTINCT
                client_code AS Client ,
                matter_number AS Matter ,
                client_name AS ClientName ,
                matter_description AS MatterDescription ,
                fee_earner_code AS FeeEarnerCode ,
                name AS USERName ,
                CASE WHEN @test = 1 THEN 'Kevin.Hansen@Weightmans.com'
                     ELSE workemail
                END AS UserEmailAddress ,
                date_opened_case_management AS Dateopened ,
                worksforname AS BCMName ,
                CASE WHEN @test = 1 THEN 'Kevin.Hansen@Weightmans.com'
                     ELSE worksforemail
                END AS BCMEmailAddress ,
                 CASE WHEN DATEDIFF(d,
                                                       CONVERT(DATE, tskDue, 103),
                                                       GETDATE()) = 3
                                         THEN 'FeeEarner'
                                         WHEN DATEDIFF(d,
                                                       CONVERT(DATE, tskDue, 103),
                                                       GETDATE()) = 7
                                         THEN 'BCMandAudits'
                                    END AS EmailType
FROM MS_PROD.dbo.dbTasks 
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dbTasks.fileid=ms_fileid
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE tskFilter IN ('tsk_065_01_020_ConflictSearch','tsk_01_030_remconflictcheck','tsk_01_060_REMCompleteConflictCheck')
AND tskComplete=0
AND tskActive=1
AND reporting_exclusions=0
AND client_code <>'00030645'
AND date_closed_practice_management IS NULL
AND fileID NOT IN (SELECT fileID FROM ms_prod.dbo.udExtFile
WHERE CRSystemSourceID LIKE 'NHS%') -- #151948 exclude the ward hadaway cases
AND (CASE WHEN DATEDIFF(d,
                                                       CONVERT(DATE, tskDue, 103),
                                                       GETDATE()) = 3
                                         THEN 'FeeEarner'
                                         WHEN DATEDIFF(d,
                                                       CONVERT(DATE, tskDue, 103),
                                                       GETDATE()) = 7
                                         THEN 'BCMandAudits'
                                    END) IS NOT NULL

ORDER BY dim_matter_header_current.client_code,matter_number
                    


    OPEN cur 
    FETCH NEXT FROM cur INTO @Client, @Matter, @ClientName, @MatterDescription,
        @FeeEarnerCode, @USERName, @UserEmailAddress, @Dateopened, @BCMName,
        @BCMEmailAddress, @EmailType
    WHILE @@FETCH_STATUS = 0 
        BEGIN 
            SET @vSubject = ''
            SET @vBody = ''
            SET @cc = ''
            SET @vRecipients = @UserEmailAddress

            SET @vSubject = 'Conflict Procedure Alert: ' + RTRIM(@Client) + '-'
                + @Matter + ' ' + RTRIM(@MatterDescription)  


            SET @vBody = '<font size="2" face= "Lucida Sans Unicode">'
                + 'Client: ' + @Client + '<br>' + 'Matter: ' + @Matter
                + '<br>' + 'Client Name: ' + @ClientName + '<br>'
                + 'Matter Description: ' + @MatterDescription + '<br>'
                + '<br>'


            SET @vBody = @vBody + 'This file was opened on '
                + CONVERT(VARCHAR(10), @DateOpened, 103) + '.' + '<p>'
                + 'The conflict procedure is incomplete/outstanding – the entire procedure should be run at the outset of the file being opened.'
                + '<p>'
                + 'ACTION REQUIRED (IF NOT ALREADY DONE SO): 
						<ol>
							<li>Complete and save conflict search to case plan.</li>
							<li>Complete conflict procedure following review of conflict results.</li>
							<li>Complete relevant conflict note (e.g. complete “DOC – Conflict Note B” ).</li>
						</ol>'
                + '<p>'
                + 'Please ensure the conflict procedure is completed today.'
                + '<p>'
                + 'Should you have any queries or if you are unsure what to do, please contact Hillary Stephenson at 
					hillary.stephenson@weightmans.com or on extension 137352 or Angie Shepherd at 
						angela.shepherd@weightmans.com or on extension 133399  '

            SET @vBody = @vBody + '<br>' + '<p>' + 'Fee Earner Code: '
                + @FeeEarnerCode + '<br>' + 'Fee Earner Name: ' + @USERName
                + '<br>' + 'Fee Earner Email Address: ' + @UserEmailAddress
                + '<br>' + 'BCM Name: ' + @BCMName + '<br>'
                + 'BCM Email Address: ' + @BCMEmailAddress + '<p>'
                + '<b>This is a system generated email. Please do not reply.</b>'

            BEGIN

                IF @EmailType = 'FeeEarner' 
                    BEGIN --main email to BCM, cc'd to Sue, and FEE EARNER
                        SET @vRecipients = @UserEmailAddress
                       -- SET @cc = 'Jenny.Norman@Weightmans.com'
                        SET @cc = @BCMEmailAddress + ';' + @cc

                    END
                IF @EmailType = 'BCMandAudits' 
                    BEGIN --main email to BCM, cc'd to Sue, and FEE EARNER
                        SET @vRecipients = @BCMEmailAddress + ';'
                            + @UserEmailAddress + ';'
                            + 'Rachel.Mead@Weightmans.com'--'jenny.barr@weightmans.com' --+ ';' + 'Kevin.Hansen@Weightmans.com'
                        
                        --SET @cc = 'Jenny.Norman@Weightmans.com'
                        --SET @cc = @BCMEmailAddress + ';' + @cc

                    END		
			
                SET @returncode = -1

                EXEC @returncode = msdb.dbo.sp_send_dbmail @profile_name = NULL,
                    @recipients = @vRecipients,--@UserEmailAddress,
                    @copy_recipients = @cc, @subject = @vSubject,
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

            FETCH NEXT FROM cur INTO @Client, @Matter, @ClientName,
                @MatterDescription, @FeeEarnerCode, @USERName,
                @UserEmailAddress, @Dateopened, @BCMName, @BCMEmailAddress,
                @EmailType

        END 
    CLOSE cur 
    DEALLOCATE cur 

    SET @log = @log + '<br>' + CHAR(13)
        + '[AUDIT.usp_ConflictSearchAlert] Successful Emails Sent: '
        + CAST(@SuccessfulEmailCounter AS VARCHAR)
    SET @log = @log + '<br>' + CHAR(13)
        + '[AUDIT.usp_ConflictSearchAlert] Failed Emails Sent: '
        + CAST(@FailedEmailCounter AS VARCHAR)
    SET @log = @log + '<br>' + CHAR(13)
        + '[END  ][AUDIT.usp_ConflictSearchAlert][StartTime:'
        + CONVERT(VARCHAR(20), GETDATE(), 13) + ']'

    PRINT @log

    SET @vSubject = 'AUDIT.usp_ConflictSearchAlert LOG:'
        + CONVERT(VARCHAR(20), GETDATE(), 13)
    EXEC @returncode = msdb.dbo.sp_send_dbmail @profile_name = NULL,
        @recipients = @vTestEmail, @subject = @vSubject, @body = @log,
        @importance = @vImportance, @body_format = 'HTML'
	



    SET NOCOUNT OFF





























GO

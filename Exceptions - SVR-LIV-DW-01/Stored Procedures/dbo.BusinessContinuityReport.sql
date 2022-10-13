SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author: Fai Ho Fu
-- Create date: 23/12/2010
-- Description: replacement Business Continuity report from axxidxsvr
-- this uses a cursor to loop through the emails to be sent to the bcm, and managers
-- objects used are:
-- dw.tbl_HighTide
-- DW.tbl_BusinessContinuityReport
-- dw.dim_employee
-- [cascade].dbo.Employee e
-- [CasCade].dbo.EmployeeHomeAddress
-- dw.usp_BusinessContinuityReport

-- RH Updated 25/03/2020 - Moved from 2008 server and modified to use red_dw instead of cascade.
-- Sends an email to all managers with a list of their employees phone numbers
-- To send to all managers execute SP 
-- To test change recipients param at bottom of proc where it sends the mail. You can limit the number of emails sent by changing the where clause in the #fullhierarchy query
-- =============================================
Create PROC [dbo].[BusinessContinuityReport]

AS

SET NOCOUNT ON;

DECLARE @BusinessContinuityKey INT,
		@Relationship VARCHAR(100),
        @UserID1 UNIQUEIDENTIFIER,
        @KnownAs1 VARCHAR(100),
        @Surname1 VARCHAR(100),
        @EmailAddress1 VARCHAR(100),
        @cnt INT = 0,
        @returncode INT,
        @vSubject VARCHAR(1000),
        @vBody VARCHAR(MAX),
        @vSQL VARCHAR(MAX);


PRINT 'DW.tbl_BusinessContinuityReport_New'

-- Creates business hierarchy

IF OBJECT_ID('tempdb..#FullHierarchy') IS NOT NULL
    DROP TABLE [#FullHierarchy];
CREATE TABLE [#FullHierarchy]
(
    [EmployeeEmployeeID] UNIQUEIDENTIFIER,
    [EmployeeForename] [VARCHAR](50),
    [EmployeeSurname] [VARCHAR](50),
    [EmployeeKnownAs] [VARCHAR](50),
    [EmployeeEmailAddress] [VARCHAR](150),
    [EmployeeManagerID] UNIQUEIDENTIFIER,
    [EmployeeReportingBCMID] UNIQUEIDENTIFIER,
    [ManagerEmployeeID] UNIQUEIDENTIFIER,
    [ManagerForename] [VARCHAR](50),
    [ManagerSurname] [VARCHAR](50),
    [ManagerKnownAs] [VARCHAR](50),
    [ManagerEmailAddress] [VARCHAR](150),
    [BCMEmployeeID] UNIQUEIDENTIFIER,
    [BCMForename] [VARCHAR](50),
    [BCMSurname] [VARCHAR](50),
    [BCMKnownAs] [VARCHAR](50),
    [BCMEmailAddress] [VARCHAR](150)
);

INSERT INTO [#FullHierarchy]
SELECT 
    --emp.EmployeeKey,
    --emp.UserID [EmployeeUserID],
       [emp].employeeid [EmployeeEmployeeID],
       [emp1].forename [EmployeeForename],
       --emp.MiddleName [EmployeeMiddlename],
       [emp1].surname [EmployeeSurname],
       [emp1].knownas [EmployeeKnownAs],
       [emp1].workemail [EmployeeEmailAddress],
       [emp].worksforemployeeid [EmployeeManagerID],
       [emp].reportingbcmidud [EmployeeReportingBCMID],

       --Manager.EmployeeKey [ManagerEmployeeKey],
       --Manager.UserID [ManagerUserID],
       [manager].employeeid [ManagerEmployeeID],
       [manager1].forename [ManagerForename],
       --Manager.MiddleName [ManagerMiddlename],
       [manager1].surname [ManagerSurname],
       [manager1].knownas [ManagerKnownAs],
       [manager1].workemail [ManagerEmailAddress],

       --BCM.UserID [BCMUserID],
       [bcm].employeeid [BCMEmployeeID],
       [bcm1].forename [BCMForename],
       --BCM.MiddleName [BCMiddlename],
       [bcm1].surname [BCMSurname],
       [bcm1].knownas [BCMKnownAs],
       [bcm1].workemail [BCMEmailAddress]
	   -- select *
FROM red_dw.dbo.load_cascade_employee_jobs [emp]-- [DW].[dim_CascadeEmployeeDetails] [emp]
   INNER JOIN red_dw.dbo.load_cascade_employee [emp1] ON [emp1].employeeid = emp.employeeid
	JOIN
    (
        SELECT *,
               RANK() OVER (PARTITION BY employeeid,
                                         relatedsystemidud
                            ORDER BY activeud DESC
                           ) [RNK]
						   -- select *
        FROM -- [Cascade].[dbo].[EmployeeLogins_CLIENT]
			red_dw.dbo.ds_sh_employee_logins_client
    ) [clilog]
        ON [emp].employeeid = [clilog].employeeid
           AND relatedsystemidud = 'NT Login'
           AND [RNK] = 1
           --AND Activeud = 1
           AND leaver = 0
    LEFT JOIN red_dw.dbo.load_cascade_employee_jobs [manager] -- [DW].[dim_CascadeEmployeeDetails] [manager]
        ON [manager].employeeid = [emp].worksforemployeeid
           AND [manager].sys_activejob = 1
	LEFT outer JOIN red_dw.dbo.load_cascade_employee [manager1] ON [manager].employeeid = [manager1].employeeid
    LEFT JOIN red_dw.dbo.load_cascade_employee_jobs [bcm] -- [DW].[dim_CascadeEmployeeDetails] [bcm]
        ON [bcm].employeeid = [emp].reportingbcmidud
           AND [bcm].sys_activejob = 1
	 LEFT outer JOIN red_dw.dbo.load_cascade_employee [bcm1] ON [bcm].employeeid = [bcm1].employeeid
WHERE [emp].sys_activejob = 1
--AND emp1.forename = 'Richard' AND emp1.surname = 'Howard'
AND emp.hierarchynode = '1006'
ORDER BY [BCMSurname],
         [BCMForename],      --[BCMUserID],
         [ManagerSurname],
         [ManagerForename],  --[ManagerUserID],
         [EmployeeSurname],
         [EmployeeForename]; --[EmployeeUserid]



SELECT ROW_NUMBER() OVER (ORDER BY phone.DisplayEmployeeId) [BusinessContinuityKey],
	   [RelationShip],
       [UserID1],
       [KnownAs1],
       [Surname1],
       [EmailAddress1],
       [UserID2],
       [KnownAs2],
       [Surname2],
       [EmailAddress2],
       [EmployeeID2] [EmployeeID2],
       RANK() OVER (PARTITION BY [RelationShip],
                                 [UserID1]
                    ORDER BY [RelationShip],
                             [UserID1],
                             [UserID2]
                   ) [Rank],
       --CASE WHEN EmailAddress1 = EmailAddress2 THEN 1 ELSE 0 END [MatchingEmailAddresses],
       CASE
           WHEN [UserID1] = [UserID2] THEN
               1
           ELSE
               0
       END [MatchingEmailAddresses],
       ISNULL(CAST([phone].[Phone] AS VARCHAR(50)), '') [Phone],
       ISNULL(CAST([phone].[MobilePhone] AS VARCHAR(50)), '') [MobilePhone],
       0 [EmailSent],
       GETDATE() [LoadDate]
--	INTO #tbl_BusinessContinuityReport_New
-- select *
FROM
(
    SELECT DISTINCT
           'MANAGER to EMPLOYEE' [RelationShip],
           [ManagerEmployeeID] [UserID1],
           ISNULL([ManagerKnownAs], [ManagerForename]) [KnownAs1],
           [ManagerSurname] [Surname1],
           [ManagerEmailAddress] [EmailAddress1],
           [EmployeeEmployeeID] [UserID2],
           ISNULL([EmployeeKnownAs], [EmployeeForename]) [KnownAs2],
           [EmployeeSurname] [Surname2],
           [EmployeeEmailAddress] [EmailAddress2],
           [EmployeeEmployeeID] [EmployeeID2]
    FROM [#FullHierarchy]
    WHERE [ManagerEmailAddress] IS NOT NULL
) [x]
    LEFT JOIN
    (
        SELECT [e].employeeid [DisplayEmployeeId],
              '' Phone --  ISNULL([eha].[Phone], '-') [Phone],
               ,'' MobilePhone --ISNULL([eha].[MobilePhone], '-') [MobilePhone]
        FROM red_dw.dbo.load_cascade_employee [e] -- [Cascade].[dbo].[Employee] [e]
            --JOIN  [Cascade].[dbo].[EmployeeHomeAddress] [eha]
               -- ON [e].[EmployeeId] = [eha].[EmployeeID]
    ) [phone]
        ON [phone].[DisplayEmployeeId] = [x].[EmployeeID2]
--WHERE [UserID1] = 'E2CD84A3-8DC5-425F-BC98-A3ABADFFBABA'
ORDER BY [RelationShip],
         [UserID1],
         [UserID2];




DECLARE [cur] CURSOR LOCAL FAST_FORWARD FOR --distinct "head" records
SELECT [BusinessContinuityKey],
       [RelationShip],
       [UserID1],
       [KnownAs1],
       [Surname1],
       [EmailAddress1]
FROM #tbl_BusinessContinuityReport_New
WHERE [Rank] = 1
     -- AND [BusinessContinuityKey] > @HighTideKey;

--#################

OPEN [cur];
FETCH NEXT FROM [cur]
INTO @BusinessContinuityKey,
     @Relationship,
     @UserID1,
     @KnownAs1,
     @Surname1,
     @EmailAddress1;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @vSubject
        = 'Business Continuity Plan Team Contact Details: ' + DATENAME(mm, GETDATE()) + ' '
          + CAST(DATEPART(yy, GETDATE()) AS VARCHAR(4)) + ' Update';
    SET @vSubject =  @vSubject;
    --SELECT @Cnt = COUNT(1)
    --FROM #temp
    --WHERE RelationShip = @Relationship
    --AND UserID1 = @UserID1
    --AND EmailCheck=1

    --are there team members that are not the team head
    IF EXISTS
    (
        SELECT 1
        FROM #tbl_BusinessContinuityReport_New
        WHERE [RelationShip] = @Relationship
              AND [UserID1] = @UserID1
              AND [MatchingEmailAddresses] = 0
    )
    BEGIN --sent_db_mail

        SET @vBody
            = --@EmailAddress1+
        '
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">
Dear ' + @KnownAs1
        + '</span>
</p>
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">
Please find below the monthly report showing the personal contact
details for members of your team.<br>
If the firm needs to invoke its business continuity plan, you may be
required to contact the people on your team to pass on information or
instructions, according to our cascade policy.<br>
You will be contacted first by your ROH or a member of the People &amp; Knowledge
team to initiate this communication cascade.</span></p>
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">
Please ensure that the details on this list are accurate and up to date.<br>
If amendments are required, please ask people in your team to update
their information within Cascade.</span></p>
<span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">
You do not need to print off this report.<br>
You will be able to access it remotely via </span>
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">workaway:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://workaway.weightmans.com/">https://workaway.weightmans.com</a><br>
webmail:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://webmail.weightmans.com">https://webmail.weightmans.com</a></span></p>
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">or,
if our systems are down, via:</span></p>
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">email
archive:&nbsp;&nbsp;&nbsp; </span><a href="http://www.mimecast.com"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;; color: blue;">http://www.mimecast.com</span></a></p>
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">Please
make a note of the above
addresses, so that you may access&nbsp;should the need arise.<br>
Please keep this information
confidential and respect the privacy of personal details.<br>
Please do not distribute
this report to your team.</span><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;"></span></p>
<p class="MsoNormal">
<span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">You
may want to establish a contact list for your team on your mobile phone.</span></p>
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">If
you have any questions please email <a href="mailto:hr@weightmans.com">HR@weightmans.com</a></span></p>
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">Thanks</span></p>
<p><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">

<span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;"></span>
<hr>
<p class="MsoNormal"><span
 style="font-size: 10pt; font-family: &quot;Lucida Sans Unicode&quot;,&quot;sans-serif&quot;;">Staff
details below for ' + SUBSTRING(@Relationship, 1, CHARINDEX(' ', @Relationship) - 1) + ': ' + @KnownAs1 + ' '
        + @Surname1
        + '</span></p>
<p><TABLE border=1 style="font-family: Courier"><tr>
<td>Name</td>
<td>Phone</td>
<td>Mobile Phone</td>
</tr>'  ;


        SET @vSQL
            = 'set nocount on
select distinct ''<tr><td>''+ KnownAs2 + '' '' + Surname2 +''</td>
<td>''+Phone+''</td>
<td>''+MobilePhone+''</td></tr>''
from Reporting.dw.tbl_BusinessContinuityReport_New
where Relationship = ''' + @Relationship + '''
and UserID1 = ''' + CAST(@UserID1 AS VARCHAR(50)) + '''
and MatchingEmailAddresses = 0
union all
select ''</table>''';


        --PRINT @vSQL
        --PRINT @vBody

        EXEC @returncode = [msdb].[dbo].[sp_send_dbmail] @profile_name = 'HR@weightmans.com',
                                                         --,@from_address = 'NoReply_InformationSystems@BusinessContinuityReport.com'
                                                         @from_address = 'HR@Weightmans.com'
                                                      --   ,@recipients = 'richard.howard@weightmans.com;emily.smith@weightmans.com;bob.hetherington@weightmans.com;kevin.brown@weightmans.com'
                                                         ,@recipients = @EmailAddress1
                                                         ,@subject = @vSubject,
                                                         @body = @vBody,
                                                         @body_format = 'HTML',
                                                         @query = @vSQL,
                                                         @query_result_header = 0;

        SET @cnt = @cnt + (CASE
                               WHEN @returncode = 0 THEN
                                   1
                               ELSE
                                   0
                           END
                          );

        IF @returncode = 0 --success
        BEGIN
            UPDATE [f]
            SET [f].[EmailSent] = 1
            FROM #tbl_BusinessContinuityReport_New [f]
            WHERE [f].[BusinessContinuityKey] = @BusinessContinuityKey;
        END;


    END;

    PRINT '@Relationship:' + @Relationship + ',	
@UserID:' + CAST(@UserID1 AS VARCHAR(50)) + ',	
@Cnt:'    + CAST(@cnt AS VARCHAR(30));
    --return

    WAITFOR DELAY '00:00:10';

    FETCH NEXT FROM [cur]
    INTO @BusinessContinuityKey,
         @Relationship,
         @UserID1,
         @KnownAs1,
         @Surname1,
         @EmailAddress1;
END;
CLOSE [cur];
DEALLOCATE [cur];

PRINT 'Business Continuity emails sent: ' + CAST(@cnt AS VARCHAR(30));
PRINT '[END  ][DW].[usp_BusinessContinuityReport_New]:' + CONVERT(VARCHAR(20), GETDATE(), 13);
SET NOCOUNT OFF;
--#################



GO

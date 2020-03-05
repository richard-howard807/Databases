SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[TelephoneAudit]
    (
      @StartDate DATE ,
      @EndDate DATE ,
      @Department VARCHAR(50)
    )
AS 
	
	--DECLARE @StartDate DATE ,
	--		@EndDate DATE ,
	--		@Department VARCHAR(50)

	--SET @StartDate = '20200101'
	--SET @EndDate = GETDATE()
	--SET @Department = 'Casualty'

   IF @Department='All'
    BEGIN

        SELECT  DISTINCT 
                Name																								AS [Name] ,
                BusinessLine																						AS BusinessLine ,
                PracticeArea																						AS PracticeArea ,
                Team																								AS Team ,
                Structure.[Team Leader]																				AS BCM ,
                VoicemailActivated																					AS [Voicemail activated?] ,
                DidVoicemailIndicateCorrectDate																		AS [Did voicemail indicate correct date?] ,
                DidVoicemailIndicateNameAndDepartment																AS [Did voicemail indicate name and department?] ,
                WasAnUrgentContactNameAvailable																		AS [Did voicemail indicate an alternative contact?] ,
                DidVoicemailIndicatesDateOfReturnToTheOffice														AS [Did voicemail indicate date of return to office?] ,
                WasOutofOfficeAssistantOn																			AS [Was Out of Office Assistant on?] ,
                CallAnswered																						AS [Did Out of Office Assistant indicate date of return to office?] ,
                DateRecorded																						AS [Date of audit] ,
                RecordedBy																							AS [Identity of auditor] ,
                DateOnMessage ,
                DateOnMessageComments ,
                OfficeLocation
        FROM    TelephoneAudit.dbo.TelephoneAudit
                INNER JOIN ( SELECT 
								RTRIM(knownas) + ' ' + RTRIM(surname)				AS [Name] 
								, works_for_name.works_for_name						AS [Team Leader]
								, hierarchylevel2									AS [BusinessLine] 
								, hierarchylevel3									AS [PracticeArea] 
								, hierarchylevel4									AS [Team]
							FROM red_dw.dbo.dim_employee
								INNER JOIN red_dw.dbo.ds_sh_employee_jobs
									ON ds_sh_employee_jobs.employeeid = dim_employee.employeeid
								INNER JOIN red_dw.dbo.ds_sh_valid_hierarchy_x
									ON red_dw.dbo.ds_sh_valid_hierarchy_x.hierarchynode = red_dw.dbo.ds_sh_employee_jobs.hierarchynode
								INNER JOIN (SELECT
												dim_employee.employeeid
												, knownas + ' ' + surname			AS works_for_name
												, worksforemployeeid
											FROM red_dw.dbo.dim_employee
												INNER JOIN red_dw.dbo.ds_sh_employee_jobs
													ON ds_sh_employee_jobs.employeeid = dim_employee.employeeid
											WHERE ds_sh_employee_jobs.dss_current_flag = 'Y' 
											AND ds_sh_employee_jobs.sys_activejob = 1 
											) AS works_for_name
									ON works_for_name.employeeid = red_dw.dbo.ds_sh_employee_jobs.worksforemployeeid
							WHERE 
								ds_sh_employee_jobs.dss_current_flag = 'Y' 
								AND ds_sh_employee_jobs.sys_activejob = 1 
								AND red_dw.dbo.ds_sh_valid_hierarchy_x.dss_current_flag = 'Y'
								AND (red_dw.dbo.dim_employee.leftdate IS NULL OR red_dw.dbo.dim_employee.leftdate > GETDATE())
                           ) AS Structure ON Structure.Name = REPLACE(FullName, '(Maternity)', '')  COLLATE DATABASE_DEFAULT
								AND Structure.PracticeArea = Department COLLATE DATABASE_DEFAULT
        WHERE DateRecorded BETWEEN @StartDate AND @EndDate

    END
    ELSE 
    BEGIN

        SELECT  DISTINCT
                Name																								AS [Name] ,
                BusinessLine																						AS BusinessLine ,
                PracticeArea																						AS PracticeArea ,
                Team																								AS Team ,
                Structure.[Team Leader]																				AS BCM ,
                VoicemailActivated																					AS [Voicemail activated?] ,
                DidVoicemailIndicateCorrectDate																		AS [Did voicemail indicate correct date?] ,
                DidVoicemailIndicateNameAndDepartment																AS [Did voicemail indicate name and department?] ,
                WasAnUrgentContactNameAvailable																		AS [Did voicemail indicate an alternative contact?] ,
                DidVoicemailIndicatesDateOfReturnToTheOffice														AS [Did voicemail indicate date of return to office?] ,
                WasOutofOfficeAssistantOn																			AS [Was Out of Office Assistant on?] ,
                CallAnswered																						AS [Did Out of Office Assistant indicate date of return to office?] ,
                DateRecorded																						AS [Date of audit] ,
                RecordedBy																							AS [Identity of auditor] ,
                DateOnMessage ,
                DateOnMessageComments ,
                OfficeLocation
        FROM    TelephoneAudit.dbo.TelephoneAudit
                INNER JOIN ( SELECT 
								RTRIM(knownas) + ' ' + RTRIM(surname)				AS [Name] 
								, works_for_name.works_for_name						AS [Team Leader]
								, hierarchylevel2									AS [BusinessLine] 
								, hierarchylevel3									AS [PracticeArea] 
								, hierarchylevel4									AS [Team]
							FROM red_dw.dbo.dim_employee
								INNER JOIN red_dw.dbo.ds_sh_employee_jobs
									ON ds_sh_employee_jobs.employeeid = dim_employee.employeeid
								INNER JOIN red_dw.dbo.ds_sh_valid_hierarchy_x
									ON red_dw.dbo.ds_sh_valid_hierarchy_x.hierarchynode = red_dw.dbo.ds_sh_employee_jobs.hierarchynode
								INNER JOIN (SELECT
												dim_employee.employeeid
												, knownas + ' ' + surname			AS works_for_name
												, worksforemployeeid
											FROM red_dw.dbo.dim_employee
												INNER JOIN red_dw.dbo.ds_sh_employee_jobs
													ON ds_sh_employee_jobs.employeeid = dim_employee.employeeid
											WHERE ds_sh_employee_jobs.dss_current_flag = 'Y' 
											AND ds_sh_employee_jobs.sys_activejob = 1 
											) AS works_for_name
									ON works_for_name.employeeid = red_dw.dbo.ds_sh_employee_jobs.worksforemployeeid
							WHERE 
								ds_sh_employee_jobs.dss_current_flag = 'Y' 
								AND ds_sh_employee_jobs.sys_activejob = 1 
								AND red_dw.dbo.ds_sh_valid_hierarchy_x.dss_current_flag = 'Y'
								AND (red_dw.dbo.dim_employee.leftdate IS NULL OR red_dw.dbo.dim_employee.leftdate > GETDATE())
							) AS Structure ON Structure.Name = REPLACE(FullName, '(Maternity)', '')  COLLATE DATABASE_DEFAULT
        WHERE   PracticeArea = @Department
                AND DateRecorded BETWEEN @StartDate AND @EndDate

	END









GO

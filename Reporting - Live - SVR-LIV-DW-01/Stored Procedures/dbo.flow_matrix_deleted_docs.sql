SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[flow_matrix_deleted_docs]
(
@MMEmail AS NVARCHAR(MAX),
@TMEmail AS NVARCHAR(MAX)
)
AS 

BEGIN

SET NOCOUNT ON;

DECLARE @start_date AS DATE = CAST(DATEADD(DAY, -5, GETDATE()) AS DATE)
		, @end_date AS DATE = GETDATE()
		--For testing
		--, @MMEmail AS NVARCHAR(MAX) = 'All'
		--, @TMEmail AS NVARCHAR(MAX)	= 'All'

--=========================================================================================================================================
-- Table to gather flow matrix deleted documents data
--=========================================================================================================================================
DROP TABLE IF EXISTS #deleted_documents
SELECT *
INTO #deleted_documents
FROM (
	SELECT DISTINCT 
		ArchiveAuditLog.job_id		
		, ArchiveAuditLog.event_time	
		, ArchiveAuditLog.username		
		, ArchiveAuditLog.process_id	
		, ArchiveAuditLog.pages			
		, ArchiveAuditLog.owner			
	--SELECT TOP 100 * 
	FROM [SVR-LIV-3PTY-01].PaperRiverAudit.dbo.ArchiveAuditLog 
	WHERE 1 = 1
		AND ArchiveAuditLog.event in ('Delete Document', 'IndexingDelete', 'QADelete')
		AND ArchiveAuditLog.event_time BETWEEN @start_date AND @end_date

	UNION

	SELECT DISTINCT
		RecentAuditLog.job_id		AS [job_id]
		, RecentAuditLog.event_time	AS [Date]
		, RecentAuditLog.username	AS [User]
		, RecentAuditLog.process_id	AS [Location]
		, RecentAuditLog.pages		AS [Pages]
		, RecentAuditLog.owner	AS [Owner]
	--SELECT TOP 100 *
	FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]
	WHERE 1 = 1
		AND RecentAuditLog.event IN ('Delete Document', 'IndexingDelete', 'QADelete')
		AND RecentAuditLog.event_time BETWEEN @start_date AND @end_date
) AS deleted_docs

--=======================================================================================================================================================

SELECT 
	#deleted_documents.job_id									AS [Job ID]
	, #deleted_documents.event_time								AS [Deleted Date]	
	, #deleted_documents.username								AS [User ID Deleting]
	, RTRIM(user_details.knownas) + ' ' + user_details.surname	AS [User Name Deleting]
	, #deleted_documents.process_id								AS [Location]
	, #deleted_documents.pages									AS [Pages]
	, #deleted_documents.owner									AS [Document Owner]
	, ISNULL(owner_details.name, 'Postroom')					AS [Matter Manager]
	, owner_office.workemail									AS [Matter Manager Email]
	, ISNULL(owner_details.worksforname, 'Claire Shields')		AS [Team Manager]
	, ISNULL(owner_office.worksforemail, 'Claire.Shields@Weightmans.com')			AS [Team Manager Email]
	, ISNULL(owner_details.hierarchylevel4hist, 'Facilities Management')			AS [Team]
	, ISNULL(owner_details.hierarchylevel3hist, 'Facilities')						AS [Department]
	, ISNULL(owner_details.hierarchylevel2hist, 'Business Services')				AS [Division]
	, ISNULL(owner_office.locationidud, 'Liverpool')								AS [Office]
	, 1															AS [Document Count]
	, '\\SVR-LIV-FMTX-01\workspace$' + '\' + LEFT(Jobs.guid, 2) 
		+ '\' + RIGHT(LEFT(Jobs.guid, 4), 2) + '\' + RIGHT(LEFT(Jobs.guid, 6), 2) 
		+ '\' + RIGHT(Jobs.guid, LEN(Jobs.guid)-6) + '\' + Jobs.label + '.TIF' 		AS [document_link]
FROM #deleted_documents
	LEFT OUTER JOIN [SVR-LIV-3PTY-01].[FlowMatrix].dbo.Jobs
		ON Jobs.job_id = #deleted_documents.job_id
	LEFT OUTER JOIN red_dw.dbo.dim_employee AS user_details
		ON user_details.windowsusername = #deleted_documents.username COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS owner_details
		ON owner_details.windowsusername = #deleted_documents.owner COLLATE DATABASE_DEFAULT
			AND owner_details.dss_current_flag='Y' AND (owner_details.activeud=1 OR owner_details.windowsusername IN ('cwahle','awilli07'))
	LEFT OUTER JOIN red_dw.dbo.dim_employee AS owner_office
		ON owner_office.dim_employee_key = owner_details.dim_employee_key
WHERE
	ISNULL(owner_office.workemail, 'Postroom') IN (
													SELECT
														CASE
															WHEN @MMEmail = 'All' THEN
																COALESCE(dim_employee.workemail, postroom) 
														END		AS email
													FROM red_dw.dbo.dim_employee
														FULL JOIN (
																	SELECT 
																		'Postroom' AS postroom
																   ) AS postroom
															ON postroom = dim_employee.workemail
													UNION
													SELECT 
														dim_employee.workemail
													FROM red_dw.dbo.dim_employee
													WHERE
														dim_employee.workemail = @MMEmail
												)
	AND ISNULL(owner_office.worksforemail, 'Claire.Shields@Weightmans.com') IN (
																				SELECT
																					CASE
																						WHEN @TMEmail = 'All' THEN
																							dim_employee.worksforemail
																					END		AS email
																				FROM red_dw.dbo.dim_employee
																				UNION
																				SELECT 
																					dim_employee.worksforemail
																				FROM red_dw.dbo.dim_employee
																				WHERE
																					dim_employee.worksforemail = @TMEmail
																			   )
ORDER BY
	#deleted_documents.event_time

END


GO

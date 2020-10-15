SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[flow_matrix_deleted_docs]

AS 

BEGIN

SET NOCOUNT ON;

DECLARE @start_date AS DATE = CAST(DATEADD(WEEK, -3, GETDATE()) AS DATE)
		, @end_date AS DATE = GETDATE()

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
	, owner_details.name										AS [Matter Manger]
	, owner_details.reportingbcmname							AS [Team Manager]
	, owner_details.hierarchylevel4hist							AS [Team]
	, owner_details.hierarchylevel3hist							AS [Department]
	, owner_details.hierarchylevel2hist							AS [Division]
	, owner_office.locationidud									AS [Office]
	, 1															AS [Document Count]
FROM #deleted_documents
	LEFT OUTER JOIN red_dw.dbo.dim_employee AS user_details
		ON user_details.windowsusername = #deleted_documents.username COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS owner_details
		ON owner_details.windowsusername = #deleted_documents.owner COLLATE DATABASE_DEFAULT
			AND owner_details.dss_current_flag='Y' AND (owner_details.activeud=1 OR owner_details.windowsusername IN ('cwahle','awilli07'))
	LEFT OUTER JOIN red_dw.dbo.dim_employee AS owner_office
		ON owner_office.windowsusername = #deleted_documents.owner COLLATE DATABASE_DEFAULT
ORDER BY
	#deleted_documents.event_time

END
GO

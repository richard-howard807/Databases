SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2021-01-19
-- Description: Updates the OneViewAnalytics table for the OneView Analytics Report. Report server can't access SVR-AZ-MATO-01 server
-- =============================================
CREATE PROCEDURE [dbo].[oneview_analytics]	--EXEC dbo.oneview_analytics 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	

--IF OBJECT_ID('Reporting.dbo.OneViewAnalytics') IS NOT NULL DROP TABLE  Reporting.dbo.OneViewAnalytics
/*
CREATE TABLE Reporting.dbo.OneViewAnalytics
(
username NVARCHAR(60) NULL,
idsite INT NULL,
client_name NVARCHAR(60) NULL,
visit_id NUMERIC(20, 0) NULL,
time_spent_seconds NUMERIC(10, 0) NULL,
visit_first_action_time DATETIME2 NULL,
visit_last_action_time DATETIME2 NULL,
server_time DATETIME2 NULL,
url_visited NVARCHAR(400) NULL,
site_page NVARCHAR(400) NULL,
date_logged_on DATE NULL
) ON [PRIMARY]
*/

--=================================================================================
-- matomo_log_action table
--=================================================================================
DROP TABLE IF EXISTS #log_action
SELECT * 
INTO #log_action --  temp table 
FROM OPENQUERY([SVR-AZ-MATO-01], 'SELECT * FROM bitnami_matomo.matomo_log_action')


--=================================================================================
-- matomo_log_link_visit_action table
--=================================================================================
DROP TABLE IF EXISTS #log_link_visit_action
SELECT *
INTO #log_link_visit_action --  temp table 
FROM OPENQUERY([SVR-AZ-MATO-01], 'SELECT * FROM bitnami_matomo.matomo_log_link_visit_action')


--=================================================================================
-- matomo_log_visit table
--=================================================================================
DROP TABLE IF EXISTS #log_visit
SELECT * 
INTO #log_visit --  temp table 
FROM OPENQUERY([SVR-AZ-MATO-01], 'SELECT * FROM bitnami_matomo.matomo_log_visit')


--=================================================================================
-- Main Oneview query
--=================================================================================

INSERT INTO Reporting.dbo.OneViewAnalytics

SELECT DISTINCT
	#log_visit.user_id										AS [username]
	, #log_visit.idsite
	, LTRIM(RTRIM(#log_visit.custom_dimension_2))			AS [client_name]
	, #log_visit.idvisit									AS [visit_id]
	, ISNULL(#log_link_visit_action.time_spent, 0)		AS [time_spent_seconds]
	, #log_visit.visit_first_action_time
	, #log_visit.visit_last_action_time
	, #log_link_visit_action.server_time
	, CAST(#log_action.name AS VARCHAR(400))			AS [url_visited]	
	, CASE
		WHEN RIGHT(CAST(#log_action.name AS VARCHAR(400)), 1) = '/' THEN
			REVERSE(LEFT(REVERSE(LEFT(CAST(#log_action.name AS VARCHAR(400)), LEN(CAST(#log_action.name AS VARCHAR(400)))-1)), CHARINDEX('/', REVERSE(LEFT(CAST(#log_action.name AS VARCHAR(400)), LEN(CAST(#log_action.name AS VARCHAR(400)))-1)))-1))
		ELSE
			REPLACE(REVERSE(LEFT(REVERSE(CAST(#log_action.name AS VARCHAR(400))), CHARINDEX('/', REVERSE(CAST(#log_action.name AS VARCHAR(400))))-1)), '?', '/')
	  END				AS [site_page]
	, CAST(#log_link_visit_action.server_time AS DATE)			AS [date_logged_on]
--SELECT *
FROM #log_visit
	INNER JOIN #log_link_visit_action
		ON #log_link_visit_action.idvisit = #log_visit.idvisit
	INNER JOIN #log_action
		ON #log_action.idaction = #log_link_visit_action.idaction_url
	LEFT OUTER JOIN (
						SELECT DISTINCT OneViewAnalytics.visit_id, OneViewAnalytics.server_time
						FROM Reporting.dbo.OneViewAnalytics
						--WHERE OneViewAnalytics.date_logged_on < CAST(GETDATE() AS DATE)
					) AS existing_data
		ON existing_data.visit_id = #log_visit.idvisit
			AND existing_data.server_time = #log_link_visit_action.server_time
WHERE 1 = 1
	AND #log_visit.idsite = 4
	AND #log_visit.user_id IS NOT NULL
	AND existing_data.visit_id IS NULL
ORDER BY
	#log_visit.idvisit
	, #log_link_visit_action.server_time

END	 


GO

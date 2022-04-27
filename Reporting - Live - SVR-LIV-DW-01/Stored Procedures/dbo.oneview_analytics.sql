SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2021-01-19
-- Description: Updates the OneViewAnalytics table for the OneView Analytics Report. Report server can't access SVR-AZ-MATO-01 server
--==============================================
-- 2022-04-27 - Matomo tables now in Red. Proc adjusted to look at new tables
-- =============================================

CREATE PROCEDURE [dbo].[oneview_analytics]

(
	@client NVARCHAR(MAX)
	, @start_date AS DATE
	, @end_date AS DATE
)
AS
BEGIN

IF OBJECT_ID('tempdb..#client') IS NOT NULL DROP TABLE #client

SELECT udt_TallySplit.ListValue  INTO #client FROM 	dbo.udt_TallySplit('|', @client)

SELECT 
	ds_sh_matomo_log_visit.user_id										AS [Username]
	, ds_sh_matomo_log_visit.idsite
	, LTRIM(RTRIM(ds_sh_matomo_log_visit.custom_dimension_2))			AS [Client Name]
	, ds_sh_matomo_log_visit.idvisit									AS [Visit ID]
	, ISNULL(ds_sh_matomo_log_link_visit_action.time_spent, 0)		AS [Time Spent Seconds]
	, ds_sh_matomo_log_visit.visit_first_action_time
	, ds_sh_matomo_log_visit.visit_last_action_time
	--, ds_sh_matomo_log_link_visit_action.server_time
	, CAST(ds_sh_matomo_log_action.name AS VARCHAR(255))				AS [URL Visited]	
	, CASE
		WHEN RIGHT(CAST(ds_sh_matomo_log_action.name AS VARCHAR(400)), 1) = '/' THEN
			REVERSE(LEFT(REVERSE(LEFT(CAST(ds_sh_matomo_log_action.name AS VARCHAR(400)), LEN(CAST(ds_sh_matomo_log_action.name AS VARCHAR(400)))-1)), CHARINDEX('/', REVERSE(LEFT(CAST(ds_sh_matomo_log_action.name AS VARCHAR(400)), LEN(CAST(ds_sh_matomo_log_action.name AS VARCHAR(400)))-1)))-1))
		ELSE
			REPLACE(REVERSE(LEFT(REVERSE(CAST(ds_sh_matomo_log_action.name AS VARCHAR(400))), CHARINDEX('/', REVERSE(CAST(ds_sh_matomo_log_action.name AS VARCHAR(400))))-1)), '?', '/')
	  END				AS [Site Page]
	, CAST(ds_sh_matomo_log_link_visit_action.server_time AS DATE)			AS [Date Logged on]
FROM red_dw.dbo.ds_sh_matomo_log_visit
	INNER JOIN red_dw.dbo.ds_sh_matomo_log_link_visit_action
		ON ds_sh_matomo_log_visit.idvisit = ds_sh_matomo_log_link_visit_action.idvisit
	INNER JOIN red_dw.dbo.ds_sh_matomo_log_action
		ON ds_sh_matomo_log_action.idaction = ds_sh_matomo_log_link_visit_action.idaction_url
	INNER JOIN #client
		ON #client.ListValue COLLATE DATABASE_DEFAULT = ds_sh_matomo_log_link_visit_action.custom_dimension_2
WHERE
	ds_sh_matomo_log_visit.idsite = 4
	AND ds_sh_matomo_log_visit.user_id IS NOT NULL
	AND (@start_date IS NULL OR CAST(ds_sh_matomo_log_link_visit_action.server_time AS DATE) >= @start_date)
	AND (@end_date IS NULL OR CAST(ds_sh_matomo_log_link_visit_action.server_time AS DATE) <= @end_date)
ORDER BY
	ds_sh_matomo_log_visit.idvisit
	, [Date Logged on]
END	

GO

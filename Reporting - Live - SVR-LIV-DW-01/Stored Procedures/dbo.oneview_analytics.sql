SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2021-01-19
-- Description: #84700 New report to track logins to OneView
-- =============================================
CREATE PROCEDURE [dbo].[oneview_analytics]

(
	@start_date AS DATE
	, @end_date AS DATE
	, @client AS VARCHAR(MAX)
)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- For testing
--DECLARE @start_date AS DATE = NULL --'2021-01-01'
--		, @end_date AS DATE = NULL --CAST(GETDATE() AS DATE)
--		, @client AS VARCHAR(MAX) = 'Cumbria University OV|MIB|Severn Trent Water'

IF OBJECT_ID('tempdb..#client') IS NOT NULL DROP TABLE #client

SELECT udt_TallySplit.ListValue  INTO #client FROM 	dbo.udt_TallySplit('|', @client)


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

SELECT DISTINCT
	#log_visit.user_id										AS [Username]
	, #log_visit.idsite
	, LTRIM(RTRIM(#log_visit.custom_dimension_2))			AS [Client Name]
	, #log_visit.idvisit									AS [Visit ID]
	--, logon_count.login_count								AS [Total Times Logged on]	
	--, DATEDIFF(SECOND, #log_visit.visit_first_action_time, #log_visit.visit_last_action_time)			AS [total_seconds_logged_on]
	--, #log_link_visit_action.time_spent_ref_action
	, ISNULL(#log_link_visit_action.time_spent, 0)		AS [Time Spent Seconds]
	, #log_visit.visit_first_action_time
	, #log_visit.visit_last_action_time
	--, RIGHT('0' + CAST(DATEDIFF(SECOND, #log_visit.visit_first_action_time, #log_visit.visit_last_action_time)/3600 AS VARCHAR(2)), 2)	+ ':' +
	--	RIGHT('0' + CAST(DATEDIFF(SECOND, #log_visit.visit_first_action_time, #log_visit.visit_last_action_time)%3600/60 AS VARCHAR(2)), 2)	+ ':' +
	--	RIGHT('0' + CAST(DATEDIFF(SECOND, #log_visit.visit_first_action_time, #log_visit.visit_last_action_time)%60 AS VARCHAR(2)), 2)					AS [Total Time Logged on]
	, #log_link_visit_action.server_time
	, CAST(#log_action.name AS VARCHAR(255))				AS [URL Visited]	
	, REVERSE(LEFT(REVERSE(CAST(#log_action.name AS VARCHAR(255))), CHARINDEX('/', REVERSE(CAST(#log_action.name AS VARCHAR(255))))-1))				AS [Site Page]
	, CAST(#log_link_visit_action.server_time AS DATE)			AS [Date Logged on]
--SELECT *
FROM #log_visit
	INNER JOIN #log_link_visit_action
		ON #log_link_visit_action.idvisit = #log_visit.idvisit
	INNER JOIN #log_action
		ON #log_action.idaction = #log_link_visit_action.idaction_url
	--INNER JOIN (
	--				SELECT 
	--					#log_visit.user_id
	--					, COUNT(DISTINCT #log_visit.idvisit)		AS login_count
	--				FROM #log_visit
	--					INNER JOIN #log_link_visit_action
	--						ON #log_link_visit_action.idvisit = #log_visit.idvisit
	--					INNER JOIN #log_action
	--						ON #log_action.idaction = #log_link_visit_action.idaction_url
	--				WHERE
	--					CAST(#log_link_visit_action.server_time AS DATE) >= @start_date
	--					AND CAST(#log_link_visit_action.server_time AS DATE) <= @end_date
	--				GROUP BY
	--					#log_visit.user_id
	--			) AS logon_count
		--ON logon_count.user_id = #log_visit.user_id
	INNER JOIN #client
		ON #client.ListValue COLLATE DATABASE_DEFAULT = #log_visit.custom_dimension_2
WHERE 1 = 1
	AND #log_visit.idsite = 4
	AND #log_visit.user_id IS NOT NULL
	AND (@start_date IS NULL OR CAST(#log_link_visit_action.server_time AS DATE) >= @start_date)
	AND (@end_date IS NULL OR CAST(#log_link_visit_action.server_time AS DATE) <= @end_date)
	--AND #log_visit.user_id = 'mib2@demo.com' --IS NOT NULL
	--AND #log_visit.custom_dimension_2 = 'Cumbria University OV'
	--AND #log_visit.idvisit = '1919'
ORDER BY
	#log_visit.idvisit
	, #log_link_visit_action.server_time

END	 




GO

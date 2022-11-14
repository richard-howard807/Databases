SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2022-11-01
Description:		Inserts stage table data into rta_trends_in_casualty_rates. 
					This is run via the SSIS package update_rta_trends.
====================================================
*/
CREATE PROCEDURE [dbo].[update_rta_trends_table]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 


DROP TABLE IF EXISTS #temp_stage_rta_trends
SELECT *
INTO #temp_stage_rta_trends
FROM (
	SELECT *
	FROM dbo.stage_rta_trends
	) rta_trends
PIVOT (
	SUM(casualty_value)
	FOR casualty_severity IN ([All casualties], [Slightly injured (unadjusted)], [Slightly injured (adjusted)], [Seriously injured (unadjusted)], [Seriously injured (adjusted)], [KSI (unadjusted)1], [KSI (adjusted)1], [Killed])
	) AS rta_pivot


MERGE INTO dbo.rta_trends_in_casualty_rates
USING (
	SELECT 
		#temp_stage_rta_trends.road_user_type,
        #temp_stage_rta_trends.casualty_year,
        #temp_stage_rta_trends.[All casualties],
        #temp_stage_rta_trends.[Slightly injured (unadjusted)],
        #temp_stage_rta_trends.[Slightly injured (adjusted)],
        #temp_stage_rta_trends.[Seriously injured (unadjusted)],
        #temp_stage_rta_trends.[Seriously injured (adjusted)],
        #temp_stage_rta_trends.[KSI (unadjusted)1],
        #temp_stage_rta_trends.[KSI (adjusted)1],
        #temp_stage_rta_trends.Killed
	FROM #temp_stage_rta_trends
	EXCEPT
	SELECT 
		rta_trends_in_casualty_rates.road_user_type,
        rta_trends_in_casualty_rates.casualty_year,
        rta_trends_in_casualty_rates.[All casualties],
        rta_trends_in_casualty_rates.[Slightly injured (unadjusted)],
        rta_trends_in_casualty_rates.[Slightly injured (adjusted)],
        rta_trends_in_casualty_rates.[Seriously injured (unadjusted)],
        rta_trends_in_casualty_rates.[Seriously injured (adjusted)],
        rta_trends_in_casualty_rates.[KSI (unadjusted)1],
        rta_trends_in_casualty_rates.[KSI (adjusted)1],
        rta_trends_in_casualty_rates.Killed
	FROM dbo.rta_trends_in_casualty_rates
) AS rta_changes
ON rta_changes.road_user_type = rta_trends_in_casualty_rates.road_user_type
	AND rta_changes.casualty_year = rta_trends_in_casualty_rates.casualty_year
 
WHEN MATCHED THEN
UPDATE SET rta_trends_in_casualty_rates.[All casualties] = rta_changes.[All casualties]
	, rta_trends_in_casualty_rates.[Slightly injured (unadjusted)] = rta_changes.[Slightly injured (unadjusted)]
	, rta_trends_in_casualty_rates.[Slightly injured (adjusted)] = rta_changes.[Slightly injured (adjusted)]
	, rta_trends_in_casualty_rates.[Seriously injured (unadjusted)] = rta_changes.[Seriously injured (unadjusted)]
	, rta_trends_in_casualty_rates.[Seriously injured (adjusted)] = rta_changes.[Seriously injured (adjusted)]
	, rta_trends_in_casualty_rates.[KSI (unadjusted)1] = rta_changes.[KSI (unadjusted)1]
	, rta_trends_in_casualty_rates.[KSI (adjusted)1] = rta_changes.[KSI (adjusted)1]
	, rta_trends_in_casualty_rates.Killed = rta_changes.Killed

WHEN NOT MATCHED THEN
INSERT (
	road_user_type
	, casualty_year
	, [All casualties]
	, [Slightly injured (unadjusted)]
	, [Slightly injured (adjusted)]
	, [Seriously injured (unadjusted)]
	, [Seriously injured (adjusted)]
	, [KSI (unadjusted)1]
	, [KSI (adjusted)1]
	, Killed
)
VALUES (
	rta_changes.road_user_type
	, rta_changes.casualty_year
	, rta_changes.[All casualties]
	, rta_changes.[Slightly injured (unadjusted)]
	, rta_changes.[Slightly injured (adjusted)]
	, rta_changes.[Seriously injured (unadjusted)]
	, rta_changes.[Seriously injured (adjusted)]
	, rta_changes.[KSI (unadjusted)1]
	, rta_changes.[KSI (adjusted)1]
	, rta_changes.Killed
);

END 
GO

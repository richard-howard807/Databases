SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2022-03-15
Description:		Inserts stage table data into claims_portal_figures. 
					This is run via the SSIS package stage_claims_portal_figures.
====================================================
*/
CREATE PROCEDURE [dbo].[update_claims_portal_figures_table]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

DROP TABLE IF EXISTS #gd
DROP TABLE IF EXISTS #cnf
DROP TABLE IF EXISTS #pivoted_data_merge


--==============================================================================
-- unpivots general damages data
--==============================================================================
SELECT 
	p.month
	, CASE 
		WHEN p.claim_type = 'pl_general_damages' THEN
			'PL'
		WHEN p.claim_type = 'el_general_damages' THEN
			'EL'
		WHEN p.claim_type = 'motor_general_damages' THEN
			'Motor'
		WHEN p.claim_type = 'disease_general_damages' THEN 
			'Disease'
	  END						AS claim_type
	, p.general_damages
INTO #gd
FROM (
		SELECT *
		FROM dbo.stage_portal_average_general_damages
	) AS gd
UNPIVOT
(
	general_damages FOR claim_type IN (pl_general_damages, el_general_damages, motor_general_damages, disease_general_damages)
) AS p


--==============================================================================
-- unpivots cnf data
--==============================================================================
SELECT 
	p.Month
	, CASE		
		WHEN p.claim_type = 'RTA' THEN
			'Motor'
		WHEN p.claim_type = 'ELD' THEN
			'Disease'
		WHEN p.claim_type = 'PL' THEN
			'PL'
		WHEN p.claim_type = 'EL' THEN 
			'EL'
	  END							AS claim_type
	, p.cnf_volumns
INTO #cnf
FROM (
		SELECT *
		FROM dbo.stage_portal_cnf_volumes
	) AS cnf
UNPIVOT
(
	cnf_volumns FOR claim_type IN (RTA, PL, ELD, EL)
) AS p


--==============================================================================
-- merges general damages and cnf tables together
--==============================================================================
SELECT 
	#cnf.Month
	, #cnf.claim_type
	, #gd.general_damages
	, #cnf.cnf_volumns
INTO #pivoted_data_merge
FROM #gd
	INNER JOIN #cnf
		ON #cnf.Month = #gd.month
			AND #cnf.claim_type = #gd.claim_type


--==============================================================================
-- Updates claims_portal_figures table
--==============================================================================
MERGE dbo.claims_portal_figures AS Target
USING #pivoted_data_merge AS Source
ON Source.Month = Target.Month
	AND Source.claim_type = Target.claim_type

WHEN NOT MATCHED BY TARGET THEN
	INSERT (Month, claim_type, general_damages, cnf_volumns, update_time)
	VALUES (Source.Month, Source.claim_type, Source.general_damages, Source.cnf_volumns, GETDATE())

WHEN MATCHED THEN UPDATE SET
	Target.general_damages = Source.general_damages,
	Target.cnf_volumns = Source.cnf_volumns,
	Target.update_time = GETDATE();

END

GO

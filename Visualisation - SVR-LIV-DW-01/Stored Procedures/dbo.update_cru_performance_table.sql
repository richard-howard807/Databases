SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2022-03-23
Description:		Inserts stage table data into cru_performance. 
					This is run via the SSIS package stage_cru_performance.
====================================================
*/
CREATE PROCEDURE [dbo].[update_cru_performance_table]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 


--==============================================================================
-- Updates civil_justice_stats table
--==============================================================================
MERGE dbo.cru_performance AS Target
USING (
		SELECT 
			p.year
			, CASE 
				WHEN p.claim_type = 'liability_not_known' THEN
					'Liability Not Known'
				WHEN p.claim_type = 'clinical_negligence' THEN 
					'Clinical Negligence'
				WHEN p.claim_type = 'EL' THEN
					'EL'
				WHEN p.claim_type = 'motor' THEN
					'Motor'
				WHEN p.claim_type = 'other' THEN
					'Other'
				WHEN p.claim_type = 'PL' THEN
					'PL'
			  END			AS claim_type
			, p.num_cru_cases
		FROM (
				SELECT stage_cru_performance.*
				FROM dbo.stage_cru_performance
					LEFT OUTER JOIN (
										SELECT	
											p.*
										FROM (
												SELECT *
												FROM dbo.cru_performance
											) AS d
										PIVOT
											(
												SUM(num_cru_cases)
												FOR claim_type IN ([Liability Not Known], [Clinical Negligence], [EL], [Motor], [PL], [Other])
											) AS p
									) AS cru_performance
						ON cru_performance.year = stage_cru_performance.year
				WHERE
					cru_performance.year IS NULL
					OR 
					ISNULL(stage_cru_performance.clinical_negligence, 0) <> ISNULL(cru_performance.[Clinical Negligence], 0)
					OR
					ISNULL(stage_cru_performance.EL, 0) <> ISNULL(cru_performance.EL, 0)
					OR
					ISNULL(stage_cru_performance.motor, 0) <> ISNULL(cru_performance.Motor, 0)
					OR
					ISNULL(stage_cru_performance.other, 0) <> ISNULL(cru_performance.Other, 0)
					OR
					ISNULL(stage_cru_performance.PL, 0) <> ISNULL(cru_performance.PL, 0)
					OR
					ISNULL(stage_cru_performance.liability_not_known, 0) <> ISNULL(cru_performance.[Liability Not Known], 0)
			) AS cru
		UNPIVOT
			(
				num_cru_cases FOR claim_type IN (clinical_negligence, EL, motor, other, PL, liability_not_known)	
			) AS p
	) AS Source
ON Source.year = Target.year
	AND Source.claim_type = Target.claim_type

WHEN NOT MATCHED BY TARGET THEN 
	INSERT (
		year
		, claim_type
		, num_cru_cases
		, update_time
		)
	VALUES (
		Source.year
		, Source.claim_type
		, Source.num_cru_cases
		, GETDATE()
		)

WHEN MATCHED THEN UPDATE SET
	Target.num_cru_cases = Source.num_cru_cases
	, Target.update_time = GETDATE();


END

GO

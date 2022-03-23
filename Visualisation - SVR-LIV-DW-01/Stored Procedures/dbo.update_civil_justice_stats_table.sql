SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2022-03-23
Description:		Inserts stage table data into civil_justice_stats. 
					This is run via the SSIS package stage_civil_justice_stats.
====================================================
*/
CREATE PROCEDURE [dbo].[update_civil_justice_stats_table]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 


--==============================================================================
-- Updates civil_justice_stats table
--==============================================================================
MERGE dbo.civil_justice_stats AS Target
USING (
		SELECT dbo.stage_civil_justice_stats.*
		FROM dbo.stage_civil_justice_stats
			LEFT OUTER JOIN dbo.civil_justice_stats
				ON civil_justice_stats.year = stage_civil_justice_stats.year
					AND civil_justice_stats.quarter = stage_civil_justice_stats.quarter
		WHERE
			civil_justice_stats.figure_status <> stage_civil_justice_stats.figure_status
			OR
			civil_justice_stats.year IS NULL
	)AS Source
ON Source.year = Target.year
	AND Source.quarter = Target.quarter

WHEN NOT MATCHED BY TARGET THEN
	INSERT (
		year
		, quarter
		, figure_status
		, money_claims
		, personal_injury_claims
		, other_damages_claims
		, total_damages_claims
		, total_money_and_damages_claims
		, mortgage_and_landlord_possession_claims
		, claims_for_return_of_goods
		, other_non_money_claims
		, total_non_money_claims
		, total_claims
		, total_insolvency_petitions
		, total_proceedings_started
		, total_completed_civil_proceedings_in_the_magistrates_courts
		, update_time
		)
	VALUES (
		Source.year
		, Source.quarter
		, Source.figure_status
		, Source.money_claims
		, Source.personal_injury_claims
		, Source.other_damages_claims
		, Source.total_damages_claims
		, Source.total_money_and_damages_claims
		, Source.mortgage_and_landlord_possession_claims
		, Source.claims_for_return_of_goods
		, Source.other_non_money_claims
		, Source.total_non_money_claims
		, Source.total_claims
		, Source.total_insolvency_petitions
		, Source.total_proceedings_started
		, Source.total_completed_civil_proceedings_in_the_magistrates_courts
		, GETDATE()
		)

WHEN MATCHED THEN UPDATE SET
	Target.figure_status = Source.figure_status
	, Target.money_claims = Source.money_claims
	, Target.personal_injury_claims = Source.personal_injury_claims
	, Target.other_damages_claims = Source.other_damages_claims
	, Target.total_damages_claims = Source.total_damages_claims
	, Target.total_money_and_damages_claims = Source.total_money_and_damages_claims
	, Target.mortgage_and_landlord_possession_claims = Source.mortgage_and_landlord_possession_claims
	, Target.claims_for_return_of_goods = Source.claims_for_return_of_goods
	, Target.other_non_money_claims = Source.other_non_money_claims
	, Target.total_non_money_claims = Source.total_non_money_claims
	, Target.total_claims = Source.total_claims
	, Target.total_insolvency_petitions = Source.total_insolvency_petitions
	, Target.total_proceedings_started = Source.total_proceedings_started
	, Target.total_completed_civil_proceedings_in_the_magistrates_courts = Source.total_completed_civil_proceedings_in_the_magistrates_courts
	, Target.update_time = GETDATE();

END

GO

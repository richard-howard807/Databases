SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2022-03-23
Description:		Inserts stage table data into oic tables. 
					This is run via the SSIS package stage_oic_stats.
====================================================
*/
CREATE PROCEDURE [dbo].[update_oic_stats_tables]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

--========================================================================================================
-- oic_claims MERGE
--========================================================================================================
MERGE dbo.oic_claims AS Target
USING (
		SELECT stage_oic_claims.*
		FROM dbo.stage_oic_claims
			LEFT OUTER JOIN dbo.oic_claims
				ON oic_claims.reporting_period_start = stage_oic_claims.reporting_period_start
					AND oic_claims.claims_month = stage_oic_claims.claims_month
		WHERE 
			oic_claims.reporting_period IS NULL
			OR ISNULL(oic_claims.claims_submitted, 0) <> ISNULL(stage_oic_claims.claims_submitted, 0)
	) AS Source
ON Source.reporting_period_start = Target.reporting_period_start
	AND Source.claims_month = Target.claims_month

WHEN NOT MATCHED BY TARGET THEN
	INSERT(
		reporting_period
		, reporting_period_start
		, reporting_period_end
		, claims_year
		, claims_month
		, claims_month_no
		, claims_submitted
		, update_time
		)
	VALUES(
		Source.reporting_period
		, Source.reporting_period_start
		, Source.reporting_period_end
		, Source.claims_year
		, Source.claims_month
		, Source.claims_month_no
		, Source.claims_submitted
		, GETDATE()
		)

WHEN MATCHED THEN UPDATE SET
	Target.claims_submitted = Source.claims_submitted
	, Target.update_time = GETDATE();


--========================================================================================================
-- oic_claims_type MERGE
--========================================================================================================
MERGE dbo.oic_claims_type AS Target
USING (
		SELECT stage_oic_claims_type.*
		FROM dbo.stage_oic_claims_type
			LEFT OUTER JOIN dbo.oic_claims_type
				ON oic_claims_type.reporting_period_start = stage_oic_claims_type.reporting_period_start
					AND oic_claims_type.claim_types = stage_oic_claims_type.claim_types
		WHERE 1 = 1
			AND oic_claims_type.reporting_period IS NULL
			OR ISNULL(oic_claims_type.number_of_claims, 0) <> ISNULL(stage_oic_claims_type.number_of_claims, 0)
	) AS Source
ON Source.reporting_period_start = Target.reporting_period_start
	AND Source.claim_types = Target.claim_types

WHEN NOT MATCHED BY TARGET THEN
	INSERT(
		reporting_period
		, reporting_period_start
		, reporting_period_end
		, claims_year
		, claim_types
		, claim_type_group
		, number_of_claims
		, update_time
		)
	VALUES (
		Source.reporting_period
		, Source.reporting_period_start
		, Source.reporting_period_end
		, Source.claims_year
		, Source.claim_types
		, Source.claim_type_group
		, Source.number_of_claims
		, GETDATE()
		)

WHEN MATCHED THEN UPDATE SET
	Target.number_of_claims = Source.number_of_claims
	, Target.update_time = GETDATE();

--========================================================================================================
-- oic_representation MERGE
--========================================================================================================
MERGE dbo.oic_representation AS Target
USING (
		SELECT stage_oic_representation.*
		FROM dbo.stage_oic_representation
			LEFT OUTER JOIN dbo.oic_representation
				ON oic_representation.reporting_period_start = stage_oic_representation.reporting_period_start
					AND oic_representation.type_of_user = stage_oic_representation.type_of_user
		WHERE 1 = 1
			AND oic_representation.reporting_period IS NULL
			OR ISNULL(oic_representation.number_of_claims, 0) <> ISNULL(stage_oic_representation.number_of_claims, 0)
		) AS Source
ON Source.reporting_period_start = Target.reporting_period_start
	AND Source.type_of_user = Target.type_of_user

WHEN NOT MATCHED BY TARGET THEN
	INSERT (
		reporting_period
		, reporting_period_start
		, reporting_period_end
		, claims_year
		, type_of_user
		, number_of_claims
		, update_time
		)
	VALUES (
		Source.reporting_period
		, Source.reporting_period_start
		, Source.reporting_period_end
		, Source.claims_year
		, Source.type_of_user
		, Source.number_of_claims
		, GETDATE()
		)

WHEN MATCHED THEN UPDATE SET
	Target.number_of_claims = Source.number_of_claims
	, Target.update_time = GETDATE();

--========================================================================================================
-- oic_representation_monthly MERGE
--========================================================================================================

MERGE dbo.oic_representation_monthly AS Target
USING (
		SELECT stage_oic_representation_monthly.*
		FROM dbo.stage_oic_representation_monthly
			LEFT OUTER JOIN dbo.oic_representation_monthly
				ON oic_representation_monthly.reporting_period_start = stage_oic_representation_monthly.reporting_period_start
					AND oic_representation_monthly.representation = stage_oic_representation_monthly.representation
		WHERE 1 = 1
			AND oic_representation_monthly.reporting_period IS NULL
			OR ISNULL(oic_representation_monthly.settlements_per_month, 0) <> ISNULL(stage_oic_representation_monthly.settlements_per_month, 0)
			OR ISNULL(oic_representation_monthly.portal_support_centre_calls, 0) <> ISNULL(stage_oic_representation_monthly.portal_support_centre_calls, 0)
	) AS Source
ON Source.reporting_period_start = Target.reporting_period_start
	AND Source.claims_month = Target.claims_month
		AND Source.representation = Target.representation

WHEN NOT MATCHED BY TARGET THEN
	INSERT (
		reporting_period
		, reporting_period_start
		, reporting_period_end
		, claims_year
		, claims_month
		, claims_month_no
		, representation
		, settlements_per_month
		, portal_support_centre_calls
		, update_time
		)
	VALUES (
		Source.reporting_period
		, Source.reporting_period_start
		, Source.reporting_period_end
		, Source.claims_year
		, Source.claims_month
		, Source.claims_month_no
		, Source.representation
		, Source.settlements_per_month
		, Source.portal_support_centre_calls
		, GETDATE()
		)

WHEN MATCHED THEN UPDATE SET
	Target.settlements_per_month = Source.settlements_per_month
	, Target.portal_support_centre_calls = Source.portal_support_centre_calls
	, Target.update_time = GETDATE();

--========================================================================================================
-- oic_representation_quarterly MERGE
--========================================================================================================

MERGE dbo.oic_representation_quarterly AS Target
USING (
		SELECT stage_oic_representation_quarterly.*
		FROM dbo.stage_oic_representation_quarterly
			LEFT OUTER JOIN dbo.oic_representation_quarterly
				ON oic_representation_quarterly.reporting_period_start = stage_oic_representation_quarterly.reporting_period_start
					AND oic_representation_quarterly.representation = stage_oic_representation_quarterly.representation
		WHERE 1 = 1
			AND oic_representation_quarterly.reporting_period IS NULL
			OR ISNULL(oic_representation_quarterly.claims_submitted, 0) <> ISNULL(stage_oic_representation_quarterly.claims_submitted, 0)
			OR ISNULL(oic_representation_quarterly.no_uplift_claimed, 0) <> ISNULL(stage_oic_representation_quarterly.no_uplift_claimed, 0)
			OR ISNULL(oic_representation_quarterly.exceptional_circs_uplift_claimed, 0) <> ISNULL(stage_oic_representation_quarterly.exceptional_circs_uplift_claimed, 0)
			OR ISNULL(oic_representation_quarterly.exceptional_injury_uplift_claimed, 0) <> ISNULL(stage_oic_representation_quarterly.exceptional_injury_uplift_claimed, 0)
			OR ISNULL(oic_representation_quarterly.exceptional_injury_and_circs_claimed, 0) <> ISNULL(stage_oic_representation_quarterly.exceptional_injury_and_circs_claimed, 0)
			OR ISNULL(oic_representation_quarterly.liability_in_full, 0) <> ISNULL(stage_oic_representation_quarterly.liability_in_full, 0)
			OR ISNULL(oic_representation_quarterly.liability_in_part, 0) <> ISNULL(stage_oic_representation_quarterly.liability_in_part, 0)
			OR ISNULL(oic_representation_quarterly.liability_denied, 0) <> ISNULL(stage_oic_representation_quarterly.liability_denied, 0)
			OR ISNULL(oic_representation_quarterly.dispute_causation, 0) <> ISNULL(stage_oic_representation_quarterly.dispute_causation, 0)
			OR ISNULL(oic_representation_quarterly.removed_from_portal, 0) <> ISNULL(stage_oic_representation_quarterly.removed_from_portal, 0)
			OR ISNULL(oic_representation_quarterly.withdrawn_from_portal, 0) <> ISNULL(stage_oic_representation_quarterly.withdrawn_from_portal, 0)
			OR ISNULL(oic_representation_quarterly.rejected_liability, 0) <> ISNULL(stage_oic_representation_quarterly.rejected_liability, 0)
			OR ISNULL(oic_representation_quarterly.court, 0) <> ISNULL(stage_oic_representation_quarterly.court, 0)
			OR ISNULL(oic_representation_quarterly.complex_issues_of_law, 0) <> ISNULL(stage_oic_representation_quarterly.complex_issues_of_law, 0)
			OR ISNULL(oic_representation_quarterly.fraud_or_dishonesty, 0) <> ISNULL(stage_oic_representation_quarterly.fraud_or_dishonesty, 0)
			OR ISNULL(oic_representation_quarterly.duplicate_claim, 0) <> ISNULL(stage_oic_representation_quarterly.duplicate_claim, 0)
			OR ISNULL(oic_representation_quarterly.agreement_outside_portal, 0) <> ISNULL(stage_oic_representation_quarterly.agreement_outside_portal, 0)
			OR ISNULL(oic_representation_quarterly.no_longer_wishes_to_claim, 0) <> ISNULL(stage_oic_representation_quarterly.no_longer_wishes_to_claim, 0)
			OR ISNULL(oic_representation_quarterly.instructed_legal_representative, 0) <> ISNULL(stage_oic_representation_quarterly.instructed_legal_representative, 0)
			OR ISNULL(oic_representation_quarterly.additional, 0) <> ISNULL(stage_oic_representation_quarterly.additional, 0)
			OR ISNULL(oic_representation_quarterly.other, 0) <> ISNULL(stage_oic_representation_quarterly.other, 0)
	) AS Source
ON Source.reporting_period_start = Target.reporting_period_start
	AND Source.representation = Target.representation

WHEN NOT MATCHED BY TARGET THEN
	INSERT (
		reporting_period
		, reporting_period_start
		, reporting_period_end
		, claims_year
		, representation
		, claims_submitted
		, no_uplift_claimed
		, exceptional_circs_uplift_claimed
		, exceptional_injury_uplift_claimed
		, exceptional_injury_and_circs_claimed
		, liability_in_full
		, liability_in_part
		, liability_denied
		, dispute_causation
		, removed_from_portal
		, withdrawn_from_portal
		, rejected_liability
		, court
		, complex_issues_of_law
		, fraud_or_dishonesty
		, duplicate_claim
		, agreement_outside_portal
		, no_longer_wishes_to_claim
		, instructed_legal_representative
		, additional
		, other
		, update_time
		)
	VALUES (
		Source.reporting_period
		, Source.reporting_period_start
		, Source.reporting_period_end
		, Source.claims_year
		, Source.representation
		, Source.claims_submitted
		, Source.no_uplift_claimed
		, Source.exceptional_circs_uplift_claimed
		, Source.exceptional_injury_uplift_claimed
		, Source.exceptional_injury_and_circs_claimed
		, Source.liability_in_full
		, Source.liability_in_part
		, Source.liability_denied
		, Source.dispute_causation
		, Source.removed_from_portal
		, Source.withdrawn_from_portal
		, Source.rejected_liability
		, Source.court
		, Source.complex_issues_of_law
		, Source.fraud_or_dishonesty
		, Source.duplicate_claim
		, Source.agreement_outside_portal
		, Source.no_longer_wishes_to_claim
		, Source.instructed_legal_representative
		, Source.additional
		, Source.other
		, GETDATE()
		)

WHEN MATCHED THEN UPDATE SET
	Target.claims_submitted = Source.claims_submitted
	, Target.no_uplift_claimed = Source.no_uplift_claimed
	, Target.exceptional_circs_uplift_claimed = Source.exceptional_circs_uplift_claimed
	, Target.exceptional_injury_uplift_claimed = Source.exceptional_injury_uplift_claimed
	, Target.exceptional_injury_and_circs_claimed = Source.exceptional_injury_and_circs_claimed
	, Target.liability_in_full = Source.liability_in_full
	, Target.liability_in_part = Source.liability_in_part
	, Target.liability_denied = Source.liability_denied
	, Target.dispute_causation = Source.dispute_causation
	, Target.removed_from_portal = Source.removed_from_portal
	, Target.withdrawn_from_portal = Source.withdrawn_from_portal
	, Target.rejected_liability = Source.rejected_liability
	, Target.court = Source.court
	, Target.complex_issues_of_law = Source.complex_issues_of_law
	, Target.fraud_or_dishonesty = Source.fraud_or_dishonesty
	, Target.duplicate_claim = Source.duplicate_claim
	, Target.agreement_outside_portal = Source.agreement_outside_portal
	, Target.no_longer_wishes_to_claim = Source.no_longer_wishes_to_claim
	, Target.instructed_legal_representative = Source.instructed_legal_representative
	, Target.additional = Source.additional
	, Target.other = Source.other
	, Target.update_time = GETDATE();


END 
GO

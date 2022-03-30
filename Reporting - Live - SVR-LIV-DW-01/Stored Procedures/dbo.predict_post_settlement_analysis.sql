SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-03-29
-- Description:	Ticket #140464 Data for the PREDiCT Post-Settlement Analysis Report Requirements report
-- =============================================

CREATE PROCEDURE [dbo].[predict_post_settlement_analysis]
(
	@client_code AS NVARCHAR(8)
	, @matter_number AS NVARCHAR(8)
)

AS
BEGIN


--Testing
--DECLARE @client_code AS NVARCHAR(8) = 'Z1001'
--		, @matter_number AS NVARCHAR(8) = '82980'


DROP TABLE IF EXISTS #predict_data
DROP TABLE IF EXISTS #predict_figures
DROP TABLE IF EXISTS #predict_figure_settlement_comparison

--============================================================================================================================================
-- Get last run PREDiCT document
--============================================================================================================================================
SELECT 
    dim_detail_predict.doc_file_path
    , dim_detail_predict.doc_created_date_key
    , dim_detail_predict.doc_updated_date_key
    , dim_detail_predict.predict_run_date_key
    , dim_detail_predict.doc_created_date
    , dim_detail_predict.doc_updated_date
    , dim_detail_predict.age_at_accident
    , dim_detail_predict.claimant_solicitor_category
    , dim_detail_predict.derived_injury
    , dim_detail_predict.ll01_sex
    , dim_detail_predict.ll02_legal_status
    , dim_detail_predict.ll09_initial_glasgow_coma_scale_derived
    , dim_detail_predict.ll11_frontal_lobe_damage_derived
    , dim_detail_predict.ll12_period_of_peg_feeding_derived
    , dim_detail_predict.ll13_24_hour_care_derived
    , dim_detail_predict.ll13_level_of_spinal_cord_injury_derived
    , dim_detail_predict.ll14_period_of_ventilation_days_derived
    , dim_detail_predict.ll18_is_there_a_reduced_life_expectancy_derived
    , dim_detail_predict.model_version
    , dim_detail_predict.proceedings_issued
    , dim_detail_predict.run_date_time
    , dim_detail_predict.success_fee
    , dim_detail_predict.predict_output_document_id
    , dim_detail_predict.current_document
    , fact_detail_predict.*
	, ROW_NUMBER() OVER(PARTITION BY dim_detail_predict.dim_matter_header_curr_key ORDER BY dim_detail_predict.run_date_time DESC) AS rw
INTO #predict_data
FROM red_dw.dbo.dim_detail_predict
	INNER JOIN red_dw.dbo.fact_detail_predict
		ON fact_detail_predict.doc_id = dim_detail_predict.doc_id
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = dim_detail_predict.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.master_client_code = @client_code
	AND dim_matter_header_current.master_matter_number = @matter_number



--============================================================================================================================================
-- Pivots predict figures and gets the percentile group from the column names 
--============================================================================================================================================
SELECT	
	dim_matter_header_curr_key
	, predict_figure.predict_type
	, CASE
		WHEN LOWER(predict_figure.predict_type) LIKE '%ten' THEN
			'10'
		WHEN LOWER(predict_figure.predict_type) LIKE '%twelve_point_five' THEN
			'12.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%fifteen' THEN
			'15'
		WHEN LOWER(predict_figure.predict_type) LIKE '%seventeen_point_five' THEN
			'17.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%twenty' THEN
			'20'
		WHEN LOWER(predict_figure.predict_type) LIKE '%twenty_two_point_five' THEN
			'22.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%twenty_five' THEN
			'25'
		WHEN LOWER(predict_figure.predict_type) LIKE '%twenty_seven_point_five' THEN
			'27.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%thirty' THEN
			'30'
		WHEN REPLACE(LOWER(predict_figure.predict_type), 'thrity', 'thirty') LIKE '%thirty_two_point_five' THEN
			'32.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%thirty_five' THEN
			'35'
		WHEN LOWER(predict_figure.predict_type) LIKE '%thirty_seven_point_five' THEN
			'37.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%forty' THEN
			'40'
		WHEN LOWER(predict_figure.predict_type) LIKE '%forty_two_point_five' THEN
			'42.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%forty_five' THEN
			'45'
		WHEN LOWER(predict_figure.predict_type) LIKE '%forty_seven_point_five' THEN
			'47.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%fifty' THEN
			'50'
		WHEN LOWER(predict_figure.predict_type) LIKE '%fifty_two_point_five' THEN
			'52.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%fifty_five' THEN
			'55'
		WHEN LOWER(predict_figure.predict_type) LIKE '%fifty_seven_point_five' THEN
			'57.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%sixty' THEN
			'60'
		WHEN LOWER(predict_figure.predict_type) LIKE '%sixty_two_point_five' THEN
			'62.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%sixty_five' THEN
			'65'
		WHEN LOWER(predict_figure.predict_type) LIKE '%sixty_seven_point_five' THEN
			'67.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%seventy' THEN
			'70'
		WHEN LOWER(predict_figure.predict_type) LIKE '%seventy_two_Point_five' THEN
			'72.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%seventy_five' THEN
			'75'
		WHEN LOWER(predict_figure.predict_type) LIKE '%seventy_seven_point_five' THEN
			'77.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%eighty' THEN
			'80'
		WHEN LOWER(predict_figure.predict_type) LIKE '%eighty_two_point_five' THEN
			'82.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%eighty_five' THEN
			'85'
		WHEN LOWER(predict_figure.predict_type) LIKE '%eighty_seven_point_five' THEN
			'87.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%ninety' THEN
			'90'
		WHEN LOWER(predict_figure.predict_type) LIKE '%ninety_two_point_five' THEN
			'92.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%ninety_five' THEN
			'95'
		WHEN LOWER(predict_figure.predict_type) LIKE '%ninety_seven_point_five' THEN
			'97.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%two_point_five' THEN
			'2.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%seven_point_five' THEN
			'7.5'
		WHEN LOWER(predict_figure.predict_type) LIKE '%five' THEN
			'5'
	  END								AS percentile
	, predict_figure.predict_figure
INTO #predict_figures
FROM (
	SELECT 
		fact_detail_predict.*
	FROM red_dw.dbo.fact_detail_predict
		INNER JOIN #predict_data
			ON #predict_data.doc_id = fact_detail_predict.doc_id
	) AS predict_figures
UNPIVOT (
		predict_figure FOR predict_type IN (damages_percentile_two_point_five,damages_percentile_five,damages_percentile_seven_point_five,damages_percentile_ten,damages_percentile_twelve_point_five,damages_percentile_fifteen,damages_percentile_seventeen_point_five,damages_percentile_twenty,damages_percentile_twenty_two_point_five,damages_percentile_twenty_five,damages_percentile_twenty_seven_point_five,damages_percentile_thirty,damages_percentile_thrity_two_point_five,damages_percentile_thirty_five,damages_percentile_thirty_seven_point_five,damages_percentile_forty
											,damages_percentile_forty_two_point_five,damages_percentile_forty_five,damages_percentile_forty_seven_point_five,damages_percentile_fifty,damages_percentile_fifty_two_point_five,damages_percentile_fifty_five,damages_percentile_fifty_seven_point_five,damages_percentile_sixty,damages_percentile_sixty_two_point_five,damages_percentile_sixty_five,damages_percentile_sixty_seven_point_five,damages_percentile_seventy,damages_percentile_seventy_two_Point_five,damages_percentile_seventy_five,damages_percentile_seventy_seven_point_five
											,damages_percentile_eighty,damages_percentile_eighty_two_point_five,damages_percentile_eighty_five,damages_percentile_eighty_seven_point_five,damages_percentile_ninety,damages_percentile_ninety_two_point_five,damages_percentile_ninety_five,damages_percentile_ninety_seven_point_five,tp_costs_percentile_two_point_five,tp_costs_percentile_five,tp_costs_percentile_seven_point_five,tp_costs_percentile_ten,tp_costs_percentile_twelve_point_five,tp_costs_percentile_fifteen,tp_costs_percentile_seventeen_point_five,tp_costs_percentile_twenty
											,tp_costs_percentile_twenty_two_point_five,tp_costs_percentile_twenty_five,tp_costs_percentile_twenty_seven_point_five,tp_costs_percentile_thirty,tp_costs_percentile_thrity_two_point_five,tp_costs_percentile_thirty_five,tp_costs_percentile_thirty_seven_point_five,tp_costs_percentile_forty,tp_costs_percentile_forty_two_point_five,tp_costs_percentile_forty_five,tp_costs_percentile_forty_seven_point_five,tp_costs_percentile_fifty,tp_costs_percentile_fifty_two_point_five,tp_costs_percentile_fifty_five,tp_costs_percentile_fifty_seven_point_five
											,tp_costs_percentile_sixty,tp_costs_percentile_sixty_two_point_five,tp_costs_percentile_sixty_five,tp_costs_percentile_sixty_seven_point_five,tp_costs_percentile_seventy,tp_costs_percentile_seventy_two_Point_five,tp_costs_percentile_seventy_five,tp_costs_percentile_seventy_seven_point_five,tp_costs_percentile_eighty,tp_costs_percentile_eighty_two_point_five,tp_costs_percentile_eighty_five,tp_costs_percentile_eighty_seven_point_five,tp_costs_percentile_ninety,tp_costs_percentile_ninety_two_point_five,tp_costs_percentile_ninety_five,tp_costs_percentile_ninety_seven_point_five
											,settlement_time_percentile_two_point_five,settlement_time_percentile_five,settlement_time_percentile_seven_point_five,settlement_time_percentile_ten,settlement_time_percentile_twelve_point_five,settlement_time_percentile_fifteen,settlement_time_percentile_seventeen_point_five,settlement_time_percentile_twenty,settlement_time_percentile_twenty_two_point_five,settlement_time_percentile_twenty_five,settlement_time_percentile_twenty_seven_point_five,settlement_time_percentile_thirty,settlement_time_percentile_thrity_two_point_five,settlement_time_percentile_thirty_five
											,settlement_time_percentile_thirty_seven_point_five,settlement_time_percentile_forty,settlement_time_percentile_forty_two_point_five,settlement_time_percentile_forty_five,settlement_time_percentile_forty_seven_point_five,settlement_time_percentile_fifty,settlement_time_percentile_fifty_two_point_five,settlement_time_percentile_fifty_five,settlement_time_percentile_fifty_seven_point_five,settlement_time_percentile_sixty,settlement_time_percentile_sixty_two_point_five,settlement_time_percentile_sixty_five,settlement_time_percentile_sixty_seven_point_five
											,settlement_time_percentile_seventy,settlement_time_percentile_seventy_two_Point_five,settlement_time_percentile_seventy_five,settlement_time_percentile_seventy_seven_point_five,settlement_time_percentile_eighty,settlement_time_percentile_eighty_two_point_five,settlement_time_percentile_eighty_five,settlement_time_percentile_eighty_seven_point_five,settlement_time_percentile_ninety,settlement_time_percentile_ninety_two_point_five,settlement_time_percentile_ninety_five,settlement_time_percentile_ninety_seven_point_five
											)
		) AS predict_figure

--============================================================================================================================================
-- Get Predicts closest damages reserve match with settlement value 
--============================================================================================================================================
SELECT 
	COALESCE(damages_comparison.dim_matter_header_curr_key, tp_costs_comparison.dim_matter_header_curr_key, settlement_comparison.dim_matter_header_curr_key) AS dim_matter_header_curr_key
	, damages_comparison.percentile		AS damages_percentile
	, damages_comparison.damages_predict_figure
	, tp_costs_comparison.percentile		AS tp_costs_percentile
	, tp_costs_comparison.tp_costs_predict_figure
	, settlement_comparison.percentile		AS settlement_time_percentile
	, settlement_comparison.settlement_time_predict_figure
INTO #predict_figure_settlement_comparison
FROM (
		SELECT TOP 1
			#predict_figures.dim_matter_header_curr_key
			, #predict_figures.predict_type
			, #predict_figures.percentile
			, #predict_figures.predict_figure		AS damages_predict_figure
			, fact_detail_paid_detail.large_loss_hundred_perc_paid_total
		FROM #predict_figures
			LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
				ON fact_detail_paid_detail.dim_matter_header_curr_key = #predict_figures.dim_matter_header_curr_key
		WHERE
			#predict_figures.predict_type LIKE 'damages_percentile%'
		ORDER BY
			ABS(#predict_figures.predict_figure - fact_detail_paid_detail.large_loss_hundred_perc_paid_total) 
	) AS damages_comparison
	LEFT OUTER JOIN (
		SELECT TOP 1
			#predict_figures.dim_matter_header_curr_key
			, #predict_figures.predict_type
			, #predict_figures.percentile
			, #predict_figures.predict_figure		AS tp_costs_predict_figure
			, fact_detail_paid_detail.claimant_legal_costs_paid
		FROM #predict_figures
			LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
				ON fact_detail_paid_detail.dim_matter_header_curr_key = #predict_figures.dim_matter_header_curr_key
		WHERE
			#predict_figures.predict_type LIKE 'tp_costs%'
		ORDER BY
			ABS(#predict_figures.predict_figure - fact_detail_paid_detail.claimant_legal_costs_paid) 
	) AS tp_costs_comparison
	ON tp_costs_comparison.dim_matter_header_curr_key = damages_comparison.dim_matter_header_curr_key
	LEFT OUTER JOIN (
		SELECT TOP 1
			#predict_figures.dim_matter_header_curr_key
			, #predict_figures.predict_type
			, #predict_figures.percentile
			, #predict_figures.predict_figure			AS settlement_time_predict_figure
			, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded)		AS days_to_settle
		FROM #predict_figures
			LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
				ON dim_detail_core_details.dim_matter_header_curr_key = #predict_figures.dim_matter_header_curr_key
			LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
				ON dim_detail_outcome.dim_matter_header_curr_key = #predict_figures.dim_matter_header_curr_key
		WHERE
			#predict_figures.predict_type LIKE 'settlement_time%'
		ORDER BY
			ABS(#predict_figures.predict_figure - DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded)) 
	) AS settlement_comparison
	ON tp_costs_comparison.dim_matter_header_curr_key = damages_comparison.dim_matter_header_curr_key



--============================================================================================================================================
-- Main Query
--============================================================================================================================================
SELECT 
    dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [MS Ref]
	, dim_fed_hierarchy_history.name			AS [MS Case Handler]
	, dim_matter_header_current.matter_description		AS [Case Description]
	, COALESCE(NULLIF(dim_client_involvement.client_reference, ''), dim_client_involvement.insurerclient_reference)		AS [Client Ref]
	, dim_detail_core_details.clients_claims_handler_surname_forename		AS [Client Handler]
	, FORMAT(predict_data.run_date_time, 'dd MMMM yyyy')		AS [Predict Run Date]
	, predict_data.model_version		AS [Model Version]
	, FORMAT(dim_detail_outcome.date_claim_concluded, 'dd MMMM yyyy')			AS [Date Claim Concluded]
	, dim_detail_outcome.outcome_of_case			AS [Outcome of Case]
	, dim_detail_core_details.injury_type			AS [Injury Type]
	, predict_data.derived_injury				AS [Predict Derived Injury]
	, dim_detail_core_details.ll01_sex				AS [Sex]
	, predict_data.ll01_sex					AS [Predict Sex]
	, dim_detail_core_details.ll02_legal_status		AS [Legal Status]
	, predict_data.ll02_legal_status			AS [Predict Legal Status]
	,  DATEDIFF(YEAR, dim_detail_core_details.claimants_date_of_birth, dim_detail_core_details.incident_date)- 
		CASE 
			WHEN (MONTH(dim_detail_core_details.claimants_date_of_birth) > MONTH(dim_detail_core_details.incident_date)) OR (MONTH(dim_detail_core_details.claimants_date_of_birth) = MONTH(dim_detail_core_details.incident_date) AND DAY(dim_detail_core_details.claimants_date_of_birth) > DAY(dim_detail_core_details.incident_date)) THEN 
				1 
			ELSE 
				0 
		END				AS [Age at Accident]
	, predict_data.age_at_accident			AS [Predict Age at Accident]
	, dim_detail_core_details.ll09_initial_glasgow_coma_scale		AS [Initial Glasgow Coma Scale]
	, REPLACE(predict_data.ll09_initial_glasgow_coma_scale_derived, 'not applicable', 'N/A')			AS [Predict Initial Glasgow Coma Scale]
	, dim_detail_core_details.ll11_frontal_lobe_damage				AS [Frontal Lobe Damage]
	, predict_data.ll11_frontal_lobe_damage_derived					AS [Predict Frontal Lobe Damage]
	, dim_detail_core_details.ll13_level_of_spinal_cord_injury		AS [Level of Spinal Cord Injury]
	, REPLACE(predict_data.ll13_level_of_spinal_cord_injury_derived, 'not applicable', 'N/A')			AS [Predict Level of Spinal Cord Injury]
	, IIF(LOWER(RTRIM(dim_detail_core_details.ll10_period_of_hospitalisation_days_text)) = 'unknown upon conclusion', dim_detail_core_details.ll10_period_of_hospitalisation_days_text, dim_detail_core_details.ll10_period_of_hospitalisation_days)		AS [Hospitalisation Days]
	, predict_data.ll10_period_of_hospitalisation_days		AS [Predict Hospitalisation Days]
	, IIF(LOWER(RTRIM(dim_detail_core_details.ll14_period_of_ventilation_days_text)) = 'unknown upon conclusion', dim_detail_core_details.ll14_period_of_ventilation_days_text, dim_detail_core_details.ll14_period_of_ventilation_days)		AS [Ventilation Days]
	, predict_data.ll14_period_of_ventilation_days_derived			AS [Predict Ventilation Days]
	, IIF(LOWER(RTRIM(dim_detail_core_details.ll12_period_of_peg_feeding_text)) = 'unknown upon conclusion', dim_detail_core_details.ll12_period_of_peg_feeding_text, dim_detail_core_details.ll12_period_of_peg_feeding)		AS [Peg Feeding Days]
	, predict_data.ll12_period_of_peg_feeding_derived		AS [Predict Peg Feeding Days]
	, dim_detail_future_care.ll13_24_hour_care				AS [24 Hour Care]
	, predict_data.ll13_24_hour_care_derived				AS [Predict 24 Hour Care]
	, dim_detail_core_details.ll18_is_there_a_reduced_life_expectancy		AS [Reduced Life Expectancy]
	, predict_data.ll18_is_there_a_reduced_life_expectancy_derived			AS [Predict Reduced Life Expectancy]
	, fact_detail_paid_detail.large_loss_hundred_perc_paid_total			AS [Large Loss 100% Paid Total]	
	, fact_detail_paid_detail.hospital_charges_paid							AS [Hospital Charges Paid]
	, fact_detail_paid_detail.ll25_cru_paid				AS [CRU Paid]
	, fact_detail_reserve_detail.large_loss_hundred_perc_reserve_total		AS [Weightmans Initial Damages Reserve]
	, fact_detail_reserve_detail.large_loss_hundred_perc_current_dam_res_total	AS [Weightmand Current Damages Reserve]
	, fact_detail_reserve_initial.predict_rec_damages_reserve_initial		AS [Predict Recommended Damgaes Reserve Initial]
	, fact_detail_reserve_detail.predict_rec_damages_reserve_current		AS [Predict Recommended Damgaes Reserve Current]
	, predict_data.meta_model_damages			AS [Predict Damages Meta Model]
	, predict_data.meta_model_percentile_damages		AS [Predict Damages Meta Model Percent]
	, CASE
		WHEN dim_detail_outcome.date_claim_concluded IS NULL THEN
			NULL 
		ELSE
			#predict_figure_settlement_comparison.damages_predict_figure		
	  END									AS [Predict Closest Percentile to Damages Settlement]
	, CASE
		WHEN dim_detail_outcome.date_claim_concluded IS NULL THEN
			NULL 
		ELSE
			#predict_figure_settlement_comparison.damages_percentile			
	  END									AS [Damages Percentile]
	, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded)		AS [Days to Settle]
	, predict_data.meta_model_percentile_settlement_time		AS [Predict Settlement Time Meta Model]
	, CASE
		WHEN dim_detail_outcome.date_claim_concluded IS NULL THEN
			NULL 
		ELSE
			#predict_figure_settlement_comparison.settlement_time_predict_figure	
	  END										AS [Predict Closest Percentile to Damages Settlement Time]
	, CASE
		WHEN dim_detail_outcome.date_claim_concluded IS NULL THEN
			NULL 
		ELSE
			#predict_figure_settlement_comparison.settlement_time_percentile		
	  END											AS [Settlement Time Percentile]
	, dim_detail_claim.dst_claimant_solicitor_firm			AS [Claimant Solicitor Firm]
	, predict_data.claimant_solicitor_category				AS [Claimant Solicitor Category]
	, FORMAT(dim_detail_outcome.date_costs_settled, 'dd MMMM yyyy')		AS [Date Costs Settled]
	, fact_detail_paid_detail.claimant_legal_costs_paid		AS [Claimant Legal Costs Paid]
	, fact_detail_reserve_detail.ll28_claimants_legal_costs_reserve_initial		AS [Weightmans Initial Claimant Costs Reserve]
	, fact_detail_reserve_detail.own_legal_costsdisbs_reserve_12_month		AS [Weightmans Current Claimants Costs Reserve]
	, fact_detail_reserve_initial.predict_rec_claimant_costs_reserve_initial		AS [Predict Recommended Claimant Costs Reserve Initial]
	, fact_detail_reserve_detail.predict_rec_claimant_costs_reserve_current		AS [Predict Recommended Claimant Costs Reserve Current]
	, predict_data.meta_model_tp_costs		AS [Predict Claimant Costs Meta Model]
	, predict_data.meta_model_percentile_tp_costs	AS [Predict Claimant Costs Meta Model Percent]
	, CASE	
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			NULL 
		ELSE
			#predict_figure_settlement_comparison.tp_costs_predict_figure		
	  END								AS [Predict Closest Percentile to Costs Settlement]
	, CASE	
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			NULL 
		ELSE
			#predict_figure_settlement_comparison.tp_costs_percentile			
	  END										AS [TP Costs Percentile]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN #predict_data AS predict_data
		ON predict_data.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND predict_data.rw = 1
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_future_care
		ON dim_detail_future_care.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_initial
		ON fact_detail_reserve_initial.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #predict_figure_settlement_comparison
		ON #predict_figure_settlement_comparison.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE 1 = 1
	
END 


GO

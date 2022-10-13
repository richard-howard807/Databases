SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-27
Description:		Public Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [Omni].[PublicDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		SELECT
				 RTRIM(dimmain.client_code)+'/'+dimmain.matter_number AS [Weightmans Reference]
				,dimmain.client_code AS [Client Code]
				,dimmain.matter_number AS [Matter Number]
				,dim_detail_claim.[source_of_instruction] AS [Source of Instruction]
				,dim_detail_claim.[district] AS [Police District]
				,dim_detail_advice.[surrey_police_stations] AS [Surrey Police Stations]
				,dim_detail_advice.[sussex_police_stations] AS [Sussex Police Stations]
				,dim_detail_advice.[surrey_sussex_police_issue] AS [Police Issue]
				,dim_detail_advice.[surrey_sussex_police_date_of_written_response] AS [Surrey/Sussex Police) Date of Written Response]
				,dim_detail_advice.[date_call_closed] AS [Date Call Closed]
				,dim_detail_advice.[risk] AS [Risk]
				,dim_detail_advice.[name_of_caller] AS [Name of Caller]
				,dim_detail_advice.[status] AS [Status]
				,dim_detail_advice.[knowledge_gap] AS [Knowledge Gap]
				,dim_detail_advice.[summary_of_advice] AS [Summary of Advice]
				,CASE WHEN DATEPART(MONTH,dim_detail_core_details.[date_instructions_received])<=3 THEN 'Qtr 1'
					WHEN DATEPART(MONTH,dim_detail_core_details.[date_instructions_received])<=6 THEN 'Qtr 2'
					WHEN DATEPART(MONTH,dim_detail_core_details.[date_instructions_received])<=9 THEN 'Qtr 3'
					WHEN DATEPART(MONTH,dim_detail_core_details.[date_instructions_received])<=12 THEN 'Qtr 4'
				 END AS [Quarter Received]
				,CASE WHEN dim_detail_advice.[date_call_closed] IS NOT NULL THEN DATEDIFF(DAY,dim_detail_core_details.[date_instructions_received],dim_detail_advice.[surrey_sussex_police_date_of_written_response]) ELSE '' END AS [Days from Received to Written Response]
				,dim_detail_advice.dvpo_victim_postcode
				,dim_detail_advice.dvpo_number_of_children
				,dim_detail_advice.dvpo_division
				,dim_detail_advice.dvpo_granted
				,dim_detail_advice.dvpo_contested
				,dim_detail_advice.dvpo_breached
				,dim_detail_advice.dvpo_is_first_breach
				,dim_detail_advice.dvpo_breach_admitted
				,dim_detail_advice.dvpo_breach_proved
				,dim_detail_advice.dvpo_breach_sentence
				,dim_detail_advice.dvpo_breach_sentence_length
				,dim_detail_advice.dvpo_legal_costs_sought
				,dim_detail_advice.dvpo_court_fee_awarded
				,dim_detail_advice.dvpo_own_fees_awarded

		FROM 
		red_dw.dbo.fact_dimension_main AS dimmain
		LEFT OUTER JOIN red_dw.dbo.dim_detail_claim AS dim_detail_claim ON dim_detail_claim.dim_detail_claim_key=dimmain.dim_detail_claim_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_advice AS dim_detail_advice ON dim_detail_advice.dim_detail_advice_key = dimmain.dim_detail_advice_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome AS dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = dimmain.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=dimmain.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = dimmain.dim_client_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = dimmain.dim_detail_core_detail_key

		WHERE 
		ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
		AND dim_matter_header_current.reporting_exclusions=0
		AND (dim_matter_header_current.date_closed_case_management >= '20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)



		ORDER BY dimmain.client_code, dimmain.matter_number

END

GO

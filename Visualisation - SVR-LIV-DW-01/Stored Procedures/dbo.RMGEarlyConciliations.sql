SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Max Taylor>
-- Create date: <2021-05-04>
-- Description:	<Initial Create for Tableau RMGEC --http://bardetail/reports/report/5%20-%20Client%20Reports/RMG/RMG%20Early%20Conciliations>
-- =============================================

CREATE PROCEDURE  [dbo].[RMGEarlyConciliations]

AS

SELECT DISTINCT 
            
            
            Client = dim_client.[client_code],
            Matter = dim_matter_header_current.[matter_number],
            [Matter description] = dim_matter_header_current.[matter_description],
            [Work Type] = dim_matter_worktype.[work_type_name],
			[Instruction Type] = dim_instruction_type.[instruction_type],
            [ACAS Ref] = dim_court_involvement.[acas_reference],
            [ACAS Conciliator] = dim_court_involvement.[acas_name],
            [CWU Rep] = dim_claimant_thirdparty_involvement.[claimantrep_name],
            [Repeat Claim?] = dim_detail_advice.[repeat_claim],
            [Case manager] = dim_fed_hierarchy_history.name,
			[Date case opened FED] = CAST(dim_matter_header_current.date_opened_case_management AS DATE) ,
            [Date case closed FED] = CAST(dim_matter_header_current.date_closed_case_management AS DATE) ,
            [Primary classification] = dim_detail_practice_area.[primary_case_classification],
            [Secondary classification] = dim_detail_practice_area.[secondary_case_classification],
            [Claimant's place of work] = dim_detail_client.[emp_claimants_place_of_work],
 			[Region] = dim_detail_client.[rm_region],
            [Pay number] = dim_detail_advice.[pay_number],
            [Sensitive case] = dim_detail_client.[emp_rmg_sensitive_case],
            [Diversity issue?] = dim_detail_advice.[diversity_issue],
            [Policy issue?] = dim_detail_advice.[policy_issue],
            [Claimant represented] = dim_detail_practice_area.[emp_claimant_represented],
            [EC expiry] = dim_detail_practice_area.[ec_expiry],
            [Potential compensation] = fact_detail_reserve_detail.[potential_compensation],
            [Prospects of success] = dim_detail_practice_area.[emp_prospects_of_success],
			[Decision Maker] = txtDecMaker,
            [EC status] = dim_detail_advice.[ec_status],
            [EC outcome] = dim_detail_advice.[ec_outcome],
			[Calculation Date] = dim_detail_advice.[calculation_date], 
			[Date COT3 received / payment request] = dim_detail_advice.[date_cot3_received_or_payment_requested],
            [Date concluded] = dim_detail_outcome.[date_claim_concluded],
            [Actual compensation] = fact_detail_paid_detail.[actual_compensation],                        
            [ET claim] = dim_detail_advice.[et_claim],
			[Matter Client Accessible Notes] = dim_file_notes.external_file_notes 
			
       FROM red_dw.dbo.fact_dimension_main
	   JOIN red_dw.dbo.dim_matter_header_current
	   ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	   JOIN red_dw.dbo.dim_client
	   ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
	   LEFT JOIN red_dw.dbo.dim_instruction_type
	   ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
	   LEFT JOIN red_dw.dbo.dim_matter_worktype
	   ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	   LEFT JOIN red_dw.dbo.dim_court_involvement 
	   ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
	   LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
	   ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
	   LEFT JOIN red_dw.dbo.dim_detail_advice
	   ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
	   LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
	   ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
       LEFT JOIN red_dw.dbo.dim_detail_practice_area
	   ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
	   LEFT JOIN red_dw.dbo.dim_detail_client
	   ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
	   LEFT JOIN red_dw.dbo.fact_detail_reserve_detail
	   ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
	   LEFT JOIN red_dw.dbo.dim_detail_outcome
	   ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	   LEFT JOIN red_dw.dbo.fact_detail_paid_detail
	   ON fact_detail_paid_detail.master_fact_key = fact_detail_reserve_detail.master_fact_key
	   LEFT JOIN ms_prod.dbo.udMIPAEmployment
       ON fileID=ms_fileid  AND dim_client.client_code IN ('R1001','P00005','P00018')   AND txtDecMaker IS NOT NULL 
	   LEFT JOIN red_dw.dbo.dim_file_notes 
	   ON dim_file_notes.dim_file_notes_key = fact_dimension_main.dim_file_notes_key

 WHERE 1 = 1 
 
 AND dim_client.[client_code] =  'P00018'
 OR (dim_client.[client_code] = 'P00005' 
 AND TRIM(dim_matter_header_current.[matter_number]) IN ('00001152', '00001153', '00001154', '00001155', '00001162'))

 OR (dim_client.[client_code] = 'R1001' 
 AND  TRIM(dim_instruction_type.[instruction_type]) = 'Employment Early Conciliations (Annual Retainer)') 


ORDER BY
    dim_client.[client_code],
    dim_matter_header_current.[matter_number]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[SeftonMBCClaimsReviewReport_ds]

(
@DateClosed AS DATE

)

AS
-------Testing
--DECLARE @DateClosed AS DATE = GETDATE() -300


SELECT 
[Mattersphere Weightmans Reference] = dim_matter_header_current.master_client_code +'-'+ dim_matter_header_current.master_matter_number
,[Matter Description] = dim_matter_header_current.matter_description
,[Date Case Opened] = dim_matter_header_current.date_opened_case_management
,[Date Case Closed] = dim_matter_header_current.date_closed_case_management
,[Case Manager] = dim_fed_hierarchy_history.name
,[Team] = dim_fed_hierarchy_history.hierarchylevel4hist
,[Work Type] = dim_matter_worktype.work_type_name
,[Present Position] = dim_detail_core_details.[present_position]
,[Brief Details of Claim] = dim_detail_core_details.[brief_details_of_claim]
,[Description of Injury] = dim_detail_core_details.brief_description_of_injury
,[Incident Date] = dim_detail_core_details.incident_date
,[Damages Reserve Current] = fact_finance_summary.[damages_reserve] 
,[Claimant Costs Reserve Current] = fact_detail_reserve_detail.claimant_costs_reserve_current
,[Outcome of Case] = dim_detail_outcome.outcome_of_case
,[Date Claim Concluded] = dim_detail_outcome.[date_claim_concluded] 
,[Damages Paid by Client] = fact_finance_summary.[damages_paid] 
,[Damages Reserve V Damages Paid] = CASE WHEN  fact_finance_summary.[damages_paid]  IS NULL THEN NULL ELSE  ISNULL(fact_finance_summary.[damages_reserve] , 0) - ISNULL(fact_finance_summary.[damages_paid], 0) END
,[Claimant's Costs Paid by Client] = fact_finance_summary.[claimants_costs_paid]
,[Costs Reserve v Claimant’s Costs Paid] = CASE WHEN fact_finance_summary.[claimants_costs_paid] IS NULL THEN NULL ELSE ISNULL(fact_detail_reserve_detail.claimant_costs_reserve_current,0) -  ISNULL(fact_finance_summary.[claimants_costs_paid], 0) END
,[Total Bill Amount] = fact_finance_summary.total_amount_bill_non_comp 
,[Last Bill Date] = fact_matter_summary_current.last_bill_date 
,[Date of Last Time Posting] = fact_matter_summary_current.last_time_transaction_date
,[LiveClosed] = CASE WHEN MS_Prod.config.dbFile.fileStatus =  'LIVE' THEN 'Live'
                     WHEN MS_Prod.config.dbFile.fileStatus =  'DEAD' THEN 'Closed'
					 WHEN MS_Prod.config.dbFile.fileStatus = 'PENDCLOSE' THEN 'Pending Close' END

 ,work_type_group

--,fact_finance_summary.[damages_reserve]                            AS  '[fact_finance_summary.[damages_reserve]]'
--,fact_finance_summary.[personal_injury_paid]                       AS 'fact_finance_summary.[personal_injury_paid]'
--,fact_detail_reserve_detail.claimant_costs_reserve_current         AS 'fact_detail_reserve_detail.claimant_costs_reserve_current'
--,fact_detail_client.[claimants_costs]                              AS 'fact_detail_client.[claimants_costs]'
--,fact_detail_paid_detail.[total_claimants_costs_paid]              AS 'fact_detail_paid_detail.[total_claimants_costs_paid]'
--,fact_detail_paid_detail.[total_claimants_costs_claimed]           AS 'fact_detail_paid_detail.[total_claimants_costs_claimed]'
--,dim_detail_core_details.[date_instructions_received]              AS 'dim_detail_core_details.[date_instructions_received]'




FROM red_dw.dbo.dim_matter_header_current
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_detail_reserve_detail
ON  fact_detail_reserve_detail.dim_matter_header_curr_key = fact_finance_summary.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN MS_Prod.config.dbFile ON dbFile.fileID=dim_matter_header_current.ms_fileid
LEFT JOIN red_dw.dbo.fact_detail_client
ON fact_detail_client.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
WHERE 1 = 1 
AND reporting_exclusions = 0

AND (
   matter_description LIKE '%Sefton MBC%'
OR matter_description LIKE '%Sefton Council%'
OR matter_description LIKE '%Sefton Metropolitan Borough%'

OR dim_matter_header_current.client_name LIKE '%Sefton MBC%'
OR dim_matter_header_current.client_name LIKE '%Sefton Council%'
OR dim_matter_header_current.client_name LIKE '%Sefton Metropolitan Borough%'

OR  dim_client_involvement.[insuredclient_name] LIKE '%Sefton MBC%'
OR  dim_client_involvement.[insuredclient_name] LIKE '%Sefton Council%'
OR  dim_client_involvement.[insuredclient_name] LIKE '%Sefton Metropolitan Borough%'

)

AND TRIM(work_type_group)
IN ('PL All' ,'Disease' ,'Motor','EL'  )

AND ( dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management >= @DateClosed )
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CostsBudgetingReport]

AS

BEGIN

 SET NOCOUNT ON;
 
 select   dim_matter_header_current.client_code as Client
		,dim_matter_header_current.matter_number as Matter
		,client_name as [Client Name]
		, ChgTimeVal as [ChgTimeVal]
		, matter_description as [Name of Case]
		,name as [Fee Earner Name]
		, hierarchylevel4hist as [Fee Earner Team]
		,date_opened_case_management as [Date Case Opened]
		,date_closed_case_management as [Date Case Closed]
		,dim_detail_core_details.[track] as [Track]
		,dim_detail_core_details.[will_the_court_require_a_cost_budget]  as [Will the Court Require a Cost Budget]
		,fact_detail_cost_budgeting.[estimated_value_costs_budget] as [Estimated Total Value of Our Costs Budget?]
		,CASE WHEN ms_only=1 THEN cboCostBudChal ELSE  COS285.case_text END COLLATE DATABASE_DEFAULT as [Who is Instructed to Challenge Opponents Costs Budget?]
		, COS215.case_text as [Who Will Compile the Budget?]
		,CASE WHEN ms_only=1  THEN cboIdentCostBud ELSE COS204.case_text END  COLLATE DATABASE_DEFAULT as [Identity of Cost Budget Service Provider]
		, COS218.case_date as [Date Costs Budget Received From Other Side]
		, fact_detail_cost_budgeting.[value_budget_other_side] as [Value of Budget From Other Side?]
		,fact_detail_cost_budgeting.[total_disbs_budget_agreedrecorded] as [Total Disbs Budget Agreed/Recorded]
		, fact_detail_cost_budgeting.[total_profit_costs_budget_agreedrecorded] as [Total Profit Costs Budget Agreed/Recorded]
		,CASE WHEN ms_only=1  THEN cboBudAppCrt ELSE COS713.case_text END COLLATE DATABASE_DEFAULT  as [Budget Approved by Court]
		,CASE WHEN ms_only=1   THEN cboStaged ELSE COS714.case_text END  COLLATE DATABASE_DEFAULT as [Staged?]
		,CASE WHEN ms_only=1 THEN txtDistJudge ELSE  COS715.case_text END COLLATE DATABASE_DEFAULT as [District Judge]
		, fact_detail_cost_budgeting.[total_disbs_budget_agreedrecorded_other_side] as [Total Disbs Budget Agreed/Recorded (Other Side)]
		, fact_detail_cost_budgeting.[total_profit_costs_budget_agreedrecorded_other_side] as [Total Profit Costs Budget Agreed/Recorded (Other Side)]
		, fact_detail_cost_budgeting.[budget_approved_by_court_other_side] as [Budget Approved by Court (other Side)]
		,COS735.case_text  as [Staged (Other Side)]
		, dim_detail_core_details.[referral_reason] AS [Referral Reason]
		,dim_detail_core_details.[proceedings_issued] as [Proceedings Issued]
		,CASE WHEN ms_only=1 THEN cboBudgOSPreLit ELSE COS200.case_text END COLLATE DATABASE_DEFAULT AS [Instructed to Budget with other side in Pre-lit phase?]
		
		FROM red_dw.dbo.dim_matter_header_current
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		 ON fed_code=fee_earner_code AND dss_current_flag='Y'
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		 ON dim_matter_header_current.client_code=dim_detail_core_details.client_code
		 AND dim_matter_header_current.matter_number=dim_detail_core_details.matter_number
		LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting
		 ON dim_matter_header_current.client_code=fact_detail_cost_budgeting.client_code
		 AND dim_matter_header_current.matter_number=fact_detail_cost_budgeting.matter_number		 
		LEFT OUTER JOIN (SELECT client_code,matter_number,SUM(time_charge_value) AS ChgTimeVal
	FROM red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
	WHERE time_activity_code in ('CB01','CB01')
	GROUP BY client_code,matter_number) AS TimeCharge
			 ON dim_matter_header_current.client_code=TimeCharge.client_code
		 AND dim_matter_header_current.matter_number=TimeCharge.matter_number	 
		 LEFT OUTER JOIN MS_Prod.dbo.udMICoreGeneral WITH(NOLOCK)
		  ON dim_matter_header_current.ms_fileid=udMICoreGeneral.fileID
				 LEFT OUTER JOIN MS_Prod.dbo.udMIOwnCostsBudget WITH(NOLOCK)
		  ON dim_matter_header_current.ms_fileid=udMIOwnCostsBudget.fileID  
		  
		  
		 LEFT OUTER JOIN (SELECT * FROM axxia01.dbo.casdet WHERE case_detail_code='COS285') AS COS285
		  ON dim_matter_header_current.case_id=COS285.case_id
		 LEFT OUTER JOIN (SELECT * FROM axxia01.dbo.casdet WHERE case_detail_code='COS215') AS COS215
		  ON dim_matter_header_current.case_id=COS215.case_id
		 LEFT OUTER JOIN (SELECT * FROM axxia01.dbo.casdet WHERE case_detail_code='COS218') AS COS218
		  ON dim_matter_header_current.case_id=COS218.case_id		  
		 LEFT OUTER JOIN (SELECT * FROM axxia01.dbo.casdet WHERE case_detail_code='COS204') AS COS204
		  ON dim_matter_header_current.case_id=COS204.case_id				 	  
		 LEFT OUTER JOIN (SELECT * FROM axxia01.dbo.casdet WHERE case_detail_code='COS713') AS COS713
		  ON dim_matter_header_current.case_id=COS713.case_id				 
		 LEFT OUTER JOIN (SELECT * FROM axxia01.dbo.casdet WHERE case_detail_code='COS714') AS COS714
		  ON dim_matter_header_current.case_id=COS714.case_id						  
		   
		 LEFT OUTER JOIN (SELECT * FROM axxia01.dbo.casdet WHERE case_detail_code='COS715') AS COS715
		  ON dim_matter_header_current.case_id=COS715.case_id						  
		   		  		  
		 LEFT OUTER JOIN (SELECT * FROM axxia01.dbo.casdet WHERE case_detail_code='COS735') AS COS735
		  ON dim_matter_header_current.case_id=COS735.case_id						  
		 LEFT OUTER JOIN (SELECT * FROM axxia01.dbo.casdet WHERE case_detail_code='COS200') AS COS200
		  ON dim_matter_header_current.case_id=COS200.case_id				   		  		  		   		  		  
		   		  		  		   		  		  
WHERE  date_opened_case_management >= '2013-04-01'
	AND dim_detail_core_details.[track]= 'Multi Track'
	AND reporting_exclusions=0

	
	
	 END
GO

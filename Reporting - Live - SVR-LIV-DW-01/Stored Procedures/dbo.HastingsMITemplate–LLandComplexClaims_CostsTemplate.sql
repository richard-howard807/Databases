SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[HastingsMITemplate–LLandComplexClaims_CostsTemplate]-- EXEC [dbo].[HastingsMITemplate–LLandComplexClaims_CostsTemplate]

AS


SELECT * 

FROM 

(
SELECT DISTINCT 
[Claim Reference]	               =     COALESCE([dim_client_involvement].client_reference, [dim_client_involvement].insurerclient_reference),
[Final Bill Date]                  =     dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill],
[Fee]                              =     dim_employee.forename  +' ' + dim_employee.surname , 
[Fee Amount]                       = SUM(fact_bill_billed_time_activity.actual_time_recorded_value),
[Fee VAT]                          =  NULL,
[Hours Spent]                      =	SUM(CAST(fact_bill_billed_time_activity.minutes_recorded AS DECIMAL(10,2)))/60,
[Disbursements]                    =   CAST('' AS VARCHAR(100)),
[Disbursements Amount]             =   NULL,
[Order]                            =   1


-- dim_matter_header_current.dim_matter_header_curr_key
--, TimeRecordedBy.fed_code [Unique timekeeper ID per timekeeper]

FROM red_dw.dbo.fact_bill_billed_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
 ON dim_bill_date.dim_bill_date_key = fact_bill_billed_time_activity.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS TimeRecordedBy
 ON TimeRecordedBy.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key 
INNER JOIN red_dw.dbo.dim_employee WITH(NOLOCK)
 ON dim_employee.dim_employee_key = TimeRecordedBy.dim_employee_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history AS Levelname
 ON Levelname.fed_code = TimeRecordedBy.fed_code AND Levelname.dss_current_flag = 'Y'
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key


WHERE 1 =1 

 AND dim_matter_header_current.master_client_code = '4908'
 AND date_opened_case_management >= '2021-05-01'  --01/05/2021
 AND dim_matter_header_current.reporting_exclusions = 0 
 AND dim_matter_header_current.master_client_code +'-' + master_matter_number <> '4908-19'
 --AND dim_matter_header_current.master_client_code +'-' + master_matter_number = '4908-9'
 --AND  dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL 


GROUP BY  COALESCE([dim_client_involvement].client_reference, [dim_client_involvement].insurerclient_reference),
		  dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill],
    	  dim_employee.forename  +' ' + dim_employee.surname 

		  UNION 



SELECT DISTINCT
[Claim Reference]	          =  COALESCE([dim_client_involvement].client_reference, [dim_client_involvement].insurerclient_reference),   
[Final Bill Date]             =   dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill],
[Fee]                         =  dim_disbursement_cost_type.cost_type_description ,
[Fee Amount]                  = NULL  ,
[Fee VAT]                     = NULL  ,
[Hours Spent]                 = NULL  ,
[Disbursements]               = CostCard.Narrative,
[Disbursements Amount]        = CostCard.RefAmt_ccc,
[Order]                       = 2 




FROM TE_3E_Prod.dbo.CostCard
    INNER JOIN TE_3E_Prod.dbo.Matter
        ON CostCard.Matter = matter.MattIndex
    INNER JOIN MS_Prod.config.dbFile
        ON MattIndex = fileExtLinkID
    LEFT OUTER JOIN MS_Prod.config.dbClient
        ON dbClient.clID = dbFile.clID
    LEFT OUTER JOIN TE_3E_Prod.dbo.InvMaster
        ON CostCard.InvMaster = InvMaster.InvIndex
    LEFT OUTER JOIN TE_3E_Prod.dbo.Client
        ON matter.Client = Client.ClientIndex
    LEFT OUTER JOIN TE_3E_Prod.dbo.CostBill
        ON CostCard.CostIndex = CostBill.CostCard
           AND CostBill.IsReversed = 0
    LEFT OUTER JOIN TE_3E_Prod.dbo.ChrgBillTax
        ON CostBill.CostBillIndex = ChrgBillTax.CostBill
    LEFT OUTER JOIN TE_3E_Prod.dbo.CostType
        ON CostCard.CostType = CostType.Code
    LEFT OUTER JOIN TE_3E_Prod.dbo.Timekeeper
        ON CostCard.Timekeeper = Timekeeper.TkprIndex
		JOIN red_dw.dbo.dim_matter_header_current 
		ON ms_fileid = fileID

		 LEFT JOIN red_dw.dbo.fact_disbursements_detail   
 ON CostCard.CostIndex = fact_disbursements_detail.costindex
 LEFT JOIN red_dw.dbo.dim_disbursement_cost_type 
  ON fact_disbursements_detail.dim_disbursement_cost_type_key = dim_disbursement_cost_type.dim_disbursement_cost_type_key
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
WHERE 1 = 1 

      AND TE_3E_Prod.dbo.CostCard.IsActive = 1
  
	  AND dim_matter_header_current.master_client_code = '4908'

	  AND dim_matter_header_current.master_client_code +'-' + master_matter_number <> '4908-19'

	  AND date_opened_case_management >= '2021-05-01'  --01/05/2021
      
	  AND dim_matter_header_current.reporting_exclusions = 0 

	--  AND  dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL 


	  ) ALLdata

	  ORDER BY ALLdata.[Claim Reference], [ALLdata].[Order] desc
	

--[Fee] = Timekeeper.DisplayName ,
-- CostCard.WIPRate ,
--[Disbursements] = CostCard.Narrative,
--[Disbursements Amount] = CostCard.RefAmt_ccc

--,ms_fileid
--,ClientMatter = TRIM(dim_matter_header_current.master_client_code) +'.'+TRIM(master_matter_number)

--,InvMaster.OrgAmt, 
--InvMaster.OrgFee, 
--InvMaster.OrgHCo,
--InvMaster.OrgTax


--,CostBillIndex
--,CostIndex
--,CostBill.InvMaster
--,InvIndex
--, dim_disbursement_cost_type.cost_type_description 
--,fact_disbursements_detail.total_unbilled_disbursements
--,fact_disbursements_detail.dim_matter_header_curr_key
GO

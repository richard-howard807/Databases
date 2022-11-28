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
[Fee]                              =     TRIM([3E billing description]) COLLATE DATABASE_DEFAULT, 
[Fee Amount]= SUM(fees_total),
[Fee VAT]                          =     VAT.[VAT on Legal Costs],

[Hours Spent]                      =	(HrsBilled),
[Disbursements]                    =   CAST('' AS VARCHAR(100)),
[Disbursements Amount]             =   NULL,
[Order]                            =   1
FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
 LEFT OUTER JOIN red_dw.dbo.dim_client_involvement 
  ON dim_client_involvement.client_code = dim_matter_header_current.client_code
  AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
  ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT fact_bill_billed_time_activity.dim_matter_header_curr_key

,SUM(BillHrs) AS HrsBilled
FROM  red_dw.dbo.fact_bill_billed_time_activity
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
        LEFT OUTER JOIN TE_3E_Prod.dbo.TimeBill
            ON TimeCard = fact_bill_billed_time_activity.transaction_sequence_number
               AND TimeBill.timebillindex = fact_bill_billed_time_activity.timebillindex
WHERE dim_matter_header_current.master_client_code = '4908'
GROUP BY fact_bill_billed_time_activity.dim_matter_header_curr_key
) AS HrsBilled
 ON  HrsBilled.dim_matter_header_curr_key = dim_detail_outcome.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT dbfile.fileid
,		SUM(TB.billamt) AS [Legal Costs]
,		SUM(cbt.chrgamt) AS [VAT on Legal Costs]
,MAX(ARD.invdate) AS LastBillDate

FROM red_dw.dbo.ds_sh_3e_armaster ARD WITH(NOLOCK)
INNER JOIN red_dw.dbo.ds_sh_3e_matter AS m WITH(NOLOCK)
 ON ARD.matter=m.mattindex
INNER JOIN red_dw.dbo.ds_sh_ms_dbfile AS dbfile WITH(NOLOCK)
 ON m.mattindex=dbfile.fileextlinkid
INNER JOIN red_dw.dbo.ds_sh_ms_dbclient WITH(NOLOCK)
 ON ds_sh_ms_dbclient.clid = dbfile.clid
INNER JOIN red_dw.dbo.ds_sh_3e_timebill TB WITH(NOLOCK)  
ON TB.armaster = ARD.armindex
LEFT JOIN red_dw.dbo.ds_sh_3e_chrgbilltax CBT WITH(NOLOCK) 
ON tb.timebillindex = cbt.timebill
WHERE clno IN ('4908')
AND ARD.arlist  IN ('Bill','BillRev')
GROUP BY dbfile.fileid
) AS VAT
 ON ms_fileid=VAT.fileid
LEFT OUTER JOIN 
(
SELECT dbFile.fileID
,REPLACE(b.Description,'DO NOT USE','') AS [3E billing description]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN MS_Prod.config.dbFile
 ON ms_fileid=dbfile.fileid
LEFT OUTER JOIN MS_Prod.dbo.udExtFile
ON ms_fileid=udExtFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.dbUser
 ON dbfile.createdby=dbUser.usrid
 LEFT OUTER JOIN TE_3E_Prod.dbo.Arrangement AS a
 ON cboRateArrange=a.Code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN TE_3E_Prod.dbo.Arrangement AS b
 ON billing_arrangement=b.Code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE master_client_code='4908'
) AS RateArr
 ON RateArr.fileID = ms_fileid
WHERE 1 =1 

 AND dim_matter_header_current.master_client_code = '4908'
 AND date_opened_case_management >= '2021-05-01'  --01/05/2021
 AND dim_matter_header_current.reporting_exclusions = 0 
 AND dim_matter_header_current.master_client_code +'-' + master_matter_number <> '4908-19'
 AND ISNULL(dim_detail_core_details.[referral_reason], '') <> 'Recovery'
 --AND dim_matter_header_current.master_client_code +'-' + master_matter_number = '4908-9'
 AND  dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL 
 AND ISNULL(fact_bill.amount_outstanding, 0) = 0
GROUP BY COALESCE([dim_client_involvement].client_reference, [dim_client_involvement].insurerclient_reference),
         mib_grp_zurich_pizza_hut_date_of_final_bill,
         TRIM([3E billing description]),
         VAT.[VAT on Legal Costs]
 ,HrsBilled


   

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
	LEFT JOIN red_dw.dbo.fact_bill
ON fact_bill.dim_bill_key = fact_disbursements_detail.dim_bill_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 WHERE 1 = 1 

      AND TE_3E_Prod.dbo.CostCard.IsActive = 1
  
	  AND dim_matter_header_current.master_client_code = '4908'

	  AND dim_matter_header_current.master_client_code +'-' + master_matter_number <> '4908-19'

	  AND date_opened_case_management >= '2021-05-01'  --01/05/2021
      
	  AND dim_matter_header_current.reporting_exclusions = 0 

	  AND  dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL 

	  AND ISNULL(fact_bill.amount_outstanding, 0) = 0
	  AND ISNULL(dim_detail_core_details.[referral_reason], '') <> 'Recovery'




	  ) ALLdata

	  ORDER BY ALLdata.[Claim Reference], [ALLdata].[Order] DESC
	

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

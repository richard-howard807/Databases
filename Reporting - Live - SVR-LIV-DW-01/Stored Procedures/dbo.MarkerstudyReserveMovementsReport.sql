SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MarkerstudyReserveMovementsReport]
@DateClaimConcluded AS VARCHAR(20), @SettlementMonth AS VARCHAR(20)
  
 AS
  

 -- TESTING 
  --DECLARE @DateClaimConcluded AS VARCHAR(20) = 'Dec-2021'
  --, @SettlementMonth AS VARCHAR(20) = NULL
  
  DROP TABLE IF EXISTS #DamagesReserveChanges
 SELECT  x.master_fact_key, 
  [Damages Reserve Set at Initial Report (first damages reserve input into MI)]  = MAX(CASE WHEN x.RN = 1 THEN x.damages_reserve_rsa END) ,
  [Second damages reserve figure input into MI] = MAX(CASE WHEN x.RN = 2 THEN x.damages_reserve_rsa END),
  [Date second damages reserve figure was input into MI ] = MAX(CASE WHEN x.RN = 2 THEN x.transaction_calendar_date END), 	
  [Third damages reserve figure input into MI] = MAX(CASE WHEN x.RN = 3 THEN x.damages_reserve_rsa END), 
  [Date third damages reserve figure was input into MI]	= MAX(CASE WHEN x.RN = 3 THEN x.transaction_calendar_date END), 
  [Fourth damages reserve figure input into MI]	= MAX(CASE WHEN x.RN = 4 THEN x.damages_reserve_rsa END), 
  [Date fourth damages reserve figure was input into MI] = MAX(CASE WHEN x.RN = 4 THEN x.transaction_calendar_date END), 
  [Fifth damages reserve figure input into MI] = MAX(CASE WHEN x.RN = 5 THEN x.damages_reserve_rsa END),
  [Date fifth damages reserve figure was input into MI] = MAX(CASE WHEN x.RN = 5 THEN x.transaction_calendar_date END) ,
  [Damages Reserve Change Count] = MAX(x.RN)
 INTO #DamagesReserveChanges
 FROM 
 
 (
  
  
  SELECT a.master_fact_key,
         a.transaction_calendar_date,
         a.damages_reserve_rsa,
         ROW_NUMBER() OVER (PARTITION BY  a.master_fact_key  ORDER BY a.transaction_calendar_date) RN
		 
		 FROM 
  (
   SELECT 
   fact_dimension_main.master_fact_key,
   transaction_calendar_date,
   [fact_finance_monthly].[damages_reserve_rsa]
   ,ROW_NUMBER() OVER (PARTITION BY  fact_dimension_main.master_fact_key, [fact_finance_monthly].[damages_reserve_rsa]  ORDER BY transaction_calendar_date) RN
   FROM [red_dw].[dbo].[fact_finance_monthly]
   JOIN red_dw.dbo.fact_dimension_main
  ON fact_dimension_main.master_fact_key = fact_finance_monthly.master_fact_key
  JOIN red_dw.dbo.dim_matter_header_current
  ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
  WHERE fact_dimension_main.master_client_code IN ('C1001', 'W24438')

  /*Testing*/
 -- AND fact_dimension_main.master_client_code +'-'+master_matter_number = 'C1001-76621'

) a 
WHERE a.RN = 1 AND a.damages_reserve_rsa IS NOT NULL 

) x 
GROUP BY x.master_fact_key


SELECT 
  [DateClaimConcludedMonth] =  LEFT(DATENAME(MONTH, dim_detail_outcome.[date_claim_concluded]), 3) +'-'+CAST(YEAR(dim_detail_outcome.[date_claim_concluded]) AS VARCHAR(4)) ,
  [3E Reference] = fact_dimension_main.master_client_code +'-'+master_matter_number,
  [Co op Handler] = dim_detail_core_details.[clients_claims_handler_surname_forename],
  [CIS Reference] = dim_client_involvement.insurerclient_reference	,
  [Name of Case]	=matter_description,
  [Fee Earner Name]	= name,
  [Date of Accident]	 = dim_detail_core_details.incident_date,
  [Date File Opened]	 = CASE  
WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
COALESCE(  
dim_detail_core_details.date_instructions_received,  
dim_matter_header_current.date_opened_case_management  
)  
ELSE  
dim_matter_header_current.date_opened_case_management  
END ,
  [Work Type] = dim_matter_worktype.work_type_name, 	
  [Proceedings Issued] =	dim_detail_core_details.proceedings_issued,
  [Fixed Fee] =	dim_detail_core_details.fixed_fee ,
  [Damages Reserve Held Before Payment (current damages reserve)]	= CASE  
WHEN department_code = '0027' THEN  
red_dw.dbo.fact_detail_reserve_detail.general_damages_reserve_current  
ELSE  
red_dw.dbo.fact_finance_summary.damages_reserve  
END,
 [Outcome] = CASE  
WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
dim_detail_client.outcome_category  
ELSE  
dim_detail_outcome.outcome_of_case  
END,		
  [Date Damages Concluded] = CAST(dim_detail_outcome.[date_claim_concluded] AS DATE),
  [Total damages paid] = fact_finance_summary.[damages_paid],
  [No.Times Damages Reserve Changed] = ISNULL([Damages Reserve Change Count], 0), --dc.[No. Times Damages Changed],
  
  
  /* Damage Reserve Changes*/
  [Damages Reserve Set at Initial Report (first damages reserve input into MI)],
  [Date of Initial Report] = dim_detail_core_details.[date_initial_report_sent],
  [Second damages reserve figure input into MI],
  [Date second damages reserve figure was input into MI ], 	
  [Third damages reserve figure input into MI], 
  [Date third damages reserve figure was input into MI], 
  [Fourth damages reserve figure input into MI],
  [Date fourth damages reserve figure was input into MI], 
  [Fifth damages reserve figure input into MI],
  [Date fifth damages reserve figure was input into MI] ,


  /* Settlement Month */
  [Settlement Month] = LEFT(DATENAME(MONTH, dim_detail_outcome.[date_costs_settled]), 3) +'-'+CAST(YEAR(dim_detail_outcome.[date_costs_settled]) AS VARCHAR(4))

  FROM  red_dw.dbo.fact_dimension_main
  JOIN red_dw.dbo.dim_matter_header_current
  ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
  JOIN red_dw.dbo.dim_fed_hierarchy_history
  ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
  LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
  ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
  LEFT JOIN red_dw.dbo.dim_defendant_involvement
  ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
  LEFT JOIN red_dw.dbo.dim_detail_outcome
  ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
  JOIN red_dw.dbo.dim_detail_core_details
  on dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
  LEFT JOIN red_dw.dbo.dim_client_involvement
  ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
 LEFT JOIN red_dw.dbo.dim_matter_worktype  
	ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
  LEFT JOIN red_dw.dbo.fact_detail_reserve_detail
  ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_detail_core_details.dim_matter_header_curr_key
  LEFT JOIN red_dw.dbo.fact_finance_summary
  ON fact_finance_summary.master_fact_key = fact_detail_reserve_detail.master_fact_key
  LEFT JOIN red_dw.dbo.dim_detail_client
  ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
  LEFT JOIN red_dw.dbo.dim_client
  ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
  
  LEFT JOIN(  
SELECT client_code,  
curdamrescur.matter_number,  
SUM(changes) AS [No. Times Damages Changed]  
FROM  
(  
SELECT dim_client.client_code,  
matter_number,  
COUNT(*) - 1 changes,  
'fed' AS source_system  
FROM red_dw.dbo.dim_client  
INNER JOIN red_dw.dbo.dim_matter_header_current  
ON dim_matter_header_current.client_code = dim_client.client_code  
AND(dim_matter_header_current.date_closed_case_management IS NULL  
OR dim_matter_header_current.date_closed_case_management >= '2014-01-01')  
INNER JOIN red_dw.dbo.ds_sh_axxia_casdet  
ON ds_sh_axxia_casdet.case_id = dim_matter_header_current.case_id  
AND deleted_flag = 'N'  
AND case_detail_code = 'TRA076'  
AND case_value IS NOT NULL  
WHERE 1 = 1   
  
AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
AND department_code <> '0027'  
  
GROUP BY dim_client.client_code,  
matter_number  
UNION  
SELECT dim_client.client_code,  
matter_number,  
COUNT(*) - 1 changes,  
'ms' AS source_system  
FROM red_dw.dbo.dim_client  
INNER JOIN red_dw.dbo.dim_matter_header_current  
ON dim_matter_header_current.client_code = dim_client.client_code  
AND  
(  
dim_matter_header_current.date_closed_case_management IS NULL  
OR dim_matter_header_current.date_closed_case_management >= '2014-01-01'  
)  
INNER JOIN red_dw.dbo.ds_sh_ms_udmicurrentreserves_history  
ON fileid = ms_fileid  
AND curdamrescur IS NOT NULL  
WHERE 1 = 1  
  
AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
AND department_code <> '0027'  
  
GROUP BY dim_client.client_code,  
matter_number  
) curdamrescur  
GROUP BY curdamrescur.client_code,  
curdamrescur.matter_number  
) dc  
ON dc.client_code = red_dw.dbo.fact_dimension_main.client_code  
AND dc.matter_number = red_dw.dbo.fact_dimension_main.matter_number  
LEFT JOIN #DamagesReserveChanges
ON #DamagesReserveChanges.master_fact_key = fact_dimension_main.master_fact_key


 
  WHERE fact_dimension_main.master_client_code IN ('C1001', 'W24438')
  AND reporting_exclusions = 0  
  AND LOWER(ISNULL(outcome_of_case, '')) NOT IN ( 'exclude from reports', 'returned to client' )  
  AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
  AND CASE  
WHEN department_code = '0027' /*OR PracticeArea='Converge'*/ THEN  
'Converge'  
WHEN dim_detail_client.[coop_master_reporting] = 'Yes'  
OR dim_fed_hierarchy_history.hierarchylevel4hist = 'Fraud and Credit Hire Liverpool' THEN  
'MLT'  
WHEN dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - LTA' THEN  
'Commercial'  
ELSE  
'Insurance'  
END NOT IN ('Converge','MLT' )  
AND dim_client.client_code IN  ('00046018', 'C15332', 'C1001', 'W24438')  
AND department_code <> '0027'  
AND  
(  
dim_matter_header_current.date_closed_case_management IS NULL  
OR dim_matter_header_current.date_closed_case_management >= '2014-01-01'  
)  
--AND hierarchylevel4hist IN (@Team)  
  
AND ms_fileid NOT IN   
 (SELECT DISTINCT [fileID] FROM [MS_Prod].[dbo].[udMIClientMSG]  
  LEFT JOIN [MS_Prod].[dbo].dbCodeLookup ON cdType = 'MSGINSTYPE' AND cdCode = [cboInsTypeMSG]   
  WHERE dbCodeLookup.cdDesc  =  'MSG Savings project'   
  AND [fileID] IS NOT NULL  
  )

  AND CASE WHEN @DateClaimConcluded ='All' 
  THEN ISNULL(LEFT(DATENAME(MONTH, dim_detail_outcome.[date_claim_concluded]), 3) +'-'+CAST(YEAR(dim_detail_outcome.[date_claim_concluded]) AS VARCHAR(4)), '')  
  ELSE @DateClaimConcluded END
  = ISNULL(LEFT(DATENAME(MONTH, dim_detail_outcome.[date_claim_concluded]), 3) +'-'+CAST(YEAR(dim_detail_outcome.[date_claim_concluded]) AS VARCHAR(4)), '') 
  
  AND 
  CASE WHEN @SettlementMonth ='All'  
  THEN  ISNULL(LEFT(DATENAME(MONTH, dim_detail_outcome.[date_costs_settled]), 3) +'-'+CAST(YEAR(dim_detail_outcome.[date_costs_settled]) AS VARCHAR(4)), '')
  ELSE @SettlementMonth END = ISNULL(LEFT(DATENAME(MONTH, dim_detail_outcome.[date_costs_settled]), 3) +'-'+CAST(YEAR(dim_detail_outcome.[date_costs_settled]) AS VARCHAR(4)),'')
  
  
  /*Testing*/
 -- AND fact_dimension_main.master_client_code +'-'+master_matter_number = 'C1001-76621'
  --ORDER BY [fact_finance_monthly].[dim_transaction_date_key]
  ORDER BY [Date File Opened]
GO

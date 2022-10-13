SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--EXEC [dbo].[AXAXLDataSubmission]
CREATE PROCEDURE [dbo].[AXAXLDataSubmission]

AS 

BEGIN 

DROP TABLE IF EXISTS #AXAXLDataSubmission

--select * from #AXAXLDataSubmission

SELECT  DISTINCT

ROW_NUMBER() OVER (PARTITION BY dim_matter_header_current.ms_fileid ORDER BY dim_matter_header_current.ms_fileid  ) AS RN
,dim_matter_header_current.ms_fileid
, [AXA XL Claim Number] = COALESCE(client_reference, insurerclient_reference, AXAXLClaimNumber COLLATE DATABASE_DEFAULT, 'TBA')
, [Law Firm Matter Number] = RTRIM(dim_matter_header_current.master_client_code)+ '-' + RTRIM(dim_matter_header_current.master_matter_number) 
, [Line of Business] = hierarchylevel3hist 
, [New Line of Business] = cboLineofBus.cdDesc--LineofBus.[CaseText] -- Needs Correcting 20210909 - MT

, [Product Type] = work_type_name   
, [Product Type New] =  ProdType.[CaseText] -- Needs Correcting 20210909 - MT

 
, [Insured Name]  = CASE WHEN ISNULL(dim_detail_claim.[dst_insured_client_name], '') = '' THEN dim_client_involvement.insuredclient_name ELSE dim_detail_claim.[dst_insured_client_name] END  
, [AXA XL Percentage line share of loss / expenses / recovery] = CASE WHEN udMICoreAXA.pctLineShare > 1 THEN udMICoreAXA.pctLineShare/100 ELSE COALESCE(udMICoreAXA.pctLineShare, 1) END  -- udMICoreAXA
, [AXA XL Claims Handler] = dim_detail_core_details.[clients_claims_handler_surname_forename]                                       
, [Third Party Administrator]  = Brokername 
, [Coverage / defence?]  = cboCovDef.cdDesc  -- API.[cboCovDef_CaseText]  -- udMICoreAXA
, [Law firm handling office (city)] = branch_name 
, [Date Instructed] = COALESCE(dim_detail_core_details.[date_instructions_received], dim_matter_header_current.date_opened_case_management) 
, [Opposing Side's Solicitor Firm Name] = COALESCE(dim_detail_claim.[dst_claimant_solicitor_firm], red_dw.dbo.dim_claimant_thirdparty_involvement.claimantsols_name) 
, [Reason For instruction] = CASE WHEN dim_detail_core_details.[proceedings_issued] = 'Yes' THEN 'Litigation' ELSE cboReaIns.cdDesc  END    -- udMICoreAXA
, [Fee Scale] = CASE WHEN dim_detail_finance.[output_wip_fee_arrangement] = 'Fixed Fee/Fee Quote/Capped Fee' THEN 'fixed_fee' ELSE dim_detail_finance.[output_wip_fee_arrangement] END 
, [Damages Claimed] = damages_reserve 
, [First acknowledgement Date]= COALESCE(dim_detail_claim.[axa_first_acknowledgement_date] , udMICoreAXA.[dteFirstAck])  
, [Report Date] = ISNULL(date_subsequent_sla_report_sent,date_initial_report_sent) 
, [Date Proceedings Issued] = CASE WHEN dim_detail_core_details.[proceedings_issued] = 'Yes' THEN COALESCE(dim_detail_court.[date_proceedings_issued], KD_Acknowledgement.[Acknowledgement of Service]) END
, [AXA XL as defendant]  =  CASE WHEN dim_detail_core_details.[proceedings_issued] = 'Yes' THEN  COALESCE(cboIsAXADef.cdDesc, 'Yes')  END -- udMICoreAXA NEW*** 
, [Reason for proceedings] = 
CASE WHEN dim_detail_core_details.[proceedings_issued] = 'Yes' THEN
	(CASE WHEN cboReForProc.cdDesc = 'Quantum dispute' THEN 'Quantum disputes' 
		 WHEN cboReForProc.cdDesc = 'Insured delay - should be settled' THEN 'Insured delay should be settled'
		 ELSE cboReForProc.cdDesc END) END  -- udMICoreAXA
, [Proceeding Track] = CASE WHEN dim_detail_core_details.[proceedings_issued] = 'Yes' THEN  dim_detail_core_details.[track] ELSE NULL END 
, [Trial date] = ISNULL(dim_detail_court.[date_of_trial],Trials.TrialDate) 
, fact_finance_summary.damages_reserve AS [Damages Reserve]
, COALESCE(fact_finance_summary.[tp_total_costs_claimed], tp_costs_reserve) AS [Opposing side's costs reserve]
, defence_costs_reserve AS [Panel budget/reserve]
,  COALESCE(cboReaForPanel.cdDesc, 'No change') AS  [Reason for panel budget change if occurred] -- udMICoreAXA
, defence_costs_billed AS [Panel Fees Paid]
, Disbursements.[Disbs - Counsel fees] AS  [Counsel Paid]
, ISNULL(Disbursements.DisbAmount, 0) - ISNULL(Disbursements.[Disbs - Counsel fees], 0) [Other Disbursements Paid]
, fact_finance_summary.[tp_total_costs_claimed]  AS [Opposing side's Costs Claimed]

, NULL [Timekeepers - Details of anyone who worked on the case during the time period.]
, BilledTime.Name [Name]
, BilledTime.[First name] AS Timekeepers_Firstname
, BilledTime.[Last name] AS Timekeepers_Lastname
, BilledTime.[Unique timekeeper ID per timekeeper] [Unique timekeeper ID per timekeeper]
, BilledTime.[Level (solicitor, partner)] AS  [Level (solicitor, partner)]
, BilledTime.PQE [PQE]
, BilledTime.[Hours spent on case] [Hours spent on case]
, NULL [Upon closing a case add the following information]
, [Date closed] = 
CASE WHEN fact_finance_summary.unpaid_bill_balance = 0.00 AND dim_detail_core_details.[present_position] IN ('Final bill sent - unpaid','To be closed/minor balances to be clear') THEN Receipt.receipt_date END
, [Date of Final Panel Invoice] = 
CASE WHEN dim_detail_core_details.[present_position] IN ('Final bill sent - unpaid','To be closed/minor balances to be clear') THEN last_bill_date END
, date_claim_concluded [Date Damages settled]
, fact_finance_summary.[damages_paid] AS [Final Damages Amount]
, [Claimants Costs Handled by Panel?] = CASE WHEN  TRIM(cboOutOfIns.cdDesc) IN 
('Coverage (declined claim)','Coverage advice given','Discontinued','Not pursued','Successfully defended (no indemnity payment)','Trial (NI won - successful lodgement)','Trial (won - no indemnity payment)','Trial (won - recovery)') THEN 'No'
      WHEN TRIM(cboOutOfIns.cdDesc) IN ('Settled','Settled - Pursuing recovery','Trial (Lost)','Trial (won - successful part 36 offer)') THEN 'Yes'
	   END
, date_costs_settled AS  [Date Claimants costs settled]
, [Final Claimants Costs Amount] =  fact_finance_summary.[claimants_costs_paid]
, cboMedOutcome.cdDesc AS  [Mediated outcome - Select from list]   -- udMICoreAXA
, [Outcome of Instruction - Select from list]  =
CASE WHEN cboOutOfIns.cdDesc = 'Discontinued' THEN   'Discontinued or not pursued' 
	 WHEN cboOutOfIns.cdDesc = 'Not pursued'  THEN   'Discontinued or not pursued' 
	 WHEN cboOutOfIns.cdDesc = 'Trial (Lost)' THEN 'Trial lost'
	 WHEN cboOutOfIns.cdDesc = 'Trial (won - recovery)' THEN 'Trial won recovery'
	 WHEN cboOutOfIns.cdDesc = 'Trial (won - no indemnity payment)' THEN 'Trial won no indemnity payment'
	 WHEN cboOutOfIns.cdDesc = 'Trial (NI won - successful lodgement)' THEN 'Trail north ire won successful lodgement'
	 WHEN cboOutOfIns.cdDesc = 'Successfully defended (no indemnity payment)' THEN 'Successfully defended no indemnity payment'
	 WHEN cboOutOfIns.cdDesc = 'Coverage (declined claim)' THEN 'Coverage declined claim'
	 ELSE cboOutOfIns.cdDesc END   -- udMICoreAXA


, [Was litigation avoidable - Select from list] =
CASE WHEN cboWasLitAv.cdDesc = 'Yes – other' THEN 'Yes other' -- udMICoreAXA
     WHEN cboWasLitAv.cdDesc = 'Yes - other' THEN 'Yes other'
	 WHEN cboWasLitAv.cdDesc = 'Yes - General delay' THEN 'Yes general delay'
	 WHEN cboWasLitAv.cdDesc = 'Yes - Insured delay' THEN 'Yes insured delay'
	 WHEN cboWasLitAv.cdDesc = 'Yes - Insurer delay' THEN 'Yes insurer delay'
	 WHEN cboWasLitAv.cdDesc = 'Yes – Differing opinions on merits' THEN 'Yes differing opinions on merits'
	 ELSE cboWasLitAv.cdDesc
	 END

/*•	Yes – other
•	Yes - General delay = Yes general delay
•	Yes - Insured delay = Yes insured delay
•	Yes - Insurer delay = Yes insurer delay
And they seem to have added a new option which will need to be added to MS.  The mapping for that option will be:
•	Yes – Differing opinions on merits = Yes differing opinions on merits
*/
,hierarchylevel3hist
,hierarchylevel4hist AS [Team]
,dim_fed_hierarchy_history.name AS [Weightmans Handler name]
,dim_detail_core_details.referral_reason AS [Referral reason]
,dim_detail_core_details.[proceedings_issued] 
,[Counsel Paid / Other disbursements] = Disbursements.[Disbs - Counsel fees]
,[Disbursements] = Disbursements.DisbAmount

,dim_detail_core_details.[present_position] AS [status_present_postition]
,dim_matter_header_current.date_closed_case_management 
,matter_description

,dim_client_involvement.insuredbroker_name
,dim_client_involvement.broker_name
,fact_finance_summary.disbursements_billed

, [Quantified Damages] = udMICoreAXA.curQuanDam -- udMICoreAXA NEW***

,[WIP] =wip
,[Unbilled disbursements] = fact_finance_summary.disbursement_balance
,[Unpaid Bill Balance] = fact_finance_summary.unpaid_bill_balance 
,[Last Bill Date]= CASE WHEN final_bill_flag  = 1 THEN last_bill_date END
,[Last Time Transaction Date] = last_time_transaction_date
 ,[Final Bill Flag] =  final_bill_flag 
 ,Receipt.receipt_date

/*Panel Fees

=Fields!fact_finance_summary_defence_costs_billed_.Value 
+Fields!fact_finance_summary_disbursements_billed_.Value 
+ Fields!Damages.Value 
+Fields!Costs.Value
+(IIF(ISNOTHING(LOOKUP(TRIM(Fields!dim_client_client_code_.Value)&TRIM(Fields!dim_matter_header_current_matter_number_.Value)
,TRIM(Fields!client_code.Value)&TRIM(Fields!matter_number.Value)
,Fields!Total_VAT_Billed_to_Markel_In_Period.Value, "MarkelTax")),0,LOOKUP(TRIM(Fields!dim_client_client_code_.Value)&TRIM(Fields!dim_matter_header_current_matter_number_.Value)
,TRIM(Fields!client_code.Value)&TRIM(Fields!matter_number.Value)
,Fields!Total_VAT_Billed_to_Markel_In_Period.Value, "MarkelTax")))


Fields!Damages.Value  =IIF(ISNOTHING(Fields!fact_finance_summary_damages_paid_.Value),Fields!fact_finance_summary_damages_interims_.Value,Fields!fact_finance_summary_damages_paid_.Value)
Fields!Costs.Value=IIF(ISNOTHING(Fields!fact_finance_summary_claimants_costs_paid_.Value),Fields!fact_detail_paid_detail_interim_costs_payments_.Value,Fields!fact_finance_summary_claimants_costs_paid_.Value)
*/
,[PanelFeesTest] = ISNULL(fact_finance_summary.disbursements_billed, 0) + 
ISNULL(defence_costs_billed, 0) +
COALESCE(ISNULL(fact_finance_summary.damages_paid, 0), ISNULL(fact_finance_summary.damages_interims, 0)) +
COALESCE(ISNULL(fact_finance_summary.claimants_costs_paid, 0), ISNULL(fact_detail_paid_detail.interim_costs_payments, 0)) +
ISNULL(PanelFees.[Total VAT Billed to AXA In Period], 0)
INTO #AXAXLDataSubmission
FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_worktype WITH(NOLOCK)
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement WITH(NOLOCK)
 ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK)
 ON  fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON  dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement WITH(NOLOCK)
 ON  dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance WITH(NOLOCK)
 ON  dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court WITH(NOLOCK)
 ON  dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current WITH(NOLOCK)
 ON  fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK)
 ON  dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail WITH(NOLOCK)
 ON  fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
 LEFT JOIN red_dw.dbo.dim_detail_claim 
 ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
 LEFT JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
 
 
 
LEFT OUTER JOIN 
(
SELECT ms_fileid,MAX(tskDue) AS TrialDate FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN MS_Prod.dbo.dbTasks WITH(NOLOCK)
 ON ms_fileid=fileID
WHERE client_group_name='AXA XL'
--AND dim_fed_hierarchy_history.hierarchylevel3hist='Casualty'
AND (date_closed_case_management IS NULL OR CONVERT(DATE,date_closed_case_management,103)='2021-03-29')
AND tskActive=1
AND tskDesc LIKE '%Trial date - today%'
GROUP BY ms_fileid
) AS Trials
 ON Trials.ms_fileid = dim_matter_header_current.ms_fileid


LEFT OUTER JOIN 
(
SELECT dim_matter_header_current.dim_matter_header_curr_key
, dim_employee.surname +', ' + dim_employee.forename AS [Name]
, dim_employee.forename AS [First name]
, dim_employee.surname AS [Last name]
, TimeRecordedBy.fed_code [Unique timekeeper ID per timekeeper]
, TimeRecordedBy.jobtitle [Level (solicitor, partner)]
, DATEDIFF(YEAR,admissiondateud,CONVERT(DATE,bill_date,103)) [PQE]
, SUM(CAST(minutes_recorded AS DECIMAL(10,2)))/60 [Hours spent on case]
, [Max Time Recorded Date] = MAX(bill_date)
FROM red_dw.dbo.fact_bill_billed_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
 ON dim_bill_date.dim_bill_date_key = fact_bill_billed_time_activity.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS TimeRecordedBy
 ON TimeRecordedBy.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_employee WITH(NOLOCK)
 ON dim_employee.dim_employee_key = TimeRecordedBy.dim_employee_key

WHERE client_group_name='AXA XL'
--AND dim_fed_hierarchy_history.hierarchylevel3hist='Casualty'
AND (date_closed_case_management IS NULL OR CONVERT(DATE,date_closed_case_management,103)='2021-03-29')
GROUP BY dim_matter_header_current.dim_matter_header_curr_key
, dim_employee.surname +', ' + dim_employee.forename 
, TimeRecordedBy.fed_code 
, TimeRecordedBy.jobtitle
, dim_employee.surname, dim_employee.forename 
, DATEDIFF(YEAR,admissiondateud,CONVERT(DATE,bill_date,103))
) AS BilledTime
 ON BilledTime.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key


 /*Disbursements*/
LEFT JOIN(
 SELECT dim_matter_header_current.dim_matter_header_curr_key
,SUM(bill_total_excl_vat) AS DisbAmount
,SUM(CASE WHEN LOWER(cost_type_description) LIKE ('%counsel%') THEN bill_total_excl_vat ELSE 0 END) AS  [Disbs - Counsel fees]
FROM red_dw.dbo.fact_bill_detail WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current 
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_detail.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill WITH(NOLOCK)
ON dim_bill.dim_bill_key = fact_bill_detail.dim_bill_key
INNER JOIN red_dw.dbo.fact_bill WITH(NOLOCK)
ON fact_bill.dim_bill_key = fact_bill_detail.dim_bill_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
ON dim_bill_date.dim_bill_date_key = fact_bill_detail.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_cost_type ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
WHERE client_group_name='AXA XL'
AND (date_closed_case_management IS NULL OR CONVERT(DATE,date_closed_case_management,103)='2021-03-29')
AND  fact_bill_detail.charge_type='disbursements'
AND bill_reversed=0
GROUP BY dim_matter_header_current.dim_matter_header_curr_key


) Disbursements ON Disbursements.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

LEFT JOIN 

(

/*Panel Fees  */

SELECT 
  DISTINCT
  dim_matter_header_curr_key
,SUM([AllData].[AXATax]) OVER (PARTITION BY  dim_matter_header_curr_key) AS [Total VAT Billed to AXA In Period]

FROM
(SELECT 
coalesce(left(Matter.loadnumber,(charindex('-',Matter.loadnumber)-1)),
Client.altnumber,CASE WHEN ISNUMERIC(Client.number) = 1 
THEN RIGHT(CAST(CAST(Client.number AS int)  + 100000000 AS varchar(9)),8) ELSE Client.number END)  AS client_code
,isnull(right(Matter.loadnumber, len(Matter.loadnumber) - charindex('-',Matter.loadnumber))
,right(Matter.altnumber, len(Matter.altnumber) - charindex('-',Matter.altnumber)))  AS matter_number
,CASE WHEN LOWER(Payor.DisplayName) LIKE '%axa %' THEN  ARDetail.ARTAx ELSE 0 END AS [AXATax]

FROM TE_3E_Prod.dbo.ARDetail WITH (NOLOCK)
INNER JOIN TE_3E_Prod.dbo.InvMaster WITH (NOLOCK)
 ON ARDetail.InvMaster=InvMaster.InvIndex
INNER JOIN TE_3E_Prod.dbo.Matter WITH (NOLOCK) 
 ON ARDetail.Matter=Matter.MattIndex
INNER JOIN TE_3E_Prod.dbo.Client WITH (NOLOCK)
 ON Matter.Client=Client.ClientIndex
LEFT OUTER JOIN TE_3E_Prod.dbo.Payor WITH (NOLOCK)  
 ON ARDetail.Payor=Payor.PayorIndex
WHERE ARList IN ('Bill','BillRev')
AND InvNumber <>'PURGE'
) AS AllData
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON AllData.client_code=dim_matter_header_current.client_code collate DATABASE_DEFAULT
 AND AllData.matter_number=dim_matter_header_current.matter_number  collate database_default 
 AND client_group_name='AXA XL'

WHERE client_group_name='AXA XL'
AND [AXATax] > 0


) PanelFees on PanelFees.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

/*Added as a temp fix before the datawarehouse fields are added in */
LEFT JOIN ms_prod.dbo.udMICoreAXA
ON fileID = dim_matter_header_current.ms_fileid

/*Coverage Defence   - cboCovDef */
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboCovDef' AND txtMSTable = 'udMICoreAXA') cboCovDef ON cboCovDef.cdCode = udMICoreAXA.cboCovDef

/*Reason for Instruction    - cboReaIns */ 
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboReaIns' AND txtMSTable = 'udMICoreAXA') cboReaIns ON cboReaIns.cdCode = udMICoreAXA.cboReaIns

/*Is AXA XL the Defendant  - cboIsAXADe */

LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboIsAXADef' AND txtMSTable = 'udMICoreAXA') cboIsAXADef ON cboIsAXADef.cdCode = udMICoreAXA.cboIsAXADef

/*Reason for Proceedings   - cboReForProc */ 
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboReForProc' AND txtMSTable = 'udMICoreAXA') cboReForProc ON cboReForProc.cdCode = udMICoreAXA.cboReForProc

/*Reason for panel budget change    - cboReaForPanel */ 
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboReaForPanel' AND txtMSTable = 'udMICoreAXA') cboReaForPanel ON cboReaForPanel.cdCode = udMICoreAXA.cboReaForPanel

/*Mediated Outcome    - cboMedOutcome */ 
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboMedOutcome' AND txtMSTable = 'udMICoreAXA') cboMedOutcome ON cboMedOutcome.cdCode = udMICoreAXA.cboMedOutcome

/*Outcome of Instruction     - cboOutOfIns */ 
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboOutOfIns' AND txtMSTable = 'udMICoreAXA') cboOutOfIns ON cboOutOfIns.cdCode = udMICoreAXA.cboOutOfIns

/*Was Litigation avoidable     - cboWasLitAv */ 
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboWasLitAv' AND txtMSTable = 'udMICoreAXA') cboWasLitAv ON cboWasLitAv.cdCode = udMICoreAXA.cboWasLitAv 

/*Line of Business    - cboLineofBus */ 
LEFT JOIN (SELECT DISTINCT cdCode, cdDesc FROM  MS_PROD.dbo.udMapDetail
JOIN ms_prod.dbo.dbCodeLookup ON txtLookupCode = cdType
WHERE txtMSCode = 'cboLineofBus' AND txtMSTable = 'udMICoreAXA') cboLineofBus ON cboLineofBus.cdCode = udMICoreAXA.cboLineofBus 



LEFT JOIN (SELECT fileID,  dateadd(DD, -14, cast(MAX(tskDue)as date)) AS [Acknowledgement of Service]
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE' AND tskDesc ='Acknowledgement of Service due - today'
	GROUP BY fileID) AS [KD_Acknowledgement] ON [KD_Acknowledgement].fileID=dim_matter_header_current.ms_fileid


/* Temp Fix due to API issues. */

--LEFT JOIN 
--(
--SELECT ClNo 
  
-- ,MAX(CASE WHEN TRIM([MSCode])  = 'cboReForProc' THEN  TRIM([CaseText]) END) [cboReForProc_CaseText]
-- ,MAX(CASE WHEN TRIM([MSCode])  = 'cboReaIns' THEN  TRIM([CaseText]) END) [cboReaIns_CaseText]
-- ,MAX(CASE WHEN TRIM([MSCode])  = 'cboCovDef' THEN  TRIM([CaseText]) END) [cboCovDef_CaseText]
-- ,MAX(CASE WHEN TRIM([MSCode])  = 'cboIsAXADe' THEN  TRIM([CaseText]) END) [cboIsAXADef_CaseText]
-- ,MAX(CASE WHEN TRIM([MSCode])  = 'Not created  - check' THEN  [CaseDate] END) [FirstAcknowledgementDate]
--  FROM [SQLAdmin].[dbo].[_20210509_API] 
--  WHERE TRIM([MSCode]) IN ('cboReForProc', 'cboReaIns', 'cboCovDef', 'cboIsAXADe', 'Not created  - check')
--  GROUP BY ClNo
--  ) API
--  ON API.ClNo  = dim_matter_header_current.master_client_code COLLATE DATABASE_DEFAULT + '-' + master_matter_number COLLATE DATABASE_DEFAULT

 
 /* MS fix for [AXA XL Claim Number] */
 LEFT JOIN 
 (
 SELECT fileID, assocRef  AS AXAXLClaimNumber FROM ms_prod.[config].[dbAssociates]
WHERE 1 = 1 
AND assocType = 'CLIENT'
) AXAXLClaimNumber ON CAST(AXAXLClaimNumber.fileID AS NVARCHAR(20)) = CAST(dim_matter_header_current.ms_fileid AS NVARCHAR(20)) COLLATE DATABASE_DEFAULT

/*Broker */
LEFT JOIN 
 (
 SELECT distinct fileID,MAX(contName) Brokername   FROM ms_prod.[config].[dbAssociates]
 JOIN ms_prod.config.dbContact ON dbContact.contID = dbAssociates.contID
WHERE 1 = 1 
AND assocType = 'BROKER'
GROUP BY fileID
) Brokername ON CAST(Brokername.fileID AS NVARCHAR(20)) = CAST(dim_matter_header_current.ms_fileid AS NVARCHAR(20)) COLLATE DATABASE_DEFAULT

/* MS Fix for Product Type and Business Line*/

LEFT JOIN SQLAdmin.dbo._20210909_AXA_ProductsandBusinessType LineofBus
ON LineofBus.[ClNo] = dim_matter_header_current.master_client_code COLLATE DATABASE_DEFAULT
AND LineofBus.[FileNo] = master_matter_number  COLLATE DATABASE_DEFAULT AND LineofBus.[MSCode]  = 'cboLineofBus'

LEFT JOIN  SQLAdmin.dbo._20210909_AXA_ProductsandBusinessType ProdType
ON ProdType.[ClNo] = dim_matter_header_current.master_client_code COLLATE DATABASE_DEFAULT
AND ProdType.[FileNo] = master_matter_number COLLATE DATABASE_DEFAULT AND ProdType.[MSCode]  = 'cboPrrodType'


/* Receipt Date */

LEFT JOIN (SELECT  

dim_matter_header_current.dim_matter_header_curr_key ,
 MAX(fact_bill_receipts.gldate) [receipt_date]
 FROM red_dw..fact_bill_receipts
 JOIN red_dw.dbo.fact_dimension_main
 ON fact_dimension_main.dim_matter_header_curr_key = fact_bill_receipts.dim_matter_header_curr_key
 JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
 GROUP BY 
 dim_matter_header_current.dim_matter_header_curr_key ) Receipt ON Receipt.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key




WHERE 1 =1 

AND client_group_name='AXA XL'
AND (dim_matter_header_current.date_closed_case_management IS NULL OR CONVERT(DATE,dim_matter_header_current.date_closed_case_management,103)>='2021-03-29')
AND (date_costs_settled  IS NULL OR CONVERT(DATE,date_costs_settled,103)>='2021-03-29')
AND (date_claim_concluded IS NULL OR CONVERT(DATE,date_claim_concluded ,103)>='2021-03-29')

--just a quick one on this for the time being - can you restrict it to show files that are "live" - 
--so this will be where date claim concluded or date costs settled are null
AND TRIM(dim_matter_header_current.matter_number) <> 'ML'
AND reporting_exclusions = 0
AND dim_matter_header_current.master_client_code + '-' + master_matter_number NOT IN 
( 'A1001-6044','A1001-10784','A1001-10789','A1001-10798','A1001-10822','A1001-10877','A1001-10913','A1001-10992','A1001-11026','A1001-11140','A1001-11180','A1001-11237','A1001-11254','A1001-11329','A1001-11363','A1001-11375','A1001-11470','A1001-11547','A1001-11562','A1001-11566','A1001-11567','A1001-11586','A1001-11600','A1001-11616','A1001-11618','A1001-11624','A1001-11699','A1001-11749','A1001-11759','A1001-11832','A1001-11894','A1001-4822','A1001-9272', '207818-2'
)
/* Excludes cases opened in current month */
--AND dim_matter_header_current.date_opened_case_management <= DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)



/* Main Lookup */

DROP TABLE IF EXISTS #MainAPI

SELECT DISTINCT  
      [AXA XL Claim Number],
      [Law Firm Matter Number],
      [Line of Business],
      [Product Type],
      [Insured Name],
      [AXA XL Percentage line share of loss expenses recovery],
      [AXA XL Claims Handler],
      [Third Party Administrator],
      [Coverage defence ],
      [Law firm handling office city ],
      [Date Instructed],
      [Opposing Side's Solicitor Firm Name],
      [Reason For instruction],
      [Fee Scale],
      [Damages Claimed],
      [First acknowledgement Date],
      [Report Date],
      [Date Proceedings Issued],
      [AXA XL as defendant],
      [Reason for proceedings],
      [Proceeding Track],
      [Trial date],
      [Damages Reserve],
      [Opposing sides costs reserve],
      [Panel budget reserve],
      [Reason for panel budget change if occurred],
      [Panel Fees Paid],
      [Counsel Paid],
      [Other Disbursements Paid],
      [Opposing sides Costs Claimed],
      [Date closed],
      [Date of Final Panel Invoice],
      [Date Damages settled],
      [Final Damages Amount],
      [Claimants Costs Handled by Panel ],
      [Date Claimants costs settled],
      [Final Claimants Costs Amount],
      [Mediated outcome Select from list],
      [Outcome of Instruction Select from list],
      [Was litigation avoidable Select from list],
	  dss_load_date,
	  dss_current_flag

      INTO #MainAPI
      FROM Reporting.[dbo].[AXAXLDataSubmissionAPIStage]

	  WHERE dss_current_flag = 'Y'
	  AND RowOrder = 1 


--UPDATE #AXAXLDataSubmission  
--SET #AXAXLDataSubmission.[Reason for panel budget change if occurred] = #AXAXLDataSubmission.[Law Firm Matter Number] + ' has increased from £' + CAST(ISNULL(#MainAPI.[Panel budget reserve], 0.00) AS NVARCHAR(20)) + ' to £' + CAST(#AXAXLDataSubmission.[Panel budget/reserve] AS NVARCHAR(20)) COLLATE DATABASE_DEFAULT

--FROM #AXAXLDataSubmission 
--JOIN #MainAPI ON  #MainAPI.[Law Firm Matter Number] COLLATE DATABASE_DEFAULT = #AXAXLDataSubmission.[Law Firm Matter Number]
--WHERE ISNULL(REPLACE(#MainAPI.[Panel budget reserve], ',', ''), '') <> ISNULL(CAST(#AXAXLDataSubmission.[Panel budget/reserve] AS NVARCHAR(20)), '')
--AND CAST(#AXAXLDataSubmission.[Panel budget/reserve] AS NVARCHAR(20)) <> ISNULL(#MainAPI.[Panel budget reserve], '0.00')

SELECT DISTINCT * FROM #AXAXLDataSubmission
WHERE RN = 1
ORDER BY ms_fileid



END




GO

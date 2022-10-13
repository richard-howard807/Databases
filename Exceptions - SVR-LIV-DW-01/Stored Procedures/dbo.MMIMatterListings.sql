SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Kevin Hansen
-- Create date: 02.04.19
-- Description:	New report for Request 15232
-- =============================================
CREATE PROCEDURE [dbo].[MMIMatterListings]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT 
name AS [Fee Earner – Case Manager]
,matter_partner_full_name AS [Supervising Partner – Matter Partner]
,'MMI' AS [Nature of instruction – default to “MMI”]
,dim_client_involvement.[insurerclient_reference] AS [MMI Ref – Reference from Insurer Client Associate]
,insurerclient_reference AS [Zurich Ref – leave blank]
,RTRIM(dim_matter_header_current.client_code) +'.' + CAST(CAST(red_dw.dbo.dim_matter_header_current.matter_number AS INT) AS NVARCHAR(MAX)) AS [Panel Firm Ref – Weightmans Client/Matter]
,dim_detail_core_details.[delegated] AS [Delegated Authority - TRA115 cboDelegated]
,insuredclient_name AS [MMI Insured – Name from Insured Client Associate]
,defendant_name AS [Defendant – Name from Defendant Associate]
,CASE WHEN ms_only=1 THEN  Claimant.FirstName ELSE dim_claimant_thirdparty_involvement.claimant_name  END COLLATE DATABASE_DEFAULT AS [Claimant First Name]
,CASE WHEN ms_only=1 THEN  Claimant.Surname ELSE dim_claimant_thirdparty_involvement.claimant_name  END COLLATE DATABASE_DEFAULT AS[Claimant Surname]
,ms_only
,claimantsols_name AS [Claimant Solicitor – Name from Claimant Solicitor Associate]
,CASE WHEN work_type_name LIKE 'Disease -%' THEN  REPLACE(work_type_name,'Disease - ','')
WHEN work_type_code IN ('1571','1254','1255','1256','1257','1258','1259','1260'
,'1261','1262','1263','1274','1275','1276','1277') THEN 'Abuse'
ELSE 'Other' END  AS [Claim Type]-- for Work Type Group “Disease” show the Work Type, but remove the “Disease – ” prefix, for work types 1254-1263, 1274-1277 or 1571 show “Abuse” and for all other work types, show “Other”]
,dim_detail_core_details.[occupation] AS [Job Role]        
,dim_detail_client.[mmi_abuse_risk_type] AS [Risk Type]
,dim_detail_core_details.[incident_location] AS [Risk location]
,dim_detail_client.[mmi_risk_descriptor_abuser] AS [Risk descriptor]
,dim_detail_client.[mmi_abuse_category_most_serious] AS [Abuse Codes]
,dim_detail_client.[mmi_abuse_allegation_type] AS [Allegation type]
,dim_detail_critical_mi.[period_of_exposure] AS [Exposure / Abuse period]
,fact_detail_claim.[disease_insurer_clients_contrib_damages] AS [MMI’s % - Damages]
,fact_detail_paid_detail.[indemnity_savings] AS [MMI’s % - CRU]
,fact_detail_claim.[disease_insurer_clients_contrib_costs] AS [MMI’s % - Costs]
,fact_detail_client.[disease_insurer_clients_per_contribution_to_defence_costs] AS [MMI’s % - Defence costs - NMI997]
,CASE WHEN dim_detail_core_details.[is_this_the_lead_file]='No' THEN 'No' ELSE 'Yes' END  AS [MMI Lead]
,dim_matter_header_current.date_opened_case_management AS [Open Date]
,referral_reason AS [Referral reason (internal only)]
,dim_detail_core_details.[date_letter_of_claim]  AS [Date of LoC]
,dim_detail_core_details.[has_the_claimant_got_a_cfa] AS [Has the Claimant got a CFA? (internal only)]
,dim_detail_core_details.[date_of_cfa] AS [Date of CFA/DBA]
,dim_detail_core_details.[proceedings_issued] AS [Proceedings Issued (Internal only)]
,dim_detail_court.[date_proceedings_issued] AS [Issue Date]
,dim_detail_health.[date_of_service_of_proceedings] AS [Service Date]
,dim_detail_core_details.[zurich_grp_rmg_was_litigation_avoidable] AS [Avoidable]
,dim_detail_litigation.[mmi_litigation_cause] AS [Litigation cause - LIT1217]
,NULL AS [Total Incurred]
,fact_finance_summary.[damages_reserve] AS [Reserve Damages (Gross) (Internal only)]
,CASE WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL THEN 0 ELSE fact_finance_summary.[damages_reserve] - (fact_detail_paid_detail.[interim_damages_paid_by_client_preinstruction]+ fact_finance_summary.[damages_interims])
 END AS [Reserve Damages (Net)]-- – Show “0” if TRA086 is complete, otherwise (TRA076 curDamResCur – (FTR049 curIntDamsPreIn + NMI065 curInDamPayPo))]
,fact_finance_summary.[cru_reserve] AS [Reserve CRU (Gross)(Internal only)]
,CASE WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL THEN 0 ELSE fact_finance_summary.[cru_reserve] END AS [Reserve CRU (Net)]
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Reserve Claimant’s Costs (Gross) (Internal only)]
,CASE WHEN date_costs_settled IS NOT NULL THEN 0 ELSE fact_detail_reserve_detail.[claimant_costs_reserve_current] - (fact_detail_paid_detail.[interim_damages_paid_by_client_preinstruction] + fact_detail_paid_detail.[interim_costs_payments]) END AS [Reserve Claimant’s Costs (Net)]-- – Show “0” if FTR087 is complete, otherwise (TRA080 curClaCostReCur – (FTR049 curIntDamsPreIn + NMI066 curIntCoPayPost))]
,fact_finance_summary.[defence_costs_reserve] AS [Reserve Own Costs (Gross)]
,CASE WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 0 ELSE ISNULL(fact_finance_summary.[defence_costs_reserve],0)  - ISNULL(TotalBilled,0) END  AS [Reserve Own Costs (Net)]--– Show “0” if closed in MS, otherwise (TRA078 curDefCostReCur – “Total Billed exc. VAT” where payor contains “MMI” OR “Municipal Mutual Insurance”)]
,NULL AS [Total O/S Reserve]-- – sum of “Reserve Damages (Net)” + “Reserve CRU (Net)” + “Reserve Claimant’s Costs (Net)” + “Reserve Own Costs (Net)”]
,fact_finance_summary.[damages_paid] AS [Damages Paid (inc. CRU) (Internal only)]
,ISNULL(fact_detail_paid_detail.[interim_damages_paid_by_client_preinstruction],0) + ISNULL(fact_finance_summary.[damages_interims],0) AS [Interim Damages Paid (Internal only) - FTR049 curIntDamsPreIn + NMI065 curInDamPayPo]
,CASE  WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL THEN ISNULL(fact_finance_summary.[damages_paid],0) + ISNULL(fact_detail_paid_detail.[cru_costs_paid],0)
ELSE ISNULL(fact_finance_summary.[damages_interims],0) + ISNULL(fact_detail_paid_detail.[interim_damages_paid_by_client_preinstruction],0) END  AS [Paid Damages]-- – Show (TRA070 curDamsPaidCli - WPS038 curCRUCostsPaid) if TRA086 is completed, otherwise, show FTR049 curIntDamsPreIn + NMI065 curInDamPayPo]
,fact_detail_paid_detail.[cru_costs_paid] AS [Paid CRU]
,ISNULL(fact_detail_paid_detail.[interim_damages_paid_by_client_preinstruction],0) + ISNULL(fact_detail_paid_detail.[interim_costs_payments],0) AS [Interim Costs Paid (Internal only) - FTR049 curIntDamsPreIn + NMI066 curIntCoPayPost]
,CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL THEN fact_finance_summary.[claimants_costs_paid] ELSE 
ISNULL(fact_detail_paid_detail.[interim_damages_paid_by_client_preinstruction],0) + ISNULL(fact_detail_paid_detail.[interim_costs_payments],0) END AS [Paid Claimant’s Costs]--  - Show TRA072 curClaCostCliBS if FTR087 is completed, otherwise show FTR049 curIntDamsPreIn + NMI066 curIntCoPayPost]
,TotalBilled AS [Paid Own Costs]-- - “Total Billed exc. VAT” where payor contains “MMI” OR “Municipal Mutual Insurance”]
,NULL AS [Total Paid - Sum of columns “Paid Damages” + “Paid CRU” + “Paid Claimant’s Costs” + “Paid Own Costs”]
,fact_finance_summary.total_recovery AS [Total Recovery]
,fact_detail_claim.[mmi_claimants_part_36_offer] AS [Claimant’s P36 - LIT1214]
,fact_detail_claim.[mmi_defendants_part_36_offer] AS [Defendant’s P36 - LIT1215]
,outcome_of_case AS [Outcome (Internal only) – TRA068 cboOutcomeCase]
,CASE WHEN dim_matter_header_current.date_closed_practice_management IS NULL THEN 'Open' ELSE 'Closed' END  AS [Status]
,dim_detail_core_details.present_position AS [Present Position (Internal only)]
,dim_detail_litigation.[mmi_present_position_barriers_to_settlement] AS [Present Position / Barriers to settlement - LIT1216]
,date_claim_concluded AS [Date Damages Settled]
,date_costs_settled AS [Date Costs Agreed]
,CASE WHEN dim_detail_core_details.present_position IN ('Final bill sent – unpaid','To be closed/minor balances to be clear')  THEN LastBillDate ELSE NULL END  AS [Date Final Bill Issued]-- - Show Date of last bill if TRA125 is set to “Final bill sent – unpaid”/ “To be closed/minor balances to be clear”]
,dim_matter_header_current.date_closed_case_management AS [Closed Date]
,ms_fileid AS [MSFileID]
,red_dw.dbo.fact_finance_summary.claimants_total_costs_paid_by_all_parties	AS [Damages Paid (all parties) (internal only)]
,fact_detail_paid_detail.total_settlement_value_of_the_claim_paid_by_all_the_parties AS [Claimant’s Costs Paid (all parties) (internalonly)]
,red_dw.dbo.fact_finance_summary.total_amount_billed AS [TotalBilled (internal only)]
,CASE 
WHEN red_dw.dbo.dim_detail_outcome.outcome_of_case  = 'Exclude fromreports' THEN 'Cancelled'
WHEN dim_matter_header_current.date_closed_case_management IS NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Settled','Lost at trial') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties >0 THEN 'Closed - Paid Claim'
WHEN dim_matter_header_current.date_closed_case_management IS NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Discontinued','Won at trial','Struck out') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties =0 THEN 'Closed – Repudiated'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Discontinued','Won at trial','Struck out') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties =0 THEN 'Open – Repudiated'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Settled','Lost at trial') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties >0 AND date_costs_settled IS NOT NULL THEN 'Open – CostsSettled'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Settled','Lost at trial') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties >0 AND fact_finance_summary.[claimants_costs_paid] >0THEN 'Open – CostsSettled'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND red_dw.dbo.dim_detail_outcome.outcome_of_case  IN( 'Settled','Lost at trial') OR fact_finance_summary.claimants_total_costs_paid_by_all_parties >0 AND date_costs_settled IS NULL AND fact_finance_summary.[claimants_costs_paid] = NULL OR fact_finance_summary.[claimants_costs_paid] =0 THEN 'Open – DamagesSettled'  
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND date_costs_settled IS NOT NULL THEN 'Open – Costs Settled'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND date_claim_concluded IS NOT NULL THEN 'Open – Damages Settled'
WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL AND referral_reason = 'Advice only'THEN 'Closed – Advice only'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND referral_reason = 'Advice only'THEN 'Open – Advice only'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND dim_detail_core_details.present_position IN   ('To be closed/minor balances to be clear', 'Final bill sent– unpaid','Final bill due – claim and costs concluded', 'Claim and costsconcluded but recovery outstanding') THEN 'Open - Costs Settled'
WHEN dim_matter_header_current.date_opened_case_management IS NOT NULL AND dim_detail_core_details.present_position IN ('Claim concluded but costs outstanding') THEN 'Open -Damages Settled'
ELSE 'Live'
END AS [Status (Internal Only)]
,fact_matter_summary_current.last_bill_date
,dim_detail_litigation.mmi_present_position_barriers_to_settlement 
,NULLIF(dim_detail_core_details.associated_matter_numbers,'N/A') AS [Zurich Ref]

INTO #temptabl
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary 
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_defendant_involvement
 ON dim_defendant_involvement.client_code = dim_matter_header_current.client_code
 AND dim_defendant_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT fileID,contName AS ClaimantName 
,contChristianNames AS [FirstName]
,contSurname AS [Surname]


FROM MS_Prod.config.dbAssociates
INNER JOIN MS_Prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN MS_Prod.dbo.dbContactIndividual
 ON dbContactIndividual.contID = dbAssociates.contID
 WHERE assocType='CLAIMANT') AS Claimant
 ON ms_fileid=Claimant.fileID
LEFT OUTER JOIN  red_dw.dbo.dim_claimant_thirdparty_involvement 
  ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN  red_dw.dbo.dim_detail_outcome 
  ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN  red_dw.dbo.dim_detail_critical_mi 
  ON dim_detail_critical_mi.client_code = dim_matter_header_current.client_code
 AND dim_detail_critical_mi.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN  red_dw.dbo.fact_detail_claim 
  ON fact_detail_claim.client_code = dim_matter_header_current.client_code
 AND fact_detail_claim.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN  red_dw.dbo.dim_detail_court 
  ON dim_detail_court.client_code = dim_matter_header_current.client_code
 AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN  red_dw.dbo.dim_detail_health 
  ON dim_detail_health.client_code = dim_matter_header_current.client_code
 AND dim_detail_health.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN  red_dw.dbo.fact_detail_paid_detail 
  ON fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_paid_detail.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN  red_dw.dbo.fact_detail_reserve_detail 
  ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN  red_dw.dbo.dim_detail_client 
  ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN  red_dw.dbo.fact_detail_client 
  ON fact_detail_client.client_code = dim_matter_header_current.client_code
 AND fact_detail_client.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN  red_dw.dbo.dim_detail_litigation 
  ON dim_detail_litigation.client_code = dim_matter_header_current.client_code
 AND dim_detail_litigation.matter_number = dim_matter_header_current.matter_number

 
 
LEFT OUTER JOIN (SELECT 
coalesce(left(Matter.loadnumber,(charindex('-',Matter.loadnumber)-1)),Client.altnumber,CASE WHEN ISNUMERIC(Client.number) = 1 THEN RIGHT(CAST(CAST(Client.number AS int)  + 100000000 AS varchar(9)),8) ELSE Client.number END)  AS client_code
,isnull(right(Matter.loadnumber, len(Matter.loadnumber) - charindex('-',Matter.loadnumber))
,right(Matter.altnumber, len(Matter.altnumber) - charindex('-',Matter.altnumber)))  AS matter_number
,SUM(ARAmt)  - SUM(ARTAx) AS [TotalBilled]
,MAX(InvMaster.InvDate) AS LastBillDate
FROM TE_3E_Prod.dbo.ARDetail WITH (NOLOCK)
INNER JOIN TE_3E_Prod.dbo.InvMaster
 ON ARDetail.InvMaster=InvMaster.InvIndex
INNER JOIN TE_3E_Prod.dbo.Matter WITH (NOLOCK) 
 ON ARDetail.Matter=Matter.MattIndex
INNER JOIN TE_3E_Prod.dbo.Client
 ON Matter.Client=Client.ClientIndex
LEFT OUTER JOIN TE_3E_Prod.dbo.Payor ON ARDetail.Payor=Payor.PayorIndex
WHERE  ARList IN ('Bill','BillRev')
AND coalesce(left(Matter.loadnumber,(charindex('-',Matter.loadnumber)-1)),Client.altnumber,CASE WHEN ISNUMERIC(Client.number) = 1 THEN RIGHT(CAST(CAST(Client.number AS int)  + 100000000 AS varchar(9)),8) ELSE Client.number END)='M00001'
AND Payor.DisplayName IN 
(
'MMI','MMI c/o Weightmans','MMI c/o Zurich','MMI c/o Zurich Commercial'
,'MMI c/o Zurich Insurance','MMI Insurance','Municipal Insurance'
,'Municipal Mutual','Municipal Mutual Insurance','Municipal Mutual Insurance Limited'
,'Municipal Mutual Insurance Ltd'

)
GROUP BY (coalesce(left(Matter.loadnumber,(charindex('-',Matter.loadnumber)-1)),Client.altnumber,CASE WHEN ISNUMERIC(Client.number) = 1 THEN RIGHT(CAST(CAST(Client.number AS int)  + 100000000 AS varchar(9)),8) ELSE Client.number END))
,(isnull(right(Matter.loadnumber, len(Matter.loadnumber) - charindex('-',Matter.loadnumber))
,right(Matter.altnumber, len(Matter.altnumber) - charindex('-',Matter.altnumber))))) AS TotalBilled
 ON dim_matter_header_current.client_code=TotalBilled.client_code COLLATE DATABASE_DEFAULT
 AND  dim_matter_header_current.matter_number=TotalBilled.matter_number COLLATE DATABASE_DEFAULT
 
 

WHERE (dim_matter_header_current.client_code='M00001' OR ms_fileid=4967122)
AND dim_matter_header_current.matter_number <>'ML'
AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>='2018-01-01')
AND dim_detail_litigation.mmi_present_position_barriers_to_settlement <> 'Exclude - finalised pre-2018'
AND RTRIM(dim_matter_header_current.client_code)+'/'+dim_matter_header_current.matter_number NOT IN 
( 'M00001/00101874',
  'M00001/00101760',
  'M00001/00101865',
  'M00001/00101875',
 'M00001/00101858',
 'M00001/00101987',
  'M00001/00101940',
  'M00001/00101942',
  'M00001/00101948',
  'M00001/00101876',
  'M00001/00101976',
  'M00001/00101932',
    'M00001/00102075',
  'M00001/00102027',
 'M00001/00102038',
  'M00001/11111696',
  'M00001/11111697',
  'M00001/11111692',
  'M00001/11111698'
)


SELECT
*,CASE WHEN [Claim Type] = 'Abuse' THEN 'N/A' ELSE [Job Role] END AS [Job Role_case]
,CASE WHEN [Claim Type] <>'Abuse'THEN 'N/A' ELSE [Risk Type]END AS [Risk Type_case]
,CASE WHEN [Claim Type] <> 'Abuse' THEN 'N/A' ELSE [Risk descriptor] END AS [Risk Descriptor_case]
,CASE WHEN [Claim Type] <> 'Abuse' THEN 'N/A' ELSE [Abuse Codes] END AS [Abuse Code_case]
,CASE WHEN [Claim Type] <> 'Abuse' THEN 'N/A' ELSE [Allegation type] END AS [Allegation_case]
,CASE WHEN [Status (Internal Only)] = 'Open – Repudiated”/”Closed – Repudiated' THEN 'N/A - Repuduated' ELSE [MMI’s % - Damages] END AS [MMI'S Damages_case] 


from #temptabl

END
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-06-06
-- Description:	AIGBudgetReportShortFormBuild
-- =============================================
CREATE PROCEDURE [AIG].[AIGBudgetReportShortFormBuild]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF object_id('dbo.AIGShortFormDataLoad') IS NOT NULL DROP TABLE  dbo.AIGShortFormDataLoad

IF OBJECT_ID ('tempdb.dbo.#LeadFile') IS NOT NULL
DROP TABLE #LeadFile

IF OBJECT_ID ('tempdb.dbo.#FirstUpload') IS NOT NULL
DROP TABLE #FirstUpload

IF OBJECT_ID ('tempdb.dbo.#LeadlinkedWipDisp') IS NOT NULL
DROP TABLE #LeadlinkedWipDisp

IF OBJECT_ID ('tempdb.dbo.#LeadlinkedBills') IS NOT NULL
DROP TABLE #LeadlinkedBills

IF OBJECT_ID ('tempdb.dbo.#LeadLinkedFixedFeeAmount') IS NOT NULL
DROP TABLE #LeadLinkedFixedFeeAmount

IF OBJECT_ID ('tempdb.dbo.#NumberRefs') IS NOT NULL
DROP TABLE #NumberRefs

IF OBJECT_ID ('tempdb.dbo.#Un_Submitted_Debt') IS NOT NULL
DROP TABLE #Un_Submitted_Debt

IF OBJECT_ID ('tempdb.dbo.#FirstMatter') IS NOT NULL
DROP TABLE #FirstMatter

IF OBJECT_ID ('tempdb.dbo.#wip') IS NOT NULL
DROP TABLE #wip

-------------------------------------WIp--------------------------------------
SELECT master_fact_key, SUM(wip_value) wip
INTO #wip FROM red_dw.dbo.fact_wip
GROUP BY master_fact_key

--------------------------------------LeadFile--------------------------------------

	SELECT 
	case_id AS ID,
	[aig_litigation_number],
	[AIG Budget approval],
	[Total budget uploaded],
	[Date budget uploaded],
	[Has budget been approved?]
	INTO #LeadFile
    FROM
    (
        SELECT RTRIM(aig_litigation_number.client_code) + '-' + aig_litigation_number.matter_number case_id,
               [aig_litigation_number] AS [aig_litigation_number],
               [aig_budget_approval] AS [AIG Budget approval],
               [total_budget_uploaded] AS [Total budget uploaded],
               [date_budget_uploaded] AS [Date budget uploaded],
               [has_budget_been_approved] AS [Has budget been approved?],
               ROW_NUMBER() OVER (PARTITION BY [aig_litigation_number]
                                  ORDER BY [date_budget_uploaded] DESC
                                 ) AS OrderID
        FROM
        (
            SELECT dim_parent_key,
                   [aig_budget_approval],
                   sequence_no,
                   client_code,
                   matter_number
            FROM red_dw.dbo.dim_parent_detail WITH (NOLOCK)
        ) AS MainDetail
            LEFT JOIN
            (
                SELECT dim_parent_key,
                       total_budget_uploaded AS total_budget_uploaded,
                       parent
                FROM  red_dw.dbo.fact_child_detail WITH (NOLOCK)
                WHERE total_budget_uploaded IS NOT NULL
            ) AS total_budget_uploaded
                ON MainDetail.dim_parent_key = total_budget_uploaded.dim_parent_key
                   AND MainDetail.sequence_no = total_budget_uploaded.parent
            LEFT JOIN
            (
                SELECT dim_parent_key,
                       date_budget_uploaded AS date_budget_uploaded,
                       parent
                FROM red_dw.dbo.dim_child_detail WITH (NOLOCK)
                WHERE date_budget_uploaded IS NOT NULL
            ) AS date_budget_uploaded
                ON MainDetail.dim_parent_key = date_budget_uploaded.dim_parent_key
                   AND MainDetail.sequence_no = date_budget_uploaded.parent
            LEFT JOIN
            (
                SELECT dim_parent_key,
                       has_budget_been_approved AS has_budget_been_approved,
                       parent
                FROM red_dw.dbo.dim_child_detail WITH (NOLOCK)
                WHERE has_budget_been_approved IS NOT NULL
            ) AS has_budget_been_approved
                ON MainDetail.dim_parent_key = has_budget_been_approved.dim_parent_key
                   AND MainDetail.sequence_no = has_budget_been_approved.parent
            INNER JOIN
            (
                SELECT client_code,
                       matter_number,
                       [aig_litigation_number]
                FROM red_dw.dbo.dim_detail_client WITH (NOLOCK)
                WHERE [aig_litigation_number] IS NOT NULL
            ) AS [aig_litigation_number]
                ON MainDetail.client_code = [aig_litigation_number].client_code
                   AND MainDetail.matter_number = [aig_litigation_number].matter_number
    ) AS FilteredDetail
    WHERE OrderID = 1

--------------------------------------FirstUpload--------------------------------------


SELECT FirstID,
           MIN([First Budget uploaded]) AS [First Budget uploaded]
		   INTO #FirstUpload
    FROM
    (
        SELECT [aig_litigation_number] AS FirstID,
               [First Budget uploaded]
        FROM
        (
            SELECT dim_parent_key,
                   client_code,
                   matter_number,
                   [aig_budget_approval] AS [AIG Budget approval],
                   sequence_no
            FROM red_dw.dbo.dim_parent_detail WITH (NOLOCK)
        ) AS MainDetail
            INNER JOIN
            (
                SELECT client_code,
                       matter_number,
                       [aig_litigation_number]
                FROM red_dw.dbo.dim_detail_client WITH (NOLOCK)
                WHERE [aig_litigation_number] IS NOT NULL
            ) AS [aig_litigation_number]
                ON MainDetail.client_code = [aig_litigation_number].client_code
                   AND MainDetail.matter_number = [aig_litigation_number].matter_number
            LEFT JOIN
            (
                SELECT dim_parent_key,
                       [date_budget_uploaded] AS [First Budget uploaded],
                       parent
                FROM red_dw.dbo.dim_child_detail WITH (NOLOCK)
                WHERE [date_budget_uploaded] IS NOT NULL
            ) AS [First Budget uploaded]
                ON MainDetail.dim_parent_key = [First Budget uploaded].dim_parent_key
                   AND MainDetail.sequence_no = [First Budget uploaded].parent
    ) AS FirstBudgetDate
    GROUP BY FirstID
   
SELECT [aig_litigation_number],
           SUM(wip) AS LeadLinkedWIP,
           SUM(disbursement_balance) AS LeadLinkedDis
		   INTO #LeadlinkedWipDisp
    FROM
    (
        SELECT [aig_litigation_number],
               #wip.wip,
               disbursement_balance
        FROM red_dw.dbo.fact_dimension_main WITH (NOLOCK) /*1.1*/
            LEFT JOIN red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
                ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
            LEFT JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
                ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
            LEFT JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
                ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
				LEFT JOIN #wip ON #wip.master_fact_key = fact_dimension_main.master_fact_key
        WHERE client_group_code = '00000013'
              AND [aig_litigation_number] IS NOT NULL
              AND [aig_litigation_number] NOT IN ( 'Closed claim 20.01.15', 'Closed Claim 20.01.15' )
    ) AS LineLevel
    GROUP BY [aig_litigation_number]

--------------------------------------LeadlinkedBills--------------------------------------  

SELECT [aig_litigation_number],
[First Budget uploaded],
           SUM(bill_total_first) AS  TotalBilled ,
		   SUM(bill_total) AS TotalBilledTD,
		   SUM(bill_total_excl_vat) AS TotalBilled_exl_vat
		   INTO #LeadlinkedBills
    FROM
    (
        SELECT [aig_litigation_number],
		[First Budget uploaded],
               CASE WHEN dim_date.calendar_date >=FirstUpload.[First Budget uploaded] then bill_total ELSE 0 END bill_total_first,
			   bill_total,
			   bill_total_excl_vat
        FROM red_dw.dbo.fact_bill_detail WITH (NOLOCK) /*1.1*/
            LEFT JOIN red_dw.dbo.dim_client WITH (NOLOCK)
                ON dim_client.dim_client_key = fact_bill_detail.dim_client_key
            LEFT JOIN red_dw.dbo.fact_dimension_main WITH (NOLOCK)
                ON fact_bill_detail.master_fact_key = fact_dimension_main.master_fact_key
            LEFT JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
                ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
            LEFT JOIN red_dw.dbo.dim_date WITH (NOLOCK)
                ON dim_date.dim_date_key = fact_bill_detail.dim_bill_date_key
			LEFT JOIN #FirstUpload AS FirstUpload ON FirstUpload.FirstID = [aig_litigation_number]

        WHERE client_group_code = '00000013'
              AND [aig_litigation_number] IS NOT NULL
              AND [aig_litigation_number] NOT IN ( 'Closed claim 20.01.15', 'Closed Claim 20.01.15' )
    ) AS LineLevel
    GROUP BY [aig_litigation_number],[First Budget uploaded]

--------------------------------------LeadLinkedFixedFeeAmount--------------------------------------  

SELECT [aig_litigation_number] AS FixedFeeID,
           SUM([fact_finance_summary].[fixed_fee_amount]) AS LeadlinkedFTR058,
		   SUM([defence_costs_reserve]) AS LeadlinkedTRA078
		   INTO #LeadLinkedFixedFeeAmount
    FROM red_dw.dbo.fact_dimension_main WITH (NOLOCK)
        LEFT JOIN red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
            ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        LEFT JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
            ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
        LEFT JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
            ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
    WHERE [aig_litigation_number] IS NOT NULL
          AND [aig_litigation_number] <> 'Closed Claim 20.01.15'
    GROUP BY [aig_litigation_number]

--------------------------------------NumberRefs--------------------------------------  

SELECT [aig_litigation_number],
           COUNT(*) NumberRefs
		   INTO #NumberRefs
    FROM red_dw.dbo.dim_detail_client WITH (NOLOCK)
    WHERE [aig_litigation_number] IS NOT NULL
    GROUP BY [aig_litigation_number]

   --------------------------------------Un_Submitted_Debt--------------------------------------
 
SELECT master_fact_key,
SUM(CASE WHEN BillSentToClientDate IS NULL THEN bill_amount ELSE 0 end) UnSubmittedDebt,
SUM(CASE WHEN BillSentToClientDate IS not NULL THEN bill_amount ELSE 0 END) SubmittedDebt 
INTO #Un_Submitted_Debt
FROM red_dw.dbo.fact_bill_activity WITH (NOLOCK)
LEFT JOIN red_dw.dbo.dim_client WITH (NOLOCK) ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
LEFT JOIN  [Reporting].[dbo].[BatchPayee]   [BatchPayee] on [BatchPayee].[ActualBillNumber] collate database_default = fact_bill_activity.bill_number collate database_default and SendToClientError is null
WHERE client_group_code = '00000013'
GROUP BY master_fact_key

SELECT case_id, 'Yes' AS FirstMatter
INTO #FirstMatter
FROM 
(
SELECT RTRIM(dim_detail_client.client_code)+'-'+RTRIM(dim_detail_client.matter_number) case_id, aig_litigation_number,dim_open_case_management_date_key,ROW_NUMBER() OVER(PARTITION BY aig_litigation_number ORDER BY dim_open_case_management_date_key ASC) AS OrderID 
FROM red_dw.dbo.fact_dimension_main 
LEFT JOIN red_dw.dbo.dim_detail_client ON  dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
) AS FirstMatter
WHERE OrderID=1




SELECT  
[Client]
,[Matter]
,[Case Description]
,[Fee Earner]
,[Team]
,[AIG Reference]
,[Insurer Reference]
,[Insured Client]
,[NumberRefs]	
,[AIG litigation number]
,[AIG) Instructing office]
,[Client's claims handler]
,[Date Opened on FED]
,[Fixed Fee]
,[Suspicion of fraud?]
,[Initial fraud type]
,[Current fraud type]
,[AIG Current Fee Scale]
,[Referral Reason]
,[Present Position]
,[Outcome]
,[Date Claim Concluded]
,[Date Costs Settled]
,[Unpaid Bills]
,UnSubmittedDebt
,SubmittedDebt
,ISNULL([Unpaid WIP],0) [Unpaid WIP]
,[Total Billed to Date]
,[Defence Costs Reserve Current]
,[Net Defence Costs Reserve]
,[Evaluation fees - experts/consultants]
,[Evaluation fees - documents/file management]
,[Evaluation fees - budgeting]
,[Evaluation fees - pleadings]
,[Evaluation fees - prelim injunctions/provisional remedies]
,[Evaluation fees - fact investigation/development]
,[Evaluation fees - analysis/strategy]
,[Discovery/Disclosure fees - court mandated conferences]
,[Discovery/Disclosure fees-other written motion.submission]
,[Discovery/Disclosure fees-written discovery/interrogatori]
,[Discovery/Disclosure fees - document production]
,[Discovery/Disclosure fees - depositions]
,[Discovery/Disclosure fees - expert discovery]
,[Discovery/Disclosure fees - discovery motions]
,[Discovery/Disclosure fees - discovery on-site inspections]
,[ADR fees - Settlement.non-binding ADR]
,[Trial fees - fact witnesses]
,[Trial fees - expert witnesses]
,[Trial fees - written motions/submissions]
,[Trial fees - trial preparation + support]
,[Trial fees - trial and hearing attendance]
,[Trial fees - post trial motions/submissions]
,[Trial fees - enforcement]
,[Appeal fees - appellate proceedings/motions practice]
,[Appeal fees - appellate briefs]
,[Appeal fees - oral argument]
,[Overall costs budget figure]
,[Evaluation expenses]
,[Discovery/Disclosure expenses]
,[ADR expenses]
,[Trial expenses]
,[Appeal expenses]
,[Multi-Phase expenses]
,[Overall expenses figure]
,[Fixed Fee Budget - Fees]                                  
,[Fixed Fee Budget - Expenses]                              
,[Fixed Fee Budget - Vat]  
,AIGHIDE_Flag
,[Date instructions received] 
,[AIG Budget approval]
,ISNULL([Total budget uploaded],0)[Total budget uploaded]
,Total
,[Date budget uploaded]
,[First Budget uploaded]
,[Has budget been approved?]  
--,CASE WHEN [Fixed Fee]='Yes' AND  [Total budget uploaded] < LeadLinkedFixedFee THEN [Percentage Of Budget]*-1
--ELSE [Percentage Of Budget] END AS [Percentage Of Budget]
,[Percentage Of Budget]
,ISNULL(LeadLinkedTotalBilled,0) LeadLinkedTotalBilled
,ISNULL(LeadLinkedFixedFee,0) LeadLinkedFixedFee
,case WHEN AllData.[AIG litigation number] IS NULL THEN ISNULL(AllData.[Unpaid WIP],0) else ISNULL(LeadLinkedWIP,0) end LeadLinkedWIP
,ISNULL(LeadLinkedDis,0) LeadLinkedDis
,[Is Insured VAT Registered]
,AllData.[Master Client]
,AllData.[Master Matter]
,
--ISNULL(CASE WHEN [Percentage Of Budget] >=0.9 AND ISNULL([Present Position],'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear') THEN 'Total of billed and unbilled costs is more than 90% of total budget uploaded' END,'|') + ' ' +
--ISNULL(CASE WHEN [Percentage Of Budget] >=0.75 AND ISNULL([Present Position],'') NOT IN ('Final bill sent - unpaid','To be closed/minor balances to be clear') AND [Fixed Fee]<>'Yes' AND  [Percentage Of Budget] <0.9 THEN 'Total of billed and unbilled costs is more than 75% of total budget uploaded' END,'|') + ' ' +
--ISNULL(CASE WHEN [Date Opened on FED] >'2014-10-24' AND  [Total budget uploaded] <> [Defence Costs Reserve Current] THEN 'Total budget uploaded does not equal current defence costs reserve' END,'|') + ' ' +
--ISNULL(CASE WHEN [Fixed Fee]='Yes' AND  ISNULL([Fixed Fee Budget - Fees],0) +ISNULL([Fixed Fee Budget - Expenses],0) + ISNULL([Fixed Fee Budget - Vat],0) >0
--AND [Total budget uploaded] <> ISNULL([Fixed Fee Budget - Fees],0) +ISNULL([Fixed Fee Budget - Expenses],0) + ISNULL([Fixed Fee Budget - Vat],0)
-- THEN 'Total budget uploaded does not equal the sum of the total budget fields' END,'') AS Exceptions,

ISNULL(CASE WHEN LeadFileBudget = 'Yes' AND ISNULL([Total budget uploaded],0) > 0 AND ISNULL([Total budget uploaded],0)-ISNULL(LeadLinkedTotalBilled,0) <= 0
 THEN 'Remaining budget is £0 or less.  Review of budget required before billing' END,'')
 +''+
 ISNULL( CASE WHEN [AIG litigation number] IS NULL THEN 'No Lit Number' END , '')
  +''+
  ISNULL(CASE WHEN [AIG litigation number]LIKE  '%*LIT-%' then 'LIT number set up with incorrect fee scale' END , '')
    +''+
ISNULL(CASE  WHEN [AIG litigation number] LIKE  '#LIT-' THEN 'LIT number not in Collaborati' END , '')
    +''+
ISNULL(CASE WHEN LOWER([Has budget been approved?]) = 'rejected' THEN 'Rejected Budget' END , '')
    +''+
ISNULL(CASE WHEN  LOWER([Has budget been approved?]) = 'no'  THEN 'Awaiting Budget Approval' END , '')
    +''+
ISNULL(CASE WHEN LeadFileBudget = 'Yes' AND ISNULL([Total budget uploaded],0) > 0 AND ISNULL([Total budget uploaded],0)-ISNULL(LeadLinkedTotalBilled,0) BETWEEN 0.01 AND 500 
		THEN 'Remaining budget is £500 or less, consider reviewing your budget' END,'')
				
		 AS Exceptions /*1.1*/

,BudgetNotMatch
,ISNULL(UnbilledDisbs,0) UnbilledDisbs
,[is_this_a_linked_file] [Is this a linked file]    
,[is_this_the_lead_file] [Is this the lead file]
,[lead_file_matter_number_client_matter_number] [Lead file matter number]
,[Fedcode]
,TotalBilledToDateLeadLinked AS [Total Billed To Date Lead Linked]
,[LeadlinkedTRA078] AS [LeadlinkedTRA078]
,LeadFileBudget AS LeadFileBudget
,AIGTotalBudgetFixedFee
,AIGTotalBudgetHourlyRate
,[aig_costs_practice_area_only_budget] LIT216 
,CASE WHEN LeadFileBudget = 'Yes' THEN CASE WHEN ISNULL([Total budget uploaded],0) > 0 THEN ISNULL([Total budget uploaded],0)-ISNULL(LeadLinkedTotalBilled,0) ELSE 0 END ELSE 0 END AS [TotalBudgetRemaining]  /*1.1*/
,CASE WHEN LeadFileBudget = 'Yes' THEN CASE WHEN ISNULL([Total budget uploaded],0) > 0 THEN ISNULL([Total budget uploaded],0)-ISNULL(TotalBilled_exl_vat,0) ELSE 0 END ELSE 0 END AS [TotalBudgetRemainingVAt]  /*1.1*/
--,AllData.[AIG litigation number]-------------KM added 22-08-2019
,AllData.[FED Ref]
, AllData.[MS Ref] ------ KM
	 --,  CASE WHEN AllData.[AIG litigation number] IS NULL THEN 'No Lit Number'
	 --  WHEN AllData.[AIG litigation number]LIKE  '%*LIT-%' then 'LIT number set up with incorrect fee scale'
	 --  	   WHEN AllData.[AIG litigation number] LIKE  '#LIT-' THEN 'LIT number not in Collaborati'
		--   WHEN LOWER(AllData.[Has budget been approved?]) = 'rejected' THEN 'Rejected Budget'
		--   WHEN  LOWER(AllData.[Has budget been approved?]) = 'no'  THEN 'Awaiting Budget Approval'-------------- KM 

INTO dbo.AIGShortFormDataLoad
FROM (
--------------------------------------select statement--------------------------------------
SELECT 
--dim_client.client_group_code,
      -- ms_only,
       --LeadLinkedWIP,
       dim_matter_header_current.client_code [Client],
       dim_matter_header_current.matter_number [Matter],
	   dim_matter_header_current.master_client_code [Master Client], master_matter_number [Master Matter],
       matter_description [Case Description],
       name [Fee Earner],
	   TotalBilled_exl_vat,
       hierarchylevel4hist [Team],
       [aig_reference] [AIG Reference],
       insurerclient_reference [Insurer Reference],
       insuredclient_name [Insured Client],
       [NumberRefs] [NumberRefs],
       CASE
           WHEN ISNULL([Total budget uploaded], 0) = 0 THEN
               NULL
           WHEN [dim_detail_core_details].[fixed_fee] = 'Yes' THEN
               NULL
           WHEN date_opened_case_management < '2014-10-24' THEN
               NULL
           ELSE
               CAST(ISNULL(TotalBilledTD, 0) + ISNULL(#wip.wip, 0) AS DECIMAL(10, 2))
               / CAST(ISNULL([Total budget uploaded], 0) AS DECIMAL(10, 2))
       END AS PercentageRemaining,
       [dim_detail_client].[aig_litigation_number] [AIG litigation number],
       [aig_instructing_office] [AIG) Instructing office],
       [clients_claims_handler_surname_forename] [Client's claims handler],
       date_opened_case_management [Date Opened on FED],
       [dim_detail_core_details].[fixed_fee] [Fixed Fee],
       [suspicion_of_fraud] [Suspicion of fraud?],
       [fraud_initial_fraud_type] [Initial fraud type],
       [fraud_current_fraud_type] [Current fraud type],
       [aig_current_fee_scale] [AIG Current Fee Scale],
       [referral_reason] [Referral Reason],
       [dim_detail_core_details].[present_position] [Present Position],
       [outcome_of_case] [Outcome],
       [date_claim_concluded] [Date Claim Concluded],
       [date_costs_settled] [Date Costs Settled],
       unpaid_bill_balance [Unpaid Bills],
       Un_Submitted_Debt.UnSubmittedDebt UnSubmittedDebt,                                                    --Double check
       Un_Submitted_Debt.SubmittedDebt SubmittedDebt,                                                        --Double check
       #wip.wip [Unpaid WIP],                                                                                     --Double check
       TotalBilledTD [Total Billed to Date],                                                           --Double check
       [defence_costs_reserve] [Defence Costs Reserve Current],
       ISNULL([defence_costs_reserve], 0) - (ISNULL(TotalBilledTD, 0)) AS [Net Defence Costs Reserve], --Double check
       [evaluation_fees_expertsconsultants] [Evaluation fees - experts/consultants],
       [evaluation_fees_documentsfile_management] [Evaluation fees - documents/file management],
       [evaluation_fees_budgeting] [Evaluation fees - budgeting],
       [evaluation_fees_pleadings] [Evaluation fees - pleadings],
       [evaluation_fees_prelim_injunctionsprovisional_remedies] [Evaluation fees - prelim injunctions/provisional remedies],
       [evaluation_fees_fact_investigationdevelopment] [Evaluation fees - fact investigation/development],
       [evaluation_fees_analysisstrategy] [Evaluation fees - analysis/strategy],
       [discoverydisclosure_fees_court_mandated_conferences] [Discovery/Disclosure fees - court mandated conferences],
       [discoverydisclosure_feesother_written_motionsubmission] [Discovery/Disclosure fees-other written motion.submission],
       [discoverydisclosure_feeswritten_discoveryinterrogatori] [Discovery/Disclosure fees-written discovery/interrogatori],
       [discoverydisclosure_fees_document_production] [Discovery/Disclosure fees - document production],
       [discoverydisclosure_fees_depositions] [Discovery/Disclosure fees - depositions],
       [discoverydisclosure_fees_expert_discovery] [Discovery/Disclosure fees - expert discovery],
       [n_discoverydisclosure_fees_discovery_motions] [Discovery/Disclosure fees - discovery motions],
       [o_discoverydisclosure_fees_discovery_onsite_inspections] [Discovery/Disclosure fees - discovery on-site inspections],
       [p_adr_fees_settlementnonbinding_adr] [ADR fees - Settlement.non-binding ADR],
       [q_trial_fees_fact_witnesses] [Trial fees - fact witnesses],
       [r_trial_fees_expert_witnesses] [Trial fees - expert witnesses],
       [s_trial_fees_written_motionssubmissions] [Trial fees - written motions/submissions],
       [t_trial_fees_trial_preparation_support] [Trial fees - trial preparation + support],
       [u_trial_fees_trial_and_hearing_attendance] [Trial fees - trial and hearing attendance],
       [v_trial_fees_post_trial_motionssubmissions] [Trial fees - post trial motions/submissions],
       [w_trial_fees_enforcement] [Trial fees - enforcement],
       [x_appeal_fees_appellate_proceedingsmotions_practice] [Appeal fees - appellate proceedings/motions practice],
       [y_appeal_fees_appellate_briefs] [Appeal fees - appellate briefs],
       [yy_appeal_fees_oral_argument] [Appeal fees - oral argument],
       [yz_overall_costs_budget_figure] [Overall costs budget figure],
       [za_evaluation_expenses] [Evaluation expenses],
       [zb_discoverydisclosure_expenses] [Discovery/Disclosure expenses],
       [zc_adr_expenses] [ADR expenses],
       [zd_trial_expenses] [Trial expenses],
       [ze_appeal_expenses] [Appeal expenses],
       [zf_multiphase_expenses] [Multi-Phase expenses],
       [zg_overall_expenses_figure] [Overall expenses figure],
       [aig_fixed_fee_budget_fees] [Fixed Fee Budget - Fees],
       [aig_fixed_fee_budget_expenses] [Fixed Fee Budget - Expenses],
       [aig_fixed_fee_budget_vat] [Fixed Fee Budget - Vat],
       CASE WHEN LOWER(file_notes) LIKE '%aighide%' THEN 1 ELSE 0 end AIGHIDE_Flag,
       [date_instructions_received] [Date instructions received],
       [AIG Budget approval],
       [Total budget uploaded],
       ISNULL([yz_overall_costs_budget_figure], 0) + ISNULL([zg_overall_expenses_figure], 0) [Total],
       [Date budget uploaded],
       [FirstUpload].[First Budget uploaded],
       [Has budget been approved?],
	   dim_detail_client.aig_litigation_number,
	   REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.client_code),'0',' ') ),' ','0')+'-'+REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.matter_number),'0',' ') ),' ','0') AS [FED Ref], 
	   REPLACE(LTRIM(REPLACE(RTRIM(dim_matter_header_current.master_client_code),'0',' ') ),' ','0')+'-'+REPLACE(LTRIM(REPLACE(RTRIM(master_matter_number),'0',' ') ),' ','0') AS [MS Ref]
	   ,
	   CASE WHEN dim_detail_client.aig_litigation_number IS NULL THEN 'No Lit Number'
	   WHEN dim_detail_client.aig_litigation_number LIKE  '%*LIT-%' then 'LIT number set up with incorrect fee scale'
	   	   WHEN dim_detail_client.aig_litigation_number LIKE  '#LIT-' THEN 'LIT number not in Collaborati'
		   WHEN LOWER(has_budget_been_approved) = 'rejected' THEN 'Rejected Budget'
		   WHEN  LOWER(has_budget_been_approved) = 'no'  THEN 'Awaiting Budget Approval'
		   ELSE '-' END AS 'Litigation Exception'
		   --,   is_insured_vat_registered [Is Insured Vat Registered]
		   , 
 




-----------------------

       CASE
           
		   WHEN NumberRefs.NumberRefs = 1
                AND ISNULL([dim_detail_core_details].[fixed_fee], '') = 'Yes'
                AND [FirstUpload].[First Budget uploaded] IS NOT NULL THEN --Fixed Fee Non Linked Case
               CAST(ISNULL(LeadlinkedFTR058, 0) + ISNULL(LeadLinkedDis, 0) AS DECIMAL(10, 2))
               / CAST([Total budget uploaded] AS DECIMAL(10, 2)) -- Added By Bob Ticket 148896
--  ----------------------------------------------------------------------------         
		   WHEN NumberRefs = 1
                AND ISNULL([dim_detail_core_details].[fixed_fee], '') <> 'Yes'
                AND [FirstUpload].[First Budget uploaded] IS NOT NULL THEN --Hourly Rate Non Linked Case
       (CASE WHEN [Total budget uploaded]=0 THEN NULL ELSE 
	   (((CASE
             WHEN ISNULL([is_insured_vat_registered], 'Yes') = 'No' THEN
                 #wip.wip + #wip.wip * 0.2
             ELSE
                 #wip.wip
         END
        ) + (CASE
                 WHEN ISNULL([is_insured_vat_registered], 'Yes') = 'No' THEN
                     disbursement_balance + disbursement_balance * 0.2
                 ELSE
                     disbursement_balance
             END
            ) + ISNULL(LeadlinkedBills.TotalBilled, 0)
       ) / CAST([Total budget uploaded] AS DECIMAL(10, 2)))
	   END)
--  ----------------------------------------------------------------------------------------------      
		WHEN NumberRefs.NumberRefs > 1
                AND ISNULL([dim_detail_core_details].[fixed_fee], '') = 'Yes'
                AND [FirstUpload].[First Budget uploaded] IS NOT NULL THEN --Fixed Fee Linked Case
               CAST(ISNULL(LeadlinkedFTR058, 0) + ISNULL(LeadLinkedDis, 0) AS DECIMAL(10, 2))
               / CAST([Total budget uploaded] AS DECIMAL(10, 2)) -- Added By Bob Ticket 148896
------------------------------------------------------------------------------------------------------
        WHEN NumberRefs > 1
                AND ISNULL([dim_detail_core_details].[fixed_fee], '') <> 'Yes'
                AND [FirstUpload].[First Budget uploaded] IS NOT NULL THEN --Hourly Rate Linked Case
       ((CASE
             WHEN ISNULL([is_insured_vat_registered], 'Yes') = 'No' THEN
                 LeadLinkedWIP + LeadLinkedWIP * 0.2
             ELSE
                 LeadLinkedWIP
         END
        ) + (CASE
                 WHEN ISNULL([is_insured_vat_registered], 'Yes') = 'No' THEN
                     LeadLinkedDis + LeadLinkedDis * 0.2
                 ELSE
                     LeadLinkedDis
             END
            ) + ISNULL(LeadlinkedBills.TotalBilled, 0)
       ) / CAST([Total budget uploaded] AS DECIMAL(10, 2))
-- -------------------------------------------------------------------------      
	   END AS [Percentage Of Budget],
       LeadlinkedBills.TotalBilled LeadLinkedTotalBilled,
       LeadLinkedFixedFeeAmount.LeadlinkedFTR058 LeadLinkedFixedFee,
       CASE
           WHEN ISNULL([is_insured_vat_registered], 'Yes') = 'No' THEN
               LeadLinkedWIP + LeadLinkedWIP * 0.2
           ELSE
               LeadLinkedWIP
       END AS LeadLinkedWIP,
       CASE
           WHEN ISNULL([is_insured_vat_registered], 'Yes') = 'No' THEN
               LeadLinkedDis + LeadLinkedDis * 0.2
           ELSE
               LeadLinkedDis
       END LeadLinkedDis,
       [is_insured_vat_registered] [Is Insured VAT Registered],
	   '' exception,
       NULL AS BudgetNotMatch,
       disbursement_balance UnbilledDisbs,
       [is_this_a_linked_file],
       [is_this_the_lead_file],
       [lead_file_matter_number_client_matter_number],
       fed_code [Fedcode],
       TotalBilledTD AS TotalBilledToDateLeadLinked,
       LeadlinkedTRA078 [LeadlinkedTRA078],
       CASE WHEN LTRIM(RTRIM(fact_dimension_main.client_code))+'-'+LTRIM(RTRIM(fact_dimension_main.matter_number))=LeadFile.ID AND fact_dimension_main.dim_closed_case_management_date_key = 0  THEN 'Yes'
      WHEN LTRIM(RTRIM(fact_dimension_main.client_code))+'-'+LTRIM(RTRIM(fact_dimension_main.matter_number))<>LeadFile.ID AND  fact_dimension_main.dim_closed_case_management_date_key <> 0 THEN 
	  ISNULL(FirstMatter.FirstMatter,'No')
	  WHEN dim_detail_client.aig_litigation_number IS NULL THEN 'Yes'  ELSE 'No' 
      
     END AS LeadFileBudget ,
       [aigtotalbudgetfixedfee] [AIGTotalBudgetFixedFee],
       [aigtotalbudgethourlyrate] [AIGTotalBudgetHourlyRate],
       [aig_costs_practice_area_only_budget]
--------------------------------------red tables--------------------------------------
FROM red_dw.dbo.fact_dimension_main WITH (NOLOCK)
    LEFT JOIN red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT JOIN red_dw.dbo.dim_client WITH (NOLOCK)
        ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
    LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK)
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
    LEFT JOIN red_dw.dbo.dim_detail_core_details WITH (NOLOCK)
        ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
    LEFT JOIN red_dw.dbo.dim_client_involvement WITH (NOLOCK)
        ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
    LEFT JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
        ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
    LEFT JOIN red_dw.dbo.dim_detail_fraud WITH (NOLOCK)
        ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
    LEFT JOIN red_dw.dbo.dim_detail_outcome WITH (NOLOCK)
        ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
    LEFT JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
        ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
    LEFT JOIN red_dw.dbo.fact_detail_cost_budgeting WITH (NOLOCK)
        ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
    LEFT JOIN red_dw.dbo.dim_file_notes WITH (NOLOCK)
        ON dim_file_notes.dim_file_notes_key = fact_dimension_main.dim_file_notes_key


    --CTEs
    LEFT JOIN #NumberRefs AS NumberRefs
        ON dim_detail_client.[aig_litigation_number] = NumberRefs.[aig_litigation_number]
   
    LEFT OUTER JOIN #FirstUpload AS FirstUpload
        ON [dim_detail_client].[aig_litigation_number] = FirstUpload.FirstID
    LEFT OUTER JOIN #LeadLinkedFixedFeeAmount AS LeadLinkedFixedFeeAmount
        ON [dim_detail_client].[aig_litigation_number] = LeadLinkedFixedFeeAmount.FixedFeeID
    LEFT OUTER JOIN #LeadlinkedWipDisp AS LeadlinkedWipDisp
        ON [dim_detail_client].[aig_litigation_number] = LeadlinkedWipDisp.[aig_litigation_number]
    LEFT JOIN #LeadlinkedBills AS LeadlinkedBills
        ON [dim_detail_client].[aig_litigation_number] = LeadlinkedBills.[aig_litigation_number]
   LEFT join #FirstMatter AS FirstMatter ON  RTRIM(fact_dimension_main.client_code) + '-' + fact_dimension_main.matter_number = FirstMatter.case_id
    LEFT JOIN #LeadFile AS LeadFile
        ON RTRIM(fact_dimension_main.client_code) + '-' + fact_dimension_main.matter_number = LeadFile.ID
   LEFT JOIN #wip ON #wip.master_fact_key = fact_dimension_main.master_fact_key

	LEFT JOIN #Un_Submitted_Debt AS Un_Submitted_Debt ON Un_Submitted_Debt.master_fact_key = fact_finance_summary.master_fact_key
--------------------------------------where--------------------------------------
WHERE (
          dim_matter_header_current.case_id IN ( 464543, 592809 )
          OR (
                 dim_client.client_group_code = '00000013'
                 AND date_closed_case_management IS NULL
                 AND reporting_exclusions = 0
                 AND fact_dimension_main.matter_number <> 'ML'
                 AND fact_dimension_main.client_code NOT IN ( '00030645', '453737', '95000C' )
             )
      )
--------------------------------------testing--------------------------------------
      --AND fact_dimension_main.client_code = '00006865'
      --AND fact_dimension_main.matter_number = '00000237'
--------------------------------------order by--------------------------------------


 ) AS AllData

 ORDER BY [AIG litigation number],Client,Matter

--To allow the report to run while the data is being loaded

IF object_id('dbo.AIGShortFormData') IS NOT NULL DROP TABLE  dbo.AIGShortFormData

select * into dbo.AIGShortFormData from dbo.AIGShortFormDataLoad
 
IF object_id('dbo.AIGShortFormDataLoad') IS NOT NULL DROP TABLE  dbo.AIGShortFormDataLoad
	
--END
	
END
GO

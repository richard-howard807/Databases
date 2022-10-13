SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE PROCEDURE [dbo].[CentricaRecoveries]

AS

BEGIN 

SELECT 'Centrica' AS Client,
work_type_code,
matter_owner_full_name,
red_dw.dbo.dim_matter_worktype.work_type_name,
red_dw.dbo.dim_matter_worktype.work_type_group ,
client_balance,
fact_dimension_main.client_code [Client Number],
fact_dimension_main.matter_number [Matter number],
Client.ClientReference AS [ClientRef],
LEFT(RIGHT(Client.cleaned_client_ref, LEN(Client.cleaned_client_ref) - (PATINDEX('%[A-z]%', Client.cleaned_client_ref)-1)), 
	PATINDEX('%[^A-z]%', RIGHT(Client.cleaned_client_ref, LEN(Client.cleaned_client_ref) - (PATINDEX('%[A-z]%', Client.cleaned_client_ref)-1)))-1)	AS [Work Type],
DriverName.DriverName AS [DriverName],
THIRDPARTY.TPName AS [TPName],
dim_matter_header_current.matter_description [Matter Description],
name [Case Handler Name ],
dim_fed_hierarchy_history.hierarchylevel3hist [Department ],
red_dw.dbo.dim_detail_core_details.referral_reason [Referral Reason],
work_type_name [Worktype (Name) ],
dim_detail_core_details.[present_position] [Present Position ],
date_opened_case_management [Date opened ],
date_closed_case_management[Date Closed ],
Defendant.[Insurer Name] [Insurer Name ],
NULL [Insurer Ref],
dim_detail_core_details.[incident_date] [Date of Accident ],
NULL AS [Reason for instruction ],
dim_detail_client.[fee_arrangement] [Fee Arrangement ], 
dim_detail_outcome.[date_claim_concluded] [Date claim concluded],
dim_detail_outcome.[outcome_of_case] [Reason for recovery/outcome],
NULL AS [Costs/ QOCS position],
NULL AS[Reason indemnity refused ],
NULL AS [Date PH/driver notified re indemnity ],
fact_detail_paid_detail.[total_damages_paid] [Claimant's damages paid ],
fact_finance_summary.[total_tp_costs_paid_to_date] [Claimant's costs paid ],
--fact_detail_paid_detail.[total_damages_paid] +fact_finance_summary.[total_tp_costs_paid_to_date] [Recovery sought],
fact_detail_recovery_detail.[amount_recovery_sought] [Recovery sought],
--fact_finance_summary.[total_recovery] [Amount recovered],
ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0) AS  [Amount recovered],
--(fact_detail_paid_detail.[total_damages_paid] +fact_finance_summary.[total_tp_costs_paid_to_date] ) - fact_finance_summary.[total_recovery] [Balance outstanding],

CASE WHEN balance_due_on_charging_order IS NOT NULL  THEN balance_due_on_charging_order
WHEN date_recovery_concluded IS NOT NULL THEN 0 ELSE
ISNULL(fact_detail_recovery_detail.[amount_recovery_sought],0) - ( ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0)) 
END [Balance outstanding],
fact_detail_client.[balance_due_on_charging_order] [Balance due on charging order],
dim_detail_claim.[date_recovery_concluded][Date recovery concluded],
dim_detail_claim.[date_of_charging_order]  [Date of charging order],
dim_detail_outcome.[recovery_claimants_our_client_damages] [Damages sent to client ],
fact_detail_recovery_detail.[recovery_claimants_our_client_costs] [Costs sent to client ],
    fact_finance_summary.[defence_costs_billed][Amount PC billed from recovery],
fact_bill_detail_summary.disbursements_billed_exc_vat + fact_finance_summary.vat_billed  [Amount billed for VAT & disbs from recovery],
fact_bill_detail_summary.disbursements_billed_exc_vat   [Amount billed for disbs from recovery],
fact_bill_detail_summary.disbursements_billed_exc_vat + fact_finance_summary.vat_billed +   fact_finance_summary.[defence_costs_billed] [Total PC billed inc recovery],
--dim_detail_claim.[notes_on_recovery] 
ISNULL(recovery_notes,'')  AS Notes1,
ISNULL(detailed_recovery_notes,'') AS [Notes2],
red_dw.dbo.dim_detail_core_details.incident_date,
red_dw.dbo.dim_matter_header_current.matter_owner_full_name  [Matter Owner],
red_dw..dim_detail_finance.output_wip_fee_arrangement  [Fee Type],
dim_detail_claim.[dst_insured_client_name] AS [Insured Client Name],
--red_dw.dbo.fact_detail_recovery_detail.amount_recovery_sought AS [Recovery Sought],
red_dw.dbo.fact_finance_summary.wip,
ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0) AS [Total Recovery],

CASE WHEN ISNULL(ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0),0) <=10000 
THEN (ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0))*0.18
WHEN ISNULL(ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0),0)>10000 THEN 10000 *0.18 + (ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0)-10000)*0.10  END 
AS TotalRecoverCalcPer,

red_dw.dbo.dim_claimant_thirdparty_involvement.tpinsurer_name AS [Claimant],
red_dw.dbo.fact_finance_summary.defence_costs_billed AS Revenue,
red_dw.dbo.fact_finance_summary.client_account_balance_of_matter AS [Client Balance of Matter], 

dim_detail_core_details.year_of_account [Year of Account ],

  DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, GETDATE())  [Elapsed Days]

,dim_detail_core_details.[proceedings_issued]
,recovery_sent_to_client
,date_ph_notified_re_indemnity
,date_notes_updated
,CASE WHEN ISNULL(amount_recovery_sought,0) <=10000 THEN amount_recovery_sought*0.18
WHEN ISNULL(amount_recovery_sought,0)>10000 THEN 10000 *0.18 + (amount_recovery_sought-10000)*0.10  END 
AS potential_fee_percent
,CASE WHEN ISNULL(recovery_notes,'')  IN ('monthly replayment (new)','Recovery Abandoned','Successful recovery')THEN 'N/A' ELSE chance_of_success_percent END AS chance_of_success_percent
,recoveries_year_of_account
,indemnity_granted_or_reason_refused
,HrsWorked.HrsWorked
,CASE WHEN ISNULL(recovery_notes,'')  IN ('monthly replayment (new)','Recovery Abandoned','Successful recovery')THEN 0
ELSE 
CAST((CASE WHEN ISNULL(amount_recovery_sought,0) <=10000 THEN amount_recovery_sought*0.18
WHEN ISNULL(amount_recovery_sought,0)>10000 THEN 10000 *0.18 + (amount_recovery_sought-10000)*0.10  END
) AS DECIMAL(10,2))  * (CAST(chance_of_success_percent AS DECIMAL(10,2)) /100)

END 
	
AS SuccessChance

,dim_detail_claim.[insured_vehicle_reg]

,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS fileStatus

,CASE WHEN PostLitFee.PostLitFeeType='Specified Judgment' AND amount_recovery_sought BETWEEN 25.00 AND 500.00 THEN 50.00 +22.00
WHEN PostLitFee.PostLitFeeType='Specified Judgment' AND amount_recovery_sought BETWEEN 500.01 AND 1000.00 THEN 70.00  +22.00
WHEN PostLitFee.PostLitFeeType='Specified Judgment' AND amount_recovery_sought BETWEEN 1000.01 AND 5000.00 THEN 80.00  +22.00
WHEN PostLitFee.PostLitFeeType='Specified Judgment' AND amount_recovery_sought >5000 THEN 100  +22.00
WHEN PostLitFee.PostLitFeeType='Defended over 3months to Trial' THEN 200
WHEN PostLitFee.PostLitFeeType='Defended within 3 months of Trial' THEN 300
WHEN PostLitFee.PostLitFeeType='SCT Fixed Costs' AND amount_recovery_sought BETWEEN 25.00 AND 500.00 THEN 50.00
WHEN PostLitFee.PostLitFeeType='SCT Fixed Costs' AND amount_recovery_sought BETWEEN 500.01 AND 1000.00 THEN 70.00
WHEN PostLitFee.PostLitFeeType='SCT Fixed Costs' AND amount_recovery_sought BETWEEN 1000.01 AND 5000.00 THEN 80.00
WHEN PostLitFee.PostLitFeeType='SCT Fixed Costs' AND amount_recovery_sought >5000 THEN 100
WHEN PostLitFee.PostLitFeeType='FT- Non Fixed Costs' THEN curFTNonFix
END AS PostLitFee
,PostLitFee.PostLitFeeType
,CASE WHEN ISNULL(amount_recovery_sought,0) BETWEEN 0 AND 500.00 THEN amount_recovery_sought *0.20
WHEN amount_recovery_sought BETWEEN 500.01 AND 2500.00 THEN amount_recovery_sought *0.15
WHEN amount_recovery_sought BETWEEN 2500.01 AND 5000.00 THEN amount_recovery_sought *0.10
WHEN amount_recovery_sought BETWEEN 5000.01 AND 10000.00 THEN amount_recovery_sought *0.5 END  +60.00
AS [PreLitFee]
FROM 
red_dw.dbo.fact_dimension_main 
LEFT JOIN  red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw..fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.fact_detail_client ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.fact_detail_recovery_detail ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.fact_bill_detail_summary ON fact_bill_detail_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key


LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
            ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = red_dw.dbo.fact_dimension_main.dim_claimant_thirdpart_key


        LEFT JOIN
        (
            SELECT fileID, 
                   assocType,
                   contName AS [Insurer Name],
                   dbAssociates.assocRef AS [Insurer Reference],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
					LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.ms_fileid=dbAssociates.fileID
            WHERE assocType = 'DEFENDANT'
			AND client_code='W15381'
        )

		        AS Defendant
            ON dim_matter_header_current.ms_fileid = Defendant.fileID
               AND Defendant.XOrder = 1

        LEFT JOIN
        (
            SELECT fileID,
                   assocType,
                   contName AS [TPName],
                   dbAssociates.assocRef AS [TPRef],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
					LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.ms_fileid=dbAssociates.fileID
            WHERE assocType = 'THIRDPARTY'
			AND client_code='W15381'
        )

		        AS THIRDPARTY
            ON dim_matter_header_current.ms_fileid = THIRDPARTY.fileID
               AND THIRDPARTY.XOrder = 1


			   
  LEFT JOIN
        (
            SELECT fileID,
                   assocType,
                   contName AS ClientName,
                   dbAssociates.assocRef AS ClientReference,
				   -- Needed to clean misc characters at end of client reference that trim doesn't sort
				   LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(dbAssociates.assocRef, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32)))) AS cleaned_client_ref,
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
					LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.ms_fileid=dbAssociates.fileID
            WHERE assocType = 'CLIENT'
			AND client_code='W15381'
        )

		        AS Client
            ON dim_matter_header_current.ms_fileid = Client.fileID
               AND Client.XOrder = 1

  LEFT JOIN
        (
            SELECT fileID,
                   assocType,
                   contName AS DriverName,
                   dbAssociates.assocRef AS DriverRef,
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
					LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.ms_fileid=dbAssociates.fileID
            WHERE assocType = 'DRIVER'
			AND client_code='W15381'
        )

		        AS DriverName
            ON dim_matter_header_current.ms_fileid = DriverName.fileID
               AND DriverName.XOrder = 1

LEFT OUTER JOIN (SELECT client_code,matter_number,SUM(wiphrs) AS HrsWorked
FROM red_dw.dbo.fact_all_time_activity
WHERE client_code='W15381'
GROUP BY client_code,matter_number) AS HrsWorked
 ON fact_dimension_main.client_code=HrsWorked.client_code
 AND fact_dimension_main.matter_number=HrsWorked.matter_number
LEFT OUTER JOIN (SELECT fileID,cboPostLitApp,cdDesc AS PostLitFeeType,curFTNonFix
FROM ms_prod.dbo.udMIRecoveries WITH(NOLOCK)
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup WITH(NOLOCK)
 ON cboPostLitApp=cdCode AND cdType='POSTLITFEE'
WHERE cboPostLitApp IS NOT NULL OR curFTNonFix IS NOT NULL) AS PostLitFee
 ON ms_fileid=PostLitFee.fileID
WHERE 
fact_dimension_main.client_code = 'W15381'
AND reporting_exclusions = 0 
AND
(
dim_detail_core_details.referral_reason='Recovery'
OR work_type_name   IN ('Debt Recovery','Contract'))
--AND ms_only= 1 

ORDER BY master_matter_number
END 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[HavenRecoveries]

AS

BEGIN 

SELECT  
Client.ClientName AS Client,
fact_dimension_main.client_code [Client Number],
fact_dimension_main.matter_number [Matter number],
Client.ClientReference AS [ClientRef],
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
Defendant.[Defendant Name] [Defendant Name ],
InsurerName.InsurerName [Insurer Name],
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
ISNULL(fact_detail_recovery_detail.[amount_recovery_sought],fact_detail_reserve_detail.[recovery_reserve]) [Recovery sought],
--fact_finance_summary.[total_recovery] [Amount recovered],
ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0) AS  [Amount recovered],
--(fact_detail_paid_detail.[total_damages_paid] +fact_finance_summary.[total_tp_costs_paid_to_date] ) - fact_finance_summary.[total_recovery] [Balance outstanding],

CASE WHEN balance_due_on_charging_order IS NOT NULL  THEN balance_due_on_charging_order
WHEN date_recovery_concluded IS NOT NULL THEN 0 ELSE
ISNULL(fact_detail_recovery_detail.[amount_recovery_sought],ISNULL(fact_detail_reserve_detail.[recovery_reserve],0)) - ( ISNULL(red_dw.dbo.fact_detail_recovery_detail.recovery_claimants_our_client_damages,0) + ISNULL(recovery_claimants_our_client_costs,0)) 
END [Balance outstanding],
fact_detail_client.[balance_due_on_charging_order] [Balance due on charging order],
dim_detail_claim.[date_recovery_concluded][Date recovery concluded],
dim_detail_claim.[date_of_charging_order]  [Date of charging order],
dim_detail_outcome.[recovery_claimants_our_client_damages] [Damages sent to client ],
fact_detail_recovery_detail.[recovery_claimants_our_client_costs] [Costs sent to client ],
    fact_finance_summary.[defence_costs_billed][Amount PC billed from recovery],
fact_bill_detail_summary.disbursements_billed_exc_vat + fact_finance_summary.vat_billed  [Amount billed for VAT & disbs from recovery],
fact_bill_detail_summary.disbursements_billed_exc_vat + fact_finance_summary.vat_billed +   fact_finance_summary.[defence_costs_billed] [Total PC billed inc recovery],
--dim_detail_claim.[notes_on_recovery] 
ISNULL(recovery_notes,'')  AS Notes1,
--ISNULL(detailed_recovery_notes,'') AS [Notes2],
dim_file_notes.external_file_notes AS [Notes2],
red_dw.dbo.dim_detail_core_details.incident_date,
red_dw.dbo.dim_matter_header_current.matter_owner_full_name  [Matter Owner],
red_dw..dim_detail_finance.output_wip_fee_arrangement  [Fee Type],
dim_detail_claim.[dst_insured_client_name] AS [Insured Client Name],
red_dw.dbo.fact_detail_recovery_detail.amount_recovery_sought AS [Recovery Sought],
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

, CASE	
	WHEN dim_matter_header_current.date_closed_practice_management IS NULL THEN	
		'Open'
	ELSE
		'Closed'
  END						AS [status]


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
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
            ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = red_dw.dbo.fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_file_notes
ON dim_file_notes.client_code = fact_dimension_main.client_code
AND dim_file_notes.matter_number = fact_dimension_main.matter_number

        LEFT JOIN
        (
            SELECT fileID, 
                   assocType,
                   contName AS [Defendant Name],
                   dbAssociates.assocRef AS [Defendant Reference],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
					LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.ms_fileid=dbAssociates.fileID
            WHERE assocType = 'DEFENDANT'
			AND client_code='H00001'
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
			AND client_code='H00001'
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
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
					LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.ms_fileid=dbAssociates.fileID
            WHERE assocType = 'CLIENT'
			AND client_code='H00001'
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
			AND client_code='H00001'
        )

		        AS DriverName
            ON dim_matter_header_current.ms_fileid = DriverName.fileID
               AND DriverName.XOrder = 1

LEFT JOIN
        (
            SELECT fileID,
                   assocType,
                   contName AS InsurerName,
                   dbAssociates.assocRef AS InsurerRef,
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            --SELECT DISTINCT dbAssociates.assocType
			FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
					LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.ms_fileid=dbAssociates.fileID
            WHERE assocType = 'INSURERCLIENT'
			AND client_code='H00001'
        )

		        AS InsurerName
            ON dim_matter_header_current.ms_fileid = InsurerName.fileID
               AND InsurerName.XOrder = 1

LEFT OUTER JOIN (SELECT client_code,matter_number,SUM(wiphrs) AS HrsWorked
FROM red_dw.dbo.fact_all_time_activity
WHERE client_code='H00001'
GROUP BY client_code,matter_number) AS HrsWorked
 ON fact_dimension_main.client_code=HrsWorked.client_code
 AND fact_dimension_main.matter_number=HrsWorked.matter_number

WHERE
dim_matter_header_current.master_client_code = 'H00001'
AND reporting_exclusions = 0 
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND ms_only= 1 
AND dim_fed_hierarchy_history.name='Rachel Houghton'


END 
GO

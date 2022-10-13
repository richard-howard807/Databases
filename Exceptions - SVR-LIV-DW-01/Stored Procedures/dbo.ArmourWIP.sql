SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-05-04
-- Description:	New report for Armour recovery files, 57421
-- JL - 20200512 added in worked hours as per ticket 57800 1.1
-- =============================================
CREATE PROCEDURE [dbo].[ArmourWIP]

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

SELECT RTRIM(dim_matter_header_current.client_code)+'-'+dim_matter_header_current.matter_number AS [Client/Matter Ref]
	, matter_description AS [Matter Description]
	, matter_owner_full_name AS [Matter Owner]
	, date_opened_case_management AS [Date Opened]
	, proceedings_issued AS [Proceedings Issued]
	, date_claim_concluded AS [Date Claim Concluded]
	, total_recovery AS [Total Recovered]
	, defence_costs_reserve AS [Defence Costs Reserve]
	, wip AS [WIP]
	, WIP.[WIP - Susan Carville]
	, WIP.[WIP - Ian Young]
	, WIP.[WIP - Andrew Sutton]
	, WIP.[WIP - Laura Moore]
	, WIP.[WIP - Chris Ball]
	, WIP.[WIP - Other]
	, HoursBilled.[Total Hours Billed]
	, HoursBilled.[Hours Billed - Susan Carville]
	, HoursBilled.[Hours Billed - Ian Young]
	, HoursBilled.[Hours Billed - Andrew Sutton]
	, HoursBilled.[Hours Billed - Laura Moore]
	, HoursBilled.[Hours Billed - Chris Ball]
	, HoursBilled.[Hours Billed - Other]
	, WorkedHours.[Worked Hours - Susan Carville] 
	, WorkedHours.[Worked Hours - Ian Young] 
	, WorkedHours.[Worked Hours - Andrew Sutton]
	, WorkedHours.[Worked Hours - Laura Moore] 
	, WorkedHours.[Worked Hours - Chris Ball] 
	, WorkedHours.[Worked Hours - Other] 
	, WorkedHours.HoursRecorded
	, defence_costs_billed AS [Revenue]
	, client_account_balance_of_matter AS [Client Balance]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

LEFT OUTER JOIN (SELECT client
	, matter
	, SUM(wip_minutes) wip_minutes
	, SUM(wip_value) wip_value
	, SUM(CASE WHEN name ='Susan Carville' THEN wip_value ELSE NULL END) AS [WIP - Susan Carville]
	, SUM(CASE WHEN name ='Ian Young' THEN wip_value ELSE NULL END) AS [WIP - Ian Young]
	, SUM(CASE WHEN name ='Andrew Sutton' THEN wip_value ELSE NULL END) AS [WIP - Andrew Sutton]
	, SUM(CASE WHEN name ='Laura Moore' THEN wip_value ELSE NULL END) AS [WIP - Laura Moore]
	, SUM(CASE WHEN name ='Chris Ball' THEN wip_value ELSE NULL END) AS [WIP - Chris Ball]
	, SUM(CASE WHEN NOT (name IN ('Susan Carville','Ian Young','Andrew Sutton','Laura Moore','Chris Ball')) THEN wip_value ELSE NULL END) AS [WIP - Other]
FROM red_dw.dbo.fact_wip
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_wip.dim_fed_hierarchy_history_key
WHERE client='00752920'
AND matter_owner='1856'
GROUP BY client,
         matter) AS WIP 
		 ON dim_matter_header_current.client_code=WIP.client AND dim_matter_header_current.matter_number=WIP.matter



LEFT OUTER JOIN (SELECT client_code_bill_item,
					   matter_number_bill_item,
                       master_fact_key,
					   SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue],
					   SUM(fact_bill_detail.bill_hours) AS [Total Hours Billed], 
                       SUM(CASE WHEN name ='Susan Carville' THEN fact_bill_detail.bill_hours ELSE 0 END ) AS [Hours Billed - Susan Carville],
                       SUM(CASE WHEN name ='Ian Young' THEN fact_bill_detail.bill_hours ELSE 0 END) AS [Hours Billed - Ian Young],
					   SUM(CASE WHEN name ='Andrew Sutton' THEN fact_bill_detail.bill_hours ELSE  0  END ) AS [Hours Billed - Andrew Sutton],
					   SUM(CASE WHEN name ='Laura Moore' THEN fact_bill_detail.bill_hours ELSE  0  END) AS [Hours Billed - Laura Moore],
					   SUM(CASE WHEN name ='Chris Ball' THEN fact_bill_detail.bill_hours ELSE  0  END) AS [Hours Billed - Chris Ball],
                       SUM(CASE WHEN name <> 'Susan Carville'
                              AND name <> 'Ian Young'
                              AND name <> 'Andrew Sutton'
                              AND name <> 'Laura Moore'
							  AND name <> 'Chris Ball'
                                 THEN   fact_bill_detail.bill_hours ELSE  0 END ) AS [Hours Billed - Other]
                FROM red_dw.dbo.fact_bill_detail
                    LEFT OUTER JOIN
                    (
                        SELECT DISTINCT
                               dim_fed_hierarchy_history_key,
                               name
                        FROM red_dw.dbo.dim_fed_hierarchy_history
                    ) AS FeeEarners
                        ON FeeEarners.dim_fed_hierarchy_history_key = fact_bill_detail.dim_fed_hierarchy_history_key
                WHERE charge_type='time'
					  AND fact_bill_detail.client_code_bill_item IN ('00752920')
					  --AND matter_number_bill_item='00000084'
                GROUP BY client_code_bill_item,
                         matter_number_bill_item,
                         master_fact_key) AS [HoursBilled] ON HoursBilled.master_fact_key = fact_dimension_main.master_fact_key
						 
--****HOURS WORKED (JL ADDED AS PER TICKET  57800 1.1)*****
LEFT OUTER JOIN (
SELECT 
                
SUM(minutes_recorded) / 60 AS [HoursRecorded]
,SUM(minutes_recorded) AS [MinutesRecorded]
,ct.master_fact_key
,SUM(CASE WHEN FeeEarners.name ='Susan Carville' THEN ct.minutes_recorded ELSE NULL END) /60 AS [Worked Hours - Susan Carville]
	, SUM(CASE WHEN name ='Ian Young' THEN ct.minutes_recorded ELSE NULL END) / 60 AS [Worked Hours - Ian Young]
	, SUM(CASE WHEN name ='Andrew Sutton' THEN ct.minutes_recorded ELSE NULL END) / 60 AS [Worked Hours - Andrew Sutton]
	, SUM(CASE WHEN name ='Laura Moore' THEN ct.minutes_recorded ELSE NULL END) / 60 AS [Worked Hours - Laura Moore]
	, SUM(CASE WHEN name ='Chris Ball' THEN ct.minutes_recorded ELSE NULL END) / 60 AS [Worked Hours - Chris Ball]
	, SUM(CASE WHEN NOT (name IN ('Susan Carville','Ian Young','Andrew Sutton','Laura Moore','Chris Ball')) THEN ct.minutes_recorded ELSE NULL END) / 60 AS [Worked Hours - Other]

FROM red_dw.dbo.fact_chargeable_time_activity AS ct 

LEFT OUTER JOIN(

	 SELECT DISTINCT
	 dim_fed_hierarchy_history_key,
	 name
	 FROM red_dw.dbo.dim_fed_hierarchy_history
  )AS FeeEarners
ON FeeEarners.dim_fed_hierarchy_history_key = ct.dim_fed_hierarchy_history_key

GROUP BY
ct.master_fact_key

) AS WorkedHours
ON WorkedHours.master_fact_key = fact_dimension_main.master_fact_key
-----1.1 jl

WHERE dim_matter_header_current.master_client_code='752920'
AND reporting_exclusions=0
AND matter_owner_full_name='Sam Gittoes'

END
GO

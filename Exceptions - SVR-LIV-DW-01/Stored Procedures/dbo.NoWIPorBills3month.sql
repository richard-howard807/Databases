SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		orlagh kelly
-- Create date: 31-07-2018
-- Description:	 Stored Procedure to drive the no wip or Bills on a matter in 3 months/ report is stored in the HST -TM Folder 
						
 --=============================================
CREATE PROCEDURE [dbo].[NoWIPorBills3month]


AS
BEGIN

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED




SELECT 
fee_earner.hierarchylevel2hist [division]
,fee_earner.hierarchylevel3hist [department]
,fee_earner.hierarchylevel4hist [team]
,matter.matter_owner_full_name
,outcome
,matter.date_opened_case_management
, matter.final_bill_date [Final Bill Date]
,matter.client_group_name
,REPLACE(REPLACE(REPLACE(matter.client_name,CHAR(10),'') ,CHAR(13),''),CHAR(9),'') client_name
,matter.client_code
,matter.matter_number
,outcome.outcome_of_case
,finance.wip [total_wip]
,finance.total_amount_billed
,finance.defence_costs_billed [total_defence_costs_billed]
--,finance.defence_costs_billed_composite
,finance.unpaid_bill_balance
,last_bill_date.last_bill_date [Last bill date ]
,bill.bill_flag 


, case when bill.bill_flag = 'f' then 'Final'
		when bill.bill_flag = 'i' then 'Interim' 
		else 'Incomplete' 
		end as [Interim or Final]

,bill.bill_number
,last_time_posted.last_posting_date [Last time worked ]



FROM red_dw.dbo.dim_matter_header_current matter
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history fee_earner ON matter.fee_earner_code = fee_earner.fed_code AND fee_earner.dss_current_flag = 'Y'
INNER JOIN red_dw.dbo.dim_detail_outcome outcome ON outcome.client_code = matter.client_code AND outcome.matter_number = matter.matter_number
INNER JOIN red_dw.dbo.fact_finance_summary finance ON finance.client_code = matter.client_code AND finance.matter_number = matter.matter_number
INNER join red_dw.dbo.fact_dimension_main on fact_dimension_main.client_code = finance.client_code and fact_dimension_main.matter_number = finance.matter_number
		--, dim_date_last_time.last_time_calendar_date


LEFT JOIN (SELECT dim_matter_header_curr_key
FROM [red_dw].[dbo].[fact_bill_matter_detail]
WHERE dim_bill_date_key BETWEEN 20180201 AND 201805018
) billed ON billed.dim_matter_header_curr_key = matter.dim_matter_header_curr_key
LEFT JOIN (SELECT dim_matter_header_curr_key 
FROM red_dw.dbo.fact_all_time_activity 
WHERE dim_gl_date_key BETWEEN '20180201' AND '20180518' AND chargeable_nonc_nonb IN ('C','NC')
AND reporting_exclusions <> 1
) wip ON wip.dim_matter_header_curr_key = matter.dim_matter_header_curr_key

LEFT OUTER JOIN (SELECT dim_matter_header_curr_key,MAX(dim_bill_key) max_dim_bill_key, MAX(bill.bill_date) [last_bill_date] 
FROM [red_dw].[dbo].[fact_bill_matter_detail] bill
GROUP BY dim_matter_header_curr_key
) last_bill_date ON last_bill_date.dim_matter_header_curr_key = matter.dim_matter_header_curr_key

LEFT OUTER JOIN red_dw.dbo.dim_bill bill ON last_bill_date.max_dim_bill_key = bill.dim_bill_key


LEFT OUTER JOIN (SELECT dim_matter_header_curr_key,MAX(posting_date.calendar_date) [last_posting_date]
FROM red_dw.dbo.fact_all_time_activity 
INNER JOIN red_dw.dbo.dim_date posting_date ON posting_date.dim_date_key = fact_all_time_activity.dim_gl_date_key
WHERE  chargeable_nonc_nonb IN ('C','NC')
AND reporting_exclusions <> 1
GROUP BY dim_matter_header_curr_key
) last_time_posted  ON last_time_posted.dim_matter_header_curr_key = matter.dim_matter_header_curr_key

--LEFT OUTER JOIN (

WHERE matter.date_closed_case_management IS NULL
AND matter.reporting_exclusions <> 1
AND matter.matter_number <>'ML'
AND ISNULL(outcome.outcome_of_case,'') <> 'Exclude from reports'
AND billed.dim_matter_header_curr_key IS NULL  -- no bills
AND wip.dim_matter_header_curr_key IS NULL -- no wip
AND UPPER(matter.client_name) NOT LIKE '%TEST%'
AND UPPER(matter.client_name) NOT LIKE '%ERROR%' 
AND fee_earner.hierarchylevel2hist not in ('Business Services' , 'Client Relationships' , 'Operations' )
--and matter.date_opened_case_management>= '01-01-2014'







end 
GO

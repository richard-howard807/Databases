SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
===================================================
===================================================
Author:				Emily Smith
Created Date:		2021-06-29
Description:		This is a copy of the surrey and sussex police sproc
					#104524 Request a new police report to be made available
					Police use composite billing, but this report looks at the amount on the matter and gives the associated profit costs between bill dates. 
Current Version:	Initial Create
====================================================
====================================================

*/
CREATE PROCEDURE [dbo].[British_Transport_Police_Listing_Reports]  --'2017-05-01', '2021-06-29'
(
 @StartFY as date,
@EndFY as date
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED



SELECT
 fact_dimension_main.client_code [Client Code]
, fact_dimension_main.matter_number [Matter Number]
, client_name AS [Client Name]
, matter_description AS [Matter Description]
, matter_owner_full_name AS [Matter Owner]
, date_opened_case_management AS [Date Case Opened]
, date_closed_case_management AS [Date Case Closed]
, work_type_name AS [Work Type]
, dim_detail_claim.[source_of_instruction] AS [Source of Instruction]
, dim_detail_claim.district AS District
, dim_detail_advice.sussex_police_stations
, dim_detail_claim.borough AS [Borough]
, surrey_police_stations 
, fee_earner_code
, hierarchylevel4hist AS Team
,dbo.PoliceWorkTypes.GroupWorkTypeLookup
--,bill_total AS [Total Billed to date]
--,fees_total as [Profit Costs to date]
,Billed.TotalBilled as [Total Billed]
,Billed.ProfitCostsBilled as [Profit Costs]
,Billed.[Disbursementsincvat] AS Disbursements



from red_dw..fact_dimension_main
left join red_dw..dim_matter_header_current on fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
left join red_dw..dim_fed_hierarchy_history on dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code and dim_fed_hierarchy_history.dss_current_flag = 'Y'
left join red_dw..fact_bill_matter on fact_dimension_main.master_fact_key = fact_bill_matter.master_fact_key
left join red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
left join red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
left join red_dw.dbo.dim_detail_advice ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
left join reporting.[dbo].[PoliceWorkTypes] ON red_dw.dbo.dim_matter_worktype.work_type_name = [dbo].[PoliceWorkTypes].[Work Type] COLLATE DATABASE_DEFAULT
inner join 
       (                       
              select
              client_code
              ,dim_matter_header_curr_key
              ,matter_number
              ,sum(bill_total) as TotalBilled
              ,sum(fees_total) as ProfitCostsBilled
              ,sum(hard_costs + soft_costs + other_costs + vat) as [Disbursementsincvat]
              
              from red_dw..fact_bill_matter_detail  --
			  where  bill_date between @StartFY and @EndFY
              and client_code IN ('09008076') 
              
              group by 
              client_code,matter_number, dim_matter_header_curr_key 
              having sum(bill_total) <>0
       ) as Billed
       on fact_dimension_main.dim_matter_header_curr_key = Billed.dim_matter_header_curr_key

WHERE 
dim_matter_header_current.client_code IN ('09008076') 
AND dim_matter_header_current.matter_number <>'ML'

END

GO

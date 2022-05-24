SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2017-10-12
Description:		This drives the Police listing report for Sussex and Surrey. Sussex and Surrey use composite billing, but this report looks at the amount on the matter and gives the associated profit costs between bill dates. 
Current Version:	Initial Create
====================================================
--ES 2022/03/16 #139463, added suffolk client code 817395
--JL 2022/04/19 #143521, added new field for area column 
--JB 2022/05/24 #149458, added new Surrey Police fields
====================================================

*/
CREATE PROCEDURE [dbo].[SussexandSurreyPolice_Listing_Reports]  --'2017-05-01', '2017-10-12'
(
 @StartFY as date,
@EndFY as date
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--DECLARE @StartFY AS DATE = (SELECT MIN(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.current_fin_year = 'Current')
--		, @EndFY AS DATE = CAST(GETDATE() AS DATE)

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
,dim_detail_core_details.suffolk_police_area

, dim_detail_client.surrey_pol_division_where_claim_arises		AS [SP Division]
, dim_detail_client.surrey_pol_type_of_negligence_claim			AS [Neg Type]
, dim_detail_client.surrey_pol_lessons_learnt_paid_claims	AS [Lessons]

from red_dw..fact_dimension_main
left join red_dw..dim_matter_header_current on fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
left join red_dw..dim_fed_hierarchy_history on dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code and dim_fed_hierarchy_history.dss_current_flag = 'Y'
left join red_dw..fact_bill_matter on fact_dimension_main.master_fact_key = fact_bill_matter.master_fact_key
left join red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
left join red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
left join red_dw.dbo.dim_detail_advice ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
left join red_dw.dbo. dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
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
              and client_code IN ('00451638' , '00113147','00817395') 
              
              group by 
              client_code,matter_number, dim_matter_header_curr_key 
              having sum(bill_total) <>0
       ) as Billed
       on fact_dimension_main.dim_matter_header_curr_key = Billed.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE 
dim_matter_header_current.client_code IN ('00451638' , '00113147','00817395') 
AND dim_matter_header_current.matter_number <>'ML'

END

  





GO

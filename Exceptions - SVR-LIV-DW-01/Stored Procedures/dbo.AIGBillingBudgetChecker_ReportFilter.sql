SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[AIGBillingBudgetChecker_ReportFilter]

AS

SELECT ms_fileid,
RTRIM(dim_detail_client.client_code) client_code,
RTRIM(dim_detail_client.matter_number) matter_number,
matter_description,
dim_matter_header_current.master_client_code + '-' +master_matter_number AS [Elite Matter],
dim_matter_header_current.client_name,
insuredclient_name AS [Insured Name],
is_insured_vat_registered,
total_budget_uploaded,
has_budget_been_approved,
aig_current_fee_scale,
aig_litigation_number,
fact_dimension_main.master_fact_key,
fact_finance_summary.portal_bill_total_excl_vat,
profstatus,
loadnumber,
altnumber,
dim_detail_core_details.fixed_fee,
dim_detail_client.aig_rates_assigned_in_ascent			AS [LIT Number Rates in ASCENT],
CASE WHEN 
dim_matter_header_current.fee_arrangement  = 'Fixed Fee/Fee Quote/Capped Fee                              ' THEN 'Fixed Fee'
WHEN dim_matter_header_current.fee_arrangement  IN
(
'Hourly rate                                                 ',
'Hourly Rate                                                 ',
'Hourly rate                                                 '
)
THEN 'Hourly' ELSE ' '
END AS [LIT Type], 

CASE WHEN dim_detail_core_details.fixed_fee = 'No' THEN 
ISNULL(fact_detail_cost_budgeting.[aigtotalbudgethourlyrate], 0) + ISNULL(fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget] , 0 )
WHEN dim_detail_core_details.fixed_fee = 'Yes' THEN 
ISNULL(fact_detail_cost_budgeting.[aigtotalbudgetfixedfee], 0)+ ISNULL(fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget], 0)

END AS [Total Budget in MS]
, prof.portal_bill_total_excl_vat_vew
	FROM red_dw.dbo.fact_dimension_main 
	LEFT JOIN red_dw.dbo.fact_finance_summary ON  fact_dimension_main.master_fact_key = red_dw.dbo.fact_finance_summary.master_fact_key
	LEFT JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT JOIN red_dw.dbo.dim_detail_client ON  fact_dimension_main.dim_detail_client_key = dim_detail_client.dim_detail_client_key 
	LEFT JOIN red_dw.dbo.fact_detail_cost_budgeting ON fact_detail_cost_budgeting.master_fact_key = fact_finance_summary.master_fact_key
	LEFT JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT JOIN (
				SELECT aig_litigation_number lit_number,SUM(portal_bill_total_excl_vat) lit_total 
				from red_dw.dbo.fact_dimension_main 
				LEFT JOIN red_dw.dbo.fact_finance_summary ON  fact_dimension_main.master_fact_key = red_dw.dbo.fact_finance_summary.master_fact_key
				LEFT JOIN red_dw.dbo.dim_detail_client ON  fact_dimension_main.dim_detail_client_key = dim_detail_client.dim_detail_client_key  
				GROUP BY aig_litigation_number
				HAVING SUM(portal_bill_total_excl_vat) > 0 --and aig_litigation_number IS NOT null
			  ) lit_number ON lit_number.lit_number = aig_litigation_number

	-- RH 22/03/2022 -- changed logic below to match portal billing report following 3e upgrade
	 LEFT JOIN  (SELECT profstatus,altnumber,loadnumber, sum(ISNULL(ds_sh_3e_profmaster.totamt,0) - ISNULL(ds_sh_3e_profmaster.taxamt,0)) portal_bill_total_excl_vat_vew 
				from red_dw.dbo.ds_sh_3e_profmaster
				LEFT JOIN red_dw.dbo.ds_sh_3e_matter ON leadmatter = mattindex
				 JOIN TE_3E_Prod..NxWfItemStep (nolock) as NxWfItemStep ON NxWfItemStep.JoinID = ds_sh_3e_profmaster.profmasterid and NxWfItemStep.NxWFStepState = 1 
				where  1 = 1 
				--AND ds_sh_3e_profmaster.invmaster is null
				and ds_sh_3e_profmaster.profstatus not in ('Billed','RejectApproval','CL','CL_WM')
				group by ds_sh_3e_profmaster.profstatus
					   , ds_sh_3e_matter.altnumber
					   , ds_sh_3e_matter.loadnumber) prof 
	ON loadnumber COLLATE DATABASE_DEFAULT = LTRIM(RTRIM(dim_detail_client.client_code)) +'-'+LTRIM(RTRIM(dim_detail_client.matter_number)) COLLATE DATABASE_DEFAULT OR 
	prof.altnumber COLLATE DATABASE_DEFAULT = LTRIM(RTRIM(dim_detail_client.client_code)) +'-'+LTRIM(RTRIM(dim_detail_client.matter_number)) COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
	 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
	 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number

WHERE 1 = 1
AND (prof.portal_bill_total_excl_vat_vew > 0  OR  portal_bill_total_excl_vat > 0 )
and profstatus  in ('Approved' )    --, 'Tier2', 'BTKApprove')
and altnumber LIKE 'A2002%'

--/*Testing*/
--and dim_matter_header_current.ms_fileid IN 

--(
--SELECT ms_fileid FROM red_dw.dbo.dim_matter_header_current
--WHERE master_client_code + '-' + master_matter_number IN ( 'A2002-16544')
--)

ORDER BY  prof.altnumber



--SELECT profstatus,altnumber,loadnumber, sum(ISNULL(ds_sh_3e_profmaster.totamt,0) - ISNULL(ds_sh_3e_profmaster.taxamt,0)) portal_bill_total_excl_vat_vew 
--				from red_dw.dbo.ds_sh_3e_profmaster
--				LEFT JOIN red_dw.dbo.ds_sh_3e_matter ON leadmatter = mattindex
--				  JOIN TE_3E_Prod..NxWfItemStep (nolock) as NxWfItemStep ON NxWfItemStep.JoinID = ds_sh_3e_profmaster.profmasterid and NxWfItemStep.NxWFStepState = 1 
--				where 1 = 1
--				--AND ds_sh_3e_profmaster.invmaster is null
--				and ds_sh_3e_profmaster.profstatus not in ('Billed','RejectApproval','CL','CL_WM')
--				AND altnumber = 'A2002-00016544'
--				group by ds_sh_3e_profmaster.profstatus
--					   , ds_sh_3e_matter.altnumber
--					   , ds_sh_3e_matter.loadnumber




GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[dm_FixedFeeAccuracy] as

select
fact_finance_summary.client_code + '-' + fact_finance_summary.matter_number as matter_number, 
fact_finance_summary.fixed_fee_amount,
time_charge_value,
prof.cost_of_time,
prof.cost_of_time - fact_finance_summary.fixed_fee_amount as 'difference',
rtrim(isnull(dim_detail_core_details.credit_hire, 'No')) as 'credit_hire',
rtrim(isnull(case when does_claimant_have_personal_injury_claim in ('Don''t know', 'N') then 'No' 
	       when does_claimant_have_personal_injury_claim in ('Y') then 'Yes' 
		   else does_claimant_have_personal_injury_claim end, 'No')) does_claimant_have_personal_injury_claim,
rtrim(isnull(case when has_the_claimant_got_a_cfa = 'N' then 'No' when has_the_claimant_got_a_cfa = 'Y' then 'Yes' when has_the_claimant_got_a_cfa = '' then null else has_the_claimant_got_a_cfa end, 'No')) has_the_claimant_got_a_cfa,
isnull(rtrim(case when proceedings_issued = 'Y' then 'Yes'
           when proceedings_issued = 'N' then 'No' 
		   else proceedings_issued end), 'No') proceedings_issued,
rtrim(LOWER(isnull(case when rtrim(lower(referral_reason)) in ('adv', 'dolq', 'inquest', 'nomination only', 'recovery', 'paid', 'hse prosecution', 'pad', 'doq', 'pre-action disclosure', 'advice only', 'dispute on liability', 'costs dispute', 'infant approval') then 'Other' else referral_reason end, 'None'))) referral_reason,
rtrim(isnull(case when dim_detail_core_details.delegated = 'yes' then 'Yes' else dim_detail_core_details.delegated end, 'No')) delegated,
rtrim(isnull(case when lower(is_there_an_issue_on_liability) = 'don''t know' then 'No' when is_there_an_issue_on_liability = '' then null else is_there_an_issue_on_liability end, 'No')) is_there_an_issue_on_liability,
case when datediff(year,claimants_date_of_birth, GETDATE()) < 0 then null 
     when datediff(year,claimants_date_of_birth, GETDATE()) > 100 then null 
	 else datediff(year,claimants_date_of_birth, GETDATE()) end as claimants_age,
dim_matter_header_current.date_opened_practice_management as 'date_opened',
--dim_matter_header_current.date_closed_practice_management as 'date_closed',
isnull(rtrim(sd_listxt), 'None') as injury_type,
case when injury_type_group.Site in ('Ear', 'Neck') then injury_type_group.Site else 'Other' end as 'injury_type_site',
injury_type_group.Severity as 'injury_type_severity',
lower(rtrim(isnull(case when track = 'SMALL' then 'Small Claims' when track = 'FAST' then 'Fast Track' else track end, 'None'))) as track,
rtrim(lower(isnull(case when lower(outcome_of_case) like 'assessment%' then 'assessment of damages'
				 when lower(outcome_of_case) like 'discontinued%' then 'discontinued'
				 when lower(outcome_of_case) like 'lost at trial%' then 'lost at trial'
				 when lower(outcome_of_case) like 'settled%' then 'settled'
				 when lower(outcome_of_case) like 'struck out%' then 'struck out'
				 when lower(outcome_of_case) like 'won at trial%' then 'won at trial'
			--else 'other' 
			end, 'None'))) as outcome_of_case,
damages_paid,
case when lower(outcome_of_case) like 'assessment%' or lower(outcome_of_case) like 'lost at trial%' or lower(outcome_of_case) like 'settled%'
then 'No'
when  lower(outcome_of_case) like 'discontinued%' or  lower(outcome_of_case) like 'struck out%' or lower(outcome_of_case) like 'won at trial%'
then 'Yes'
else 'No outcome'
end as repudiated,
claimant_costs_reserve_current,
chargeable_minutes_recorded / 60 as hours_recorded,
fact_detail_reserve_detail.damages_reserve,
fact_detail_reserve_detail.defence_costs_reserve,
date_claim_concluded,
dcc.fin_month_no as date_claim_concluded_month_no,
dcc.fin_year as date_claim_concluded_fin_year,
fact_detail_reserve_detail.total_reserve,
DATEDIFF(DAY, dim_matter_header_current.date_opened_practice_management, dim_date.calendar_date) as elapsed_days,
case when DATEDIFF(year, admissiondateud, dim_matter_header_current.date_opened_practice_management) < 0 then 0 
     when DATEDIFF(year, admissiondateud, dim_matter_header_current.date_opened_practice_management) > 30 then 30
	 else DATEDIFF(year, admissiondateud, dim_matter_header_current.date_opened_practice_management) end as matter_owner_pqe,
dim_fed_hierarchy_history.fte,
case when lower(dim_fed_hierarchy_history.jobtitle) in ('paralegal', 'solicitor', 'associate', 'partner') then dim_fed_hierarchy_history.jobtitle 
     when LOWER(dim_fed_hierarchy_history.jobtitle) like '%legal exec%' then 'Legal Executive'
	 when LOWER(dim_fed_hierarchy_history.jobtitle) like '%costs%' then 'Other'
	 when LOWER(dim_fed_hierarchy_history.jobtitle) in ('trainee solicitor', 'trainee', 'administration assistant') then 'Paralegal'
	 when LOWER(dim_fed_hierarchy_history.jobtitle) in ('plot sales executive') then 'Solicitor'
	 when LOWER(dim_fed_hierarchy_history.jobtitle) in ('technical manager', 'team leader') then 'Associate'
else 'Other' end as 'jobtitle',
hierarchylevel3hist as 'department',
hierarchylevel4hist as 'team',
name,
rtrim(lower(case when branch_name in ('Birmingham', 'Liverpool') then branch_name else 'Other' end)) as 'branch_name',
rtrim(dim_matter_worktype.work_type_group) as 'work_type_group',
dim_instruction_type.instruction_type,
case when isnull(dim_client.client_group_name, 'Individual') in (
'Aon', 'Aviva', 'Axa CS', 'Cheshire East Council', 'Cheshire West & Cheshire Council', 'Crawford & Co' ,'Gallagher Bassett', 'Greater Manchester Police', 'Halton BC',
'JCB', 'Merseyside Police', 'Metropolitan Police', 'North Wales Police', 'Vinci', 'Warwickshire County Council', 'Wirral MBC', 'Individual')
then 'Other' else dim_client.client_group_name end as 'client_group_name',
client_partner_name,
segment,
sector,
sub_sector



from red_dw.dbo.fact_dimension_main 

inner join red_dw.dbo.dim_detail_core_details on dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
inner join red_dw.dbo.fact_finance_summary on fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
left join red_dw.dbo.load_artiion_stdetlst on sd_liscod = dim_detail_core_details.injury_type and sd_detcod = 'WPS027'
inner join red_dw.dbo.dim_detail_outcome on dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
inner join red_dw.dbo.fact_detail_reserve_detail  on fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
inner join red_dw.dbo.fact_matter_summary_current on fact_matter_summary_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
inner join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_matter_summary_current.dim_fed_hierarchy_history_key
inner join red_dw.dbo.dim_date on dim_date.dim_date_key = fact_matter_summary_current.dim_last_transaction_date_key
left join red_dw.dbo.dim_employee on dim_employee.employeeid = dim_fed_hierarchy_history.employeeid
inner join red_dw.dbo.dim_matter_header_current on dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
inner join red_dw.dbo.dim_matter_worktype on dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
inner join red_dw.dbo.dim_client on dim_client.dim_client_key = fact_dimension_main.dim_client_key
inner join red_dw.dbo.dim_date dcc on dcc.calendar_date = date_claim_concluded
inner join (select  fact_profitability.dim_matter_header_curr_key, sum(fact_profitability.cost_of_time_act) cost_of_time, SUM(fact_profitability.chargeable_minutes) prof_cm, p.minutes_recorded from red_dw.dbo.fact_profitability
inner join (select  dim_matter_header_curr_key, sum(minutes_recorded) minutes_recorded  from red_dw.dbo.fact_billable_time_activity group by dim_matter_header_curr_key) p 
	on p.dim_matter_header_curr_key = fact_profitability.dim_matter_header_curr_key
group by fact_profitability.dim_matter_header_curr_key, p.minutes_recorded
having SUM(fact_profitability.chargeable_minutes) = p.minutes_recorded) as prof	on prof.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
left join Reporting.dbo.injury_type_group on injury_type_group.[Injury Type] = isnull(rtrim(sd_listxt), 'None') collate database_default
left join red_dw.dbo.dim_instruction_type on dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key


where 
dim_detail_core_details.fixed_fee = 'Yes'
and fact_finance_summary.fixed_fee_amount <> 0 and fact_finance_summary.fixed_fee_amount = defence_costs_billed --and ISNULL(time_charge_value, 0) <> 0
and date_claim_concluded >= '2015-05-01' and date_claim_concluded < '2018-05-01'
--and dim_fed_hierarchy_history.hierarchylevel2hist in ('Legal Ops - Claims', 'Legal Ops - LTA')
and DATEDIFF(DAY, dim_matter_header_current.date_opened_practice_management, dim_date.calendar_date) >= 0 
and rtrim(isnull(case when is_this_a_linked_file = '' then null when is_this_a_linked_file = 'N' then 'No' else is_this_a_linked_file end, 'No')) != 'Yes'
and rtrim(isnull(case when suspicion_of_fraud = 'Y' then 'Yes' when suspicion_of_fraud = 'N' then 'No' when suspicion_of_fraud = 'YES' then 'Yes' else suspicion_of_fraud end, 'No')) != 'Yes'

/* outlier removal */
--and fact_finance_summary.fixed_fee_amount <= 1500
--and ISNULL(damages_paid, 0) <= 10000
--and ISNULL(claimant_costs_reserve_current, 0) <= 20000
--and ISNULL(fact_detail_reserve_detail.damages_reserve, 0) <= 10000
--and ISNULL(fact_detail_reserve_detail.defence_costs_reserve, 0) <= 5000
--and DATEDIFF(DAY, dim_matter_header_current.date_opened_practice_management, dim_date.calendar_date) <= 1500
--and rtrim(dim_matter_worktype.work_type_group) not in ('NHSLA', 'Recovery', 'Other', 'Insurance Costs', 'Healthcare')
--and hierarchylevel3hist not in ('Converge', 'Corp-Comm', 'EPI', 'Information Systems', 'Large Loss', 'Litigation', 'Real Estate', 'Regulatory')
--and lower(rtrim(isnull(case when track = 'SMALL' then 'Small Claims' when track = 'FAST' then 'Fast Track' else track end, 'None'))) not in ('multi track')





GO

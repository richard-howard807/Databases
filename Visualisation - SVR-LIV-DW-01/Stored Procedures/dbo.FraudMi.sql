SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2022-03-17
Description:		Fraud MI
====================================================
*/

CREATE PROCEDURE [dbo].[FraudMi]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @start_date AS DATE = (SELECT CAST(DATEADD(YEAR, -3, MIN(dim_date.calendar_date)) AS DATE)	AS report_start_date FROM red_dw.dbo.dim_date WHERE	dim_date.current_fin_year = 'Current')

--SELECT @start_date

SELECT
	dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [MS Reference]
	, dim_matter_header_current.matter_description		AS [Matter Description]
	, dim_matter_worktype.work_type_name		AS [Matter Type Name]
	, dim_matter_worktype.work_type_group		AS [Matter Type Group]
	, dim_fed_hierarchy_history.name		AS [Matter Owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist		AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist		AS [Department]
	, RTRIM(COALESCE(NULLIF(dim_client.client_group_name, ''), dim_client.client_name))			AS [Client Name]
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)		AS [Date Opened]
	, dim_date_open.fin_year		AS [Opened Financial Year]
	, dim_date_open.fin_month_name		AS [Opened Month]
	, dim_date_open.fin_month_no		AS [Opened Month No]
	, 'Q' + CAST(dim_date_open.fin_quarter_no AS NVARCHAR(1))	AS [Opened Quarter]
	, IIF(dim_date_open.fin_quarter_no IN (1,2), 'May - Oct', 'Nov - Apr')		AS [Opened Half Years]
	, CAST(dim_matter_header_current.date_closed_case_management AS DATE)		AS [Date Closed]
	, CASE
		WHEN RTRIM(LOWER(dim_detail_core_details.present_position)) IN ('final bill sent - unpaid', 'to be closed/minor balances to be clear') 
		OR dim_matter_header_current.date_closed_case_management IS NOT NULL THEN
			'Closed'
		ELSE
			'Open'
	  END					AS [Matter Status]
	, dim_detail_core_details.present_position		AS [Present Position]
	, dim_detail_core_details.suspicion_of_fraud	AS [Suspicion of Fraud]
	, CASE 
		WHEN dim_detail_critical_mi.[litigated]='Yes' OR dim_detail_core_details.[proceedings_issued]='Yes' THEN 
			'Litigated' 
		ELSE 
			'Pre-Litigated' 
	  END											AS [Litigated/Proceedings Issued]
	, CASE 
		WHEN dim_detail_core_details.present_position = 'Claim and costs outstanding' AND dim_matter_header_current.date_closed_case_management IS NULL 
		AND CAST(dim_detail_outcome.date_claim_concluded AS DATE) IS NULL THEN
			'Live'
		ELSE
			'Concluded'
	  END			AS claim_status
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)				AS [Date Claim Concluded]
	, dim_date_concluded.fin_year		AS [Concluded Financial Year]
	, dim_date_concluded.fin_month_name		AS [Concluded Month]
	, 'Q' + CAST(dim_date_concluded.fin_quarter_no AS NVARCHAR(1))	AS [Concluded Quarter]
	, IIF(dim_date_concluded.fin_quarter_no IN (1,2), 'May - Oct', 'Nov - Apr')		AS [Concluded Half Years]
	, DATEDIFF(DAY, CAST(dim_matter_header_current.date_opened_case_management AS DATE),CAST(dim_detail_outcome.date_claim_concluded AS DATE))		AS [Lifecycle]
	, dim_detail_outcome.repudiation_outcome			AS [Repudiation - outcome]
	, dim_detail_outcome.outcome_of_case		AS [Outcome of Case]
	, CAST(fact_matter_summary_current.last_bill_date AS DATE)			AS [Date of Last Bill]
	, fact_detail_reserve_detail.damages_reserve	AS [Damages Reserve Current]	
	, fact_finance_summary.damages_paid				AS [Damages Paid]
	, dim_detail_finance.damages_banding			AS [Damages Banding]
	, fact_detail_reserve_detail.claimant_costs_reserve_current		AS [Claimant Costs Reserve Current]
	, fact_finance_summary.claimants_costs_paid				AS [Claimant Costs Paid]
	, fact_detail_reserve_detail.defence_costs_reserve			AS [Defence Costs Reserve Current]
	, CASE 
		WHEN RTRIM(LOWER(dim_detail_core_details.motor_personal_motor_corporate)) = 'motor personal' THEN 
			ISNULL(fact_finance_summary.total_amount_bill_non_comp, 0)
		ELSE
			ISNULL(fact_finance_summary.total_amount_bill_non_comp, 0) - ISNULL(fact_finance_summary.vat_non_comp, 0)
	  END					defence_costs_paid
	, (ISNULL(fact_detail_reserve_detail.damages_reserve, 0) + ISNULL(fact_detail_reserve_detail.claimant_costs_reserve_current, 0)
		+ CASE 
			WHEN RTRIM(LOWER(dim_detail_core_details.motor_personal_motor_corporate)) = 'motor personal' THEN 
				ISNULL(fact_finance_summary.total_amount_bill_non_comp, 0)
			ELSE
				ISNULL(fact_finance_summary.total_amount_bill_non_comp, 0) - ISNULL(fact_finance_summary.vat_non_comp, 0)
		  END) 
			- (ISNULL(fact_finance_summary.damages_paid, 0) + ISNULL(fact_finance_summary.claimants_costs_paid, 0) + ISNULL(fact_detail_reserve_detail.defence_costs_reserve, 0))	 AS [Total Savings]
	, dim_detail_outcome.are_we_pursuing_a_recovery		AS [Are We Pursuing a Recovery]
	, fact_detail_recovery_detail.recovery_claimants_damages_via_third_party_contribution	AS [Recovery Claimant's Damages Via TP Contribution]
	, fact_detail_recovery_detail.recovery_defence_costs_from_claimant		AS [Recovery Defence Costs From Claimant]
	, fact_detail_recovery_detail.recovery_claimants_costs_via_third_party_contribution	AS [Recovery Claimant Costs Via TP Contribution]
	, fact_detail_recovery_detail.recovery_defence_costs_via_third_party_contribution		AS [Recovery Defence Costs Via TP Contribution]
	, fact_detail_recovery_detail.total_recovery			AS [Total Recovery]
	, CASE 
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'access legal%' THEN 'Access Legal'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'aegis%' THEN 'Aegis Legal'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'agea law%' THEN 'Ageas Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'alyson france%' THEN 'Alyson France and Co'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'andrew and %' THEN 'Andrew and Co LLP Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'antony gold%' THEN 'Anthony Gold Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'armstrong%' THEN 'Armstrong Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'ashton%' THEN 'Ashton KCJ'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'aspire law%' THEN 'Aspire Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'barlow robbins%' THEN 'Barlow Robbins LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'barr ellison%' THEN 'Barr Ellison LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'slater and gordon%' THEN 'Slater and Gordon'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'slater gordon%' THEN 'Slater and Gordon'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'slater & gordon%' THEN 'Slater and Gordon'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'slater and gordan%' THEN 'Slater and Gordon'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'slater gordan%' THEN 'Slater and Gordon'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'cleaver thompson%' THEN 'Cleaver Thompson Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'thompsons%' THEN 'Thompsons'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'thompson sol%' THEN 'Thompsons'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'irwin mitchell%' THEN 'Irwin Mitchell LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'irwin michell%' THEN 'Irwin Mitchell LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'irwinmitchell%' THEN 'Irwin Mitchell LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE '1st central law%' THEN '1st Central Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE '2020 legal %' THEN '2020 Legal Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'accident claims lawyers%' THEN 'Accident Claims Lawyers'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'admiral law%' THEN 'Admiral Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'affinity law%' THEN 'Affinity Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'ageas law%' THEN 'Ageas Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'amanda cunliffe%' THEN 'Amanda Cunliffe Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'anthony collins%' THEN 'Anthony Collins Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'anthony gold%' THEN 'Anthony Gold Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'awh %' THEN 'AWH Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'bartlett% solicitor%' THEN 'Bartletts Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'barletts solicitor%' THEN 'Bartletts Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'bartletts solictor%' THEN 'Bartletts Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'bde law%' THEN 'BDE Law Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'beecham peacock%' THEN 'Beecham Peacock Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'birchall blackburn%' THEN 'Birchall Blackburn Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'bolt burdon%' THEN 'Bolt Burdon Kemp Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'bond turner%' THEN 'Bond Turner Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'brindley twist%' THEN 'Brindley Twist Tafft & James Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'browell smith & co%' THEN 'Browell Smith & Co Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'carpenters%' THEN 'Carpenters Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'carter rose%' THEN 'Carter Rose Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'curtis law%' THEN 'Curtis Law Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'das law%' THEN 'DAS Law Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'digby brown%' THEN 'Digby Brown LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'express solicitors%' THEN 'Express Solicitors Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'farleys solicitors%' THEN 'Farleys Solicitors LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'fbc man%' THEN 'FBC Manby Bowdler Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'fletcher% solcitiors%' THEN 'Fletchers Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'forster dean%' THEN 'Forster Dean Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'gavin edmondson%' THEN 'Gavin Edmondson Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'harris fowler%' THEN 'Harris Fowler Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'hayes connor%' THEN 'Hayes Connor Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'heptonstall%' THEN 'Heptonstalls Ltd Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'horwich cohen%' THEN 'Horwich Cohen Coghlan'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'horwich farrelly%' THEN 'Horwich Farrelly Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'hugh james%' THEN 'Hugh James Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'ime law%' THEN 'IME Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'imperium law%' THEN 'Imperium Law Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'jf law%' THEN 'JF Law Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'jigsaw law%' THEN 'Jigsaw Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'jiva solicitor%' THEN 'Jiva Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'jmw%' THEN 'JMW Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'judge & priest%' THEN 'Judge & Priestley LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'kinetic law%' THEN 'Kinetic Law Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'lyons davidson%' THEN 'Lyons Davidson Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'mercury legal%' THEN 'Mercury Legal LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'michael w halsall%' THEN 'Michael W Halsall Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'minster law%' THEN 'Minster Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'oakwood solicitors%' THEN 'Oakwood Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'oliver & co%' THEN 'Oliver & Co Solicitors Ltd'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'pabla & pabla%' THEN 'Pabla & Pabla Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'pabla + pabla%' THEN 'Pabla & Pabla Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'pabla and pabla%' THEN 'Pabla & Pabla Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'pattinson% brewer%' THEN 'Pattinson & Brewer'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'pattison% brewer%' THEN 'Pattinson & Brewer'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'pm law%' THEN 'PM Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'principia law%' THEN 'Principia Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'proddow mackay%' THEN 'proddow mackay solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'pure legal%' THEN 'Pure Legal Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'qc law%' THEN 'QC Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'ralli%' THEN 'Ralli Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'ramsden%' THEN 'Ramsdens Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'rcn law%' THEN 'RCN Law'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'robert% jackson%' THEN 'Roberts Jackson Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'royds withy king%' THEN 'Royds Withy King'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'roythornes%' THEN 'Roythornes Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'rushton hinchy%' THEN 'Rushton Hinchy Solicitors LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'russell worth%' THEN 'Russell Worth Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'satchell moran%' THEN 'Satchell Moran Solicitors Ltd'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'scott rees%' THEN 'Scott Rees & Co'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'shakespear% martineau%' THEN 'Shakespeare Martineau LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'silverbeck rymer%' THEN 'Silverbeck Rymer Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'simpson millar%' THEN 'Simpson Millar LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'simpson miller%' THEN 'Simpson Millar LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'sintons%' THEN 'Sintons LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'sovereign solicitors%' THEN 'Sovereign Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'stephensons%' THEN 'Stephensons Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'switalskis%' THEN 'Switalskis Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'the asbestos law%' THEN 'The Asbestos Law LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'thorneycroft%' THEN 'Thorneycroft Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'tilly bailey%' THEN 'Tilly Bailey & Irvine LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'tilley bailey%' THEN 'Tilly Bailey & Irvine LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'till bailey%' THEN 'Tilly Bailey & Irvine LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'tinsdill%' THEN 'Tinsdills Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'tjl solicitors%' THEN 'TJL Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'trade union%' THEN 'Trade Union Legal LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'true solicitors%' THEN 'True Solicitors LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'unionline%' THEN 'Unionline'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'union line%' THEN 'Unionline'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'versus law%' THEN 'Versus Law Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'versuslaw%' THEN 'Versus Law Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'waldrons%' THEN 'Waldrons Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'walker preston%' THEN 'Walker Prestons Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'ward & rider%' THEN 'Ward & Rider Ltd'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'winn solicitors%' THEN 'Winn Solicitors Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'wixted & co%' THEN 'Wixted & Co Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'wixted and co%' THEN 'Wixted & Co Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'wixred & co%' THEN 'Wixted & Co Solicitors'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'your law%' THEN 'Your Law LLP'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'your lawyers%' THEN 'Your Lawyers Limited'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'your legal%' THEN 'Your Legal Friend'
		WHEN LOWER(TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name])) LIKE 'zen law%' THEN 'Zen Law Solicitors'
		ELSE TRIM(dim_claimant_thirdparty_involvement.[claimantsols_name]) 
	  END																AS [Claimant's Solicitor]
	, dim_detail_claim.dst_claimant_solicitor_firm		AS [DST Claimant Solicitor Firm]
	, CASE 
		WHEN fraud_handlers.fraud_handler IS NOT NULL AND RTRIM(LOWER(dim_detail_core_details.suspicion_of_fraud)) = 'yes' THEN
			'Fraud'
		ELSE
			'Non-Fraud'
	  END					AS [Fraud/Non-Fraud]
	, CASE
		WHEN fraud_handlers.fraud_handler IS NOT NULL AND RTRIM(LOWER(dim_detail_core_details.suspicion_of_fraud)) = 'yes' THEN 
			fraud_handlers.fraud_handler
		ELSE
			' Non-Fraud Handler' --space at the front to ensure this option appears at top of filter in dashboard
	  END						AS [Fraud Handler]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_client	
		ON dim_client.client_code = dim_matter_header_current.client_code
	LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
		ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_critical_mi
		ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
		ON fact_detail_recovery_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN (
						SELECT dim_fed_hierarchy_history.dim_fed_hierarchy_history_key, dim_fed_hierarchy_history.name	AS fraud_handler
						FROM red_dw.dbo.dim_fed_hierarchy_history
						WHERE
							dim_fed_hierarchy_history.fed_code IN (
							'3067','3080','3174','4195','4343','5171','551','5527','5735','6279','6291','6378','6481',
							'1767','3459','5599','3233','4664','2014','4957','4480','5036','5430','1767','6427','1697',
							'5431','4625','3366','1480','4755','5176','5608','6136','6753', '6704', '6681', '4656', '6722'
							)
					)		AS fraud_handlers
		ON fraud_handlers.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_date AS dim_date_open
		ON dim_date_open.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
	LEFT OUTER JOIN red_dw.dbo.dim_date AS dim_date_concluded
		ON dim_date_concluded.calendar_date = CAST(dim_detail_outcome.date_claim_concluded AS DATE)
WHERE 1 = 1
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.master_client_code <> '30645'
	AND dim_matter_header_current.master_matter_number <> '0'
	AND dim_matter_header_current.matter_number <> 'ML'
	AND ISNULL(RTRIM(LOWER(dim_detail_outcome.outcome_of_case)), '') <> 'exclude from reports'
	AND dim_fed_hierarchy_history.hierarchylevel2hist LIKE '%Legal Ops%Claims%'
	AND (
		CAST(dim_matter_header_current.date_opened_case_management AS DATE) >= @start_date
		OR
        CAST(dim_detail_outcome.date_claim_concluded AS DATE) >= @start_date
		)
	AND ISNULL(RTRIM(dim_matter_worktype.work_type_name), '') <> 'Claims Handling'


END




GO

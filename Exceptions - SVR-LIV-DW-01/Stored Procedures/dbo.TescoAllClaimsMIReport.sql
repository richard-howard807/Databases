SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		M Taylor
-- Create date: 2022-08-03
-- Description:	Initial Create 
-- =============================================

CREATE PROCEDURE [dbo].[TescoAllClaimsMIReport]

AS

SELECT 

[Solicitor Firm]	        ='Weightmans',
[Solicitor Office]  	    = dim_matter_branch.branch_name,
[Solicitor Reference]	    = TRIM(dim_matter_header_current.master_client_code) + '-' + TRIM(dim_matter_header_current.master_matter_number),
[Solicitor Fee-Earner]      = name	 ,  --Weightmans' file handler" "***INTERNAL ONLY FIELD***
[Solicitor Team]            = hierarchylevel4hist ,  --	Weightmans' Team""***INTERNAL ONLY FIELD***
[Is this a Tier 1-3 Case?]	= dim_detail_claim.[tier_1_3_case], -- "***INTERNAL ONLY FIELD***
[Tesco Office Handling] 	= dim_detail_claim.ageas_office,
[Tesco Handler]	            = dim_detail_core_details.[grpageas_case_handler], --udMIClientAgeas.cboCaseHandler
[Tesco reference]	        = COALESCE(dim_client_involvement.insurerclient_reference,dim_client_involvement.client_reference),
[Instruction Date]	        = dim_matter_header_current.date_opened_case_management,
[Name of Claimant]          = udMIClientTesco.txtClaimantName, --"From 'Claimant' Associate  Format: Forename Surname"
[Name of Tesco Insured]     = udMIClientTesco.txtPolicyName, --Format: Forename Surname"	"From 'Insured Client' Associate
[Accident Date]             = dim_detail_core_details.[incident_date],
[Claim Type]                = CASE WHEN TRIM(dim_detail_claim.[ageas_instruction_type]) = 'Fraud'  THEN 'Fraud'
                                   WHEN LOWER(TRIM(dim_detail_core_details.[suspicion_of_fraud])) = 'yes' THEN 'Fraud'
								   WHEN dim_detail_fraud.[fraud_type_motor] IS NULL AND hierarchylevel4hist = 'Motor' THEN 'Fraud'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction])  = 'Limitation' THEN 'Limitation'
								   WHEN dim_detail_fraud.[fraud_type_motor] IS NULL AND LOWER(TRIM(dim_detail_core_details.[suspicion_of_fraud])) = 'no' AND TRIM(dim_detail_claim.[ageas_instruction_type])  IN ('Large and Complex PI', 'Small PI') THEN 'Personal Injury'
								   WHEN dim_detail_fraud.[fraud_type_motor] IS NULL AND LOWER(TRIM(dim_detail_core_details.[suspicion_of_fraud])) = 'no' AND TRIM(dim_detail_claim.[ageas_instruction_type]) = 'Non-PI' THEN 'Non-PI'
								   WHEN LOWER(TRIM(dim_detail_claim.[ageas_instruction_type])) = 'representation only' THEN 'Criminal Representation'
								   WHEN dim_detail_fraud.[fraud_type_motor] IS NULL AND LOWER(TRIM(dim_detail_core_details.[suspicion_of_fraud])) = 'no' AND TRIM(ISNULL(dim_detail_claim.[ageas_instruction_type], '')) NOT IN ('Large and Complex PI', 'Small PI', 'Non-PI', 'Fraud')    AND LOWER(TRIM(dim_detail_core_details.does_claimant_have_personal_injury_claim)) = 'yes' THEN 'Personal Injury'
								   WHEN dim_detail_fraud.[fraud_type_motor] IS NULL AND LOWER(TRIM(dim_detail_core_details.[suspicion_of_fraud])) = 'no' AND TRIM(ISNULL(dim_detail_claim.[ageas_instruction_type], '')) NOT IN ('Large and Complex PI', 'Small PI', 'Non-PI', 'Fraud')    AND LOWER(TRIM(dim_detail_core_details.does_claimant_have_personal_injury_claim)) = 'no' THEN 'Non-PI'
								   ELSE 'Other'
								   END,

[Reason For Instruction] =    CASE 
WHEN TRIM(LOWER(dim_detail_client.[tesco_reason_for_instruction])) = 'phantom' THEN 'Phantom'
WHEN TRIM(LOWER(dim_detail_client.[tesco_reason_for_instruction]))= 'farmed' THEN 'Farmed'

WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) IN ('Liability', 'Quantum (S3)','Quantum (non MOJ)', 'Quntum (non MOJ)' ) AND TRIM(dim_detail_core_details.[referral_reason]) = 'Dispute on liability and quantum' THEN 'Quantum and Liability'
                                   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) IN ('Liability', 'Quantum (S3)','Quantum (non MOJ)', 'Quntum (non MOJ)' ) AND TRIM(dim_detail_core_details.[referral_reason]) IN ('Dispute on Liability','Dispute on liability') THEN 'Liability'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) IN ('Liability', 'Quantum (S3)','Quantum (non MOJ)', 'Quntum (non MOJ)' ) AND TRIM(dim_detail_core_details.[referral_reason]) = 'Dispute on quantum' THEN 'Quantum'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Infant Approval' THEN 'IAH'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) IN ( 'Credit Hire','Credit hire') THEN 'Credit Hire'
                                   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Late Claim' THEN 'Late'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Staged' THEN 'Staged'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) IN ( 'Slam On', 'Slam on') THEN 'Slam On'
                                   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Costs only' THEN 'Other'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Limitation' THEN 'Other'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) IN ( 'LVI / Exaggerated', 'LVI/Exaggeration') THEN 'LSI'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Other' AND TRIM(dim_detail_core_details.[referral_reason]) NOT IN  ('Dispute on Liability','Dispute on liability','Dispute on liability and quantum' ,'Dispute on quantum' ) THEN 'Other'
                                   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Other' AND TRIM(dim_detail_core_details.[referral_reason]) = 'Dispute on liability and quantum' THEN 'Quantum and liability'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Other' AND TRIM(dim_detail_core_details.[referral_reason]) = 'Dispute on quantum' THEN 'Quantum'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Other' AND TRIM(dim_detail_core_details.[referral_reason]) IN ('Dispute on Liability','Dispute on liability' ) THEN 'Liability'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Other' AND ISNULL(dim_detail_core_details.[referral_reason], '') = '' THEN 'Other'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) = 'Liability' AND TRIM(ISNULL(dim_detail_core_details.[referral_reason], ''))  IN  ('Advice only','Recovery','') THEN 'Other'
								   WHEN TRIM(dim_detail_client.[tesco_reason_for_instruction]) IN ('Quantum (non MOJ)', 'Quntum (non MOJ)') AND TRIM(ISNULL(dim_detail_core_details.[referral_reason], ''))  IN  ('Advice only','Recovery','') THEN 'Other'
                                   WHEN TRIM(dim_detail_core_details.[referral_reason]) IN ('Infant Approval', 'Infant approval') THEN 'IAH'
								   WHEN ISNULL(dim_detail_client.[tesco_reason_for_instruction], '') = '' THEN 
										CASE WHEN TRIM(dim_detail_core_details.[referral_reason]) = 'Dispute on liability and quantum' THEN 'Quantum and liability'
										     WHEN TRIM(dim_detail_core_details.[referral_reason]) = 'Dispute on quantum' THEN 'Quantum'
											 WHEN TRIM(dim_detail_core_details.[referral_reason]) IN ('Dispute on Liability', 'Dispute on liability') THEN 'Liability'
											 WHEN ISNULL(dim_detail_core_details.[referral_reason], '') = '' THEN 'Other' END
									 END,


Track  =                      CASE WHEN TRIM(dim_matter_branch.branch_name) = 'Glasgow' THEN 'Scotland'
		                     	   WHEN TRIM(dim_detail_client.[tesco_track]) IN ('Small Track','Small track' ) THEN  'Small Track'
                                   WHEN TRIM(dim_detail_client.[tesco_track])  = 'Fast track up to £25k' THEN 'Fast Track'
                                   WHEN TRIM(dim_detail_client.[tesco_track]) IN ('Multi -- Track -- up to £50k','Multi -- Track -- £50k +' ) THEN 'Multi Track'
		                     	   WHEN TRIM(dim_detail_client.[tesco_track]) = 'MOJ P8' THEN 'MOJ'
		                     	   WHEN TRIM(dim_detail_client.[tesco_track]) = 'OIC' THEN 'OIC'
		                     	   ELSE CASE WHEN dim_detail_core_details.[track] = 'Fast Track' THEN 'Fast Track'
		                     	           WHEN dim_detail_core_details.[track] = 'Multi Track' THEN 'Multi Track'
		                     			   WHEN TRIM(dim_detail_core_details.[track]) = 'Small Claims' THEN 'Small Track'
		                     			   END END,

[Third Party Claimant Solicitors]  =   dim_claimant_thirdparty_involvement.claimantsols_name,  
[Panel Charging Basis]             = 	dim_matter_header_current.fee_arrangement,

[Live/Settled] = CASE WHEN COALESCE(dim_detail_outcome.[date_claim_concluded], dim_matter_header_current.date_closed_case_management) IS NULL THEN 'LiveFiles'
      WHEN COALESCE(dim_detail_outcome.[date_claim_concluded], dim_matter_header_current.date_closed_case_management) IS NOT NULL AND 
	  dim_detail_outcome.[date_claim_concluded] >= '2022-07-01' THEN 'SettledClaims'
	  END,

	  /* Fields  for Settled Claims tab*/


[Date Closed] = dim_matter_header_current.date_closed_case_management, 
[MI Closed Month] = CAST(DATEPART(MONTH, dim_matter_header_current.date_closed_case_management) AS VARCHAR(4)) +'/' + CAST(RIGHT(YEAR(dim_matter_header_current.date_closed_case_management), 2) AS VARCHAR(2)),
[Total Damages Paid] = udMIOutcomeDamages.curDamsPaidCli,
[Agreed General Damages] = ISNULL(fact_detail_paid_detail.[personal_injury_paid], 0) +ISNULL(fact_detail_paid_detail.[general_damages_misc_paid], 0),
[Agreed Special Damages] = ISNULL(fact_detail_paid_detail.[past_care_paid], 0) + ISNULL(fact_detail_paid_detail.[past_loss_of_earnings_paid], 0) + ISNULL(fact_finance_summary.[special_damages_miscellaneous_paid], 0) + ISNULL(fact_detail_paid_detail.[future_care_paid], 0) + ISNULL(fact_detail_paid_detail.[future_loss_of_earnings_paid], 0) + ISNULL(fact_detail_paid_detail.[future_loss_misc_paid], 0),
[Date final damages agreed] = dim_detail_outcome.[date_claim_concluded],
[Agreed Claimant Profit costs (inc vat)] = ISNULL(fact_detail_paid_detail.[claimant_s_solicitor_s_base_costs_paid_vat],0),
[Agreed Claimant Disb (inc VAT)] = ISNULL(fact_finance_summary.claimants_solicitors_disbursements_paid, 0),--ISNULL(fact_detail_paid_detail.[claimant_s_solicitor_s_disbursements_paid],0),  --fact_detail_paid_detail[claimant_s_solicitor_s_base_costs_paid_vat]. --fact_finance_summary.[claimants_solicitors_disbursements_paid],

[Panel Sols Total Profit costs (inc VAT)] = ISNULL(fact_finance_summary.defence_costs_billed,0) + ISNULL(fact_finance_summary.defence_costs_vat,0), 
[Panel Sols Total Disbursements (inc VAT)] = ISNULL(fact_finance_summary.disbursements_billed, 0) + ISNULL(fact_finance_summary.total_billed_disbursements_vat, 0) ,


[Settlement Stage] = 
CASE WHEN LOWER(TRIM(dim_detail_outcome.[outcome_of_case]))= 'returned to client' THEN 'Settled by Insurer'
     WHEN LOWER(TRIM(dim_detail_outcome.[outcome_of_case])) IN  ('settled','settled – claimant accepts p36 offer','settled – claimant accepts p36 offer out of time','settled – defendant accepts p36 offer','settled – defendant accepts p36 offer out of time','settled – early neutral evaluation' ,'settled – jsm', 'settled - defendant accepts p36 offer', 'settled  - claimant accepts p36 offer out of time', 'settled - claimant accepts p36 offer' ) THEN 'Settled'
	 WHEN LOWER(TRIM(dim_detail_outcome.[outcome_of_case])) IN ('discontinued – indemnified by third party','discontinued – post-lit with costs orders','discontinued – post-lit with no costs orders','discontinued – pre-lit' , 'discontinued - pre-lit', 'discontinued - post-lit with no costs order', 'discontinued - post-lit with costs order') THEN 'Claimant Discontinues'
	 WHEN LOWER(TRIM(dim_detail_outcome.[outcome_of_case])) IN ('struck out','won at trial','assessment of damages (claimant fails to beat p36 offer)' ) THEN 'Win at Trial'
	 WHEN LOWER(TRIM(dim_detail_outcome.[outcome_of_case])) IN ('lost at trial','lost at trial (damages exceed claimant’s p36 offer)' ,'assessment of damages (damages exceed claimant''s p36 offer)') THEN 'Lose at Trial' 
	 END ,
	 dim_detail_outcome.[outcome_of_case],
[Court]  = dim_court_involvement.court_name,

/* Additional fields added 04/08/2022*/

[Full case description] = dim_matter_header_current.matter_description,
[Date file closed] = dim_matter_header_current.date_closed_case_management,
[Date of last time entry] = fact_matter_summary_current.last_time_transaction_date,
[Present position] = dim_detail_core_details.[present_position],
[Instruction Type] = dim_detail_claim.[ageas_instruction_type],
[Tesco) Reason for Instruction] = dim_detail_client.[tesco_reason_for_instruction] ,
[Referral Reason] =  dim_detail_core_details.[referral_reason],
[Tesco) Track] =  dim_detail_client.[tesco_track],
[Name of Claimant - Associates]          = dim_claimant_thirdparty_involvement.claimant_name, --"From 'Claimant' Associate  Format: Forename Surname"
[Name of Tesco Insured - Associates ]     = dim_client_involvement.insuredclient_name, --Format: Forename Surname"	"From 'Insured Client' Associate

[Outcome of Case] =  dim_detail_outcome.[outcome_of_case],

[Track - Internal] =  dim_detail_core_details.[track]




        FROM red_dw.dbo.fact_dimension_main
        JOIN red_dw.dbo.dim_matter_header_current
        	ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        LEFT JOIN red_dw.dbo.dim_matter_branch
        	ON dim_matter_branch.branch_code = dim_matter_header_current.branch_code
        LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
        	ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
        LEFT JOIN red_dw.dbo.dim_detail_claim
        	ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
        LEFT JOIN red_dw.dbo.dim_detail_core_details
        	ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
        LEFT JOIN red_dw.dbo.dim_client_involvement
        	ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
        LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
        	ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
        LEFT JOIN red_dw.dbo.dim_detail_outcome
			ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
        LEFT JOIN red_dw.dbo.dim_detail_fraud
			ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
	    LEFT JOIN red_dw.dbo.dim_detail_client
		    ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
		LEFT JOIN red_dw.dbo.fact_detail_claim
			ON fact_detail_claim.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.fact_detail_paid_detail
			ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.fact_finance_summary
			ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
        LEFT JOIN red_dw.dbo.dim_court_involvement
			ON dim_court_involvement.dim_court_involvement_key = fact_dimension_main.dim_court_involvement_key
		LEFT JOIN red_dw.dbo.fact_matter_summary_current
			ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
        LEFT JOIN ms_prod.dbo.udMIClientTesco
			ON udMIClientTesco.fileID = dim_matter_header_current.ms_fileid
        LEFT JOIN ms_prod.dbo.udMIOutcomeDamages
			ON udMIOutcomeDamages.fileID = ms_fileid

WHERE reporting_exclusions = 0 
AND LOWER(TRIM(ISNULL(dim_detail_outcome.[outcome_of_case], ''))) <> 'exclude from reports' 

AND 
(
dim_matter_header_current.master_client_code = 'T3003'
OR TRIM(dim_detail_claim.[name_of_instructing_insurer]) = 'Tesco Underwriting (TU)'
)

AND CASE WHEN COALESCE(dim_detail_outcome.[date_claim_concluded], dim_matter_header_current.date_closed_case_management) IS NULL THEN 'LiveFiles'
      WHEN COALESCE(dim_detail_outcome.[date_claim_concluded], dim_matter_header_current.date_closed_case_management) IS NOT NULL AND 
	  dim_detail_outcome.[date_claim_concluded] >= '2022-07-01' THEN 'SettledClaims'
	  END IN ('LiveFiles','SettledClaims')

	  --TESTING
	--AND TRIM(dim_matter_header_current.master_client_code) + '-' + TRIM(dim_matter_header_current.master_matter_number) IN ( 'T3003-1697', 'T3003-1602')


GO

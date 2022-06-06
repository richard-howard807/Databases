SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[HastingsMITemplate–LLandComplexClaims]

AS

SELECT  

[Claim Reference]	=                             COALESCE([dim_client_involvement].client_reference, [dim_client_involvement].insurerclient_reference),	--Insurer client reference from associates or if blank client reference from associates --11 Digit Integer, starting "300…"	
[HD Instruction Team]	= 	                      dim_detail_claim.[hastings_hd_instruction_team],
[MOJ/OIC]	=	                                  CASE WHEN TRIM(dim_detail_core_details.[referral_reason]) IN ('MOJ', 'OIC') THEN  dim_detail_core_details.[referral_reason] ELSE 'Other' END  ,
[Supplier Handler]	=                             dim_fed_hierarchy_history.name, 
[Supplier Reference]	= 		                  TRIM(dim_matter_header_current.master_client_code) + '-' + TRIM(master_matter_number), --MatterSphere reference (4908-1 format)
[Claimant First Name]	=                     	  Claimant.contChristianNames, --Claimant associate record
[Claimant Surname]	=                             Claimant.contSurname, -- Claimant associate record
[Claimant DOB] = 	                              dim_detail_core_details.[claimants_date_of_birth],
[Is Claimant Injured?] =	                      dim_detail_core_details.[does_claimant_have_personal_injury_claim],
[Injury Category] =                               hastings_child_details.hastings_injury_category,	                         
[Prognosis Time] = 	                              hastings_child_details.hastings_prognosis_time,
[PD Type] = 		                              dim_detail_outcome.[hastings_pd_type],
[Credit Hire Duration]   =                        CASE WHEN dim_detail_hire_details.[hastings_credit_hire_duration] = 0 THEN NULL ELSE dim_detail_hire_details.[hastings_credit_hire_duration] END,    --	Integer	Show as blank if zero is entered	
[Loss Date] =                                     dim_detail_core_details.[incident_date],
[SCNF / LOC Date]=		                          dim_detail_claim.[hastings_scnf_loc_date] ,   
[Date of Instruction] =                		      dim_detail_core_details.[date_instructions_received] ,
[Claimant Solicitor] = 		                      ClaimantSols.contName, --claimant solicitor associate record or if blank look to claimants representative associate record
[Claimant Solicitor Postcode] = 	              ClaimantSols.addPostcode, --claimant solicitor associate record or if blank look to claimants representative associate record
[Litigated?] =                                    dim_detail_core_details.[proceedings_issued],
[Date Litigated] = 	                              dim_detail_court.[date_proceedings_issued],  
[CRU Applicable?] = 			                  dim_detail_claim.[hastings_cru_applicable],
[Liability Percentage] = 			              dim_detail_core_details.[hastings_fault_liability_percent],  
[Liability Position] =  	                      dim_detail_claim.[hastings_liability_position],
[Was Litigation Avoidable?] =   	              dim_detail_core_details.[zurich_grp_rmg_was_litigation_avoidable],
[Reason for Avoidable Litigation]=          	  dim_detail_outcome.[hastings_reason_for_avoidable_litigation],
[Reason For Litigation] =	    		          dim_detail_claim.[hastings_reason_for_litigation],
[Fraud Type]  	= 								  dim_detail_fraud.[hastings_fraud_type],
[Allocated Court Name] = 		                  Court.contName, --Court associate record (most recent record to allow for where CCMCC then allocated).
[Allocated Court Postcode]  =                     Court.addPostcode, --Address	Court associate record (most recent record to allow for where CCMCC then allocated).
[Judgement Entered] = 		                      dim_detail_outcome.[judgment_entered],
[Judgement Against] =	                    	  dim_detail_claim.[hastings_judgement_against],
[Date of Judgement] =		                      dim_detail_court.[hastings_date_of_judgement], 
[Judgement Fault]=		                          dim_detail_claim.[hastings_judgement_fault],
[Claimant General Damages Claimed] = 	          CASE WHEN fact_detail_cost_budgeting.[hastings_claimant_general_damages_claimed]    =0 THEN NULL ELSE fact_detail_cost_budgeting.[hastings_claimant_general_damages_claimed]     END,
[Claimant LOE Claimed] = 	                      CASE WHEN fact_detail_cost_budgeting.[hastings_claimant_loe_claimed]		          =0 THEN NULL ELSE	fact_detail_cost_budgeting.[hastings_claimant_loe_claimed]		           END,
[Claimant Treatment Claimed] = 	                  CASE WHEN fact_detail_cost_budgeting.[hastings_claimant_treatment_claimed]	      =0 THEN NULL ELSE	fact_detail_cost_budgeting.[hastings_claimant_treatment_claimed]	       END,
[Claimant Vehicle Damages Claimed] = 	          CASE WHEN fact_detail_cost_budgeting.hastings_claimant_vehicle_damages_claime  =0 THEN NULL ELSE	fact_detail_cost_budgeting.hastings_claimant_vehicle_damages_claime	   END,
[Claimant Hire Claimed] = 	                      CASE WHEN fact_detail_cost_budgeting.[hastings_claimant_hire_claimed]		          =0 THEN NULL ELSE	fact_detail_cost_budgeting.[hastings_claimant_hire_claimed]		           END,
[Claimant Other Costs Claimed] = 	              CASE WHEN fact_detail_cost_budgeting.[hastings_claimant_other_costs_claimed]		  =0 THEN NULL ELSE	fact_detail_cost_budgeting.[hastings_claimant_other_costs_claimed]		   END,
[Hastings Total GD Best Offer] = 	              CASE WHEN fact_detail_claim.hastings_hastings_total_gd_best_offer				  =0 THEN NULL ELSE	fact_detail_claim.hastings_hastings_total_gd_best_offer			   END,
[Hastings Total LOE Best Offer] = 	              CASE WHEN fact_detail_claim.[hastings_total_loe_best_offer]						  =0 THEN NULL ELSE	fact_detail_claim.[hastings_total_loe_best_offer]						   END,
[Hastings Total Treatment Best Offer] =           CASE WHEN fact_detail_claim.[hastings_hastings_total_treatment_best_offer]	      =0 THEN NULL ELSE	fact_detail_claim.[hastings_hastings_total_treatment_best_offer]	       END,
[Hastings Total Damages Best Offer] = 	          CASE WHEN fact_detail_claim.[hastings_hastings_total_damages_best_offer]			  =0 THEN NULL ELSE	fact_detail_claim.[hastings_hastings_total_damages_best_offer]			   END,
[Hastings Total Hire Best Offer] = 	              CASE WHEN fact_detail_claim.[hastings_hastings_total_hire_best_offer]				  =0 THEN NULL ELSE	fact_detail_claim.[hastings_hastings_total_hire_best_offer]				   END,
[Hastings Total Other Costs Best Offer] = 	      CASE WHEN fact_detail_claim.[hastings_total_other_costs_best_offer]			      =0 THEN NULL ELSE	fact_detail_claim.[hastings_total_other_costs_best_offer]			       END,
[Total General Damages to be Reserved] = 	      CASE WHEN fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved]=0 THEN NULL ELSE	fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved] END,
[Total LOE to be Reserved] = 	                  CASE WHEN fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved]		      =0 THEN NULL ELSE fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved]		       END,   
[Total Treatment to be Reserved] = 	              CASE WHEN fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved]	  =0 THEN NULL ELSE fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved]	   END,   
[Total Damages costs to be Reserved]= 	          CASE WHEN fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved]  =0 THEN NULL ELSE fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved]   END,   
[Total Hire to be Reserved] = 	                  CASE WHEN fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved]		      =0 THEN NULL ELSE fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved]		       END,   
[Total other specials to be Reserved] = 	      CASE WHEN fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved] =0 THEN NULL ELSE	fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved]  END,
[Total General Damages to be Paid] = 	          CASE WHEN fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid]		  =0 THEN NULL ELSE fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid]		   END, 
[Total LOE to be Paid] =	                      CASE WHEN fact_detail_paid_detail.[hastings_total_loe_to_be_paid]		              =0 THEN NULL ELSE fact_detail_paid_detail.[hastings_total_loe_to_be_paid]		               END,   
[Total Treatment to be Paid] =   	              CASE WHEN fact_detail_paid_detail.[hastings_total_treatment_to_be_paid]	          =0 THEN NULL ELSE fact_detail_paid_detail.[hastings_total_treatment_to_be_paid]	           END,   
[Total Damages costs to be Paid] =                CASE WHEN fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid]      =0 THEN NULL ELSE fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid]       END, 	
[Total Hire to be Paid] =                         CASE WHEN fact_detail_paid_detail.[hastings_total_hire_to_be_paid]                  =0 THEN NULL ELSE fact_detail_paid_detail.[hastings_total_hire_to_be_paid]                   END, 	
[Total other specials to be Paid] =               CASE WHEN fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid]        =0 THEN NULL ELSE fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid]         END, 	
[Global Offer?] = 			                      dim_detail_claim.[hastings_global_offer], 
[Global Settlement?] 	=	                      dim_detail_future_care.[global_settlement],
[Outcome Type]=		                              dim_detail_outcome.[hastings_outcome_type],
[CRU to be Paid] = 		                          fact_detail_paid_detail.[cru_costs_paid], 	
[NHS to be Paid] = 		                          fact_detail_paid_detail.[nhs_charges_paid_by_client], 
[Supplier Own Fees (Exc vat)] =                   CASE WHEN dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL THEN  ISNULL(hastings_listing_table.defence_costs_billed, 0) END,	    --		3E - Revenue
[Supplier VAT] =                                  CASE WHEN dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL THEN ISNULL(hastings_listing_table.vat_billed, 0) END,		--3E
[Disbursements cost] =                            CASE WHEN dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL THEN ISNULL(hastings_listing_table.disbursements_billed, 0) END,	--3E
[Recovery to be made?] = 	                      dim_detail_outcome.[hastings_recovery_to_be_made],
[Damages Recovery Amount] =                       CASE WHEN dim_detail_outcome.[hastings_recovery_to_be_made] ='Yes' THEN  (ISNULL(fact_detail_recovery_detail.[recovery_damages_counterclaim_third_party], 0) + ISNULL(fact_detail_recovery_detail.[recovery_damages_counterclaim_claimant], 0) + ISNULL(fact_detail_recovery_detail.[recovery_claimants_damages_claimant], 0) + ISNULL(fact_finance_summary.[recovery_claimants_damages_via_third_party_contribution], 0)) END, --Financial Amount	Only show sum value if dim_detail_outcome[hastings_recovery_to_be_made] is yes	"Sum of:
[Costs Recovery Amount] = 	                      CASE WHEN dim_detail_outcome.[hastings_recovery_to_be_made] = 'Yes' THEN (ISNULL(fact_finance_summary.[recovery_defence_costs_via_third_party_contribution], 0) +  ISNULL(fact_detail_recovery_detail.[recovery_claimants_costs_via_third_party_contribution], 0) +ISNULL(fact_finance_summary.[recovery_defence_costs_from_claimant], 0) ) END, --[Costs Recovery Amount] Financial Amount	Only show sum value if dim_detail_outcome[hastings_recovery_to_be_made] is yes	"Sum of: 
[Assumed Court Track At Instruction] = 			 
 


 CASE 
     WHEN TRIM(dim_detail_claim.[hastings_jurisdiction]) = 'England & Wales' then dim_detail_core_details.[track] 
	 WHEN TRIM(dim_detail_core_details.[track]) =  'Small claims' THEN 'Small Claims Track'
	 WHEN ISNULL(TRIM(dim_detail_claim.[hastings_jurisdiction]),'') <> 'England & Wales' then dim_detail_court.[hastings_assumed_court_track_at_instruction]
     ELSE dim_detail_court.[hastings_assumed_court_track_at_instruction] END,

[Court Track Current] = 			        

CASE WHEN ISNULL(dim_detail_core_details.[proceedings_issued], '')  = 'No' THEN 'Not Litigated'
     WHEN ISNULL(dim_detail_core_details.[proceedings_issued],'') = 'Yes' AND ISNULL(dim_detail_claim.[hastings_jurisdiction], '') <> 'England & Wales' THEN dim_detail_court.[hastings_court_track_current]
	 WHEN ISNULL(dim_detail_claim.[hastings_jurisdiction], '') = 'England & Wales' THEN dim_detail_core_details.[track]
	 WHEN TRIM(dim_detail_core_details.[track]) = 'Small claims' THEN dim_detail_court.[hastings_court_track_current] END,

[Date Damages Agreed] =		                      dim_detail_outcome.[date_claim_concluded], 
[Date Costs Agreed] =		                      dim_detail_outcome.[date_costs_settled], 
[Final Damages Payment Requested] = 		      dim_detail_claim.[hastings_final_damages_payment_requested], 
[Final Costs Payment Requested] = 	              dim_detail_claim.[hastings_final_costs_payment_requested], 
[Total Claimant Costs] =                          fact_finance_summary.[claimants_costs_paid]		
,ms_fileid,
/* Costs Template*/
[Final Bill Date]      = dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] ,
[Fee] =   '',
[Fee Amount] = CASE WHEN dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL THEN  ISNULL(hastings_listing_table.defence_costs_billed, 0) END,
[Fee VAT] = CASE WHEN dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL THEN ISNULL(hastings_listing_table.vat_billed, 0) END,
[Hours Spent] = '',
[Disbursements] = '',
[Disbursements Amount] = CASE WHEN dim_detail_outcome.[mib_grp_zurich_pizza_hut_date_of_final_bill] IS NOT NULL THEN ISNULL(hastings_listing_table.disbursements_billed, 0) END

,dim_detail_core_details.[referral_reason]

FROM red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current
	ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_finance_summary 
	ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_detail_claim
	ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
	ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_detail_court
	ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT JOIN red_dw.dbo.fact_detail_recovery_detail
	ON fact_detail_recovery_detail.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_detail_paid_detail
	ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_future_care
	ON dim_detail_future_care.dim_detail_future_care_key = fact_dimension_main.dim_detail_future_care_key
LEFT JOIN red_dw.dbo.fact_detail_cost_budgeting
	ON fact_detail_cost_budgeting.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_core_details
	ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_hire_details
	ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
	ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_client_involvement
	ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_detail_fraud
	ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
LEFT JOIN red_dw.dbo.fact_detail_claim
ON fact_detail_claim.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
/*Claimant associate details*/
LEFT JOIN 
(

 SELECT  fileID,contName,    assocType
,[dbContactIndividual].contChristianNames, contSurname
,ROW_NUMBER() OVER (PARTITION BY fileID ORDER BY CASE WHEN contName IS NOT NULL THEN 1 ELSE 0 END DESC) RN
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
    ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbAddress
    ON contDefaultAddress=addID
LEFT JOIN MS_Prod.[dbo].[dbContactIndividual]
    ON dbContactIndividual.contID = dbAssociates.contID
       WHERE assocType =  'CLAIMANT'
	   AND contName IS NOT NULL 
	   AND assocActive = 1

)  Claimant ON Claimant.fileID = ms_fileid AND Claimant.RN = 1 

/* claimant solicitor associate record or if blank look to claimants representative associate record */
LEFT JOIN (
SELECT  
	fileID,
	contName,    
    addPostcode
	,ROW_NUMBER() OVER (PARTITION BY fileID ORDER BY CASE WHEN assocType = 'CLAIMANTSOLS' THEN 1 ELSE 0 END DESC) RN
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbAddress
 ON contDefaultAddress=addID

 WHERE assocType IN ( 'CLAIMANTREP', 'CLAIMANTSOLS')
 AND assocActive = 1 
 --AND fileID = '3874866'

 ) ClaimantSols ON ClaimantSols.fileID = ms_fileid AND ClaimantSols.RN = 1


 /* Court details*/

 LEFT JOIN (
SELECT  
	fileID,
	contName,    
    addPostcode
	,ROW_NUMBER() OVER (PARTITION BY fileID ORDER BY CASE WHEN contName IS NOT NULL THEN 1 ELSE 0 END DESC) RN
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbAddress
 ON contDefaultAddress=addID

 WHERE TRIM(assocType) IN ( 'COURT', 'COUNTYCRT')
 AND assocActive = 1 
 --AND fileID = '3874866'

 ) Court ON Court.fileID = ms_fileid AND Court.RN = 1

 LEFT JOIN  Reporting.dbo.hastings_listing_table
 ON [Supplier Reference] = TRIM(dim_matter_header_current.master_client_code) +'-'+TRIM(master_matter_number)


 LEFT OUTER JOIN (
				SELECT 
					hasting_child_detail.dim_matter_header_curr_key
					, STRING_AGG(CAST(hasting_child_detail.hastings_injury_category AS NVARCHAR(MAX)), ', ')		AS hastings_injury_category
					, STRING_AGG(CAST(hasting_child_detail.hastings_prognosis_time AS NVARCHAR(MAX)), ', ')			AS hastings_prognosis_time
				FROM (
						SELECT DISTINCT
									dim_matter_header_current.dim_matter_header_curr_key
									, dim_child_detail.hastings_injury_category
									, NULL		AS hastings_prognosis_time
								FROM red_dw.dbo.dim_matter_header_current
									INNER JOIN red_dw.dbo.dim_parent_detail
										ON dim_parent_detail.client_code = dim_matter_header_current.client_code
											AND dim_parent_detail.matter_number = dim_matter_header_current.matter_number
									INNER JOIN red_dw.dbo.dim_child_detail
										ON dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
								WHERE	
									dim_matter_header_current.master_client_code = '4908'
									AND dim_child_detail.hastings_injury_category IS NOT NULL

						UNION 

						-- Hastings only want to see the most severe prognosis time.
						SELECT 
							prognosis_time.dim_matter_header_curr_key
							, NULL
							, prognosis_time.hastings_prognosis_time
						FROM (
								SELECT DISTINCT
									dim_matter_header_current.dim_matter_header_curr_key
									, dim_child_detail.hastings_prognosis_time
									, ROW_NUMBER() OVER(PARTITION BY dim_matter_header_current.dim_matter_header_curr_key ORDER BY CASE dim_child_detail.hastings_prognosis_time
																																	WHEN 'Permanent' THEN 1
																																	WHEN 'TBC - ongoing/ unresolved' THEN 2
																																	WHEN '24mth+' THEN 3
																																	WHEN '18-24mth' THEN 4
																																	WHEN '12-18mth' THEN 5
																																	WHEN '6-12mth' THEN 6
																																	WHEN '3-6mth' THEN 7
																																	WHEN '0-3mth' THEN 8
																																 END)					AS severity
								FROM red_dw.dbo.dim_matter_header_current
									INNER JOIN red_dw.dbo.dim_parent_detail
										ON dim_parent_detail.client_code = dim_matter_header_current.client_code
											AND dim_parent_detail.matter_number = dim_matter_header_current.matter_number
									INNER JOIN red_dw.dbo.dim_child_detail
										ON dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
								WHERE	
									dim_matter_header_current.master_client_code = '4908'
									AND dim_child_detail.hastings_prognosis_time IS NOT NULL
							) AS prognosis_time
						WHERE
							prognosis_time.severity = 1
					) AS hasting_child_detail
				GROUP BY
					hasting_child_detail.dim_matter_header_curr_key
				)	AS hastings_child_details
	ON hastings_child_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

 WHERE 1 =1 
 AND dim_matter_header_current.master_client_code = '4908'
 AND date_opened_case_management >= '2021-05-01'  --01/05/2021
 AND reporting_exclusions = 0 
 AND dim_matter_header_current.master_client_code +'-' + master_matter_number <> '4908-19'
 AND ISNULL(dim_detail_core_details.[referral_reason], '') <> 'Advice only'

 ORDER BY ms_fileid 

 


GO

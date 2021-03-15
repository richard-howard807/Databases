SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [CIS].[CoopMIUV6]
AS
begin

set tran isolation level read uncommitted

SELECT 
			 [case_id]
            ,[Client]
            ,[Matter]
            ,[CIS Reference]
            ,[Date Closed in FED]
            ,[Date Opened in FED]
            ,[Insured Name]
            ,[FeeEarner]
            ,[ID]
            ,[No. of Claimants]
            ,[RTA Date]
            ,[Date Received]
            ,[Month Instructions Received]
            ,[Last 12 Months]
            ,DATEDIFF(dd,[Date Received],[Date Closed/declared dormant]) as [Elapsed Days]
            ,[Fixed Fee]
            ,[GuidNumber]
						,
			CASE WHEN (CASE WHEN [Date re-opened] >='2014-07-01' AND [Master Outcome] IS NOT NULL THEN Outcome
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master Outcome] IS NOT NULL THEN [Master Outcome]
				WHEN [Master Outcome] IS NULL THEN Outcome 
			 END)='Pending' THEN NULL ELSE (
			CASE WHEN [Date re-opened] >='2014-07-01' AND [Master date closed/ dormant] IS NOT NULL THEN [Date Closed/declared dormant]
					WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master date closed/ dormant] IS NOT NULL THEN [Master date closed/ dormant]
					WHEN [Master date closed/ dormant] IS NULL THEN [Date Closed/declared dormant] 
			 END) END 
			  
			 AS [Date Closed/declared dormant]
			,[BlankColumn]
			,CASE WHEN [Date re-opened] >='2014-07-01' AND [Master date MI updated] IS NOT NULL THEN [Date MI Updated]
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master date MI updated] IS NOT NULL THEN [Master date MI updated]
				WHEN [Master date MI updated] IS NULL THEN [Date MI Updated] 
			 END 
			 AS [Date MI Updated]
			,[Date re-opened]
			,[Estimated Final Fee]
			
			,RTRIM(CASE WHEN [Date re-opened] >='2014-07-01' AND [Master Status] IS NOT NULL THEN [Status]
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master Status] IS NOT NULL THEN [Master Status]
				WHEN [Master Status] IS NULL THEN [Status] 
			 END)
			 AS [Status]
			 
			 ,RTRIM(CASE WHEN [Date re-opened] >='2014-07-01' AND [Master Outcome] IS NOT NULL THEN Outcome
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master Outcome] IS NOT NULL THEN [Master Outcome]
				WHEN [Master Outcome] IS NULL THEN Outcome 
			 END) 
			 AS [Outcome]
			 ,[Policyholder Involvement]
			,[Fraud Type]
			,[MI Reserve]
			,BlankColumn2
			,[Date Pleadings Issued]
			,[Paid prior to instruction]
			,CASE 
			WHEN (CASE WHEN [Date re-opened] >='2014-07-01' AND [Master Outcome] IS NOT NULL THEN Outcome
							WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master Outcome] IS NOT NULL THEN [Master Outcome]
							WHEN [Master Outcome] IS NULL THEN Outcome 
							END)='Pending' THEN NMI065
				WHEN [Date re-opened] >='2014-07-01' AND [Master settlement value] IS NOT NULL THEN [Settlement Value]
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master settlement value] IS NOT NULL THEN [Master settlement value]
				WHEN [Master settlement value] IS NULL THEN [Settlement Value] 
			 END
			  AS [Settlement Value]
			,CASE WHEN [Date re-opened] >='2014-07-01' AND [Master fees] IS NOT NULL THEN Fees
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master fees] IS NOT NULL THEN [Master fees]
				WHEN [Master fees] IS NULL THEN Fees 
			 END
			 AS [Fees]
			,CASE WHEN [Date re-opened] >='2014-07-01' AND [Master net savings] IS NOT NULL THEN [Net Savings]
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master net savings] IS NOT NULL THEN [Master net savings]
				WHEN [Master net savings] IS NULL THEN [Net Savings] 
			END 
			AS [Net Savings]
			,[Potential Recovery]
			,NULL AS [Audit] --Nulled as its always blank in current report.
			,[Narrative]
			,[Gunum]
			,[date_closed]
			,[Team]
			,[Weightmans Fee Earner]
			,FedStatus
			,[Master date closed/ dormant]    
			,[Master date MI updated]
			,[Master Status]
			,[Master Outcome]
			,[Master settlement value]
			,[Master fees]       
			,[Master net savings]

	
			,CASE WHEN  (CASE WHEN [Date re-opened] >='2014-07-01' AND [Master Status] IS NOT NULL THEN [Status]
							WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master Status] IS NOT NULL THEN [Master Status]
							WHEN [Master Status] IS NULL THEN [Status] 
						 END) IN ('Dormant - 50% confidence','Dormant - 95% confidence','Legally closed'
								 ,'Dormant - 50% Confidence','Dormant - 95% Confidence','Legally Closed')
  						AND UPPER((CASE WHEN [Date re-opened] >='2014-07-01' AND [Master Outcome] IS NOT NULL THEN Outcome
								WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master Outcome] IS NOT NULL THEN [Master Outcome]
								WHEN [Master Outcome] IS NULL THEN Outcome 
						END )) IN ('CLAIMS FRAUD PH','CLAIMS FRAUD TP','GONE AWAY','INDEMNITY FRAUD','REDUCED SETTLEMENT','WITHDRAWN') THEN 'First' 
			END  
			AS ReportingTab                                                                                                       
			,FeeEarnerCode
			,CASE 
				WHEN (CASE WHEN [Date re-opened] >='2014-07-01' AND [Master Status] IS NOT NULL THEN [Status]
								WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master Status] IS NOT NULL THEN [Master Status]
								WHEN [Master Status] IS NULL THEN [Status] 
								END) IN ('Re-opened claim - reopened from dormant 50%', 'Re-opened claim - reopened from dormant 95%', 'Re-opened claim - re-opened from dormant - 50%','Re-opened claim - re-opened from dormant - 95%')
									  AND FedStatus='Open In FED'
				THEN 'Re-Opened' 
            	WHEN (CASE WHEN [Date re-opened] >='2014-07-01' AND [Master Status] IS NOT NULL THEN [Status]
								WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master Status] IS NOT NULL THEN [Master Status]
								WHEN [Master Status] IS NULL THEN [Status] 
								END) IN ('Open claim - new', 'Open Claim - Investigation Process','Open claim - investigation process','Open Claim - Negotiation/Final Settlement Stage','Open claim - negotiation/final settlement stage'
																			   ,'Dormant - 50% confidence','Legally closed', 'Dormant - 95% confidence' )
									  AND FedStatus='Open In FED'
				THEN 'Open'
			    WHEN  FedStatus='Closed In FED' THEN 'Closed'
				ELSE 'Open' 
				END [SAP_Open]
			,[WIPBal]
			,[TotalProfitCostsBilled]
			,[ProfitCostsVAT]
			,[SAPClosedDate] AS [SAPClosedDate]
			,[Date Claim Concluded]
			,[Month Claim Concluded]
			,[Year Claim Concluded]
			,[Incident Location]
			,'' AS [Claimant Postcode]
			,[Present Position]
			,[Date of repudiation]
			,[Date Proceedings Issued]
			,[Damages Reserve Held LeadLinked]
		    ,[Opponents Costs Reserve Held LeadLinked]
			,[Defence Costs Reserve Held LeadLinked]
			,NMI864 AS [ABI Fraud Proven]
			,NMI814 AS [Is this a fraud ring]
			,NMI973 AS [Underwriting Referral Made]


			,CASE WHEN [Date re-opened] >='2014-07-01' AND [Master fees] IS NOT NULL THEN ISNULL(PreLitFees,0)
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master fees] IS NOT NULL 
				
				THEN (CASE WHEN [Date Proceedings Issued] IS NULL THEN [Master fees] ELSE 0 END)
				WHEN [Master fees] IS NULL THEN ISNULL(PreLitFees,0) 
			 END
			 AS [Pre Lit Fees]

			,CASE WHEN [Date re-opened] >='2014-07-01' AND [Master fees] IS NOT NULL THEN ISNULL(PostLitFees,0)
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master fees] IS NOT NULL 
				
				THEN (CASE WHEN [Date Proceedings Issued] IS NOT NULL THEN [Master fees] ELSE 0 END)
				WHEN [Master fees] IS NULL THEN ISNULL(PostLitFees,0)
			 END
			 AS [Litigated Fees]
			 
			,CASE WHEN [Date re-opened] >='2014-07-01' AND [Master fees] IS NOT NULL THEN ISNULL(AllDisbLeadLink,0)
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master fees] IS NOT NULL 
				
				THEN (CASE WHEN [Date Proceedings Issued] IS NOT NULL THEN 0 ELSE 0 END)
				WHEN [Master fees] IS NULL THEN ISNULL(AllDisbLeadLink,0)
			 END
			  AS [Disbursements]



		FROM 
		(
		SELECT 
			case_id AS case_id
              , COALESCE([CIS Reference],dim_client_involvement.insurerclient_reference) collate database_default AS [CIS Reference]
              , COALESCE([Date Closed in FED],date_closed_case_management) as [Date Closed in FED]
              , COALESCE([Date Opened in FED],date_opened_case_management) as [Date Opened in FED]
              , COALESCE([Insured Name],(CASE WHEN (defendant_name IS NULL OR defendant_name='') THEN InsuredName ELSE defendant_name END)) collate database_default as [Insured Name]
              ,name + ' ('+ RTRIM(fee_earner_code) +')' AS [FeeEarner]
              ,REPLACE(LTRIM(REPLACE(RTRIM(a.client_code),'0',' ') ),' ','0') + '-' + REPLACE(LTRIM(REPLACE(RTRIM(a.matter_number),'0',' ') ),' ','0') [ID]
              ,CASE WHEN coop_fraud_potential_number_of_claimants IS NULL THEN fact_detail_client.number_of_claimants ELSE coop_fraud_potential_number_of_claimants END AS [No. of Claimants]
              ,incident_date As [RTA Date]
              ,date_instructions_received AS [Date Received]
              ,convert(char(3),date_instructions_received,0) as [Month Instructions Received]
              ,DATEADD(yy,-1,GETDATE()) as [Last 12 Months]
              ,dim_detail_core_details.fixed_fee as [Fixed Fee]
              ,coop_guid_reference_number AS GuidNumber
              ,CASE WHEN OutcomeOrder=1 THEN NULL
                       WHEN (Coalesce(FRA053Date,NMI726) IS NULL) THEN Coalesce(coop_fraud_outcome_date,coop_fraud_date_outcome_changed) ELSE (Coalesce(FRA053Date,NMI726))
                       END  AS [Date Closed/declared dormant]
              ,'' AS BlankColumn
              ,
              CASE WHEN 
              (CASE WHEN Coalesce(FRA053Date,NMI726) IS NULL  THEN  Coalesce(coop_fraud_outcome_date,coop_fraud_date_outcome_changed)  ELSE Coalesce(FRA053Date,NMI726) END) > 
              (CASE WHEN coalesce(FRA048Date,NMI727) IS NULL  THEN  Coalesce(coop_fraud_status,coop_fraud_date_status_changed) ELSE coalesce(FRA048Date,NMI727) END) 
              THEN (CASE WHEN Coalesce(FRA053Date,NMI726) IS NULL  THEN  Coalesce(coop_fraud_outcome_date,coop_fraud_date_outcome_changed) 
              ELSE Coalesce(FRA053Date,NMI726) END)
              WHEN (CASE WHEN coalesce(FRA048Date,NMI727) IS NULL THEN coalesce(coop_fraud_status,coop_fraud_date_status_changed) ELSE coalesce(FRA048Date,NMI727) END) > (CASE WHEN Coalesce(FRA053Date,NMI726) IS NULL THEN  Coalesce(coop_fraud_outcome_date,coop_fraud_date_outcome_changed) ELSE Coalesce(FRA053Date,NMI726) END) THEN (CASE WHEN coalesce(FRA048Date,NMI727) IS NULL THEN Coalesce(coop_fraud_status,coop_fraud_date_status_changed) ELSE coalesce(FRA048Date,NMI727) END) ELSE (CASE WHEN Coalesce(FRA053Date,NMI726) IS NULL THEN  Coalesce(coop_fraud_outcome_date,coop_fraud_date_outcome_changed) ELSE Coalesce(FRA053Date,NMI726) END) END AS [Date MI Updated]
              ,CASE WHEN LIT054 IS NULL THEN motor_date_of_instructions_being_reopened ELSE LIT054 END  AS [Date re-opened]
              ,coop_fraud_estimated_final_fee AS [Estimated Final Fee]
              ,CASE WHEN StatusOrder=1 THEN 'Open Claim - New'
              WHEN StatusOrder=2   THEN 'Open Claim - Investigation Process'
              WHEN StatusOrder=3   THEN 'Open Claim - Negotiation/Final Settlement Stage'
              WHEN StatusOrder=4   THEN 'Re-opened claim - from dormant 50%'
              WHEN StatusOrder=5   THEN 'Re-opened claim - from dormant 95%'
              WHEN StatusOrder=6   THEN 'Dormant - 50% Confidence'
              WHEN StatusOrder=7   THEN 'Dormant - 95% Confidence'
              WHEN StatusOrder=8   THEN 'Legally Closed'
              WHEN StatusOrder=9   THEN 'Transferred File'
              WHEN StatusOrder IS NULL THEN dim_detail_client.coop_fraud_status_text
              END  AS [Status]
              ,CASE WHEN OutcomeOrder=1  THEN   'Pending'
              WHEN OutcomeOrder=2  THEN   'Reduced Settlement'
              WHEN OutcomeOrder=3  THEN   'Gone Away'
              WHEN OutcomeOrder=4  THEN   'Withdrawn'
              WHEN OutcomeOrder=5  THEN   'Claims Fraud TP'   
              WHEN OutcomeOrder=6  THEN   'Claims Fraud PH'  
              WHEN OutcomeOrder=7  THEN   'Suspect TP'                    
              WHEN OutcomeOrder=8  THEN   'Suspect PH'          
             WHEN OutcomeOrder=9  THEN   'Indemnity Fraud'   
              WHEN OutcomeOrder=10 THEN   'Validated'
             WHEN OutcomeOrder=11 THEN   'Transferred File'
              WHEN OutcomeOrder IS NULL THEN coop_fraud_outcome
              END AS Outcome
              ,CASE WHEN  StatusOrder IN (6,7,8) AND OutcomeOrder IN (6,5,2,9,4,3) THEN 'First' END  AS ReportingTab
              ,coop_fraud_policyholder_involvement AS [Policyholder Involvement]
              ,ISNULL(coop_fraud_current_fraud_type,fraud_current_fraud_type)  [Fraud Type]
              ,coop_fraud_total_potential_reserve_for_all_claimants AS [MI Reserve]
              ,'' As BlankColumn2
              ,CASE WHEN PleadingIssued =1 THEN 'Yes'
              WHEN PleadingIssued=2 THEN 'No'  
              WHEN PleadingIssued IS NULL THEN proceedings_issued END AS [Date Pleadings Issued]
              ,CASE WHEN FRA049 IS NULL THEN coop_paid_prior_to_instruction ELSE FRA049 end AS [Paid prior to instruction]
            

			  ,CASE WHEN SettlementValue IS NULL THEN ISNULL((fact_finance_summary.damages_paid),0)
				+ISNULL((fact_finance_summary.claimants_costs_paid),0)
				+ISNULL((fact_finance_summary.other_defendants_costs_paid),0)
				+ISNULL((fact_finance_summary.detailed_assessment_costs_paid),0)
				-ISNULL((fact_finance_summary.recovery_claimants_damages_via_third_party_contribution),0)
				-ISNULL((fact_detail_recovery_detail.recovery_claimants_costs_via_third_party_contribution),0)
			   ELSE SettlementValue END  AS [Settlement Value]



              ,CASE WHEN AllFees.AllFees IS NULL THEN ISNULL((defence_costs_billed),0)  + ISNULL((disbursements_billed),0) ELSE AllFees.AllFees  END AS Fees
             
			  ,(ISNULL(coop_fraud_total_potential_reserve_for_all_claimants,0) +  ISNULL(fact_finance_summary.recovery_defence_costs_from_claimant,0)) - (ISNULL((CASE WHEN AllFees.AllFees IS NULL THEN (ISNULL((defence_costs_billed),0)  + ISNULL((disbursements_billed),0)) ELSE AllFees.AllFees  END),0)+ (CASE WHEN SettlementValue IS NULL THEN 
			  ISNULL((fact_finance_summary.damages_paid),0)
				+ISNULL((fact_finance_summary.claimants_costs_paid),0)
				+ISNULL((fact_finance_summary.other_defendants_costs_paid),0)
				+ISNULL((fact_finance_summary.detailed_assessment_costs_paid),0)

              ELSE SettlementValue END)) AS [Net Savings2]

              ,CASE WHEN OutcomeOrder = 1 THEN ISNULL(coop_fraud_total_potential_reserve_for_all_claimants,0) - ISNULL((CASE WHEN AllFees.AllFees IS NULL THEN (ISNULL((defence_costs_billed),0)  + ISNULL((disbursements_billed),0)) ELSE AllFees.AllFees  END),0)
                     ELSE ((ISNULL(coop_fraud_total_potential_reserve_for_all_claimants,0)) - (ISNULL((CASE WHEN AllFees.AllFees IS NULL THEN (ISNULL((defence_costs_billed),0)  + ISNULL((disbursements_billed),0)) ELSE AllFees.AllFees  END),0)+ (CASE WHEN SettlementValue IS NULL 
					 THEN ISNULL((fact_finance_summary.damages_paid),0)
					+ISNULL((fact_finance_summary.claimants_costs_paid),0)
					+ISNULL((fact_finance_summary.other_defendants_costs_paid),0)
					+ISNULL((fact_finance_summary.detailed_assessment_costs_paid),0)
					-ISNULL((fact_finance_summary.recovery_claimants_damages_via_third_party_contribution),0)
					-ISNULL((recovery_claimants_costs_via_third_party_contribution),0)

			ELSE SettlementValue END))) END AS [Net Savings]

              ,coop_fraud_europcar_recovery AS [Potential Recovery]
              ,coop_fraud_audit AS [Audit]
              ,brief_details_of_claim AS [Narrative]
              ,a.client_code AS mg_client,a.matter_number AS mg_matter
              ,coop_guid_reference_number AS Gunum
			  ,date_closed_case_management AS  date_closed
              ,hierarchylevel4hist AS  Team
              ,dim_fed_hierarchy_history.name AS [Weightmans Fee Earner]
              ,fee_earner_code AS FeeEarnerCode
              ,a.client_code AS Client,a.matter_number AS Matter
              ,CASE WHEN FileStatusOrder=1 THEN 'Open In FED'
                     WHEN FileStatusOrder=2 THEN 'Closed In FED' 
                     WHEN FileStatusOrder IS NULL AND date_closed_practice_management IS NOT NULL THEN 'Closed In FED' 
               END AS FedStatus
              ,coop_fraud_master_date_closed_dormant AS [Master date closed/ dormant]     
              ,coop_fraud_master_date_mi_updated AS [Master date MI updated]
              ,coop_fraud_master_status AS [Master Status]
              ,coop_fraud_master_outcome AS [Master Outcome]
              ,coop_fraud_master_settlement_value AS [Master settlement value]
              ,coop_fraud_master_fees AS [Master fees]      
              ,coop_fraud_master_net_savings AS [Master net savings]
              ,wip AS [WIPBal]
              ,defence_costs_billed AS [TotalProfitCostsBilled]
			  ,defence_costs_vat AS  ProfitCostsVAT
			  ,dim_detail_core_details.present_position AS TRA125
			  ,ChangeDate [SAPClosedDate]
			  ,date_claim_concluded as [Date Claim Concluded]
			  ,convert(char(3),date_claim_concluded,0) as [Month Claim Concluded]
			  ,year(date_claim_concluded) as [Year Claim Concluded]
			  ,NMI065.NMI065 AS NMI065
			  ,incident_location_postcode as [Incident Location]
			  ,CASE WHEN PresentPositionOrder=1 THEN 'Claim and costs outstanding' 
			  WHEN PresentPositionOrder=2 THEN 'Claim concluded but costs outstanding'
			  WHEN PresentPositionOrder=3 THEN 'Claim and costs concluded but recovery outstanding'
			  WHEN PresentPositionOrder=4 THEN 'Final bill due - claim and costs concluded'
			  WHEN PresentPositionOrder=5 THEN 'Final bill sent - unpaid'
			  WHEN PresentPositionOrder=6 THEN 'To be closed/minor balances to be clear'
			  END AS [Present Position]
			  ,NMI728.NMI728 AS [Date of repudiation] 
			  ,TRA084.TRA084 AS [Date Proceedings Issued]
			,TRA076Leadlink AS [Damages Reserve Held LeadLinked]
			,TRA080Leadlink AS [Opponents Costs Reserve Held LeadLinked]
			,TRA078Leadlink AS [Defence Costs Reserve Held LeadLinked]
			,CASE WHEN ABIOrder=1 THEN 'Proven'
				  WHEN ABIOrder=2 THEN 'None'
				  WHEN ABIOrder=3 THEN 'Suspected'
				  ELSE [coop_fraud_abi_fraud_proven]END AS NMI864
			,CASE WHEN FringOrder=1 THEN 'Yes'
				  WHEN FringOrder=2 THEN 'No'
				  ELSE coop_fraud_is_this_a_fraud_ring END AS NMI814
		    ,coop_underwriting_referral_made AS NMI973
		    ,AllDisbLeadLink
		    ,PreLitFees
		   ,PostLitFees
-- select *
FROM red_dw.dbo.dim_matter_header_current AS a  WITH (NOLOCK)
INNER JOIN red_dw.dbo.fact_dimension_main  AS b  WITH (NOLOCK) 
 ON a.dim_matter_header_curr_key=b.dim_matter_header_curr_key
INNER JOIN ( SELECT dim_detail_client_key FROM red_dw.dbo.dim_detail_client  WITH (NOLOCK) 
			 WHERE coop_master_reporting ='Yes'
) AS CooopMatters
ON b.dim_detail_client_key=CooopMatters.dim_detail_client_key
INNER JOIN red_dw.dbo.dim_detail_core_details WITH (NOLOCK) 
 ON b.dim_detail_core_detail_key=dim_detail_core_details.dim_detail_core_detail_key AND is_this_the_lead_file='Yes'
LEFT OUTER JOIN red_dw.dbo.dim_detail_client AS dim_detail_client  WITH (NOLOCK)
 ON b.dim_detail_client_key=dim_detail_client.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud WITH (NOLOCK)
 ON b.dim_detail_fraud_key=dim_detail_fraud.dim_detail_fraud_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail WITH (NOLOCK)
 ON a.client_code=fact_detail_reserve_detail.client_code AND a.matter_number=fact_detail_reserve_detail.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail WITH (NOLOCK)
 ON a.client_code=fact_detail_paid_detail.client_code AND a.matter_number=fact_detail_paid_detail.matter_number 
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
 ON a.client_code=fact_finance_summary.client_code AND a.matter_number=fact_finance_summary.matter_number  
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail WITH (NOLOCK)
 ON a.client_code=fact_detail_recovery_detail.client_code AND a.matter_number=fact_detail_recovery_detail.matter_number  
LEFT OUTER JOIN red_dw.dbo.fact_detail_client WITH (NOLOCK)
 ON a.client_code=fact_detail_client.client_code AND a.matter_number=fact_detail_client.matter_number 

LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH (NOLOCK)
 ON b.dim_detail_outcome_key=dim_detail_outcome.dim_detail_outcome_key

LEFT OUTER JOIN (SELECT dim_defendant_involvement.client_code
,dim_defendant_involvement.matter_number
,client_name AS defendant_name
FROM red_dw.dbo.dim_defendant_involvement WITH (NOLOCK) 
INNER join red_dw.dbo.fact_dimension_main WITH (NOLOCK) ON fact_dimension_main.dim_defendant_involvem_key = dim_defendant_involvement.dim_defendant_involvem_key
INNER join red_dw.dbo.dim_involvement_full WITH (NOLOCK)  ON dim_involvement_full.dim_involvement_full_key = dim_defendant_involvement.defendant_1_key
INNER join red_dw.dbo.dim_client WITH (NOLOCK) ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
WHERE dim_defendant_involvement.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
AND defendant_1_key IS NOT NULL) AS defendant
 ON a.client_code=defendant.client_code AND a.matter_number=defendant.matter_number 

LEFT OUTER JOIN (SELECT dim_client_involvement.client_code
,dim_client_involvement.matter_number
,dim_client.client_name AS InsuredName
FROM red_dw.dbo.dim_client_involvement
INNER join red_dw.dbo.fact_dimension_main ON fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
INNER join red_dw.dbo.dim_involvement_full ON dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insuredclient_1_key
INNER join red_dw.dbo.dim_client ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
WHERE dim_client_involvement.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
AND insuredclient_1_key IS NOT NULL) AS InsuredName 
 ON a.client_code=InsuredName.client_code AND a.matter_number=InsuredName.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement WITH (NOLOCK) 
 ON a.client_code=dim_client_involvement.client_code AND a.matter_number=dim_client_involvement.matter_number

LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH (NOLOCK) 
 ON a.fee_earner_code=fed_code collate database_default AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim WITH (NOLOCK)   ON b.dim_detail_claim_key=dim_detail_claim.dim_detail_claim_key
LEFT OUTER JOIN 
				(
SELECT coop_guid_reference_number AS GuidNumber,MAX(coop_fraud_date_outcome_changed)  AS NMI726 FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
				) AS NMI726
		on coop_guid_reference_number=NMI726.GuidNumber

LEFT OUTER JOIN 
			(
SELECT coop_guid_reference_number AS GuidNumber,MAX(coop_fraud_status)  AS FRA048Date FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK) 
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK) 
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
			) AS FRA048Date
		on coop_guid_reference_number=FRA048Date.GuidNumber
		
LEFT OUTER JOIN 
			(
SELECT coop_guid_reference_number AS GuidNumber,MAX(coop_fraud_outcome_date)  AS FRA053Date FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
			) AS FRA053
		on coop_guid_reference_number=FRA053.GuidNumber
		
LEFT OUTER JOIN 
			(
SELECT coop_guid_reference_number AS GuidNumber,MAX(b.date_proceedings_issued)  AS TRA084 FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_court WITH (NOLOCK)
  ON a.dim_detail_court_key=dim_detail_court.dim_detail_court_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
			) AS TRA084
		on coop_guid_reference_number=TRA084.GuidNumber

LEFT OUTER JOIN 
			(
	SELECT coop_guid_reference_number AS GuidNumber,MAX(coop_fraud_outcome_date)  AS NMI727 FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
			) AS NMI727
		on coop_guid_reference_number=NMI727.GuidNumber
		LEFT OUTER JOIN 
			(
SELECT coop_guid_reference_number AS GuidNumber,SUM(damages_interims)  AS NMI065 FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK) 
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK) 
  ON a.client_code=fact_finance_summary.client_code AND a.matter_number=fact_finance_summary.matter_number
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
			) AS NMI065
	on coop_guid_reference_number=NMI065.GuidNumber
	  LEFT OUTER JOIN 
			(
SELECT coop_guid_reference_number AS GuidNumber,MAX(motor_date_of_instructions_being_reopened)  AS LIT054 FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key 
LEFT OUTER JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number

			) AS LIT054
	on coop_guid_reference_number=LIT054.GuidNumber
LEFT OUTER JOIN 
	(
	
SELECT coop_guid_reference_number AS GuidNumber,SUM(damages_reserve)  AS TRA076Leadlink FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
  ON a.client_code=fact_finance_summary.client_code AND a.matter_number=fact_finance_summary.matter_number
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
	) AS TRA076LeadLinked
on coop_guid_reference_number=TRA076LeadLinked.GuidNumber	

LEFT OUTER JOIN 
	(
SELECT coop_guid_reference_number AS GuidNumber,SUM(claimant_costs_reserve_current)  AS TRA080Leadlink FROM red_dw.dbo.fact_dimension_main AS a WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH(NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_detail_reserve_detail WITH(NOLOCK) 
  ON a.client_code=fact_detail_reserve_detail.client_code AND a.matter_number=fact_detail_reserve_detail.matter_number
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
	) AS TRA080Leadlink
on coop_guid_reference_number=TRA080Leadlink.GuidNumber
LEFT OUTER JOIN 
	(

SELECT coop_guid_reference_number AS GuidNumber,SUM(defence_costs_reserve)  AS TRA078Leadlink FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
  ON a.client_code=fact_finance_summary.client_code AND a.matter_number=fact_finance_summary.matter_number
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number

	) AS TRA078Leadlink
on coop_guid_reference_number=TRA078Leadlink.GuidNumber

LEFT OUTER JOIN 
			(
	SELECT coop_guid_reference_number AS GuidNumber,MIN(coop_fraud_date_of_repudiation)  AS NMI728 FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
			) AS NMI728
		on coop_guid_reference_number=NMI728.GuidNumber
	LEFT OUTER JOIN
		(
		SELECT GuidNumber,Min(StatusOrder)AS StatusOrder
		FROM 
			(
		SELECT coop_guid_reference_number AS GuidNumber

,CASE WHEN coop_fraud_status_text='Open Claim - New' THEN 1
				  WHEN coop_fraud_status_text IN ('Open claim - investigation process','Open Claim - Investigation Process') THEN 2
				  WHEN coop_fraud_status_text IN ('Open Claim - Negotiation/Final Settlement Stage','Open claim - negotiation/final settlement stage') THEN 3
				  WHEN coop_fraud_status_text='Re-opened Claim - From Dormant 50%' THEN 4
				  WHEN coop_fraud_status_text='Re-opened Claim - From Dormant 95%' THEN 5
				  WHEN coop_fraud_status_text IN ('Dormant - 50% confidence','Dormant - 50% Confidence') THEN 6
				  WHEN coop_fraud_status_text IN ('Dormant - 95% Confidence','Dormant - 95% confidence') THEN 7
				  WHEN coop_fraud_status_text IN ('Legally Closed','Legally closed') THEN 8
				  WHEN coop_fraud_status_text IN ('Transferred file','Transferred File') THEN 9 END AS StatusOrder
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK) 
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
--AND coop_fraud_status_text IS NOT NULL
) As ClaimStatus
Group by GuidNumber
		) As StatusOrder
	on coop_guid_reference_number=StatusOrder.GuidNumber
	
LEFT OUTER JOIN
		(
SELECT GuidNumber,Min(ABIOrder)AS ABIOrder
		FROM 
			(SELECT coop_guid_reference_number AS GuidNumber
,CASE WHEN coop_fraud_abi_fraud_proven='Proven' THEN 1
				  WHEN coop_fraud_abi_fraud_proven='None' THEN 2
				  WHEN coop_fraud_abi_fraud_proven='Suspected' THEN 3
			END AS ABIOrder
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b  WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
--AND coop_fraud_abi_fraud_proven IS NOT NULL
	) As ClaimStatus
		Group by GuidNumber
		) As ABIOrder
	on coop_guid_reference_number=ABIOrder.GuidNumber
	LEFT OUTER JOIN
		(
 SELECT GuidNumber,Min(FringOrder)AS FringOrder
		FROM 
			(SELECT coop_guid_reference_number AS GuidNumber
,CASE WHEN coop_fraud_is_this_a_fraud_ring='Yes' THEN 1
				  WHEN coop_fraud_is_this_a_fraud_ring='No' THEN 2

			END AS FringOrder 
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud WITH (NOLOCK) 
  ON a.dim_detail_fraud_key=dim_detail_fraud.dim_detail_fraud_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
--AND coop_fraud_is_this_a_fraud_ring IS NOT NULL
	) As ClaimStatus
		Group by GuidNumber

		) As FringOrder
	on coop_guid_reference_number=FringOrder.GuidNumber

LEFT OUTER JOIN
	(

		SELECT GuidNumber,Min(FileStatusOrder)AS FileStatusOrder
		FROM 
		(
SELECT coop_guid_reference_number AS GuidNumber
		,CASE WHEN date_closed_case_management IS NULL  THEN     1
		WHEN date_closed_case_management IS NOT NULL THEN 2
		END AS FileStatusOrder

FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
 ON a.dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
		) As ClaimStatus
		Group by GuidNumber
		) As FileStatusOrder
	on coop_guid_reference_number=FileStatusOrder.GuidNumber
	
LEFT OUTER JOIN
	(
	SELECT GuidNumber,Min(OutcomeOrder)AS OutcomeOrder
		FROM 
			(
		SELECT coop_guid_reference_number AS GuidNumber

	,CASE 
			WHEN coop_fraud_outcome='Pending'    THEN   1
			WHEN coop_fraud_outcome IN ('Reduced Settlement','Reduced settlement') THEN   2
			WHEN coop_fraud_outcome IN ('Gone Away','Gone away')THEN   3
			WHEN coop_fraud_outcome='Withdrawn' THEN   4
			WHEN coop_fraud_outcome IN ('Claims Fraud TP','Claims fraud TP')      THEN   5
			WHEN coop_fraud_outcome='Claims Fraud PH' THEN   6
			WHEN coop_fraud_outcome='Suspect TP' THEN   7
			WHEN coop_fraud_outcome='Suspect PH'    THEN   8
			WHEN coop_fraud_outcome IN ('Indemnity Fraud','Indemnity fraud')  THEN   9
			WHEN coop_fraud_outcome='Validated' THEN   10
			WHEN coop_fraud_outcome IN ('Transferred File','Transferred file')      THEN   11 
		 END AS OutcomeOrder
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
--AND coop_fraud_outcome IS NOT NULL

) As ClaimStatus
Group by GuidNumber
	) As OutcomeStatus
	on coop_guid_reference_number=OutcomeStatus.GuidNumber
	
LEFT OUTER JOIN
	(

	
	SELECT GuidNumber,Min(PleadingIssued) AS PleadingIssued
	FROM 
	(	
SELECT coop_guid_reference_number AS GuidNumber,proceedings_issued  AS TRA082
	,CASE WHEN proceedings_issued='Yes' THEN 1
	WHEN proceedings_issued='No' THEN 2 END AS PleadingIssued
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_court WITH (NOLOCK)
  ON a.dim_detail_court_key=dim_detail_court.dim_detail_court_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
AND proceedings_issued IS NOT NULL
	) As PleadingIssued
	Group by GuidNumber
	) As PleadingIssued
on coop_guid_reference_number=PleadingIssued.GuidNumber	
	
	
LEFT OUTER JOIN 
(

SELECT coop_guid_reference_number AS GuidNumber,SUM(coop_paid_prior_to_instruction)  AS FRA049 FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_detail_paid_detail WITH (NOLOCK)
  ON a.client_code=fact_detail_paid_detail.client_code AND a.matter_number=fact_detail_paid_detail.matter_number
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
) AS FRA049
on coop_guid_reference_number=FRA049.GuidNumber	
	
LEFT OUTER JOIN 
(
SELECT coop_guid_reference_number AS GuidNumber
,ISNULL(SUM(damages_paid),0)
+ISNULL(SUM(claimants_costs_paid),0)
+ISNULL(SUM(other_defendants_costs_paid),0)
+ISNULL(SUM(detailed_assessment_costs_paid),0)
-ISNULL(SUM(fact_finance_summary.recovery_claimants_damages_via_third_party_contribution),0)
-ISNULL(SUM(recovery_claimants_costs_via_third_party_contribution),0)


AS SettlementValue
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK) 
  ON a.client_code=fact_finance_summary.client_code AND a.matter_number=fact_finance_summary.matter_number
LEFT JOIN red_dw.dbo.fact_detail_recovery_detail WITH (NOLOCK)
  ON a.client_code=fact_detail_recovery_detail.client_code AND a.matter_number=fact_detail_recovery_detail.matter_number


WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number
) AS SettlementValue
on coop_guid_reference_number=SettlementValue.GuidNumber	

	LEFT OUTER JOIN
	(
SELECT GuidNumber,Min(PresentPositionOrder)AS PresentPositionOrder
		FROM 
			(
		SELECT coop_guid_reference_number AS GuidNumber

		,CASE WHEN b.present_position='Claim and costs outstanding'    THEN   1
			WHEN b.present_position='Claim concluded but costs outstanding'      THEN   2
			WHEN b.present_position='Claim and costs concluded but recovery outstanding'    THEN   3
			WHEN b.present_position='Final bill due - claim and costs concluded' THEN   4
			WHEN b.present_position='Final bill sent - unpaid'      THEN   5
			WHEN b.present_position='To be closed/minor balances to be clear' THEN   6
			END AS PresentPositionOrder 
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b  WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_client WITH (NOLOCK)
  ON a.dim_detail_client_key=dim_detail_client.dim_detail_client_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
AND b.present_position IS NOT NULL

) As ClaimStatus
Group by GuidNumber
	) As PresentPosition
	on coop_guid_reference_number=PresentPosition.GuidNumber	

LEFT OUTER JOIN 
(

SELECT coop_guid_reference_number AS GuidNumber
,ISNULL(SUM(defence_costs_billed),0)  + ISNULL(Sum(disbursements_billed),0) AS AllFees 
, ISNULL(Sum(disbursements_billed),0) AS AllDisbLeadLink
FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
  ON a.client_code=fact_finance_summary.client_code AND a.matter_number=fact_finance_summary.matter_number
LEFT JOIN red_dw.dbo.fact_detail_recovery_detail WITH (NOLOCK)
  ON a.client_code=fact_detail_recovery_detail.client_code AND a.matter_number=fact_detail_recovery_detail.matter_number


WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number

) AS AllFees
on coop_guid_reference_number=AllFees.GuidNumber
LEFT  OUTER JOIN 
(
SELECT TRA123.case_text AS GuidNumber,ISNULL(SUM(fact_bill.fees_total),0) AS PostLitFees 
FROM red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
INNER JOIN red_dw.dbo.fact_bill  WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_bill.client_code AND dim_matter_header_current.matter_number=fact_bill.matter_number
INNER JOIN red_dw.dbo.dim_bill_date WITH (NOLOCK) ON fact_bill.dim_bill_date_key=dim_bill_date.dim_bill_date_key  
INNER JOIN (SELECT client_code,matter_number ,coop_guid_reference_number AS case_text 
			FROM  red_dw.dbo.dim_detail_core_details WITH (NOLOCK)  ) AS TRA123
ON dim_matter_header_current.client_code=TRA123.client_code AND dim_matter_header_current.matter_number=TRA123.matter_number
LEFT OUTER JOIN (SELECT coop_guid_reference_number AS GuidNumber,MAX(b.date_proceedings_issued)  AS TRA084 FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_court WITH (NOLOCK)
  ON a.dim_detail_court_key=dim_detail_court.dim_detail_court_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number) AS Proceedings
			 ON TRA123.case_text=Proceedings.GuidNumber


WHERE fact_bill.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421','00046046','00046202','00068919','00144358','00157705')
AND TRA123.case_text not like  '%Legacy%' AND TRA123.case_text not like  '%legacy%'
AND dim_bill_date.bill_date >=TRA084
--AND GuidNumber='101053'
GROUP BY TRA123.case_text
)	 AS PostlitFees
ON   coop_guid_reference_number=PostlitFees.GuidNumber


LEFT  OUTER JOIN 
(
SELECT TRA123.case_text AS GuidNumber,ISNULL(SUM(fact_bill.fees_total),0) AS PreLitFees 
FROM red_dw.dbo.dim_matter_header_current WITH (NOLOCK)
INNER JOIN red_dw.dbo.fact_bill  WITH (NOLOCK)
 ON dim_matter_header_current.client_code=fact_bill.client_code AND dim_matter_header_current.matter_number=fact_bill.matter_number
INNER JOIN red_dw.dbo.dim_bill_date WITH (NOLOCK) ON fact_bill.dim_bill_date_key=dim_bill_date.dim_bill_date_key  
INNER JOIN (SELECT client_code,matter_number ,coop_guid_reference_number AS case_text 
			FROM  red_dw.dbo.dim_detail_core_details WITH (NOLOCK)  ) AS TRA123
ON dim_matter_header_current.client_code=TRA123.client_code AND dim_matter_header_current.matter_number=TRA123.matter_number
LEFT OUTER JOIN (SELECT coop_guid_reference_number AS GuidNumber,MAX(b.date_proceedings_issued)  AS TRA084 FROM red_dw.dbo.fact_dimension_main AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_detail_core_details AS b WITH (NOLOCK)
 ON a.dim_detail_core_detail_key=b.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_court WITH (NOLOCK)
  ON a.dim_detail_court_key=dim_detail_court.dim_detail_court_key
WHERE coop_guid_reference_number not like  '%Legacy%'
AND a.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421')
GROUP BY coop_guid_reference_number) AS Proceedings
			 ON TRA123.case_text=Proceedings.GuidNumber


WHERE fact_bill.client_code IN('C1001','00046018','00046043','00046045','00057428','00059244','00069916','00066421','00060421','00046046','00046202','00068919','00144358','00157705')
AND TRA123.case_text not like  '%Legacy%' AND TRA123.case_text not like  '%legacy%'
AND dim_bill_date.bill_date <ISNULL(TRA084,GETDATE())
GROUP BY TRA123.case_text
)	 AS PrelitFees
ON  coop_guid_reference_number=PrelitFees.GuidNumber


 LEFT OUTER JOIN dbo.CoopTRA125ChangeDate AS CoopTRA125ChangeDate
  ON coop_guid_reference_number=CoopTRA125ChangeDate.GuidNumber collate database_default

LEFT OUTER JOIN dbo.CoopMIUDataLookup AS CleanData
 ON a.client_code=CleanData.client collate database_default	
 AND a.matter_number=CleanData.matter collate database_default	
WHERE case_id NOT IN(472370,456379)


 ) AS AllData
END


GO

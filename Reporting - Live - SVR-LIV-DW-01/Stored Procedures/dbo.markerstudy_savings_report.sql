SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[markerstudy_savings_report]

AS 

BEGIN

SELECT 
	  dim_client_involvement.insuredclient_name				                    AS [Insured]
	, YEAR(dim_detail_claim.date_of_accident)				                    AS [YOA]
	, dim_client_involvement.insurerclient_reference		                    AS [Claim No.]
	, CAST(dim_detail_claim.date_of_accident AS DATE)		                    AS [Date of Loss]
	, 'Weightmans'											                    AS [Panel Firm]
	, dim_matter_header_current.matter_owner_full_name		                    AS [Fee Earner]
	, matter_description                                                        AS [Matter Description]
	, dim_matter_header_current.master_client_code + 
	'/' + dim_matter_header_current.master_matter_number		                AS [Panel Firm Ref.]
	, CAST(dim_detail_core_details.date_instructions_received AS DATE)			AS [Date Instructed]
	, fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction		AS [Paid]
	, msprod.udMIClientMSG_curCliOutRes			                                AS [Outstanding]            --curCliOutRes  -- Needs updating with new DWH field
	, msprod.udMIClientMSG_curCliRecMade			                            AS [Recoveries Received]	--curCliRecMade  -- Needs updating with new DWH field
	, msprod.udMIClientMSG_curCliRecRes			                                AS [Recoveries Reserved]	--curCliRecRes  -- Needs updating with new DWH field
	
	, (ISNULL(fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction, 0) + ISNULL(msprod.udMIClientMSG_curCliOutRes, 0)) 
			- (ISNULL(msprod.udMIClientMSG_curCliRecMade, 0) + ISNULL(msprod.udMIClientMSG_curCliRecRes	, 0))			AS [Incurred (Net of Recoveries)]  --To be updated when new fields available
	
	, CASE	
		WHEN dim_detail_outcome.outcome_of_case IS NULL THEN 
			'No'
		ELSE
			'Yes'
	  END						                                                  AS [Damages Settled]
	, fact_finance_summary.damages_paid			                                  AS [Damages Settlement Amount]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)				          AS [Date Damages Settled]
	--======================================================================================================
	-- I think these are the types of field where you can create multiple versions of them in MS 
	-- They will probably be put into dim_child and fact_child.
	-- I think we'll need to pick up the most recent entry for each matter but I couldn't build that bit until the fields are in sorry
	-- Worth double checking with Bob re this bit though. He's been off this week so haven't been able to catch up with him
	--======================================================================================================
	, msprod.udMIClientMSGDefDamSL_curAmount				            AS [Defendant Offer Made]       --udMIClientMSGDefDamSL.curAmount         -- Needs updating with new DWH field
	, msprod.udMIClientMSGDefDamSL_dteOffer 						    AS [Date Defendant Offer Made]  --udMIClientMSGDefDamSL.dteOffer          -- Needs updating with new DWH field
	, msprod.udMIClientMSGDefDamSL_cboTypeOffer   						AS [Type of Defendant Offer]	--udMIClientMSGDefDamSL.cboTypeOffer      -- Needs updating with new DWH field
	, msprod.udMIClientMSGClaimDamSL_curAmount						    AS [Claimant Offer Made]		--udMIClientMSGClaimDamSL.curAmount       -- Needs updating with new DWH field
	, msprod.udMIClientMSGClaimDamSL_dteOffer						    AS [Date Claimant Offer Made]	--udMIClientMSGClaimDamSL.dteOffer        -- Needs updating with new DWH field
	, msprod.udMIClientMSGClaimDamSL_cboTypeOffer						AS [Type of Claimant Offer]		--udMIClientMSGClaimDamSL.cboTypeOffer    -- Needs updating with new DWH field
	--======================================================================================================
	, CASE	
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			'No'
		ELSE
			'Yes'
	  END						                                            AS [Costs Settled]
	, fact_finance_summary.claimants_total_costs_claimed		            AS [Costs Claimed]
	, fact_finance_summary.claimants_costs_paid			                    AS [Costs Settlement Amount]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)		            AS [Date Costs Agreed]
	--======================================================================================================
	-- I think these are the types of field where you can create multiple versions of them in MS 
	-- They will probably be put into dim_child and fact_child.
	-- I think we'll need to pick up the most recent entry for each matter but I couldn't build that bit until the fields are in sorry
	-- Worth double checking with Bob re this bit though. He's been off this week so haven't been able to catch up with him
	--======================================================================================================
	, msprod.udMIClientMSGDefCostsSL_curAmount				                AS [Offer Made by Defendant to Settle Claimant Costs]		--udMIClientMSGDefCostsSL.curAmount 
	, msprod.udMIClientMSGDefCostsSL_dteOffer				                AS [Date Costs Offer Made]									--udMIClientMSGDefCostsSL.dteOffer 
	--======================================================================================================
	, dim_detail_core_details.proceedings_issued			                AS [Proceedings Issued]
	
	, CASE	
		WHEN ISNULL(fact_detail_reserve_detail.total_reserve, 0) = (ISNULL(fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction, 0) + ISNULL(msprod.udMIClientMSG_curCliOutRes	, 0)) THEN
			'No'
		ELSE
			'Yes'
	  END					AS [Reserve Recommendation Made]	--If there's a difference between out total reserve and (paid + outstanding columns) then Yes else No
	
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)		AS [Date File Closed]
	, ''				                                                            AS [Relevant Comments (Optional)] 
	--======================================================================================================
	-- Internal report fields below
	--======================================================================================================
	, dim_detail_core_details.referral_reason			    AS [Referral Reason]
	, dim_detail_core_details.delegated					    AS [Delegated]
	, dim_detail_finance.output_wip_fee_arrangement		    AS [Fee Arrangement]
	, fact_finance_summary.fixed_fee_amount			        AS [Fixed Fee Amount]
	, dim_detail_core_details.track				            AS [Track]
	, dim_client_involvement.insurerclient_name		        AS [Insurer Associate]
	, dim_detail_core_details.present_position			    AS [Present Position]
	, msprod.udMIClientMSG_cboInsTypeMSG			        AS [Claims Strategy]  --cboInsTypeMSG -- Needs updating with new DWH field
	, dim_detail_core_details.injury_type	        	    AS [Injury Type]
	, fact_detail_paid_detail.damages_interims		        AS [Interim Damages Post Instruction]
	, dim_detail_core_details.suspicion_of_fraud	        AS [Suspicion of Fraud]
	, dim_detail_core_details.credit_hire		            AS [Credit Hire]
	, dim_detail_core_details.has_the_claimant_got_a_cfa    AS [Has Claimant got a CFA]
	, fact_detail_reserve_detail.damages_reserve			AS [Damages Reserve]
	, fact_detail_reserve_detail.tp_costs_reserve			AS [Claimant Costs Reserve]
	, fact_detail_reserve_detail.defence_costs_reserve		AS [Defence Costs Reserve]
	, fact_detail_reserve_detail.total_reserve				AS [Total Reserve]

FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

		/* Temp MS Prod tables -- to be removed after new fields added to DWH*/

	LEFT JOIN (
     SELECT DISTINCT
       udMIClientMSG.[fileID]
      ,udMIClientMSG.[mcbClaimStrat]      AS udMIClientMSG_mcbClaimStrat
      ,udMIClientMSG.[curCliOutRes]       AS udMIClientMSG_curCliOutRes
      ,udMIClientMSG.[curCliRecMade]      AS udMIClientMSG_curCliRecMade
      ,udMIClientMSG.[curCliRecRes]       AS udMIClientMSG_curCliRecRes
	  ,dbCodeLookup.cdDesc                AS udMIClientMSG_cboInsTypeMSG
	  ,udMIClientMSGDefCostsSL.curAmount  AS udMIClientMSGDefCostsSL_curAmount
      ,udMIClientMSGDefCostsSL.dteOffer   AS udMIClientMSGDefCostsSL_dteOffer
	  ,udMIClientMSGClaimDamSL.curAmount  AS udMIClientMSGClaimDamSL_curAmount
      ,udMIClientMSGClaimDamSL.dteOffer   AS udMIClientMSGClaimDamSL_dteOffer
      ,lk.cdDesc                          AS udMIClientMSGClaimDamSL_cboTypeOffer 
	  ,udMIClientMSGDefDamSL.curAmount    AS udMIClientMSGDefDamSL_curAmount
	  ,udMIClientMSGDefDamSL.dteOffer     AS udMIClientMSGDefDamSL_dteOffer
	  ,udMIClientMSGDefDamSL.cboTypeOffer AS udMIClientMSGDefDamSL_cboTypeOffer
       
  FROM [MS_Prod].[dbo].[udMIClientMSG]
  LEFT JOIN [MS_Prod].[dbo].dbCodeLookup ON cdType = 'MSGINSTYPE' AND cdCode = [cboInsTypeMSG]
  LEFT JOIN [MS_Prod].[dbo].udMIClientMSGDefCostsSL ON udMIClientMSGDefCostsSL.fileID = udMIClientMSG.fileID
  LEFT JOIN [MS_Prod].[dbo].udMIClientMSGClaimDamSL ON udMIClientMSGClaimDamSL.fileID = udMIClientMSG.fileID
  LEFT JOIN [MS_Prod].[dbo].dbCodeLookup lk ON lk.cdType = 'MSGOFF' AND lk.cdCode = cboTypeOffer 
  LEFT JOIN [MS_Prod].[dbo].udMIClientMSGDefDamSL ON udMIClientMSGDefDamSL.fileID = udMIClientMSG.fileID
   
   ) msprod ON ms_fileid = msprod.[fileID]


WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'W24438'
	AND dim_matter_header_current.master_matter_number <> 0
	AND dim_matter_header_current.reporting_exclusions = 0
	AND LOWER(LTRIM(RTRIM(ISNULL(dim_detail_outcome.outcome_of_case, '')))) <> 'exclude from reports'
	
	AND msprod.udMIClientMSG_cboInsTypeMSG = 'MSG Savings project' --Need to update the field to dwh field

ORDER BY	
	dim_detail_core_details.date_instructions_received
	, dim_matter_header_current.master_matter_number


END	

/*  Old Version pre 19/02/2021


ALTER PROCEDURE [dbo].[markerstudy_savings_report]

AS 

BEGIN

SELECT 
	dim_client_involvement.insuredclient_name				AS [Insured]
	, YEAR(dim_detail_claim.date_of_accident)				AS [YOA]
	, dim_client_involvement.insurerclient_reference		AS [Claim No.]
	, CAST(dim_detail_claim.date_of_accident AS DATE)		AS [Date of Loss]
	, 'Weightmans'											AS [Panel Firm]
	, dim_matter_header_current.matter_owner_full_name		AS [Fee Earner]
	, dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [Panel Firm Ref.]
	, CAST(dim_detail_core_details.date_instructions_received AS DATE)			AS [Date Instructed]
	, fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction		AS [Paid]
	, ''			AS [Outstanding]  --curCliOutRes
	, ''			AS [Recoveries Received]	--curCliRecMade
	, ''			AS [Recoveries Reserved]	--curCliRecRes
	/*
	, (ISNULL(fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction, 0) + ISNULL([Outstanding], 0)) 
			- (ISNULL([Recoveries Received], 0) + ISNULL([Recoveries Reserved], 0))			AS [Incurred (Net of Recoveries)]  --To be updated when new fields available
	*/
	, CASE	
		WHEN dim_detail_outcome.outcome_of_case IS NULL THEN 
			'No'
		ELSE
			'Yes'
	  END						AS [Damages Settled]
	, fact_finance_summary.damages_paid			AS [Damages Settlement Amount]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)					AS [Date Damages Settled]
	--======================================================================================================
	-- I think these are the types of field where you can create multiple versions of them in MS 
	-- They will probably be put into dim_child and fact_child.
	-- I think we'll need to pick up the most recent entry for each matter but I couldn't build that bit until the fields are in sorry
	-- Worth double checking with Bob re this bit though. He's been off this week so haven't been able to catch up with him
	--======================================================================================================
	, ''						AS [Defendant Offer Made]   --udMIClientMSGDefDamSL.curAmount
	, ''						AS [Date Defendant Offer Made]		--udMIClientMSGDefDamSL.dteOffer
	, ''						AS [Type of Defendant Offer]		--udMIClientMSGDefDamSL.cboTypeOffer 
	, ''						AS [Claimant Offer Made]		--udMIClientMSGClaimDamSL.curAmount
	, ''						AS [Date Claimant Offer Made]	--udMIClientMSGClaimDamSL.dteOffer
	, ''						AS [Type of Claimant Offer]		--udMIClientMSGClaimDamSL.cboTypeOffer 
	--======================================================================================================
	, CASE	
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			'No'
		ELSE
			'Yes'
	  END						AS [Costs Settled]
	, fact_finance_summary.claimants_total_costs_claimed		AS [Costs Claimed]
	, fact_finance_summary.claimants_costs_paid			AS [Costs Settlement Amount]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)		AS [Date Costs Agreed]
	--======================================================================================================
	-- I think these are the types of field where you can create multiple versions of them in MS 
	-- They will probably be put into dim_child and fact_child.
	-- I think we'll need to pick up the most recent entry for each matter but I couldn't build that bit until the fields are in sorry
	-- Worth double checking with Bob re this bit though. He's been off this week so haven't been able to catch up with him
	--======================================================================================================
	, ''				AS [Offer Made by Defendant to Settle Claimant Costs]		--udMIClientMSGDefCostsSL.curAmount 
	, ''				AS [Date Costs Offer Made]									--udMIClientMSGDefCostsSL.dteOffer 
	--======================================================================================================
	, dim_detail_core_details.proceedings_issued			AS [Proceedings Issued]
	/*
	, CASE	
		WHEN ISNULL(fact_detail_reserve_detail.total_reserve, 0) = (ISNULL(fact_detail_paid_detail.interim_damages_paid_by_client_preinstruction, 0) + ISNULL([Outstanding], 0)) THEN
			'No'
		ELSE
			'Yes'
	  END					AS [Reserve Recommendation Made]	--If there's a difference between out total reserve and (paid + outstanding columns) then Yes else No
	*/
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)		AS [Date File Closed]
	, ''				AS [Relevant Comments (Optional)] 
	--======================================================================================================
	-- Internal report fields below
	--======================================================================================================
	, dim_detail_core_details.referral_reason			AS [Referral Reason]
	, dim_detail_core_details.delegated					AS [Delegated]
	, dim_detail_finance.output_wip_fee_arrangement		AS [Fee Arrangement]
	, fact_finance_summary.fixed_fee_amount			AS [Fixed Fee Amount]
	, dim_detail_core_details.track				AS [Track]
	, dim_client_involvement.insurerclient_name		AS [Insurer Associate]
	, dim_detail_core_details.present_position			AS [Present Position]
	, ''				AS [Claims Strategy]  --cboInsTypeMSG
	, dim_detail_core_details.injury_type		AS [Injury Type]
	, fact_detail_paid_detail.damages_interims		AS [Interim Damages Post Instruction]
	, dim_detail_core_details.suspicion_of_fraud			AS [Suspicion of Fraud]
	, dim_detail_core_details.credit_hire		AS [Credit Hire]
	, dim_detail_core_details.has_the_claimant_got_a_cfa		AS [Has Claimant got a CFA]
	, fact_detail_reserve_detail.damages_reserve			AS [Damages Reserve]
	, fact_detail_reserve_detail.tp_costs_reserve			AS [Claimant Costs Reserve]
	, fact_detail_reserve_detail.defence_costs_reserve		AS [Defence Costs Reserve]
	, fact_detail_reserve_detail.total_reserve				AS [Total Reserve]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'W24438'
	AND dim_matter_header_current.master_matter_number <> 0
	AND dim_matter_header_current.reporting_exclusions = 0
	AND LOWER(LTRIM(RTRIM(ISNULL(dim_detail_outcome.outcome_of_case, '')))) <> 'exclude from reports'
	/*
	AND cboInsTypeMSG = 'MSG Savings project' --Need to update the field to dwh field
	*/
ORDER BY	
	dim_detail_core_details.date_instructions_received
	, dim_matter_header_current.master_matter_number


END	

*/
GO

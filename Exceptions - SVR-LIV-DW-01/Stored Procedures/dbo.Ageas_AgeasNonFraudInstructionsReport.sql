SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/******Author : Max Taylor
       Report: Initial Create #150622 Ageas Non Fraud Instructions Report
	   Date: 01/06/2022
     ******/

CREATE PROCEDURE  [dbo].[Ageas_AgeasNonFraudInstructionsReport]
(
@StartDate AS DATE,
@EndDate AS DATE
)

AS

SELECT 
     [Solicitors Office] = 'Weightmans', 
     [Ageas Handling Office] =  dim_detail_claim.[ageas_office] , 
     [Ageas Ref] = dim_client_involvement.[insurerclient_reference] , 
	 [Ageas Case Handler] = dim_detail_core_details.grpageas_case_handler		,
     [Solcitor Ref] = RTRIM(fact_dimension_main.client_code) + '/' + fact_dimension_main.matter_number ,
	 [Name of Fee Earner] = name , 
	 [Name of Parties] = matter_description , 
	 [Date Instructions Received] = dim_detail_core_details.[date_instructions_received] , 
	 [Ageas Instruction Type  ]= dim_detail_claim.[ageas_instruction_type] , 
	 [Fixed Fee Amount] = fact_finance_summary.[fixed_fee_amount] ,
	 [Claim for PI?] = does_claimant_have_personal_injury_claim ,
	 [Suspicion of Fraud] = suspicion_of_fraud

FROM red_dw.dbo.fact_dimension_main
LEFT JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN  red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
        LEFT JOIN
        (
            SELECT fileID,
                   assocType,
                   contName AS [Insurer Name],
                   assocAddressee AS [Addressee],
                   CASE
                       WHEN assocdefaultaddID IS NOT NULL THEN
                           ISNULL(dbAddress1.addLine1, '') + ' ' + ISNULL(dbAddress1.addLine2, '') + ' '
                           + ISNULL(dbAddress1.addLine3, '') + ' ' + ISNULL(dbAddress1.addLine4, '') + ' '
                           + ISNULL(dbAddress1.addLine5, '') + ' ' + ISNULL(dbAddress1.addPostcode, '')
                       ELSE
                           ISNULL(dbAddress2.addLine1, '') + ' ' + ISNULL(dbAddress2.addLine2, '') + ' '
                           + ISNULL(dbAddress2.addLine3, '') + ' ' + ISNULL(dbAddress2.addLine4, '') + ' '
                           + ISNULL(dbAddress2.addLine5, '') + ' ' + ISNULL(dbAddress2.addPostcode, '')
                   END AS [Insurer Address],
                   dbAssociates.assocRef AS [Insurer Reference],
                   ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder
            FROM MS_Prod.config.dbAssociates WITH (NOLOCK)
                INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK)
                    ON dbAssociates.contID = dbContact.contID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress1 WITH (NOLOCK)
                    ON assocdefaultaddID = dbAddress1.addID
                LEFT OUTER JOIN MS_Prod.dbo.dbAddress AS dbAddress2 WITH (NOLOCK)
                    ON contDefaultAddress = dbAddress2.addID
            WHERE assocType = 'INSCLIENT'
        ) AS MSbillingAddress  ON dim_matter_header_current.ms_fileid = MSbillingAddress.fileID


			WHERE 1 =1 
			AND fact_dimension_main. client_code = 'A3003'
			AND CAST(dim_detail_core_details.[date_instructions_received] AS DATE) BETWEEN @StartDate AND @EndDate
            AND UPPER(ISNULL(suspicion_of_fraud,'NO')) = 'NO'
			AND ISNULL(UPPER(TRIM(outcome_of_case)),'') <> 'EXCLUDE FROM REPORTS'
			AND reporting_exclusions=0


GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:	Orlagh kelly 
-- Create date: 07-2-19
-- Description:	Script to drive the Zurich Disease Matters 
-- =============================================

CREATE PROCEDURE [dbo].[ZurichOccupationalDiseaseClaimsRosieReferralotherclosures]
	-- Add the parameters for the stored procedure here

	@DateFrom AS DATE
	,@DateTo AS DATE

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	---- For testing purposes
	--DECLARE @DateFrom DATE = '20180101'
	--DECLARE @DateTo DATE = '20160725'


	SET NOCOUNT ON;

SELECT client_code,
                   matter_number,
                   sequence_no,
                   dim_parent_key,
                   zurich_rsa_claim_number AS WPS275
				   INTO #zurich_rsa_claim_number
            FROM red_dw.dbo.dim_parent_detail
            WHERE client_code IN ( 'Z00002', 'Z00004', 'Z00018', 'Z00006', 'Z00008', 'Z00014', 'Z1001' ) AND zurich_rsa_claim_number IS NOT NULL
            

			

SELECT 
red_dw.dbo.dim_matter_header_current.master_client_code+'-'+master_matter_number [ms_ref],
dim_detail_outcome.date_claim_concluded,
fact_dimension_main.client_code,
fact_dimension_main.matter_number,
(ISNULL(fact_detail_paid_detail.general_damages_paid,0) + ISNULL(fact_detail_paid_detail.special_damages_paid,0) +  isnull(fact_detail_paid_detail.claimants_costs,0)),
'Weightmans' [Panel firm],
cASE
           WHEN RTRIM(dim_detail_core_details.[injury_type_code]) LIKE 'D17%' THEN
               'NIHL'
           WHEN RTRIM(dim_detail_core_details.[injury_type_code]) LIKE 'D31%' THEN
               'HAVS'
           ELSE
               RTRIM(dim_detail_core_details.[injury_type]) END [injury_type],
 dim_detail_client.zurich_instruction_type [Instruction type],
 dim_detail_core_details.proceedings_issued [Litigation],
 dim_detail_fraud.fraud_type [fraud_type],
 RTRIM(dim_matter_header_current.matter_partner_code) + ' '  +  RTRIM(dim_fed_hierarchy_history.fed_code) + ' ' +  RTRIM(dim_client.client_code) + ' ' + RTRIM(dim_matter_header_current.matter_number) [Panel firm reference],
 RTRIM(WPS275) [Zurich claim number],
 dim_client_involvement.insuredclient_name [Policy holder name],
 RTRIM(ISNULL(dim_insuredclient_address.insuredclient1_address_line_1,''))  +
CASE WHEN isnull(RTRIM(dim_insuredclient_address.insuredclient1_address_line_1),'') = '' THEN '' ELSE ', ' end + 
RTRIM(ISNULL(dim_insuredclient_address.insuredclient1_address_line_2,'')) +
CASE WHEN isnull(dim_insuredclient_address.insuredclient1_address_line_2,'') = ''THEN '' ELSE ', ' end + 
RTRIM(ISNULL(dim_insuredclient_address.insuredclient1_address_line_3,'')) +
CASE WHEN isnull(dim_insuredclient_address.insuredclient1_address_line_3,'') = '' THEN '' ELSE ', ' end + 
RTRIM(ISNULL(dim_insuredclient_address.insuredclient1_address_line_4,'')) [Policy holder address],
 dim_insuredclient_address.insuredclient1_postcode [Policy holder postcode],
 dim_claimant_thirdparty_involvement.claimant_name [Claimant name],
  RTRIM(ISNULL(dim_claimant_address.claimant1_address_line_1,''))  +
CASE WHEN isnull(RTRIM(dim_claimant_address.claimant1_address_line_1),'') = '' THEN '' ELSE ', ' end + 
RTRIM(ISNULL(dim_claimant_address.claimant1_address_line_2,'')) +
CASE WHEN isnull(dim_claimant_address.claimant1_address_line_2,'') = ''THEN '' ELSE ', ' end + 
RTRIM(ISNULL(dim_claimant_address.claimant1_address_line_3,'')) +
CASE WHEN isnull(dim_claimant_address.claimant1_address_line_3,'') = '' THEN '' ELSE ', ' end + 
RTRIM(ISNULL(dim_claimant_address.claimant1_address_line_4,'')) [Claimant address],
 RTRIM(dim_claimant_address.claimant1_postcode) [Claimant postcode],
 CASE WHEN dim_detail_core_details.claimants_date_of_birth IS NULL THEN NULL ELSE DATEDIFF(DAY,claimants_date_of_birth,GETDATE()) end [Claimant age],
 dim_claimant_thirdparty_involvement.claimantsols_name [Claimant solicitor name],
 dim_detail_claim.ll01_claimants_medical_experts_name [Medical expert],
 dim_detail_practice_area.examination_date [Exam. date],
 dim_detail_practice_area.audiologist_name [Other expert],
 fact_detail_paid_detail.fraud_savings [Savings made],
 WPS277 [Current reserve],
 '' [Date reserve update last sent to Zurich],
 '' [Generals_claimed],
 '' [Specials_claimed],
 '' [Costs_claimed],
 '' [Draftsman_claimed],
 '' [Generals_paid],
 '' [Specials_paid],
 '' [Costs_paid],
 '' [Draftsman_paid],
 dim_detail_client.weightmans_comments [Comments],
ISNULL(WPS386,date_settlement_form_sent_to_zurich) [Settlement form date],
CASE
			WHEN WPS387 IS NOT NULL THEN RTRIM(WPS387)
           WHEN dim_detail_critical_mi.[claim_status] IS NULL THEN
               'Open'
           WHEN dim_detail_critical_mi.[claim_status] IN ( 'Re-opened', 'Re-Opened' ) THEN
               'Open'
           ELSE
               RTRIM(dim_detail_critical_mi.[claim_status])
           END  [Claim status],
 dim_detail_fraud.reason_for_referral_to_fraud [Reason for Referral to Fraud],
dim_detail_client.[date_settlement_form_sent_to_zurich]  [Filter],
dim_detail_core_details.suspicion_of_fraud [Suspicion of Fraud ], 
 outcome_of_case,
 WPS275_grouped
FROM red_dw.dbo.fact_dimension_main
		LEFT JOIN red_Dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
		LEFT JOIN red_Dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
		LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT JOIN red_Dw.dbo.dim_detail_fraud ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
		LEFT JOIN red_Dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
		LEFT JOIN red_Dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
		LEFT JOIN red_Dw.dbo.dim_detail_practice_area ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
		LEFT join red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
		LEFT JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
		left join red_Dw.dbo.dim_fed_hierarchy_history on  dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		LEFT JOIN red_Dw.dbo.dim_detail_critical_mi ON dim_detail_critical_mi.dim_detail_critical_mi_key = fact_dimension_main.dim_detail_critical_mi_key
		LEFT JOIN red_Dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		LEFT JOIN red_Dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
		LEFT JOIN (select
fact_dimension_main.master_fact_key,
dim_client.contact_salutation insuredclient1_contact_salutation,
dim_client.addresse insuredclient1_addresse,
dim_client.address_line_1 insuredclient1_address_line_1,
dim_client.address_line_2 insuredclient1_address_line_2,
dim_client.address_line_3 insuredclient1_address_line_3,
dim_client.address_line_4 insuredclient1_address_line_4,
dim_client.postcode insuredclient1_postcode

from
red_Dw.dbo.dim_client_involvement

inner join red_Dw.dbo.fact_dimension_main
 on fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key

inner join red_Dw.dbo.dim_involvement_full 
 on dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insuredclient_1_key

inner join red_Dw.dbo.dim_client 
 on dim_client.dim_client_key = dim_involvement_full.dim_client_key

where 
dim_client.dim_client_key != 0) dim_insuredclient_address ON dim_insuredclient_address.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN (
select
fact_dimension_main.master_fact_key, 
dim_client.contact_salutation claimant1_contact_salutation,
dim_client.addresse claimant1_addresse,
dim_client.address_line_1 claimant1_address_line_1,
dim_client.address_line_2 claimant1_address_line_2,
dim_client.address_line_3 claimant1_address_line_3,
dim_client.address_line_4 claimant1_address_line_4,
dim_client.postcode claimant1_postcode,
dim_involvement_full.forename as claimant_1_forename

from
red_Dw.dbo.dim_claimant_thirdparty_involvement
inner join red_Dw.dbo.fact_dimension_main
 on fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
inner join red_Dw.dbo.dim_involvement_full 
 on dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimant_1_key
inner join red_Dw.dbo.dim_client 
 on dim_client.dim_client_key = dim_involvement_full.dim_client_key

where 
dim_client.dim_client_key != 0)  dim_claimant_address ON dim_claimant_address.master_fact_key = fact_dimension_main.master_fact_key

    LEFT OUTER JOIN
    (
        
        SELECT Parent.client_code,
               Parent.matter_number,
               sequence_no,
               Parent.dim_parent_key,
               ROW_NUMBER() OVER (PARTITION BY Parent.client_code,
                                               Parent.matter_number
                                  ORDER BY Parent.client_code,
                                           Parent.matter_number,
                                           Parent.sequence_no,
                                           Parent.dim_parent_key ASC
                                 ) AS xorder,
               WPS275,
               WPS386,
               WPS387,
			   WPS276
        FROM
        (
            SELECT client_code,
                   matter_number,
                   sequence_no,
                   dim_parent_key,
                   zurich_rsa_claim_number AS WPS275
            FROM red_dw.dbo.dim_parent_detail
            WHERE client_code IN ( 'Z00002', 'Z00004', 'Z00018', 'Z00006', 'Z00008', 'Z00014', 'Z1001' )
        ) AS Parent
            
          
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       date_settlement_form_sent_to_zurich AS WPS386
                FROM red_dw.dbo.dim_child_detail
				where date_settlement_form_sent_to_zurich is not null
            ) AS WPS386
                ON Parent.dim_parent_key = WPS386.dim_parent_key
            LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       claim_status AS WPS387
                FROM red_dw.dbo.dim_child_detail
				where claim_status is not null
            ) AS WPS387
                ON Parent.dim_parent_key = WPS387.dim_parent_key
				
                LEFT OUTER JOIN
            (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       lead_follow AS WPS276
                FROM red_dw.dbo.dim_child_detail
				where lead_follow is not null
            ) AS WPS276
                ON Parent.dim_parent_key = WPS276.dim_parent_key
				WHERE WPS275 IS NOT null
				
    ) AS ClaimDetails
        ON RTRIM(fact_dimension_main.client_code) = RTRIM(ClaimDetails.client_code)
           AND RTRIM(fact_dimension_main.matter_number) = RTRIM(ClaimDetails.matter_number)
		   AND ClaimDetails.xorder = 1
LEFT JOIN ( SELECT WPS277.client_code,WPS277.matter_number,SUM(WPS277) WPS277 FROM (
                SELECT client_code,
                       matter_number,
                       dim_parent_key,
                       current_reserve AS WPS277
                FROM  red_dw.dbo.fact_child_detail  
				where current_reserve is not null
            ) AS WPS277
			GROUP BY WPS277.client_code,WPS277.matter_number
			) WPS277  ON RTRIM(fact_dimension_main.client_code) = RTRIM(WPS277.client_code)
           AND RTRIM(fact_dimension_main.matter_number) = RTRIM(WPS277.matter_number)
LEFT JOIN (SELECT client_code,matter_number,STUFF((SELECT ',' + RTRIM(WPS275) FROM #zurich_rsa_claim_number t1
			WHERE t1.client_code = t2.client_code AND t1.matter_number = t2.matter_number FOR XML PATH('')),1,1,'') WPS275_grouped
			FROM #zurich_rsa_claim_number t2
			GROUP BY client_code,matter_number) WPS275_grouped
			ON RTRIM(fact_dimension_main.client_code) = RTRIM(WPS275_grouped.client_code)
           AND RTRIM(fact_dimension_main.matter_number) = RTRIM(WPS275_grouped.matter_number)

   LEFT JOIN red_dw.dbo.dim_date dim_last_bill_date ON dim_last_bill_date.dim_date_key = dim_last_bill_date_key


   WHERE reporting_exclusions = 0 
   AND   ISNULL(LOWER(dim_detail_outcome.outcome_of_case),'') <> 'exclude from reports'
   AND dim_client.client_group_name = 'Zurich'
   AND LOWER(dim_detail_client.zurich_instruction_type) LIKE '%outsource%'
   AND (ISNULL(fact_detail_paid_detail.general_damages_paid,0) + ISNULL(fact_detail_paid_detail.special_damages_paid,0) ) = 0
   AND ISNULL(WPS386,date_settlement_form_sent_to_zurich) IS NOT NULL
   AND LOWER(dim_detail_core_details.[suspicion_of_fraud]) ='yes'
    AND LOWER(ISNULL(WPS276,dim_detail_claim.[lead_follow])) = 'lead'

 
 
   AND 
   (
   ISNULL(WPS386,date_settlement_form_sent_to_zurich)BETWEEN @DateFrom AND @DateTo 
   --OR dim_last_bill_date.calendar_date BETWEEN @DateFrom AND @DateTo 
   )
   AND dim_detail_client.zurich_instruction_type <> 'Outsource - Mesothelioma'
   ORDER BY fact_dimension_main.client_code,
fact_dimension_main.matter_number




	END 
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-08-21
-- Description:	#69137, Surrey and Sussex SPO report
-- =============================================
CREATE PROCEDURE [police].[SurreySussexSPO] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	, matter_description AS [Matter Description]
	, matter_owner_full_name AS [Case Manager]
	, date_opened_case_management AS [Date Opened]
	, dim_detail_advice.niche_ref	AS [Niche Ref]
	, dim_detail_advice.[dvpo_victim_postcode] AS [Victim Postcode]
	, dim_detail_advice.dvpo_perpetrator_postcode AS [Perpetrator Postcode]
	, CASE WHEN dim_matter_header_current.master_client_code='451638' THEN dim_detail_claim.[borough] 
		WHEN dim_matter_header_current.master_client_code='113147' THEN dim_detail_claim.[district] 
		ELSE NULL END AS [Division]
	, CASE
		WHEN dim_matter_header_current.master_client_code = '113147' THEN 
			CASE 
				WHEN dim_detail_claim.district IN ('Adur and Worthing', 'Arun', 'Chicester', 'Crawley', 'Gatwick', 'Horsham', 'Mid Sussex') THEN
					'Sussex West'
				WHEN dim_detail_claim.district IN ('Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden') THEN
					'Sussex East'
				WHEN dim_detail_claim.district = 'Brighton and Hove' THEN
					'Sussex Brighton & Hove'
				ELSE 
					dim_detail_claim.district
			END 
		WHEN dim_matter_header_current.master_client_code = '451638' THEN	
			dim_detail_claim.borough
		ELSE
			NULL 
	  END								AS [Mapped Division]
	, dim_detail_advice.dvpo_perpetrator_age AS [Perpetrator Age]
	, dim_detail_advice.dvpo_perpetrator_gender AS [Perpetrator Gender]
	, dim_detail_advice.dvpo_perpetrator_type AS [Perpetrator Type]
	, dim_detail_advice.dvpo_victim_gender AS [Victim Gender]
	, dim_detail_advice.dvpo_victim_age AS [Victim Age]
	, dim_detail_advice.dvpo_victim_supports AS [Victim Supports]
	, dim_detail_advice.dvpo_application_contested AS [Application Contested]
	, dim_detail_advice.dvpo_interim_application AS [Interim Granted]
	, dim_detail_advice.dvpo_if_contested_date_of_next_hearing AS [If Contested, Date of Next Hearing]
	, dim_detail_advice.dvpo_full_order_granted  AS [Full Order Granted]
	, dim_detail_advice.dvpo_length_of_order AS [Length of Order]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key

WHERE dim_matter_header_current.master_client_code IN ('451638','113147')
AND work_type_name ='PL - Pol - Stalking Protection Order'
AND reporting_exclusions=0


END
GO

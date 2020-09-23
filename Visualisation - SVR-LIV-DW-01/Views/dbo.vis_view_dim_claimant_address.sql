SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[vis_view_dim_claimant_address]
AS 

SELECT fact_dimension_main.master_fact_key, 
		dim_client.contact_salutation [claimant1_contact_salutation],
		dim_client.addresse [claimant1_addresse],
		dim_client.address_line_1 [claimant1_address_line_1],
		dim_client.address_line_2 [claimant1_address_line_2],
		dim_client.address_line_3 [claimant1_address_line_3],
		dim_client.address_line_4 [claimant1_address_line_4],
		dim_client.postcode [claimant1_postcode]

FROM red_dw.dbo.dim_claimant_thirdparty_involvement WITH (NOLOCK)
INNER JOIN red_dw.dbo.fact_dimension_main WITH (NOLOCK) ON fact_dimension_main.dim_claimant_thirdpart_key = dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key
INNER JOIN red_dw.dbo.dim_involvement_full WITH (NOLOCK) ON dim_involvement_full.dim_involvement_full_key = dim_claimant_thirdparty_involvement.claimant_1_key
INNER JOIN red_dw.dbo.dim_client WITH (NOLOCK) ON dim_client.dim_client_key = dim_involvement_full.dim_client_key

WHERE dim_client.dim_client_key != 0



GO

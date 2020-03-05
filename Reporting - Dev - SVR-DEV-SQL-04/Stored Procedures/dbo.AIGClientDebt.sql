SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2017-02-24
Description:		AIG Client Debt -- this is temp sp as awaiting fields into the DWH 
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [dbo].[AIGClientDebt]

AS



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
fb.client_code
,fb.matter_number
,mh.master_client_code +'/'+ mh.master_matter_number  as Ref
,mh.matter_owner_full_name
,mh.client_group_name
,mh.client_name
,mh.matter_description
,mh.fixed_fee
,fb.bill_number
,fb.bill_total
,fb.fees_total as Profit_Costs
,fb.amount_paid as BillAmountPaid
,fb.vat_amount
,fb.amount_outstanding
,dim_detail_core_details.incident_date
,bd.bill_date
,DATEDIFF(dd,cast(bd.bill_date as datetime),GETDATE()) as [Age of Debt (Days)]
,ad.orgname
,ad.street
,ad.city
,ad.zipcode
,dim_detail_client.aig_litigation_number
,dim_detail_core_details.clients_claims_handler_surname_forename
,dim_detail_core_details.aig_ref

FROM 

red_dw.dbo.fact_bill AS fb
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current as mh 
ON mh.client_code=fb.client_code AND mh.matter_number=fb.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main 
ON fact_dimension_main.master_fact_key = fb.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client 
ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details 
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_date AS bd 
ON bd.dim_bill_date_key = fb.dim_bill_date_key
LEFT OUTER JOIN 

(SELECT dim_bill_key, bill_number, addrindex,orgname, street, city, state, country, zipcode,description, formattedstring 
FROM red_dw.dbo.dim_bill inner join red_dw.dbo.ds_sh_3e_address
on dim_bill.bill_address_id = ds_sh_3e_address.addrindex
) ad ON ad.dim_bill_key = fb.dim_bill_key

WHERE
 fb.bill_number <> 'PURGE' and amount_outstanding <>0
 and fb.client_code in( '00006861','00006864','00006865','00006866','00006868','00006876','A2002') 

ORDER BY client_code, matter_number



GO

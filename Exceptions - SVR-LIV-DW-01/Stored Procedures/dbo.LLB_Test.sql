SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 --=============================================
 --Author:		<orlagh kelly >
 --Create date: <june 2018>
 --Description:	<Stored procedure to drive the billing report  >
 -- Case Statement 
 -- If VAT Registered = Yes , then insurer contact ,Insurer Reference, Billing Address, Insured Contact and VAT Address need to be complete to raise the bill. 
 --if VAT Regiistered = No , then insurer contact, Insurer Reference , Billing Address need to be complete to raise the Bill
 --If VAT Registered IS NULL then no bills can be raised
 -- VAT Registered is a critical MI Field in Zurich. 
-------- =============================================
CREATE PROCEDURE [dbo].[LLB_Test]  

-- EXEC  dbo.LLB_Test 'cwilli'
--	 Add the parameters for the stored procedure here
--( --@WindowsUsername  as nvarchar(20),
(@FEDCodes VARCHAR(MAX),
@wipdisp as money)


AS
BEGIN

if @wipdisp = 0 set @wipdisp = null

select *, 


case when peta.[Interim or Final ] = 'FINAL ' and (peta.[can we bill VAT=no] = 'Yes' or peta.ZURCHICBILL= 'Yes') then 1 else 0 end as [BILLGOF], 
case when peta.[Interim or Final ]= 'INTERIM' and (peta.[can we bill VAT=no] = 'Yes' or peta.ZURCHICBILL= 'Yes') then 1 else 0 end as [BILLGOI]


from 

--where  windowsusername=@WindowsUsername
-- and 
-- (peta.wip + wi.disbursement_balance ) >= isnull(@wipdisp , (peta.wip + peta.disbursement_balance )) 




(Select distinct


--file information 
m.client_code [Client Code], 
m.client_name [Client Name],
m.matter_number [Matter Code],
m.matter_description [Matter Description], 
m.matter_owner_full_name [Matter Owner], 
m.fee_earner_code [Fee earner code],
m.date_opened_case_management [DateOpened],
team.hierarchylevel4 [Team Name ], 
mc.client_group_code,

(m.master_client_code + '-' + m.master_matter_number) aS [3E Reference],

-- Financial Details 
wi.wip [Wip Balance], 
wi.disbursement_balance [Disbursement Balance], 
(wi.wip + wi.disbursement_balance ) as [WIPDIS],
wi.total_amount_billed [Total Billed To Date (net)], 
(wi.total_amount_billed + wi.wip + wi.disbursement_balance ) as [Total Billed + WIP & Disbs ],
FMSC.last_time_transaction_date [Date of last time posting ], 

datediff(dd,FMSC.last_time_transaction_date,  getdate())  as [Days Since Last Time Posting],
FMSC.last_bill_date[Last Bill],
--m.final_bill_date ,
datediff(dd,FMSC.last_bill_date ,  getdate()) as  [Days Since Last Bill],

m.billing_arrangement_description [Rate Arrangement],
m.fixed_fee [Fixed Fee Yes/No],
m.fixed_fee_amount [Fixed Fee Amount],
wi.client_account_balance_of_matter [Client Balance],
wi.unpaid_bill_balance [Unpaid Bills],
wi.defence_costs_billed [Profit cost to be billed],


--Billing information 
core.incident_date [Incident Date], 
wi.defence_costs_reserve [Defence Cost Reserve] , 
(wi.defence_costs_reserve_net - wi.defence_costs_billed) as [defence cost reserve remainder ],
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default  AS [Insurer Reference ],
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default   AS  [insurer contact ] , 
COALESCE([Insured Reference],invol.insuredclient_reference)COLLATE database_default   AS [insured reference ], 
COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default   AS  [Insured Contact],
--(rtrim(mc.address_line_1)+rtrim(mc.address_line_2)+rtrim(mc.address_line_3)+rtrim(mc.address_line_4)+(mc.postcode)) as  [Billing Address],
vat.vat_registered [Vat Registered],
car.client_vehicle_registration  [Car Registration],
c.zurich_payments_offshored,
claim.claimant_name as [Claimant name ],
fc.client_balance [Client Balance_main],



CASE WHEN MSbillingAddress.fileID IS NOT NULL THEN 
ltrim(rtrim(ISNULL(MSbillingAddress.Addressee,'')))+' '+ MSbillingAddress.[Insurer Address]
ELSE ltrim(rtrim(ISNULL(billingAddress.insurer_addresse,'')))+' '+ltrim(rtrim(ISNULL(billingAddress.insurer_address_line_1, '')))+' '+ltrim(rtrim(ISNULL(billingAddress.insurer_address_line_2, '')))+' '+ltrim(rtrim(ISNULL(billingAddress.insurer_address_line_3, '')))+' '+ltrim(rtrim(ISNULL(billingAddress.insurer_address_line_4, '')))+' '+(billingAddress.insurer_postcode)  END  Collate database_default as BILLADDY,



CASE WHEN MSvatAddress.fileID IS NOT NULL THEN 
ltrim(rtrim(ISNULL(MSvatAddress.Addressee,'')))+' '+ MSvatAddress.[Insured Address]
ELSE 
ltrim(rtrim(ISNULL(vatAddress.insured_addresse, '')))
+' '+ltrim(rtrim(ISNULL(vatAddress.insured_address_line_1,'')))
+' '+ltrim(rtrim(ISNULL(vatAddress.insured_address_line_2,'')))
+' '+ltrim(rtrim(ISNULL(vatAddress.insured_address_line_3,'')))
+' '+ltrim(rtrim(ISNULL(vatAddress.insured_address_line_4,'')))
+' '+(vatAddress.insured_postcode) END Collate database_default as VATADDY,




ISNULL(case when COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is null then 'Client Reference ' else ' ' end,'')  +  ---TH
ISNULL(case when COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default  is null then 'Client Contact ' else ' ' end,'') + 
ISNULL(case when COALESCE ([Insurer Address],billingAddress.insurer_postcode)COLLATE database_default is null  then 'Billing Address ' else ' '  end,'') +
ISNULL(case when vat.vat_registered is null  then 'Vat Registration' else ' 'end,'') + 
isnull(case when mc.client_group_code = '00000001' and  c.zurich_legal_x is null  then 'Legal-X' else ' ' end, '')
as [Missing info ],



--case when billingAddress.insurer_addresse is null  then 'Billing Info ' else ' '  end + 
--case when invol.insurerclient_name is null then 'Client Contact ' else ' ' end + 
--case when invol.insurerclient_reference is null then 'Client Reference ' else ' ' end as [Missing info2 ],
--case when  vat.vat_registered is null then 'VAT Registered Yes/No ' else ' ' end 
case when m.final_bill_date is null then 'INTERIM ' else 'FINAL' end as [Interim or Final ], 



c.zurich_legal_x [Legal-X ],

-- case statement to action emails, if matters are missing MI Critical fields no bill actioned, if vat registration = no, fields need(Vat address + insured contact + MI critical ) 
  Case when 


mc.client_group_code = '00000001' then 'No'

when mc.client_group_name = 'Zurich' then 'No'
when
vat.vat_registered  = 'No' 
 and 
coalesce([Insured Reference],invol.insurerclient_reference)COLLATE database_default   is null  
and 
isnull(mc.client_group_code,' ') <> '00000001'
then  'No' 



when 
vat.vat_registered  = 'No' 
and  
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default  is null 
and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'No'



when 
 vat.vat_registered  = 'No' 
and
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default  is null
and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'No' 



when 
vat.vat_registered is null 
and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'No'
--invol.insurerclient_reference is null  then  'No' 


when 
vat.vat_registered  = 'Yes' 
and 
COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default  is null
and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'No '



when 
vat.vat_registered  = 'Yes' 
and 
COALESCE([Insured Address],vatAddress.insured_postcode ) COLLATE database_default is null 
and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'No'


when 
vat.vat_registered  = 'Yes' 
and 
COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default is not null and COALESCE([Insured Address],vatAddress.insured_postcode ) COLLATE database_default is not null  and COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default  is not null and COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default   is not null and COALESCE([Insurer Address], billingAddress.insurer_postcode )Collate database_default is not null 
and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'Yes' 



when 
vat.vat_registered  = 'Yes' 
and 
COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default is not null and COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default  is not null and COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default   is not null and COALESCE ([Insurer Address],billingAddress.insurer_postcode)COLLATE database_default is not null 
and 
 COALESCE ([Insured Address], vatAddress.insured_postcode ) COLLATE database_default is null 
 and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'No '



when 
 vat.vat_registered  = 'Yes' 
and 
 COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default  is not null and COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default  is not null and COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default is not null and COALESCE([Insurer Address],billingAddress.insurer_postcode)COLLATE database_default is not null 
and 
 COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default  is null
 and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'No '

when 
vat.vat_registered  = 'Yes' 
and  
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default  is null 
and 
isnull(mc.client_group_code,' ') <> '00000001'
then  'No' 



when 
vat.vat_registered  = 'No' 
and  
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default is null  
and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'No'


when 
 vat.vat_registered  = 'No' 
and
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default  is null 
and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'No' 


when 
vat.vat_registered  = 'No' 
and 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default  is not null and COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default  is not null and COALESCE([Insurer Address],  billingAddress.insurer_postcode )COLLATE database_default is not null 
and 
COALESCE([Insured Address],vatAddress.insured_postcode)collate database_default is null or COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default  is not null
and 
isnull(mc.client_group_code,' ') <> '00000001'
then 'Yes'





end as 
 [can we bill VAT=no],

--------------------------------ZURICHCASE------------------------------
--VAT NULL or NO
case when  
mc.client_group_code = '00000001'
and 
c.zurich_legal_x is null
then 'No' 
 when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x is null 
and 
vat.vat_registered   is null 
and 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default     is not null -- client contact 
and 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default   is not null -- client reference 
and
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is not null--billing address 
then 'No'

when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x is null 
and 
vat.vat_registered  = 'No'
and 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default     is not null -- client contact 
and 
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is not null -- client reference 
and
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is not null--billing address 
then 'No'


when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x is null 
and 
vat.vat_registered   is null 
and 
(COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default    is  null -- client contact 
or
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is  null -- client reference 
or
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is null)--billing address 
then 'No'

when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x is null 
and 
vat.vat_registered  = 'No'
and (
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default     is not null -- client contact 
or
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is not null -- client reference 
or
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is not null)--billing address 
then 
'No'

when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x is null 
and 
vat.vat_registered  = 'No'
and 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default     is not null -- client contact 
and
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is not null -- client reference 
and
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is not null--billing address 
then 
'No'



when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x IN ('Yes', 'No')
and 
vat.vat_registered  = 'No'
and 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default     is not null -- client contact 
and
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is not null -- client reference 
and
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is not null--billing address 
then 
'Yes'



when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x IN ('Yes', 'No')
and 
vat.vat_registered  = 'No'
and 
(
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default     is  null -- client contact 
or
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is null -- client reference 
or
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is not null--billing address 
)
then 
'No'

when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x in ('Yes','No')
and 
vat.vat_registered  = 'No'
and 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default    is not null -- client contact 
and
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is not null -- client reference 
and
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default   is not null--billing address 
then 
'Yes'

when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x is null 
and 
vat.vat_registered  = 'Yes'
and 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default     is not null -- client contact 
and 
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is not null -- client reference 
and
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is not null--billing address 
and 
COALESCE([Insured Address],vatAddress.insured_postcode)collate database_default is not null   -- vat address 
and
COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default   is not null  -- insured contact 

then 'No'


when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x is null 
and 
vat.vat_registered  = 'Yes'
and (
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default     is null -- client contact 
or
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is null -- client reference 
or
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is null--billing address 
or
COALESCE([Insured Address],vatAddress.insured_postcode)collate database_default is null   -- vat address 
or
COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default  is  null)  -- insured contact 

then 'No'

when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x IN ('Yes', 'No')
and 
vat.vat_registered  = 'Yes'
and (
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default   is null -- client contact 
or
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is null -- client reference 
or
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is null--billing address 
or
COALESCE([Insured Address],vatAddress.insured_postcode)collate database_default is null   -- vat address 
or
COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default   is  null)  -- insured contact 

then 'No'


when 
mc.client_group_code = '00000001'
and 
c.zurich_legal_x IN ('Yes', 'No')
and 
vat.vat_registered  = 'Yes'
and 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default    is not null -- client contact 
and
COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is not null -- client reference 
and
COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default is not null--billing address 
and
COALESCE([Insured Address],vatAddress.insured_postcode)collate database_default is not null   -- vat address 
and
COALESCE([Insured Name],invol.insuredclient_name)COLLATE database_default   is not null  -- insured contact 

then 'Yes'

when mc.client_group_code = '00000001'and 
( COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is null
or 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default    is null 
 or 
 COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default  is null  

or  vat.vat_registered is null 
or 
c.zurich_legal_x IN ('Yes', 'No'))
then 'No '



when mc.client_group_code = '00000001'and 
( COALESCE([Insurer Reference],invol.insurerclient_reference) COLLATE database_default is null
or 
COALESCE([Insurer Name],invol.insurerclient_name)COLLATE database_default    is null 
 or 
 COALESCE([Insurer Address], billingAddress.insurer_postcode) COLLATE database_default  is null  

or  vat.vat_registered is null 
or 
c.zurich_legal_x is null )
then 'No '





end as 
[ZURCHICBILL]



from red_dw.dbo.fact_dimension_main as main WITH (NOLOCK)
inner join red_dw.dbo.dim_fed_hierarchy_history as team WITH (NOLOCK)
on team.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
inner join red_dw.dbo.dim_client as mc WITH (NOLOCK)
on mc.client_code = main.client_code
left outer join red_dw.dbo.dim_detail_client as c WITH (NOLOCK)
on main.client_code = c.client_code and c.matter_number = main.matter_number
inner join red_dw.dbo.dim_matter_header_current as m WITH (NOLOCK) 
 on m.client_code = main.client_code and m.matter_number = main.matter_number 
inner join red_dw.dbo.fact_detail_client as fc WITH (NOLOCK)
on fc.client_code = c.client_code and fc.matter_number = main.matter_number
Left outer join  red_dw.dbo.dim_client_involvement as invol WITH (NOLOCK)
on invol.dim_client_involvement_key =main.dim_client_involvement_key 
Left outer join  red_dw.dbo.dim_claimant_thirdparty_involvement as claim  WITH (NOLOCK) 
 on claim.dim_claimant_thirdpart_key =main.dim_claimant_thirdpart_key
Left outer join  red_dw.dbo.dim_defendant_involvement as def WITH (NOLOCK) 
 on def.dim_defendant_involvem_key = main.dim_defendant_involvem_key
inner join red_dw.dbo.fact_finance_summary as wi WITH (NOLOCK)
on wi.client_code = main.client_code and wi.matter_number = main.matter_number
Left outer join  red_dw.dbo.dim_detail_outcome as ou WITH (NOLOCK)
on ou.client_code = m.client_code and ou.matter_number = m.matter_number
Left outer join red_dw.dbo.dim_detail_core_details as core WITH (NOLOCK) 
 on core.client_code = m.client_code and core.matter_number = m.matter_number
left outer join red_dw.dbo.dim_detail_previous_details as vat WITH (NOLOCK)
on vat.client_code = main.client_code and vat.matter_number = main.matter_number
left outer join red_dw.dbo.dim_detail_hire_details as car WITH (NOLOCK) 
 on car.dim_detail_hire_detail_key = main.dim_detail_hire_detail_key
left outer join  red_dw.dbo.fact_detail_recovery_detail as CR WITH (NOLOCK)
on CR.master_fact_key = main.master_fact_key
left outer join red_dw.dbo.fact_matter_summary_current as FMSC WITH (NOLOCK)
on FMSC.master_fact_key = main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary WITH (NOLOCK) 
 ON red_dw.dbo.fact_matter_summary.master_fact_key=main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_last_bill_date WITH (NOLOCK)
ON dim_last_bill_date.dim_last_bill_date_key=fact_matter_summary.dim_last_bill_date_key


left join (SELECT fact_dimension_main.master_fact_key [fact_key], 
              ltrim(rtrim(dim_client.contact_salutation))[insurer_contact_salutation],
              ltrim(rtrim(dim_client.addresse ))[insurer_addresse],
              ltrim(rtrim(dim_client.address_line_1)) [insurer_address_line_1],
              ltrim(rtrim(dim_client.address_line_2)) [insurer_address_line_2],
              ltrim(rtrim(dim_client.address_line_3 ))[insurer_address_line_3],
              ltrim(rtrim(dim_client.address_line_4 ))[insurer_address_line_4],
              ltrim(rtrim(dim_client.postcode)) [insurer_postcode]


FROM red_dw.dbo.dim_client_involvement  WITH (NOLOCK)
INNER join red_dw.dbo.fact_dimension_main WITH (NOLOCK) ON fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
INNER join red_dw.dbo.dim_involvement_full WITH (NOLOCK) ON dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insurerclient_1_key
INNER join red_dw.dbo.dim_client WITH (NOLOCK) ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
WHERE dim_client.dim_client_key != 0 ) 

                                                                                                                     as billingAddress on main.master_fact_key = billingAddress.fact_key



                                                              left join (                                                  
SELECT fileID,assocType,contName AS [Insurer Name]
,assocAddressee AS [Addressee]
,CASE WHEN assocdefaultaddID IS NOT NULL THEn ISNULL(dbAddress1.addLine1,'') + ' ' +
ISNULL(dbAddress1.addLine2,'') + ' ' +
ISNULL(dbAddress1.addLine3,'') + ' ' +
ISNULL(dbAddress1.addLine4,'') + ' ' + 
ISNULL(dbAddress1.addLine5,'') + ' ' + 
ISNULL(dbAddress1.addPostcode,'') ELSE 
ISNULL(dbAddress2.addLine1,'') + ' ' +
ISNULL(dbAddress2.addLine2,'') + ' ' +
ISNULL(dbAddress2.addLine3,'') + ' ' + 
ISNULL(dbAddress2.addLine4,'') + ' ' +
ISNULL(dbAddress2.addLine5,'') + ' ' + 
ISNULL(dbAddress2.addPostcode,'') END AS [Insurer Address]
,dbAssociates.assocRef AS [Insurer Reference]
,ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder

FROM MS_Prod.config.dbAssociates WITH (NOLOCK) 
INNER JOIN MS_Prod.config.dbContact  WITH (NOLOCK)
On dbAssociates.contID=dbContact.contID
LEFT OUTER JOIN  MS_Prod.dbo.dbAddress  AS dbAddress1 WITH (NOLOCK) 
ON assocdefaultaddID=dbAddress1.addID
LEFT OUTER JOIN  MS_Prod.dbo.dbAddress  AS dbAddress2 WITH (NOLOCK) 
ON contDefaultAddress=dbAddress2.addID
--WHERE assocType='INSCLIENT')
WHERE assocType='INSURERCLIENT' ) 



as MSbillingAddress
on m.ms_fileid = MSbillingAddress.fileID and MSBillingAddress.XOrder = 1


Left Join (--Vat Address
SELECT fact_dimension_main.master_fact_key [fact_key], 
              ltrim(rtrim(dim_client.contact_salutation ))[insured_contact_salutation],
              ltrim(rtrim(dim_client.addresse))[insured_addresse],
              ltrim(rtrim(dim_client.address_line_1 ))[insured_address_line_1],
              ltrim(rtrim(dim_client.address_line_2)) [insured_address_line_2],
              ltrim(rtrim(dim_client.address_line_3 ))[insured_address_line_3],
              ltrim(rtrim(dim_client.address_line_4 ))[insured_address_line_4],
              ltrim(rtrim(dim_client.postcode)) [insured_postcode]
FROM red_dw.dbo.dim_client_involvement WITH (NOLOCK)
INNER join red_dw.dbo.fact_dimension_main WITH (NOLOCK) ON fact_dimension_main.dim_client_involvement_key = dim_client_involvement.dim_client_involvement_key
INNER join red_dw.dbo.dim_involvement_full WITH (NOLOCK) ON dim_involvement_full.dim_involvement_full_key = dim_client_involvement.insuredclient_1_key
INNER join red_dw.dbo.dim_client WITH (NOLOCK) 
 ON dim_client.dim_client_key = dim_involvement_full.dim_client_key
WHERE dim_client.dim_client_key != 0 )

as vatAddress on vatAddress.fact_key= main.master_fact_key


                                                              left join (                                                  
SELECT fileID,assocType,contName AS [Insured Name]
,assocAddressee AS [Addressee]
,CASE WHEN assocdefaultaddID IS NOT NULL THEn ISNULL(dbAddress1.addLine1,'') + ' ' +
ISNULL(dbAddress1.addLine2,'') + ' ' +
ISNULL(dbAddress1.addLine3,'') + ' ' +
ISNULL(dbAddress1.addLine4,'') + ' ' + 
ISNULL(dbAddress1.addLine5,'') + ' ' + 
ISNULL(dbAddress1.addPostcode,'') ELSE 
ISNULL(dbAddress2.addLine1,'') + ' ' +
ISNULL(dbAddress2.addLine2,'') + ' ' +
ISNULL(dbAddress2.addLine3,'') + ' ' + 
ISNULL(dbAddress2.addLine4,'') + ' ' +
ISNULL(dbAddress2.addLine5,'') + ' ' + 
ISNULL(dbAddress2.addPostcode,'') END AS [Insured Address]
,dbAssociates.assocRef AS [Insured Reference]
,ROW_NUMBER() OVER (PARTITION BY dbAssociates.fileID ORDER BY assocOrder) AS XOrder

FROM MS_Prod.config.dbAssociates WITH (NOLOCK) 
INNER JOIN MS_Prod.config.dbContact WITH (NOLOCK) 
On dbAssociates.contID=dbContact.contID
LEFT OUTER JOIN  MS_Prod.dbo.dbAddress  AS dbAddress1 WITH (NOLOCK) 
ON assocdefaultaddID=dbAddress1.addID
LEFT OUTER JOIN  MS_Prod.dbo.dbAddress  AS dbAddress2 WITH (NOLOCK) 
ON contDefaultAddress=dbAddress2.addID
WHERE assocType='INSUREDCLIENT' ) 


as MSvatAddress
on m.ms_fileid = MSvatAddress.fileID and MSvatAddress.XOrder = 1



where m.date_closed_practice_management is null 


and fed_code = @FEDCodes

and (wi.wip + wi.disbursement_balance ) >= isnull(@wipdisp , (wi.wip + wi.disbursement_balance ))



and 
 --client_group_code = '00000001'

 m.matter_number <> '00030645'
 and 
 m.client_code not like  'ML%' 

 --m.matter_number = '0000030645' ----test 
 --and m.client_code ='00010692'









) as peta




where [Matter Code] not like 'ML%'





-----where client_group_code = '00000001'



END

--where 

-- windowsusername=@WindowsUsername
-- and 
-- (peta.wip + wi.disbursement_balance ) >= isnull(@wipdisp , (peta.wip + peta.disbursement_balance )) 

--where 

-- windowsusername=@WindowsUsername
-- and 
-- (peta.wip + wi.disbursement_balance ) >= isnull(@wipdisp , (peta.wip + peta.disbursement_balance )) 































GO

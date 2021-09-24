SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[KSHabroDashboard]

AS 

BEGIN

SELECT dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
, (
           SELECT fin_year
           FROM red_dw..dim_date WITH(NOLOCK)
           WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
       ) AS [Fin Year Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
,(
           SELECT fin_year
           FROM red_dw..dim_date WITH(NOLOCK)
           WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_closed_case_management AS DATE)
 ) AS [Fin Year Closed]
,RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [Mattersphere Weightmans Reference]
,NULL AS [KD Hasbro ?]
,matter_description AS [Matter Description]
,name AS [Case Manager]
,hierarchylevel4hist AS [Team]
,hierarchylevel3 AS [Department]
,work_type_name AS [Work Type]
,client_name AS [Client Name]
,dim_matter_header_current.fixed_fee_amount AS [Fixed Fee Amount]
,dim_matter_header_current.fee_arrangement AS [Fee Arrangement]
,total_amount_bill_non_comp AS [Total Bill Amount - Composite (IncVAT )]
,defence_costs_billed_composite AS [Revenue Costs Billed]
,disbursements_billed AS [Disbursements Billed ]
,vat_non_comp AS [VAT Billed]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
,revenue_estimate_net_of_vat AS [Revenue Estimate net of VAT]
,disbursements_estimate_net_of_vat AS [Disbursements net of VAT]
,ISNULL(revenue_and_disb_estimate_net_of_vat,commercial_costs_estimate) AS [Fee Estimate]
,anticipated_completion_date
,completion_date
,target_completion_date
,target_date
,dim_detail_client.present_position
,fileNotes 
,fileExternalNotes
,target_access_date
,dim_detail_property.[exchange_date]
,CASE
           WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
               NULL
           ELSE
               fact_matter_summary_current.last_bill_date
       END AS [Last Bill Date]
,fact_bill_matter.last_bill_date AS [Last Bill Date Composite]
,(
           SELECT fin_year
           FROM red_dw..dim_date
           WHERE dim_date.calendar_date = CAST(fact_bill_matter.last_bill_date AS DATE)
       ) AS [Fin Year Of Last Bill]
,fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting]
,(
           SELECT fin_year
           FROM red_dw..dim_date
           WHERE dim_date.calendar_date = CAST(fact_matter_summary_current.[last_time_transaction_date] AS DATE)
       ) AS [Fin Year Of Last Time Posting]
	   ,CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS FileStatus

 ,CASE WHEN  dim_detail_property.[status] LIKE '%Abortive%' THEN 'Silver'
 WHEN completion_date IS NOT NULL OR dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Silver'
 WHEN dim_detail_property.[status] = 'On hold' THEN '#ADD8E6'
 WHEN dim_detail_property.[exchange_date] IS NOT NULL THEN 'Turquoise'
WHEN dim_detail_client.[present_position_code] IN  ('005','006','007','018','019','029','030','031','037','038','039','045','046','047','057','058','059','069','070','071','077','078','079')THEN 'Turquoise'         
WHEN red_dw.dbo.dim_detail_client.present_position_code IN ('001','009','010','011','021','022','023','033','041','073','081','084','087','091','092','093','094') THEN '#FF3F3F'
WHEN red_dw.dbo.dim_detail_client.present_position_code IN ('002','003','004','012','013','014','015','016','024','025','026','027','028','034','035','036','042','043','044','049','050','051','052','053','054','055','056','061','062','063','064','065','066','067','068','074','075','076','082','085','088','089','090','120') THEN '#92D050'
WHEN red_dw.dbo.dim_detail_client.present_position_code IN ('005','008','017','020','032','040','048','060','072','080','083','086','116','117','118','119','121') THEN 'Silver'
WHEN red_dw.dbo.dim_detail_client.present_position_code IN ('095|096|097|098|099|100|101|102|103|104|105|106|107|108|109|110|111|112|113|114|115') THEN '#FFC000'--amber
ELSE '#92D050'
 END AS [Row Colour]
            --IF (ISBLANK(dim_detail_property[completion_date]) = FALSE, "Silver",
            --IF (dim_detail_property[status] = "On hold","#ADD8E6",
            --IF (ISBLANK(dim_detail_property[exchange_date]) = FALSE,"Turquoise",
            --IF (PATHCONTAINS ("005|006|007|018|019|029|030|031|037|038|039|045|046|047|057|058|059|069|070|071|077|078|079",dim_detail_client[present_position_code]),"Turquoise",         
            --IF (PATHCONTAINS ("001|009|010|011|021|022|023|033|041|073|081|084|087|091|092|093|094",dim_detail_client[present_position_code]),"#FF3F3F",--red
            --IF (PATHCONTAINS ("002|003|004|012|013|014|015|016|024|025|026|027|028|034|035|036|042|043|044|049|050|051|052|053|054|055|056|061|062|063|064|065|066|067|068|074|075|076|082|085|088|089|090|120",dim_detail_client[present_position_code]),"#92D050",--green
            --IF (PATHCONTAINS ("005|008|017|020|032|040|048|060|072|080|083|086|116|117|118|119|121",dim_detail_client[present_position_code]),"Silver",
            --IF (PATHCONTAINS ("095|096|097|098|099|100|101|102|103|104|105|106|107|108|109|110|111|112|113|114|115", dim_detail_client[present_position_code] ),"#FFC000",--amber
            --                        "" )
            --                ))))))))
            --),

 FROM red_dw.dbo.dim_matter_header_current
 INNER JOIN red_dw.dbo.dim_matter_worktype
  ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT JOIN red_dw.dbo.fact_bill_matter
 ON fact_bill_matter.client_code = dim_matter_header_current.client_code
 AND fact_bill_matter.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_property
 ON dim_detail_property.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN ms_prod.config.dbFile
 ON ms_fileid=fileID
WHERE client_group_code='00000124'
AND reporting_exclusions=0


END 
GO

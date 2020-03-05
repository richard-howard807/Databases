SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [MMI].[MMI_Quarterly_Dashboard]

AS
BEGIN

SELECT 
client
,[Fee Earner]
,[Supervising Partner]
,[Nature of instruction]
,[MMI Ref]
,[Zurich Ref]
,[Panel Firm Ref]
,[Delegated Authority]
,[MMI Insured]
,[Defendant]
,[Claimant First name]
,[Claimant Surname]
,[Claimant Solicitor]
,[Claim Type]
,[Work_type]
,[matter_description]
,[Present position]
,CASE WHEN [Claim Type]='Abuse' THEN 'NA' ELSE [Job Role] END AS [Job Role]
,CASE WHEN [Claim Type]<>'Abuse' THEN 'N/A' ELSE [Risk Type] END AS [Risk Type]
,[Risk location]
,CASE WHEN [Claim Type]<>'Abuse' THEN 'N/A' ELSE  [Risk descriptor (Abuser)] END AS [Risk descriptor (Abuser)]
,CASE WHEN [Claim Type]<>'Abuse' THEN 'N/A' ELSE  [Abuse Codes] END AS [Abuse Codes]
,CASE WHEN [Claim Type]<>'Abuse' THEN 'N/A' ELSE  [Allegation TYPE] END AS [Allegation TYPE]
,[Exposure / Abuse period (s)]
,[MMI’s % - Damages]
,[MMI’s % - CRU ]
,[MMI’s % - Costs]
,[MMI’s % - Defence costs]  
,[MMI Lead]
,[Open Date] 
,[Date of LoC]
,[Date of CFA/DBA]
,[Issue Date]    
,[Service Date]
,[Avoidable]
,[Litigation cause]
,[total_reserve_net] + (ISNULL(CASE WHEN client='M00001' THEN [damages_paid_to_date]  ELSE [Paid Damages] END,0)
+ISNULL([Paid CRU],0)
+ISNULL(CASE WHEN client='M00001' THEN [total_tp_costs_paid_to_date]   ELSE [Paid Claimant’s Costs] END ,0)
+ISNULL(CASE WHEN client='M00001' THEN [defence_costs_billed] ELSE [Paid Own Costs] END,0))[Gross Estimate]
,damages_reserve_net AS [Reserve Damages]
,[Reserve CRU]
,[tp_costs_reserve_net]  AS [Reserve Claimant’s Costs]
,[defence_costs_reserve_net]  AS [Reserve Own Costs]
,[total_reserve_net] AS [Total O/S Reserve]
,CASE WHEN client='M00001' THEN [damages_paid_to_date]  ELSE [Paid Damages] END [Paid Damages]
,[Paid CRU]
,CASE WHEN client='M00001' THEN [total_tp_costs_paid_to_date]   ELSE [Paid Claimant’s Costs] END AS [Paid Claimant’s Costs]
,CASE WHEN client='M00001' THEN [defence_costs_billed] ELSE [Paid Own Costs] END AS [Paid Own Costs]

,ISNULL(CASE WHEN client='M00001' THEN [damages_paid_to_date]  ELSE [Paid Damages] END,0)
+ISNULL([Paid CRU],0)
+ISNULL(CASE WHEN client='M00001' THEN [total_tp_costs_paid_to_date]   ELSE [Paid Claimant’s Costs] END ,0)
+ISNULL(CASE WHEN client='M00001' THEN [defence_costs_billed] ELSE [Paid Own Costs] END,0) AS [Total Paid]
,[Net O/S Reserve]
,[Claimant’s P36]
,[Defendant’s P36]
,[Status]
,[Present Position / Barriers to settlement]
,[Date Damages Settled]
,[Date Costs Agreed]
,[Closed Date]
,[Litigated Matter Number]
,[Quarter Received]
,[Litigated]
,[Repudiated/Settled]
,[IncidentPostcode]
FROM 
(

SELECT 
RTRIM(client) client,
RTRIM(matter) AS matter,
fed.name [Fee Earner],
par.name [Supervising Partner],
CASE WHEN client = 'M00001' THEN 'MMI' ELSE 'Zurich' END [Nature of instruction],
CASE WHEN ISNULL(Rtrim(WPS275.case_text),'') = '' THEN [dbo].[ufn_Coalesce_CapacityDetails_reference](cashdr.case_id,'TRA00002') ELSE WPS275.case_text end [MMI Ref],
'N/A' [Zurich Ref],
RTRIM(client) +'-'+ matter  [Panel Firm Ref],
CASE WHEN client = 'M00001' THEN TRA115.case_text ELSE 'Yes' END [Delegated Authority],
CASE WHEN ISNULL(RTRIM(WPS344.case_text),'') = '' THEN [dbo].[ufn_Coalesce_CapacityDetails_nameonly](cashdr.case_id,'TRA00001')  ELSE WPS344.case_text end [MMI Insured],
[dbo].[ufn_Coalesce_CapacityDetails_nameonly](cashdr.case_id,'~ZDEFEND') [Defendant],
SUBSTRING([dbo].[ufn_Coalesce_CapacityDetails_nameonly](cashdr.case_id,'~ZCLAIM'), 1, CHARINDEX(' ', [dbo].[ufn_Coalesce_CapacityDetails_nameonly](cashdr.case_id,'~ZCLAIM')) ) AS [Claimant First name],
SUBSTRING([dbo].[ufn_Coalesce_CapacityDetails_nameonly](cashdr.case_id,'~ZCLAIM'), CHARINDEX(' ', [dbo].[ufn_Coalesce_CapacityDetails_nameonly](cashdr.case_id,'~ZCLAIM')) + 1, 8000) AS [Claimant Surname],
[dbo].[ufn_Coalesce_CapacityDetails](cashdr.case_id,'~ZCLSOLS') [Claimant Solicitor],
REPLACE(REPLACE(CASE WHEN client = 'M00001' and  LOWER(WT.ds_descrn) LIKE '%disease%' THEN REPLACE(WT.ds_descrn,'Disease - ','')
	 WHEN client = 'M00001' AND ( (mg_wrktyp >= '1254' AND mg_wrktyp <= '1263') OR (mg_wrktyp >= '1274' AND mg_wrktyp <= '1277 ') OR mg_wrktyp = '1571' ) THEN 'Abuse'
	 WHEN client <> 'M00001' THEN REPLACE(sd_WPS027.sd_listxt,'Disease - ','') ELSE 'Other' END,'D17 Industrial deafness','Industrial deafness'),'D31 VWF/Reynauds phenomenon','VWF/Reynauds phenomenon') [Claim Type],
WT.ds_descrn [Work_type],
case_public_desc1 [matter_description],
TRA125.case_text [Present position],
FTR454.case_text [Job Role],
LIT1218.case_text [Risk Type],
ALOC.case_text [Risk location],
LIT1219.case_text [Risk descriptor (Abuser)],
LIT1220.case_text [Abuse Codes],
LIT1221.case_text [Allegation TYPE],
WPS075.case_text [Exposure / Abuse period (s)],
CASE WHEN WPS283.case_value IS null THEN NMI986.case_value ELSE WPS283.case_value END /100  [MMI’s % - Damages],
NMI413.case_value /100 [MMI’s % - CRU ],
CASE WHEN WPS284.case_value IS null THEN NMI987.case_value ELSE WPS284.case_value END /100  [MMI’s % - Costs],
NMI997.case_value /100 [MMI’s % - Defence costs]  ,
CASE WHEN NMI617.case_text = 'No' OR WPS276.case_text = 'Follow' THEN 'No' ELSE 'Yes' end [MMI Lead],
cashdr.date_opened [Open Date], 
LOCD.case_date [Date of LoC],
NMI1055.case_date [Date of CFA/DBA],
TRA084.case_date [Issue Date] ,   
NHS024.case_date [Service Date],
WPS114.case_text [Avoidable],
LIT1217.case_text [Litigation cause],
NULL [Gross Estimate],
LIT1222.case_value [Reserve Damages],
CASE WHEN (TRA068.case_text IS NOT NULL OR TRA086.case_date IS NOT NULL) THEN 0 ELSE WPS008.case_value END [Reserve CRU],
LIT1223.case_value [Reserve Claimant’s Costs],
LIT1225.case_value [Reserve Own Costs],
LIT1224.case_value [Total O/S Reserve],
case WHEN client <> 'M00001' then WPS279.case_value + WPS279.case_value ELSE 0 end [Paid Damages],
CASE WHEN WPS281.case_value IS NULL THEN NMI122.case_value ELSE WPS281.case_value end [Paid CRU],
case WHEN client <> 'M00001' then WPS280.case_value + WPS280.case_value ELSE 0 END [Paid Claimant’s Costs],
case WHEN client <> 'M00001' then WPS340.case_value + WPS340.case_value ELSE 0 END [Paid Own Costs],
NULL AS [Total Paid],
NULL AS [Net O/S Reserve],
LIT1214.case_value [Claimant’s P36],
LIT1215.case_value [Defendant’s P36],
CASE WHEN cashdr.date_closed IS not NULL OR VE00571.case_date IS NOT NULL THEN 'Closed' ELSE 'Open' end  [Status],
LIT1216.case_text [Present Position / Barriers to settlement],
TRA086.case_date [Date Damages Settled],
FTR087.case_date [Date Costs Agreed],
CASE WHEN VE00571.case_date IS NULL THEN date_closed ELSE VE00571.case_date END [Closed Date],
MIB020.case_text [Litigated Matter Number]
,CAST(YEAR(date_opened) AS NVARCHAR(4)) + '-Q' + CAST(DATEPART(Quarter,date_opened) AS NVARCHAR(1))  AS [Quarter Received]
,CASE WHEN TRA082.case_text='Yes' THEN 'Litigated' ELSE 'Pre-lit' END AS [Litigated]
,CASE WHEN TRA068.case_text IN 
(
'Won at trial','Struck out','Discontinued - post-lit with no costs order','Discontinued - post-lit with costs order','Discontinued - pre-lit'
,'Discontinued','Struck Out','Won at Trial','Discontinued - indemnified by third party','Discontinued - indemnified by 3rd party'
,'discontinued - pre-lit','Won','Withdrawn','Discontinued - post lit with no costs order'
) THEN 'Repudiated'
WHEN TRA068.case_text IN (
'Settled'
,'Settled - JSM'
,'Lost at trial'
,'Settled - infant approval'
,'Assessment of damages'
,'Lost at Trial'
,'Settled - mediation'
,'settled'
,'Assessment of damages (damages exceed claimant''s P36 offer)'
,'Assessment of damages (claimant fails to beat P36 offer)'
,'Lost at trial (damages exceed claimant''s P36 offer)'
,'Damages assessed'
) THEN 'Settled'
 

ELSE NULL 
END 

AS [Repudiated/Settled]
,NMI026.case_text AS [IncidentPostcode]
FROM axxia01.dbo.cashdr
LEFT JOIN axxia01.dbo.camatgrp ON  camatgrp.mg_client = client AND mg_matter = matter
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history fed ON mg_feearn = fed.fed_code AND fed.dss_current_flag = 'Y' --AND fed.activeud = 1
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history par ON mg_parter = par.fed_code AND par.dss_current_flag = 'Y' --AND par.activeud = 1
LEFT JOIN axxia01.dbo.casdet WPS275 ON cashdr.case_id = WPS275.case_id  AND WPS275.case_detail_code = 'WPS275'
LEFT JOIN axxia01.dbo.casdet WPS332 ON cashdr.case_id = WPS332.case_id  AND WPS332.case_detail_code = 'WPS332' AND WPS332.cd_parent = WPS275.seq_no
LEFT JOIN axxia01.dbo.casdet WPS344 ON cashdr.case_id = WPS344.case_id  AND WPS344.case_detail_code = 'WPS344' AND WPS344.cd_parent = WPS275.seq_no

LEFT JOIN axxia01.dbo.casdet TRA115 ON cashdr.case_id = TRA115.case_id  AND TRA115.case_detail_code = 'TRA115'
LEFT JOIN axxia01.dbo.cadescrp WT ON WT.ds_reckey = mg_wrktyp AND WT.ds_rectyp = 'WT'

LEFT JOIN axxia01.dbo.casdet WPS027 ON cashdr.case_id = WPS027.case_id  AND WPS027.case_detail_code = 'WPS027'
LEFT join axxia01.dbo.stdetlst sd_WPS027 on sd_liscod = WPS027.case_text AND sd_detcod = 'WPS027'

LEFT JOIN axxia01.dbo.casdet FTR454 ON cashdr.case_id = FTR454.case_id  AND FTR454.case_detail_code = 'FTR454' 
LEFT JOIN axxia01.dbo.casdet TRA082 ON cashdr.case_id = TRA082.case_id  AND TRA082.case_detail_code = 'TRA082' 


LEFT JOIN axxia01.dbo.casdet ALOC  ON cashdr.case_id = ALOC.case_id  AND ALOC.case_detail_code = 'ALOC'
LEFT JOIN axxia01.dbo.casdet NMI026  ON cashdr.case_id = NMI026.case_id  AND NMI026.case_detail_code = 'NMI026'

LEFT JOIN axxia01.dbo.casdet WPS075 ON cashdr.case_id = WPS075.case_id  AND WPS075.case_detail_code = 'WPS075' 

LEFT JOIN axxia01.dbo.casdet WPS283 ON cashdr.case_id = WPS283.case_id  AND WPS283.case_detail_code = 'WPS283' and WPS283.cd_parent = WPS275.seq_no
LEFT JOIN axxia01.dbo.casdet NMI986 ON cashdr.case_id = NMI986.case_id  AND NMI986.case_detail_code = 'NMI986' 

LEFT JOIN axxia01.dbo.casdet NMI413 ON cashdr.case_id = NMI413.case_id  AND NMI413.case_detail_code = 'NMI413' 

LEFT JOIN axxia01.dbo.casdet WPS284 ON cashdr.case_id = WPS284.case_id  AND WPS284.case_detail_code = 'WPS284' and WPS284.cd_parent = WPS275.seq_no
LEFT JOIN axxia01.dbo.casdet NMI987 ON cashdr.case_id = NMI987.case_id  AND NMI987.case_detail_code = 'NMI987'  

LEFT JOIN axxia01.dbo.casdet NMI997 ON cashdr.case_id = NMI997.case_id  AND NMI997.case_detail_code = 'NMI997'  

LEFT JOIN axxia01.dbo.casdet NMI617 ON cashdr.case_id = NMI617.case_id  AND NMI617.case_detail_code = 'NMI617'  
LEFT JOIN axxia01.dbo.casdet WPS276 ON cashdr.case_id = WPS276.case_id  AND WPS276.case_detail_code = 'WPS276' and WPS276.cd_parent = WPS275.seq_no

LEFT JOIN axxia01.dbo.casdet LOCD ON cashdr.case_id = LOCD.case_id  AND LOCD.case_detail_code = 'LOCD' 

LEFT JOIN axxia01.dbo.casdet NMI1055 ON cashdr.case_id = NMI1055.case_id  AND NMI1055.case_detail_code = 'NMI1055' 
 
LEFT JOIN axxia01.dbo.casdet TRA084 ON cashdr.case_id = TRA084.case_id  AND TRA084.case_detail_code = 'TRA084' 

LEFT JOIN axxia01.dbo.casdet NHS024 ON cashdr.case_id = NHS024.case_id  AND NHS024.case_detail_code = 'NHS024' 
LEFT JOIN axxia01.dbo.casdet WPS114 ON cashdr.case_id = WPS114.case_id  AND WPS114.case_detail_code = 'WPS114' 

LEFT JOIN axxia01.dbo.casdet TRA068 ON cashdr.case_id = TRA068.case_id  AND TRA068.case_detail_code = 'TRA068' 
LEFT JOIN axxia01.dbo.casdet TRA086 ON cashdr.case_id = TRA086.case_id  AND TRA086.case_detail_code = 'TRA086' 
LEFT JOIN axxia01.dbo.casdet WPS008 ON cashdr.case_id = WPS008.case_id  AND WPS008.case_detail_code = 'WPS008' 

LEFT JOIN axxia01.dbo.casdet WPS278 ON cashdr.case_id = WPS278.case_id  AND WPS278.case_detail_code = 'WPS278' AND WPS278.cd_parent = WPS275.seq_no
LEFT JOIN axxia01.dbo.casdet WPS279 ON cashdr.case_id = WPS279.case_id  AND WPS279.case_detail_code = 'WPS279' AND WPS279.cd_parent = WPS279.seq_no

LEFT JOIN axxia01.dbo.casdet WPS281 ON cashdr.case_id = WPS281.case_id  AND WPS281.case_detail_code = 'WPS281' AND WPS281.cd_parent = WPS275.seq_no
LEFT JOIN axxia01.dbo.casdet NMI122 ON cashdr.case_id = NMI122.case_id  AND NMI122.case_detail_code = 'NMI122' 

LEFT JOIN axxia01.dbo.casdet WPS280 ON cashdr.case_id = WPS280.case_id  AND WPS280.case_detail_code = 'WPS280' AND WPS280.cd_parent = WPS279.seq_no

LEFT JOIN axxia01.dbo.casdet WPS340 ON cashdr.case_id = WPS340.case_id  AND WPS340.case_detail_code = 'WPS340' AND WPS340.cd_parent = WPS279.seq_no
LEFT JOIN axxia01.dbo.casdet WPS341 ON cashdr.case_id = WPS341.case_id  AND WPS341.case_detail_code = 'WPS341' AND WPS341.cd_parent = WPS279.seq_no  

LEFT JOIN axxia01.dbo.casdet VE00571 ON cashdr.case_id = VE00571.case_id  AND VE00571.case_detail_code = 'VE00571'  

LEFT JOIN axxia01.dbo.casdet FTR087 ON cashdr.case_id = FTR087.case_id  AND FTR087.case_detail_code = 'FTR087' 


LEFT JOIN axxia01.dbo.casdet TRA125 ON cashdr.case_id = TRA125.case_id  AND TRA125.case_detail_code = 'TRA125' 

LEFT JOIN axxia01.dbo.casdet LIT1214 ON cashdr.case_id = LIT1214.case_id  AND LIT1214.case_detail_code = 'LIT1214' 
LEFT JOIN axxia01.dbo.casdet LIT1215 ON cashdr.case_id = LIT1215.case_id  AND LIT1215.case_detail_code = 'LIT1215' 
LEFT JOIN axxia01.dbo.casdet LIT1216 ON cashdr.case_id = LIT1216.case_id  AND LIT1216.case_detail_code = 'LIT1216' 
LEFT JOIN axxia01.dbo.casdet LIT1217 ON cashdr.case_id = LIT1217.case_id  AND LIT1217.case_detail_code = 'LIT1217' 
LEFT JOIN axxia01.dbo.casdet LIT1218 ON cashdr.case_id = LIT1218.case_id  AND LIT1218.case_detail_code = 'LIT1218' 
LEFT JOIN axxia01.dbo.casdet LIT1219 ON cashdr.case_id = LIT1219.case_id  AND LIT1219.case_detail_code = 'LIT1219' 
LEFT JOIN axxia01.dbo.casdet LIT1220 ON cashdr.case_id = LIT1220.case_id  AND LIT1220.case_detail_code = 'LIT1220' 
LEFT JOIN axxia01.dbo.casdet LIT1221 ON cashdr.case_id = LIT1221.case_id  AND LIT1221.case_detail_code = 'LIT1221' 
LEFT JOIN axxia01.dbo.casdet LIT1222 ON cashdr.case_id = LIT1222.case_id  AND LIT1222.case_detail_code = 'LIT1222' 
LEFT JOIN axxia01.dbo.casdet LIT1223 ON cashdr.case_id = LIT1223.case_id  AND LIT1223.case_detail_code = 'LIT1223' 
LEFT JOIN axxia01.dbo.casdet LIT1224 ON cashdr.case_id = LIT1224.case_id  AND LIT1224.case_detail_code = 'LIT1224'
LEFT JOIN axxia01.dbo.casdet LIT1225 ON cashdr.case_id = LIT1225.case_id  AND LIT1225.case_detail_code = 'LIT1225' 

LEFT JOIN axxia01.dbo.casdet MIB020 ON cashdr.case_id = MIB020.case_id  AND MIB020.case_detail_code = 'MIB020'
 
WHERE (date_closed > '2018-01-01' OR date_closed IS NULL) and client = 'M00001' OR ( WPS332.case_text IS NOT NULL AND WPS332.case_text = 'MMI') 
) AS AllData
--LEFT OUTER JOIN red_dw.dbo.fact_finance_summary AS a
-- ON AllData.client=a.client_code AND AllData.matter=matter_number
LEFT OUTER JOIN 
(
SELECT [wp_type]
,[client_group_name]
,a.[client_code]
,a.[matter_number]
,[damages_reserve_net] 
,[tp_costs_reserve_net] 
,[defence_costs_reserve_net] 
,[total_reserve_net] 
,[damages_paid_to_date] 
,[total_tp_costs_paid_to_date] 
,[defence_costs_billed] 
,[present_position]
,[wip]
,[unpaid_bill_balance]
FROM red_dw.dbo.dim_matter_header_current AS a
INNER JOIN red_dw.dbo.fact_dimension_main AS b
 ON a.dim_matter_header_curr_key=b.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim AS c
 ON b.dim_detail_claim_key=c.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary AS d
 ON a.client_code=d.client_code AND a.matter_number=d.matter_number

WHERE (a.client_code='M00001' OR (client_group_name='Zurich' AND wp_type='MMI'))
) AS DAX
 ON AllData.client=DAX.client_code AND AllData.matter=matter_number
--WHERE client='M00001' AND matter='11111189'
ORDER By client,matter
END


--[MMI].[MMI_Quarterly_Dashboard] 
GO

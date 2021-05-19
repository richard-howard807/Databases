SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[NPGPreBilling]

AS 

BEGIN 
SELECT dbFile.fileID AS [ms_fileid]
,contChristianNames + ' '+contSurname AS [Name of Surveyor / Wayleave Officer]
,txtJobNumber AS [Northern Powergrid Ref]
,clNo + '-'+ fileNo AS [Law Firm Ref]
,fileDesc AS [Job Description/Location]
,Insttype.cdDesc AS [Type of Job]
,'New/Existing' AS [Rights]
,WIP.name AS [Fee earner initials]
,WIP.hourly_charge_rate AS [Hourly Rate]
,WIP.MinutesRecorded AS [Time]
,WIP.WIPValue AS [Total  WIP Charge]
,NULL AS [VAT on Legal Costs]
,UnbilledDisbs.NotVatDisbs AS [Not-Vatable disbursements]
,UnbilledDisbs.DisbsWithVat AS [Vatable Disbursements]
,UnbilledDisbs.VatDisbursements AS [VAT on Vatable Disbursements]
,NULL AS [Purchase Order Number]
,NULL AS [Northern Powergrid Reference Number:]
,NULL AS [Authorisation/Release Number:]
,NULL AS [Is the transaction OTH]
,Fees.[Legal Costs] AS [Legal Costs(Billed)]
,Fees.[VAT on Legal Costs] AS [VAT on Legal Costs (Billed)]
,Disbs.NonVatableDisbs AS [Total costs of Non-Vatable Disbursements(Billed)]
,Disbs.VatableDisbs AS [Total cost of Vatable Disbursements (net of VAT)(Billed)]
,Disbs.VatonDisbs AS [VAT on Vatable Disbursements(Billed)]
,ISNULL(Disbs.NonVatableDisbs,0)+ISNULL(Disbs.VatableDisbs,0) AS [Net of Vat Disbursements]
,ISNULL(Fees.[Legal Costs],0)+ISNULL(Disbs.NonVatableDisbs,0)+ISNULL(Disbs.VatableDisbs,0) AS [Total costs including disbursements net of VAT(Billed)]
,ISNULL(ms_workstream.workstream,'Other') AS workstream
,cboNPGFileType
FROM ms_prod.config.dbFile WITH(NOLOCK)
INNER JOIN MS_Prod.config.dbClient WITH(NOLOCK)
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN (
SELECT dbfile.fileid
,		SUM(TB.billamt) AS [Legal Costs]
,		SUM(cbt.chrgamt) AS [VAT on Legal Costs]
FROM red_dw.dbo.ds_sh_3e_armaster ARD WITH(NOLOCK)
INNER JOIN red_dw.dbo.ds_sh_3e_matter AS m WITH(NOLOCK)
 ON ARD.matter=m.mattindex
INNER JOIN red_dw.dbo.ds_sh_ms_dbfile AS dbfile WITH(NOLOCK)
 ON m.mattindex=dbfile.fileextlinkid
INNER JOIN red_dw.dbo.ds_sh_ms_dbclient WITH(NOLOCK)
 ON ds_sh_ms_dbclient.clid = dbfile.clid
INNER JOIN red_dw.dbo.ds_sh_3e_timebill TB WITH(NOLOCK)  
ON TB.armaster = ARD.armindex
INNER JOIN red_dw.dbo.ds_sh_3e_chrgbilltax CBT WITH(NOLOCK) 
ON tb.timebillindex = cbt.timebill
WHERE clno IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND ARD.arlist  IN ('Bill','BillRev')
GROUP BY dbfile.fileid
) AS Fees
 ON  Fees.fileid = dbFile.fileID

LEFT OUTER JOIN 
(
SELECT dbfile.fileid
,SUM(CASE WHEN ISNULL(CBT.chrgamt,0)=0 THEN CB.billamt ELSE 0 END) AS NonVatableDisbs
,SUM(CASE WHEN ISNULL(CBT.chrgamt,0)<>0 THEN CB.billamt ELSE 0 END) AS VatableDisbs
,SUM(CBT.chrgamt) AS VatonDisbs
FROM red_dw.dbo.ds_sh_3e_armaster ARD WITH(NOLOCK)
INNER JOIN red_dw.dbo.ds_sh_3e_matter AS m WITH(NOLOCK)
 ON ARD.matter=m.mattindex
INNER JOIN red_dw.dbo.ds_sh_ms_dbfile AS dbfile WITH(NOLOCK)
 ON m.mattindex=dbfile.fileextlinkid
INNER JOIN red_dw.dbo.ds_sh_ms_dbclient WITH(NOLOCK)
 ON ds_sh_ms_dbclient.clid = dbfile.clid
INNER JOIN red_dw.dbo.ds_sh_3e_costbill CB ON CB.armaster = ard.armindex
	LEFT JOIN red_dw.dbo.ds_sh_3e_chrgbilltax CBT ON cb.costbillindex = cbt.costbill
WHERE clno IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND ARD.arlist  IN ('Bill','BillRev')
AND ARD.isreversed=0
GROUP BY dbfile.fileid
) AS Disbs
 ON Disbs.fileid = dbFile.fileID
LEFT OUTER JOIN MS_PROD.dbo.udMIClientNPG WITH(NOLOCK)
 ON udMIClientNPG.fileID = dbfile.fileID
LEFT OUTER JOIN MS_PROD.config.dbAssociates WITH(NOLOCK)
 ON dbAssociates.fileID = dbFile.fileID AND assocType='WAYLEA' AND dbassociates.assocActive=1
LEFT OUTER JOIN MS_PROD.config.dbContact WITH(NOLOCK)
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbContactIndividual WITH(NOLOCK)
 ON dbContactIndividual.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS Insttype WITH(NOLOCK)
ON cboInsTypeNPG=Insttype.cdCode AND Insttype.cdType='INSTYPENPG'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup   AS MatStat WITH(NOLOCK)
ON cboMatterStat=MatStat.cdCode AND MatStat.cdType='STATUSNPG'
LEFT OUTER JOIN 
(
SELECT  ms_fileid
,SUM(CASE WHEN total_unbilled_disbursements_vat=0 THEN total_unbilled_disbursements ELSE 0 END) AS NotVatDisbs
,SUM(CASE WHEN total_unbilled_disbursements_vat<>0 THEN total_unbilled_disbursements ELSE 0 END) AS DisbsWithVat
,SUM(total_unbilled_disbursements_vat) AS VatDisbursements
FROM red_dw.dbo.fact_disbursements_detail WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_disbursements_detail.dim_matter_header_curr_key
WHERE master_client_code IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND ISNULL(total_unbilled_disbursements,0) <>0
GROUP BY ms_fileid
) AS UnbilledDisbs
 ON UnbilledDisbs.ms_fileid=dbfile.fileid
LEFT OUTER JOIN 
(
SELECT ms_fileid,name,hourly_charge_rate,SUM(minutes_recorded) AS MinutesRecorded,SUM(time_charge_value)  AS WIPValue 
FROM red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
WHERE dim_bill_key=0 AND isactive=1
AND master_client_code IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
GROUP BY ms_fileid,name,hourly_charge_rate 
) AS WIP
 ON dbFile.fileID=WIP.ms_fileid
LEFT OUTER JOIN 
(
SELECT 
	dbFile.fileID
	, dbCodeLookup.cdDesc	AS workstream	
FROM MS_Prod.config.dbFile
	INNER JOIN MS_Prod.config.dbClient
		ON dbClient.clID = dbFile.clID
	INNER JOIN MS_Prod.dbo.udMIClientNPG
		ON udMIClientNPG.fileID = dbFile.fileID
	INNER JOIN MS_Prod.dbo.dbCodeLookup
		ON dbCodeLookup.cdCode = udMIClientNPG.cboWorkstream
			AND dbCodeLookup.cdType = 'NPGWORK'
WHERE 1 = 1
	AND dbClient.clNo IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
) AS ms_workstream
	ON ms_workstream.fileID = dbFile.fileID
WHERE clno IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND fileNo<>'0'
AND fileClosed IS NULL


END
GO

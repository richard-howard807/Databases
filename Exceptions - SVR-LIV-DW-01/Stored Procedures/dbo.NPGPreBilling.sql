SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

































CREATE PROCEDURE [dbo].[NPGPreBilling] --[dbo].[NPGPreBilling]'All'
(
@Team AS NVARCHAR(100)
)

AS 

BEGIN 


IF OBJECT_ID(N'tempdb..#Fees') IS NOT NULL BEGIN DROP TABLE #Fees END
IF OBJECT_ID(N'tempdb..#Disbs') IS NOT NULL BEGIN DROP TABLE #Disbs END
IF OBJECT_ID(N'tempdb..#UnbilledDisbs') IS NOT NULL BEGIN DROP TABLE #UnbilledDisbs END


SELECT dbfile.fileid
,		SUM(TB.billamt) AS [Legal Costs]
,		SUM(cbt.chrgamt) AS [VAT on Legal Costs]
,MAX(ARD.invdate) AS LastBillDate
INTO #Fees
FROM red_dw.dbo.ds_sh_3e_armaster ARD WITH(NOLOCK)
INNER JOIN red_dw.dbo.ds_sh_3e_matter AS m WITH(NOLOCK)
 ON ARD.matter=m.mattindex
INNER JOIN red_dw.dbo.ds_sh_ms_dbfile AS dbfile WITH(NOLOCK)
 ON m.mattindex=dbfile.fileextlinkid
INNER JOIN red_dw.dbo.ds_sh_ms_dbclient WITH(NOLOCK)
 ON ds_sh_ms_dbclient.clid = dbfile.clid
INNER JOIN red_dw.dbo.ds_sh_3e_timebill TB WITH(NOLOCK)  
ON TB.armaster = ARD.armindex
LEFT JOIN red_dw.dbo.ds_sh_3e_chrgbilltax CBT WITH(NOLOCK) 
ON tb.timebillindex = cbt.timebill
WHERE clno IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND ARD.arlist  IN ('Bill','BillRev')
GROUP BY dbfile.fileid


SELECT dbfile.fileid
,SUM(CASE WHEN ISNULL(CBT.chrgamt,0)=0 THEN CB.billamt ELSE 0 END) AS NonVatableDisbs
,SUM(CASE WHEN ISNULL(CBT.chrgamt,0)<>0 THEN CB.billamt ELSE 0 END) AS VatableDisbs
,SUM(CBT.chrgamt) AS VatonDisbs
INTO #Disbs
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



SELECT ms_fileid
,SUM(CASE WHEN CostCard.TaxCode='UKZO' THEN WorkAmt ELSE 0 END) AS NotVatDisbs
,SUM(CASE WHEN costcard.TaxCode<>'UKZO' THEN WorkAmt ELSE 0 END) AS DisbsWithVat
,SUM(COALESCE(VchrDetail.Amount, CostCard.WorkAmt) * (tax.Rate / 100)) AS VatDisbursements
INTO #UnbilledDisbs
FROM TE_3E_Prod.dbo.CostCard WITH(NOLOCK)
INNER JOIN TE_3E_Prod.dbo.Matter WITH(NOLOCK)
 ON TE_3E_Prod.dbo.CostCard.Matter=MattIndex
INNER JOIN ms_prod.config.dbFile WITH(NOLOCK)
 ON fileExtLinkID=MattIndex
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON fileID=ms_fileid
  LEFT OUTER JOIN TE_3E_Prod.dbo.VchrDetail AS VchrDetail WITH(NOLOCK)
            ON costcard.CostIndex = VchrDetail.CostCard
        LEFT OUTER JOIN
        (
            SELECT [TaxLkUp] [TaxCode],
                   [Rate]
            FROM [TE_3E_Prod].[dbo].[TaxDate] WITH(NOLOCK)
            WHERE NxEndDate = '9999-12-31 00:00:00.000'
        ) tax
            ON CostCard.TaxCode = tax.[TaxCode]
WHERE master_client_code IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
--AND Number='W22559-116'
AND costcard.IsActive=1
AND InvMaster IS NULL
GROUP BY ms_fileid


IF @Team='All' 

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
,ISNULL(UnbilledDisbs.NotVatDisbs,0)+ISNULL(UnbilledDisbs.DisbsWithVat,0)+ISNULL(UnbilledDisbs.VatDisbursements,0) AS [OutstandingDisbs]
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
,ISNULL(Fees.[Legal Costs],0)+ISNULL(Disbs.NonVatableDisbs,0) AS [Total costs including disbursements net of VAT(Billed)]
,ISNULL(ms_workstream.workstream,'Other') AS workstream
,cboNPGFileType
,[red_dw].[dbo].[datetimelocal](dteCompletionD) AS [Completion Date]
,NPGBIlls.[Billed To NPG]
,NPGBIlls.[Billed To Other]
,ISNULL(curTPPaying,0) AS [Third Pary Paying]
,cboFeeArrang
,curFixedFeeAmou
,LastBillDate
,usrFullName AS [Matter Owner]
,TotalWIP.TotalWIP
,CASE WHEN cboFeeArrang='FIXEDFEE' THEN  
IIF(ISNULL(curFixedFeeAmou,0) - ISNULL(NPGBIlls.[Billed To NPG],0) <0 ,0,ISNULL(curFixedFeeAmou,0) - ISNULL(NPGBIlls.[Billed To NPG],0))
ELSE NULL END AS FixedFeeLeft
,clName
,Agent.Agent
,WAYLEA.WAYLEA
FROM ms_prod.config.dbFile WITH(NOLOCK)
INNER JOIN MS_Prod.config.dbClient WITH(NOLOCK)
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN #Fees AS Fees
 ON  Fees.fileid = dbFile.fileID
 LEFT OUTER JOIN #Disbs AS Disbs
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
LEFT OUTER JOIN #UnbilledDisbs AS UnbilledDisbs
 ON UnbilledDisbs.ms_fileid=dbfile.fileid
LEFT OUTER JOIN 
(
SELECT ms_fileid,name,hourly_charge_rate,SUM(minutes_recorded) AS MinutesRecorded,SUM(time_charge_value)  AS WIPValue 
,COUNT(1) AS Records
FROM red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
WHERE dim_bill_key=0 AND isactive=1
AND dim_bill_date_key=0
AND master_client_code IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
GROUP BY ms_fileid,name,hourly_charge_rate 
) AS WIP
 ON dbFile.fileID=WIP.ms_fileid
LEFT OUTER JOIN 
(
SELECT ms_fileid,SUM(time_charge_value)  AS TotalWIP 
FROM red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
WHERE dim_bill_key=0 AND isactive=1
AND master_client_code IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND dim_bill_date_key=0
GROUP BY ms_fileid
) AS TotalWIP
 ON dbFile.fileID=TotalWIP.ms_fileid
LEFT OUTER JOIN ms_prod.dbo.dbUser ON filePrincipleID=usrID
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
LEFT OUTER JOIN ms_prod.dbo.udMICoreGeneral ON udMICoreGeneral.fileID = dbFile.fileID
LEFT OUTER JOIN (
SELECT dbfile.fileid
,SUM(CASE WHEN Payor.DisplayName IN 
('Northern Electric Plc','Northern Powergrid (Northeast) Plc'
,'Northern Powergrid (Yorkshire) Plc','Northern Powergrid Limited'
,'Npower Yorkshire Limited','Yorkshire Electricity Distribution plc','Yorkshire Electricity Group Plc'
) THEN ARDetail.arfee ELSE 0 END) AS [Billed To NPG]
,SUM(CASE WHEN Payor.DisplayName NOT IN 
('Northern Electric Plc','Northern Powergrid (Northeast) Plc'
,'Northern Powergrid (Yorkshire) Plc','Northern Powergrid Limited'
,'Npower Yorkshire Limited','Yorkshire Electricity Distribution plc','Yorkshire Electricity Group Plc'
) THEN ARDetail.arfee ELSE 0 END) AS [Billed To Other]

FROM red_dw.dbo.ds_sh_3e_ardetail AS ARDetail WITH(NOLOCK) 
INNER JOIN red_dw.dbo.ds_sh_3e_matter AS Matter
 ON ARDetail.matter=Matter.mattindex
INNER JOIN red_dw.dbo.ds_sh_ms_dbfile AS dbfile WITH(NOLOCK)
 ON matter.mattindex=dbfile.fileextlinkid
INNER JOIN red_dw.dbo.ds_sh_ms_dbclient WITH(NOLOCK)
 ON ds_sh_ms_dbclient.clid = dbfile.clid
LEFT OUTER JOIN te_3e_prod.dbo.Payor
 ON ARDetail.payor=PayorIndex
 WHERE clno IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND arlist  IN ('Bill','BillRev','BILL')

GROUP BY dbfile.fileid
) AS NPGBIlls
		  ON NPGBIlls.fileid = dbFile.fileID
LEFT OUTER JOIN 
(
SELECT  dbFile.fileID,STRING_AGG(contName,',') AS Agent
FROM ms_prod.config.dbFile
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN ms_prod.config.dbAssociates
 ON dbAssociates.fileID = dbFile.fileID
INNER JOIN ms_prod.config.dbContact 
 ON dbContact.contID = dbAssociates.contID
 WHERE  clNo IN 
(
'WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103'
)
AND assocType='AGENT'
AND assocActive=1
GROUP BY dbFile.fileID
) AS Agent
 ON Agent.fileID = dbFile.fileID

 LEFT OUTER JOIN 
(
SELECT  dbFile.fileID,STRING_AGG(contName,',') AS WAYLEA
FROM ms_prod.config.dbFile
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN ms_prod.config.dbAssociates
 ON dbAssociates.fileID = dbFile.fileID
INNER JOIN ms_prod.config.dbContact 
 ON dbContact.contID = dbAssociates.contID
 WHERE  clNo IN 
(
'WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103'
)
AND assocType='WAYLEA'
AND assocActive=1
GROUP BY dbFile.fileID
) AS WAYLEA
 ON WAYLEA.fileID = dbFile.fileID

 




WHERE clno IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND fileNo<>'0'
AND fileClosed IS NULL
AND ISNULL(cboNPGFileType,'')<>'COMLIT'
--AND fileNo='2308' 
--AND ISNULL(TotalWIP,0)=0 AND ISNULL(UnbilledDisbs.NotVatDisbs,0)+ISNULL(UnbilledDisbs.DisbsWithVat,0)+ISNULL(UnbilledDisbs.VatDisbursements,0) >0

END 

ELSE 

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
,ISNULL(UnbilledDisbs.NotVatDisbs,0)+ISNULL(UnbilledDisbs.DisbsWithVat,0)+ISNULL(UnbilledDisbs.VatDisbursements,0) AS [OutstandingDisbs]
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
,ISNULL(Fees.[Legal Costs],0)+ISNULL(Disbs.NonVatableDisbs,0) AS [Total costs including disbursements net of VAT(Billed)]
,ISNULL(ms_workstream.workstream,'Other') AS workstream
,cboNPGFileType
,[red_dw].[dbo].[datetimelocal](dteCompletionD) AS [Completion Date]
,ISNULL(curTPPaying,0) AS [Third Pary Paying]
,NPGBIlls.[Billed To NPG]
,NPGBIlls.[Billed To Other]
,cboFeeArrang
,curFixedFeeAmou
,LastBillDate
,usrFullName AS [Matter Owner]
,TotalWIP.TotalWIP
,CASE WHEN cboFeeArrang='FIXEDFEE' THEN  
IIF(ISNULL(curFixedFeeAmou,0) - ISNULL(NPGBIlls.[Billed To NPG],0) <0 ,0,ISNULL(curFixedFeeAmou,0) - ISNULL(NPGBIlls.[Billed To NPG],0))
ELSE NULL END AS FixedFeeLeft
,clName
,Agent.Agent
,WAYLEA.WAYLEA
FROM ms_prod.config.dbFile WITH(NOLOCK)
INNER JOIN MS_Prod.config.dbClient WITH(NOLOCK)
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN #Fees AS Fees
 ON  Fees.fileid = dbFile.fileID

LEFT OUTER JOIN #Disbs AS Disbs
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
LEFT OUTER JOIN #UnbilledDisbs AS UnbilledDisbs
 ON UnbilledDisbs.ms_fileid=dbfile.fileid
LEFT OUTER JOIN 
(
SELECT ms_fileid,name,hourly_charge_rate,SUM(minutes_recorded) AS MinutesRecorded,SUM(time_charge_value)  AS WIPValue 
,COUNT(1) AS Records
FROM red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
WHERE dim_bill_key=0 AND isactive=1
AND dim_bill_date_key=0
AND master_client_code IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
GROUP BY ms_fileid,name,hourly_charge_rate 
) AS WIP
 ON dbFile.fileID=WIP.ms_fileid
 LEFT OUTER JOIN ms_prod.dbo.dbUser ON filePrincipleID=usrID
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
LEFT OUTER JOIN ms_prod.dbo.udMICoreGeneral ON udMICoreGeneral.fileID = dbFile.fileID
LEFT OUTER JOIN (
SELECT dbfile.fileid
,SUM(CASE WHEN Payor.DisplayName IN 
('Northern Electric Plc','Northern Powergrid (Northeast) Plc'
,'Northern Powergrid (Yorkshire) Plc','Northern Powergrid Limited'
,'Npower Yorkshire Limited','Yorkshire Electricity Distribution plc','Yorkshire Electricity Group Plc'
) THEN ARDetail.arfee ELSE 0 END) AS [Billed To NPG]
,SUM(CASE WHEN Payor.DisplayName NOT IN 
('Northern Electric Plc','Northern Powergrid (Northeast) Plc'
,'Northern Powergrid (Yorkshire) Plc','Northern Powergrid Limited'
,'Npower Yorkshire Limited','Yorkshire Electricity Distribution plc','Yorkshire Electricity Group Plc'
) THEN ARDetail.arfee ELSE 0 END) AS [Billed To Other]

FROM red_dw.dbo.ds_sh_3e_ardetail AS ARDetail WITH(NOLOCK) 
INNER JOIN red_dw.dbo.ds_sh_3e_matter AS Matter
 ON ARDetail.matter=Matter.mattindex
INNER JOIN red_dw.dbo.ds_sh_ms_dbfile AS dbfile WITH(NOLOCK)
 ON matter.mattindex=dbfile.fileextlinkid
INNER JOIN red_dw.dbo.ds_sh_ms_dbclient WITH(NOLOCK)
 ON ds_sh_ms_dbclient.clid = dbfile.clid
LEFT OUTER JOIN te_3e_prod.dbo.Payor
 ON ARDetail.payor=PayorIndex
 WHERE clno IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND arlist  IN ('Bill','BillRev','BILL')

GROUP BY dbfile.fileid
) AS NPGBIlls
		  ON NPGBIlls.fileid = dbFile.fileID
LEFT OUTER JOIN 
(
SELECT ms_fileid,SUM(time_charge_value)  AS TotalWIP 
FROM red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
WHERE dim_bill_key=0 AND isactive=1
AND dim_bill_date_key=0
AND master_client_code IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
GROUP BY ms_fileid
) AS TotalWIP
 ON dbFile.fileID=TotalWIP.ms_fileid
LEFT OUTER JOIN 
(
SELECT  dbFile.fileID,STRING_AGG(contName,',') AS Agent
FROM ms_prod.config.dbFile
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN ms_prod.config.dbAssociates
 ON dbAssociates.fileID = dbFile.fileID
INNER JOIN ms_prod.config.dbContact 
 ON dbContact.contID = dbAssociates.contID
 WHERE  clNo IN 
(
'WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103'
)
AND assocType='AGENT'
AND assocActive=1
GROUP BY dbFile.fileID
) AS Agent
 ON Agent.fileID = dbFile.fileID
 LEFT OUTER JOIN 
(
SELECT  dbFile.fileID,STRING_AGG(contName,',') AS WAYLEA
FROM ms_prod.config.dbFile
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN ms_prod.config.dbAssociates
 ON dbAssociates.fileID = dbFile.fileID
INNER JOIN ms_prod.config.dbContact 
 ON dbContact.contID = dbAssociates.contID
 WHERE  clNo IN 
(
'WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103'
)
AND assocType='WAYLEA'
AND assocActive=1
GROUP BY dbFile.fileID
) AS WAYLEA
 ON WAYLEA.fileID = dbFile.fileID

WHERE clno IN ('WB164102','W24159','WB164104','WB164106','W22559','WB170376','WB165103')
AND fileNo<>'0'
AND fileClosed IS NULL
AND cboNPGFileType=@Team


END 

END
GO

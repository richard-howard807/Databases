SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--================================================
--ES 20200713 #64332

--================================================


CREATE PROCEDURE [CommercialRecoveries].[CostCutter]
AS
BEGIN
SELECT clNo +'-'+ fileNo AS [CaseCode] 
,fileDesc AS [CaseDesc]
,Reference AS [AlternativeRef]
,curOriginalBal AS [PrincipalDebt]
,CostcutterStatus.Termination AS [TerminationFees]
,ISNULL(curOriginalBal,0)+ISNULL(CostcutterStatus.Termination,0) AS [Total Debt]
,Ledger.Payments AS [SumsRecovered]
,curCurrentBal AS [CurrentBalance]
,txtClaNum2 AS [ClaimNumber]
,txtCurenStatNot AS [Reporting Notes]
,usrFullName AS [WeightmansHandler]
,CASE WHEN fileStatus ='LIVE' THEN 'Open' ELSE 'Closed' END AS FileStatus
,dbFile.Created AS [DateOpened]
,fileClosed AS [DateClosed]
,DATEDIFF(DAY,dbFile.Created,fileClosed) AS [DaysOpened]
,dbFile.fileID
,Defendant.Defendant
,Defendant.Postcode
,Longitude
,Latitude 
,CASE WHEN Defendant.contTypeCode='ORGANISATION' THEN 'Company' WHEN Defendant.contTypeCode='INDIVIDUAL' THEN 'Individual' ELSE 'Other' END AS [Company Or Individual]
,AnnualYTD AS [RecoveredYTD]
,CASE WHEN CostcutterStatus='Court Proceedings' THEN 'Court Proceedings'
WHEN CostcutterStatus='Insolvency' THEN CostcutterStatus + ' - ' + InsolvancyStatus	
WHEN CostcutterStatus='Insolvency Proceedings' THEN 'Insolvency Proceedings'
WHEN CostcutterStatus='Post Judgment Enforcement' THEN CostcutterStatus + ' - ' + CostcutterStatus.EnforcementStatus	
WHEN CostcutterStatus='Pre Proceedings' THEN CostcutterStatus + ' - ' + CostcutterStatus.PreStatus
END AS CostcutterStatus
,CASE WHEN CostcutterStatus='Insolvency Proceedings' AND CostcutterStatus.InsolvancyType='Personal Insolvency'  THEN CostcutterStatus.InsolvancyType + '-' + CostcutterStatus.Personal 
WHEN CostcutterStatus='Insolvency Proceedings' AND CostcutterStatus.InsolvancyType='Corporate and Personal Insolvency'  THEN CostcutterStatus.InsolvancyType + '-' + CostcutterStatus.Corporate
END AS [Insolvency proceedings]
,CASE WHEN CostcutterStatus='Court Proceedings' THEN CostcutterStatus.CourtStatus ELSE NULL END AS [Court proceedings]
,ActionReq AS ActionRequired
,HearingDate
,defence_costs_billed AS [Revenue]
,CostcutterStatus.CostsRecovered AS [Costs Recovered from o/s]
,(ISNULL(Ledger.Payments,0)+ISNULL(CostcutterStatus.CostsRecovered,0))-ISNULL(defence_costs_billed,0) AS [Net Payment to Costcutter £]
,CASE WHEN (ISNULL(Ledger.Payments,0)+ISNULL(CostcutterStatus.CostsRecovered,0))-ISNULL(defence_costs_billed,0)<=0 THEN NULL ELSE defence_costs_billed/(ISNULL(Ledger.Payments,0)+ISNULL(CostcutterStatus.CostsRecovered,0)) END AS [Net % to Costcutter]
,CAST(master_matter_number AS INT) AS master_matter_number
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dbFile.fileID=ms_fileid
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN MS_Prod.dbo.dbUser
 ON filePrincipleID=usrID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore
 ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRInsolvency 
 ON udCRInsolvency.fileID = dbFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udCRIssueDetails
 ON udCRIssueDetails.fileID = dbFile.fileID
LEFT OUTER JOIN 
(
SELECT MS_Prod.dbo.udCRLedgerSL.fileID
,ISNULL(SUM(CASE WHEN cboCatDesc='2' THEN curOffice ELSE NULL END),0) AS [Recoverable Costs]
,ISNULL(SUM(CASE WHEN cboCatDesc IN ('1') THEN curOffice ELSE NULL END),0) AS [Recoverable Disbursements]
,ISNULL(SUM(CASE WHEN cboCatDesc='0' THEN curOffice ELSE NULL END),0) AS [Unrecoverable Disbursements]
,ISNULL(SUM(CASE WHEN cboCatDesc='7' THEN curOffice ELSE NULL END),0) AS [Unrecoverable Costs]
,ISNULL(SUM(CASE WHEN cboCatDesc='4' THEN curOffice ELSE NULL END),0) AS [Interest]
,ISNULL(SUM(CASE WHEN cboCatDesc='5' AND ISNULL(cboPayType,'') <>'PAY016' THEN curClient ELSE NULL END),0) AS [Payments]
,ISNULL(SUM(CASE WHEN cboCatDesc='6' THEN curClient ELSE NULL END),0) AS [Receipta awaiting clearance]
,ISNULL(SUM(CASE WHEN cboCatDesc='3' THEN curOffice ELSE NULL END),0) AS [Original Balance]
,ISNULL(SUM(CASE WHEN cboCatDesc='5' AND YEAR(dtePosted)=YEAR(GETDATE()) THEN curClient ELSE NULL END),0) AS AnnualYTD
FROM [MS_PROD].dbo.udCRLedgerSL
INNER JOIN ms_prod.config.dbFile
 ON dbFile.fileID = udCRLedgerSL.fileID
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_Prod.dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
GROUP BY udCRLedgerSL.fileID
) AS Ledger
 ON Ledger.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT DISTINCT fileID,assocRef AS [Reference] FROM MS_Prod.config.dbAssociates
WHERE assocType='INSUREDCLIENT'
AND assocRef IS NOT NULL
) AS InsuredREf
 ON InsuredREf.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS Defendant,contTypeCode,addPostcode AS Postcode
,ROW_NUMBER() OVER (PARTITION BY fileID ORDER BY assocID ASC) AS RowNumber
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbAddress
 ON contDefaultAddress=addID
WHERE assocType='DEFENDANT') AS Defendant
 ON Defendant.fileID = dbFile.fileID
 AND Defendant.RowNumber=1
LEFT OUTER JOIN red_dw.dbo.Doogal
 ON Doogal.Postcode = Defendant.Postcode COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT fileID
,CCStatus.cdDesc AS CostcutterStatus
,Enforce.cdDesc AS [EnforcementStatus]
,pre.cdDesc AS [PreStatus]
,Insolve.cdDesc AS InsolvancyStatus
,Personal.cdDesc AS Personal
,Corp.cdDesc AS Corporate
,Court.cdDesc AS CourtStatus
,InsolveType.cdDesc AS InsolvancyType
,ActionReq.cdDesc AS ActionReq
,curTermination AS [Termination]
,curCostRecOS AS [CostsRecovered]
FROM ms_prod.dbo.udCRCostcutterDetails
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup AS CCStatus
 ON cboCstCutStatus=CCStatus.cdCode AND CCStatus.cdType='COSTCUTRSTATUS'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup AS Enforce
 ON cboEnforcStatus=Enforce.cdCode AND Enforce.cdType='ENFORCEMENTSTS'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup AS Pre
 ON cboPreProStatus=Pre.cdCode AND Pre.cdType='PREPROCEEDSTATS'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup AS Insolve
 ON cboInsolvStatus=Insolve.cdCode AND Insolve.cdType='INSOLVENCYSTS'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup AS Personal
 ON cboPersnInsoSts=Personal.cdCode AND Personal.cdType='PERSINSOLSTATUS'
LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup AS Corp
 ON cboCorpInsoSts=Corp.cdCode AND Corp.cdType='CORPINSOLSTATUS'
 LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup AS Court
 ON cboCrtProStatus=Court.cdCode AND Court.cdType='COURTPROCEEDSTS'
 LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup AS InsolveType
 ON cboInsolvType=InsolveType.cdCode AND InsolveType.cdType='INSOLVENCYTYPE'
  LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup AS ActionReq
 ON cboactreqby=ActionReq.cdCode AND ActionReq.cdType='CCACTREQBY'

 
) AS CostcutterStatus
 ON CostcutterStatus.fileID = dbFile.fileID
LEFT OUTER JOIN 
(
SELECT dbTasks.fileID,MIN(tskDue)  AS HearingDate 
FROM ms_prod.dbo.dbTasks
INNER JOIN ms_prod.config.dbFile
 ON dbFile.fileID = dbTasks.fileID
INNER JOIN MS_Prod.config.dbClient
 ON dbClient.clID = dbFile.clID
WHERE tskDesc  IN (--'Court hearing due - today',
'Hearing - today')
AND clNo='W22511' 
AND fileType='2038'
AND tskActive=1
GROUP BY dbTasks.fileID
) AS HearingDate
 ON HearingDate.fileID = CostcutterStatus.fileID
WHERE clNo='W22511' 
AND fileType='2038'


END
GO

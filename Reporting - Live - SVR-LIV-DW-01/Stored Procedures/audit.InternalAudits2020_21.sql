SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
	Copied InternalAudits2019_20 but added a few tweaks.
	It could do with improving but I've no time at the moment.

*/


CREATE PROCEDURE [audit].[InternalAudits2020_21]
AS
BEGIN

DECLARE @Year AS NVARCHAR(100)
SET @Year='2020/21'
DECLARE @nCode TINYINT = 6 -- this is the dbCode for desc '2020/21' using this instead improved the running of the query.


IF OBJECT_ID('tempdb..#MSAudits2021') IS NOT NULL DROP TABLE #MSAudits2021

SELECT master_client_code AS Client 
,master_matter_number   AS Matter
,dbFile.fileID,AUDYR.cdDesc AS AuditYear
,cboQuarter
,AUDCOMP.cdDesc AS cboAuditComp
,  [red_dw].[dbo].[datetimelocal](dteDateAudit) dteDateAudit
,txtClMtNo,udRiskSearchList.txtReason
--,txtCMFEDInits
--,txtTMName
--,SectionGroup.[Description] AS [cboPAClaim]
--,Section.Description AS [cboTeam]
,chkEXFromRep [exclude]
INTO #MSAudits2021
FROM MS_Prod.dbo.udRiskSearchList 
INNER JOIN MS_Prod.config.dbFile
 ON udRiskSearchList.fileID=dbFile.fileID
 INNER JOIN red_dw.dbo.dim_matter_header_current header ON MS_Prod.config.dbFile.fileID = header.ms_fileid
INNER JOIN MS_Prod.config.dbClient
 ON dbFile.clID=dbClient.clID
LEFT OUTER JOIN MS_Prod.dbo.udExtFile
 ON dbFile.fileID=udExtFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udAudit
 ON dbFile.fileID=udAudit.fileID
LEFT OUTER JOIN MS_Prod.dbo.udMIPARisk
 ON dbFile.fileID=udMIPARisk.fileID
LEFT OUTER JOIN MS_Prod.dbo.udRisk
 ON dbFile.fileID=udRisk.fileID
LEFT OUTER JOIN MS_Prod.dbo.dbCodeLookup AS AUDYR
 ON cboAuditYear=AUDYR.cdCode AND AUDYR.cdType='AUDYR'
LEFT OUTER JOIN MS_Prod.dbo.dbCodeLookup AS AUDCOMP
 ON cboAuditComp=AUDCOMP.cdCode AND AUDCOMP.cdType='AUDCOMP' 
LEFT OUTER JOIN TE_3E_Prod.dbo.SectionGroup 
 ON udRisk.[cboPAClaim]=SectionGroup.Code collate database_default
LEFT OUTER JOIN TE_3E_Prod.dbo.Section 
 ON udRisk.[cboTeam]=Section.Code  collate database_default

 WHERE cboAuditYear=@nCode 



SELECT Client
,[Matter]
,[Matter Description]
,[Q1 Form B Complete]
,[Q1 Date Of Audit]
,[Q1 Client Matter]
,CASE WHEN ISNULL([Q1 Form B Complete],'No')='No' AND GETDATE()>'20200930' THEN 1 ELSE 0 END AS [Excep Q1 Form B complete?]
,CASE WHEN ([Q1 Date Of Audit] IS NULL AND GETDATE()>'20200930') OR [Q1 Date Of Audit] >'20200930' THEN 1 ELSE 0 END AS [Excep Q1 Date of Audit]
,CASE WHEN ISNULL([Q1 Client Matter],'')='' AND GETDATE()>'20200930' THEN 1 ELSE 0 END AS [Excep Q1 Client & Matter Number]
,[Q2 Form B Complete]
,[Q2 Date Of Audit]
,[Q2 Client Matter]
,CASE WHEN ISNULL([Q2 Form B Complete],'No')='No' AND GETDATE()>'20201231' THEN 1 ELSE 0 END AS [Excep Q2 Form B complete?]
,CASE WHEN ([Q2 Date Of Audit] IS NULL AND GETDATE()>'20201231') OR [Q2 Date Of Audit] >'20201231' THEN 1 ELSE 0 END AS [Excep Q2 Date of Audit]
,CASE WHEN ISNULL([Q2 Client Matter],'')='' AND GETDATE()>'20201231' THEN 1 ELSE 0 END AS [Excep Q2 Client & Matter Number]
,[Q3 Form B Complete]
,[Q3 Date Of Audit]
,[Q3 Client Matter]
,CASE WHEN ISNULL([Q3 Form B Complete],'No')='No' AND GETDATE()>'20210331' THEN 1 ELSE 0 END AS [Excep Q3 Form B complete?]
,CASE WHEN ([Q3 Date Of Audit] IS NULL AND GETDATE()>'20210331') OR [Q3 Date Of Audit] >'20210331' THEN 1 ELSE 0 END AS [Excep Q3 Date of Audit]
,CASE WHEN ISNULL([Q3 Client Matter],'')='' AND GETDATE()>'20210331' THEN 1 ELSE 0 END AS [Excep Q3 Client & Matter Number]
,[Q4 Form B Complete]
,[Q4 Date Of Audit]
,[Q4 Client Matter]
,CASE WHEN ISNULL([Q4 Form B Complete],'No')='No' AND GETDATE()>'20210630' THEN 1 ELSE 0 END AS [Excep Q4 Form B complete?]
,CASE WHEN ([Q4 Date Of Audit] IS NULL AND GETDATE()>'20210630') OR [Q4 Date Of Audit] >'20210630' THEN 1 ELSE 0 END AS [Excep Q4 Date of Audit]
,CASE WHEN ISNULL([Q4 Client Matter],'')='' AND GETDATE()>'20210630' THEN 1 ELSE 0 END AS [Excep Q4 Client & Matter Number]

,[Reason no audit required]
,[TM]
,[Team]
,[PracticeArea] 
,[exclude]




FROM 
(

SELECT a.master_client_code AS Client
,a.master_matter_number AS [Matter]
,a.matter_description AS [Matter Description]
,MSQ1.cboAuditComp  COLLATE DATABASE_DEFAULT   AS [Q1 Form B Complete]
,MSQ1.dteDateAudit      AS [Q1 Date Of Audit]
,MSQ1.txtClMtNo  COLLATE DATABASE_DEFAULT  AS [Q1 Client Matter]

,MSQ2.cboAuditComp  COLLATE DATABASE_DEFAULT AS [Q2 Form B Complete]
,MSQ2.dteDateAudit  AS [Q2 Date Of Audit]
,MSQ2.txtClMtNo  COLLATE DATABASE_DEFAULT AS [Q2 Client Matter]

,MSQ3.cboAuditComp  COLLATE DATABASE_DEFAULT AS [Q3 Form B Complete]
,MSQ3.dteDateAudit  AS [Q3 Date Of Audit]
,MSQ3.txtClMtNo  COLLATE DATABASE_DEFAULT [Q3 Client Matter]

,MSQ4.cboAuditComp  COLLATE DATABASE_DEFAULT AS [Q4 Form B Complete]
,MSQ4.dteDateAudit  AS [Q4 Date Of Audit]
,MSQ4.txtClMtNo  COLLATE DATABASE_DEFAULT [Q4 Client Matter]
,COALESCE(MSQ4.txtreason,MSQ3.txtreason,MSQ2.txtreason,MSQ1.txtreason)   COLLATE DATABASE_DEFAULT AS [Reason no audit required]
,txtTMName COLLATE DATABASE_DEFAULT AS [TM]
,[cboTeam] COLLATE DATABASE_DEFAULT AS [Team]
,[cboPAClaim] COLLATE DATABASE_DEFAULT AS [PracticeArea]                                             	    
,[exclude]                                     	    
FROM red_dw.dbo.dim_matter_header_current AS a


LEFT OUTER JOIN (SELECT client,matter,cboAuditComp,dteDateAudit,txtClMtNo,txtreason FROM #MSAudits2021 WHERE cboQuarter='Q1') AS MSQ1
 ON a.master_client_code=MSQ1.client COLLATE DATABASE_DEFAULT
 AND a.master_matter_number=MSQ1.matter  COLLATE DATABASE_DEFAULT

LEFT OUTER JOIN (SELECT client,matter,cboAuditComp,dteDateAudit,txtClMtNo,txtreason FROM #MSAudits2021 WHERE cboQuarter='Q2') AS MSQ2
 ON a.master_client_code=MSQ2.client COLLATE DATABASE_DEFAULT
 AND a.master_matter_number=MSQ2.matter  COLLATE DATABASE_DEFAULT

LEFT OUTER JOIN (SELECT client,matter,cboAuditComp,dteDateAudit,txtClMtNo,txtreason FROM #MSAudits2021 WHERE cboQuarter='Q3') AS MSQ3
 ON a.master_client_code=MSQ3.client COLLATE DATABASE_DEFAULT
 AND a.master_matter_number=MSQ3.matter  COLLATE DATABASE_DEFAULT
 
LEFT OUTER JOIN (SELECT client,matter,cboAuditComp,dteDateAudit,txtClMtNo,txtreason FROM #MSAudits2021 WHERE cboQuarter='Q4') AS MSQ4
 ON a.master_client_code=MSQ4.client COLLATE DATABASE_DEFAULT
 AND a.master_matter_number=MSQ4.matter  COLLATE DATABASE_DEFAULT


LEFT OUTER JOIN (SELECT DISTINCT client,matter,[exclude] FROM #MSAudits2021  ) AS AuditNames
 ON a.master_client_code=AuditNames.client COLLATE DATABASE_DEFAULT
 AND a.master_matter_number=AuditNames.matter  COLLATE DATABASE_DEFAULT


LEFT OUTER JOIN (SELECT DISTINCT  header.master_client_code  AS Client 
	,header.master_matter_number AS Matter
	,txtCMFEDInits
	,txtTMName
	,SectionGroup.[Description] AS [cboPAClaim]
	,Section.Description AS [cboTeam]

	FROM  MS_Prod.config.dbFile
	INNER JOIN red_dw.dbo.dim_matter_header_current header ON dbFile.fileID = header.ms_fileid
	INNER JOIN MS_Prod.config.dbClient
	 ON dbFile.clID=dbClient.clID
	LEFT OUTER JOIN MS_Prod.dbo.udExtFile
	 ON dbFile.fileID=udExtFile.fileID
	LEFT OUTER JOIN MS_Prod.dbo.udAudit
	 ON dbFile.fileID=udAudit.fileID
	LEFT OUTER JOIN MS_Prod.dbo.udMIPARisk
	 ON dbFile.fileID=udMIPARisk.fileID
	LEFT OUTER JOIN MS_Prod.dbo.udRisk
	 ON dbFile.fileID=udRisk.fileID
	LEFT OUTER JOIN TE_3E_Prod.dbo.SectionGroup 
	 ON udRisk.[cboPAClaim]=SectionGroup.Code COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN TE_3E_Prod.dbo.Section 
	 ON udRisk.[cboTeam]=Section.Code  COLLATE DATABASE_DEFAULT
	WHERE client_code ='00121614'
	
	) AS b
	  ON a.master_client_code=b.Client COLLATE DATABASE_DEFAULT 
	  AND a.master_matter_number=b.Matter COLLATE DATABASE_DEFAULT


 
 
WHERE a.client_code='00121614'
AND date_closed_practice_management IS NULL AND ([exclude] = 0 OR [exclude] IS NULL)
AND a.matter_number  NOT IN ('00001359','00001446','00001531','00001804','00001883','ML')
) AS AllData
--WHERE Matter='00000263'

END

--SELECT * FROM MS_Prod.dbo.udRiskSearchList
GO

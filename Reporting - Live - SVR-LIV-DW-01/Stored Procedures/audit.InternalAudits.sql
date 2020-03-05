SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[InternalAudits]
AS
BEGIN
DECLARE @Year AS NVARCHAR(100)
SET @Year='2018/19'


IF OBJECT_ID('tempdb..#MSAudits') IS NOT NULL DROP TABLE #MSAudits

SELECT CASE WHEN udExtFile.FEDCode is null THEN (CASE WHEN ISNUMERIC(dbClient.clno)=1 THEN  RIGHT('00000000' + CONVERT(VARCHAR,dbClient.clno), 8) ELSE CAST(RTRIM(dbClient.clNo)  AS VARCHAR(8)) END) ELSE (CAST(SUBSTRING(RTRIM(udExtFile.FEDCode), 1, CASE WHEN CHARINDEX('-', RTRIM(udExtFile.FEDCode)) > 0 THEN CHARINDEX('-', RTRIM(udExtFile.FEDCode))-1
	   ELSE LEN(RTRIM(udExtFile.FEDCode)) END) AS CHAR(8))) END  AS Client 
,CASE WHEN udExtFile.FEDCode is null THEN RIGHT('00000000' + CONVERT(VARCHAR,dbfile.fileno), 8) ELSE CAST(RIGHT(RTRIM(udExtFile.FEDCode),LEN(RTRIM(udExtFile.FEDCode))-CHARINDEX('-',RTRIM(udExtFile.FEDCode)))AS CHAR(8)) END  AS Matter
,dbFile.fileID,AUDYR.cdDesc AS AuditYear
,cboQuarter
,AUDCOMP.cdDesc AS cboAuditComp
,dteDateAudit
,txtClMtNo,txtReason
,txtCMFEDInits
,txtTMName
,SectionGroup.[Description] AS [cboPAClaim]
,Section.Description AS [cboTeam]
,chkEXFromRep [exclude]
INTO #MSAudits 
FROM MS_Prod.dbo.udRiskSearchList 
INNER JOIN MS_Prod.config.dbFile
 ON udRiskSearchList.fileID=dbFile.fileID
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

 WHERE AUDYR.cdDesc=@Year 




SELECT Client
,[Matter]
,[Matter Description]
,[Q1 Form B Complete]
,[Q1 Date Of Audit]
,[Q1 Client Matter]
,case when isnull([Q1 Form B Complete],'No')='No' and GETDATE()>'20181231' then 1 else 0 end as [Excep Q1 Form B complete?]
,case when ([Q1 Date Of Audit] is null and GETDATE()>'20181231') or [Q1 Date Of Audit] >'20181231' then 1 else 0 end as [Excep Q1 Date of Audit]
,case when isnull([Q1 Client Matter],'')='' and GETDATE()>'20181231' then 1 else 0 end as [Excep Q1 Client & Matter Number]
,[Q2 Form B Complete]
,[Q2 Date Of Audit]
,[Q2 Client Matter]
,case when isnull([Q2 Form B Complete],'No')='No' and GETDATE()>'20190331' then 1 else 0 end as [Excep Q2 Form B complete?]
,case when ([Q2 Date Of Audit] is null and GETDATE()>'20190331') or [Q2 Date Of Audit] >'20190331' then 1 else 0 end as [Excep Q2 Date of Audit]
,case when isnull([Q2 Client Matter],'')='' and GETDATE()>'20190331' then 1 else 0 end as [Excep Q2 Client & Matter Number]
,[Q3 Form B Complete]
,[Q3 Date Of Audit]
,[Q3 Client Matter]
,case when isnull([Q3 Form B Complete],'No')='No' and GETDATE()>'20190730' then 1 else 0 end as [Excep Q3 Form B complete?]
,case when ([Q3 Date Of Audit] is null and GETDATE()>'20190730') or [Q3 Date Of Audit] >'20190730' then 1 else 0 end as [Excep Q3 Date of Audit]
,case when isnull([Q3 Client Matter],'')='' and GETDATE()>'20190730' then 1 else 0 end as [Excep Q3 Client & Matter Number]
,[Q4 Form B Complete]
,[Q4 Date Of Audit]
,[Q4 Client Matter]
,case when isnull([Q4 Form B Complete],'No')='No' and GETDATE()>'20190930' then 1 else 0 end as [Excep Q4 Form B complete?]
,case when ([Q4 Date Of Audit] is null and GETDATE()>'20190930') or [Q4 Date Of Audit] >'20190930' then 1 else 0 end as [Excep Q4 Date of Audit]
,case when isnull([Q4 Client Matter],'')='' and GETDATE()>'20190930' then 1 else 0 end as [Excep Q4 Client & Matter Number]

,[Reason no audit required]
,[TM]
,[Team]
,[PracticeArea] 
,[exclude]




FROM 
(

SELECT a.client_code AS Client
,a.matter_number AS [Matter]
,a.matter_description AS [Matter Description]
,CASE WHEN MSQ1.client  IS NULL THEN AUD276.case_text ELSE MSQ1.cboAuditComp END collate database_default   AS [Q1 Form B Complete]
,CASE WHEN MSQ1.client IS NULL THEN AUD281.case_date ELSE MSQ1.dteDateAudit END     As [Q1 Date Of Audit]
,CASE WHEN MSQ1.client IS NULL THEN AUD285.case_text ELSE MSQ1.txtClMtNo END collate database_default  AS [Q1 Client Matter]

,CASE WHEN MSQ2.client  IS NULL THEN AUD277.case_text ELSE MSQ2.cboAuditComp END collate database_default AS [Q2 Form B Complete]
,CASE WHEN MSQ2.client  IS NULL THEN AUD282.case_date ELSE MSQ2.dteDateAudit END As [Q2 Date Of Audit]
,CASE WHEN MSQ2.client  IS NULL THEN AUD287.case_text ELSE MSQ2.txtClMtNo END collate database_default AS [Q2 Client Matter]

,CASE WHEN MSQ3.client  IS NULL THEN AUD278.case_text ELSE MSQ3.cboAuditComp END collate database_default AS [Q3 Form B Complete]
,CASE WHEN MSQ3.client  IS NULL THEN AUD283.case_date ELSE MSQ3.dteDateAudit END AS [Q3 Date Of Audit]
,CASE WHEN MSQ3.client  IS NULL THEN AUD286.case_text ELSE MSQ3.txtClMtNo END collate database_default [Q3 Client Matter]

,CASE WHEN MSQ4.client  IS NULL THEN AUD279.case_text ELSE MSQ4.cboAuditComp END collate database_default AS [Q4 Form B Complete]
,CASE WHEN MSQ4.client  IS NULL THEN AUD284.case_date ELSE MSQ4.dteDateAudit END AS [Q4 Date Of Audit]
,CASE WHEN MSQ4.client  IS NULL THEN AUD288.case_text ELSE MSQ4.txtClMtNo END collate database_default [Q4 Client Matter]
,CASE WHEN MSQ1.client  IS NULL THEN AUD280.case_text  ELSE COALESCE(MSQ4.txtreason,MSQ3.txtreason,MSQ2.txtreason,MSQ1.txtreason) END  collate database_default AS [Reason no audit required]
,COALESCE(txtTMName,AUD004.case_text) collate database_default AS [TM]
,COALESCE([cboTeam],RIS051.case_text) collate database_default AS [Team]
,COALESCE([cboPAClaim],RIS055.case_text) collate database_default AS [PracticeArea]                                             	    
,[exclude]                                     	    
FROM red_dw.dbo.dim_matter_header_current AS a

LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD276') AS AUD276
 ON a.case_id=AUD276.case_id
LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WHERE case_detail_code='AUD281') AS AUD281
 ON a.case_id=AUD281.case_id
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD285')  AS AUD285
 ON a.case_id=AUD285.case_id 
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD277') AS AUD277
 ON a.case_id=AUD277.case_id
LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WHERE case_detail_code='AUD282') AS AUD282
 ON a.case_id=AUD282.case_id
LEFT OUTER JOIN (SELECT case_text,case_id FROM axxia01.dbo.casdet WHERE case_detail_code='AUD287') AS AUD287
 ON a.case_id=AUD287.case_id
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD278') AS AUD278
 ON a.case_id=AUD278.case_id 
LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WHERE case_detail_code='AUD283') AS AUD283
 ON a.case_id=AUD283.case_id
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD286') AS AUD286
 ON a.case_id=AUD286.case_id
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD279') AS AUD279
 ON a.case_id=AUD279.case_id
LEFT OUTER JOIN (SELECT case_id,case_date FROM axxia01.dbo.casdet WHERE case_detail_code='AUD284') AS AUD284
 ON a.case_id=AUD284.case_id 
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD288') AS AUD288
 ON a.case_id=AUD288.case_id
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD280') AS AUD280
 ON a.case_id=AUD280.case_id
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD004') AS AUD004
 ON a.case_id=AUD004.case_id 
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='AUD001') AS AUD001
 ON a.case_id=AUD001.case_id  
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='RIS055') AS RIS055
 ON a.case_id=RIS055.case_id  
LEFT OUTER JOIN (SELECT case_id,case_text FROM axxia01.dbo.casdet WHERE case_detail_code='RIS051') AS RIS051
 ON a.case_id=RIS051.case_id 
 

LEFT OUTER JOIN (SELECT client,matter,cboAuditComp,dteDateAudit,txtClMtNo,txtreason FROM #MSAudits WHERE cboQuarter='Q1') AS MSQ1
 ON a.client_code=MSQ1.client collate database_default
 AND a.matter_number=MSQ1.matter  collate database_default

LEFT OUTER JOIN (SELECT client,matter,cboAuditComp,dteDateAudit,txtClMtNo,txtreason FROM #MSAudits WHERE cboQuarter='Q2') AS MSQ2
 ON a.client_code=MSQ2.client collate database_default
 AND a.matter_number=MSQ2.matter  collate database_default

LEFT OUTER JOIN (SELECT client,matter,cboAuditComp,dteDateAudit,txtClMtNo,txtreason FROM #MSAudits WHERE cboQuarter='Q3') AS MSQ3
 ON a.client_code=MSQ3.client collate database_default
 AND a.matter_number=MSQ3.matter  collate database_default
 
LEFT OUTER JOIN (SELECT client,matter,cboAuditComp,dteDateAudit,txtClMtNo,txtreason FROM #MSAudits WHERE cboQuarter='Q4') AS MSQ4
 ON a.client_code=MSQ4.client collate database_default
 AND a.matter_number=MSQ4.matter  collate database_default


LEFT OUTER JOIN (SELECT DISTINCT client,matter,txtCMFEDInits,txtTMName
,[cboPAClaim],[cboTeam] ,[exclude] FROM #MSAudits  ) AS AuditNames
 ON a.client_code=AuditNames.client collate database_default
 AND a.matter_number=AuditNames.matter  collate database_default




 
 
WHERE a.client_code='00121614'
AND date_closed_practice_management IS NULL AND ([exclude] = 0 or [exclude] IS NULL)
AND a.matter_number  NOT IN ('00001359','00001446','00001531','00001804','00001883','ML')
) AS AllData


END
GO

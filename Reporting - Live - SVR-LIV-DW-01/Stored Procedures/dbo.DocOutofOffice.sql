SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DocOutofOffice]

AS 

BEGIN

SELECT fileID
,client_code AS [Client]
,matter_number AS [Matter]
,matter_description AS [MatterDescription]
,name AS [Fee Earner]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,txtCliMatNum AS CliMatNum
,cboPerResp AS PerResp
,cboOffice AS Office
,dteRemoved AS DateRemoved
,DocType.cdDesc AS DocType
,Reason.cdDesc AS Reason
,CASE WHEN cboCoronavirus='Y' THEN 'Yes' WHEN cboCoronavirus='N' THEN 'No' ELSE cboCoronavirus END AS Coronavirus
,txtClientNeed AS [ClientNeed]
,txtDocDestination AS DocDestination
,CASE WHEN cboDocRedacted='Y' THEN 'Yes' WHEN cboDocRedacted='N' THEN 'No' ELSE cboDocRedacted END AS DocRedacted
,CASE WHEN cboTransport='Y' THEN 'Yes' WHEN cboTransport='N' THEN 'No' ELSE cboTransport END AS Transport
,cboApprover AS Approver
,Returned.cdDesc AS DocReturned
,txtDocShredded AS DocShredded
,CASE WHEN dteRemoved BETWEEN  DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0) AND DATEADD(DAY, -(DAY(GETDATE())), GETDATE())
THEN 1 ELSE 0 END AS PreviousMonth
FROM MS_Prod.dbo.udDocumentRemoval
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON fileID=ms_fileid
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM MS_PROD.dbo.dbCodeLookup WHERE cdType='DOCTYPE2') AS DocType
 ON cboDocType=DocType.cdCode
LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM MS_PROD.dbo.dbCodeLookup WHERE cdType='REASONBUS') AS Reason
 ON cboReason=Reason.cdCode
LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM MS_PROD.dbo.dbCodeLookup WHERE cdType='DOCRETURNED') AS Returned
 ON cboDocReturned=Returned.cdCode


 
 
 ORDER BY DateRemoved


 END
GO

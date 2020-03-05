SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MIBDistribution]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT RTRIM(master_client_code) + '-'+ RTRIM(master_matter_number) [3e Reference] 
,client_name [Client Name]
,payor.DisplayName AS  [Payor Name]
,dim_detail_core_details.delegated [Delgated?]
,matter_description [Matter Description]
,name [Fee Earner]
,hierarchylevel3hist [Team]
,InvNumber [Bill Number]
,ARDetail.invdate [Bill Date]
,TE_3E_Prod.dbo.ARDetail.ARAmt AS  [Bill Amount]
,'\\svr-liv-3efn-01\TE_3E_Share\TE_3E_PROD\Inetpub\Attachment\InvMaster\' + LOWER(InvMasterID)+ '\'  + [FileName] AS InvoiceLink
,InvMaster.Narrative [Internal Comments]
,md.RecipientEmails [Distrubtion E-mail]
,md.TimeStamp[Distrubtion Date]
FROM TE_3E_Prod.dbo.ARDetail
INNER JOIN MS_Prod.config.dbFile
 ON fileExtLinkID=Matter
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON fileID=ms_fileid
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN TE_3E_Prod.dbo.InvMaster
 ON InvMaster=InvIndex
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN  MimecastData.dbo.MessageData md on md.InvoiceNumber = InvNumber collate database_default
LEFT OUTER JOIN TE_3E_PROD.dbo.NxAttachment AS DocName
 ON InvMasterID=DocName.ParentItemID
LEFT OUTER JOIN TE_3E_Prod.dbo.Payor
 ON TE_3E_Prod.dbo.ARDetail.Payor=PayorIndex
WHERE  ARList IN ('Bill','BillRev')
AND ARDetail.InvDate BETWEEN @StartDate AND  @EndDate
AND InvNumber <>'PURGE'
AND client_group_name='MIB'
AND IsReverse=0
ORDER BY InvNumber
END
GO

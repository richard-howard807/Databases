SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ClientSurveyAssociates]
(
@Division AS NVARCHAR(50)
,@DateFrom AS DATE
,@DateTo AS DATE
)
AS 

BEGIN

SELECT hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,RTRIM(master_client_code) + '-' + RTRIM(master_matter_number) AS [Mattersphere Ref]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,assocID AS [Aassoc ID]
,ISNULL(assocType,'Non Added') AS [Assoc Type]
,dbAssociates.contID AS [Contact ID]
,contName AS [Associate Name]
,contTypeCode AS [Contact Type]
,assocEmail AS [Associate Email]
,DefaultEmail AS [Contact Default Email]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN MS_Prod.config.dbAssociates 
 ON ms_fileid=fileID AND assocType IN ('INSURERCLIENT','CLIENT') AND assocActive=1
LEFT OUTER JOIN MS_Prod.config.dbContact ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN (SELECT 
    Email.contID,
    Email.Email AS DefaultEmail
FROM 
(
SELECT contID,contEmail AS Email ,ROW_NUMBER() OVER (PARTITION BY contID ORDER BY contDefaultOrder ASC)  AS xorder
FROM MS_Prod.dbo.dbContactEmails WHERE   contActive=1
) AS Email
WHERE Email.xorder=1) AS Email ON Email.contID = dbAssociates.contID 
WHERE date_closed_case_management IS NULL 
AND hierarchylevel2hist IN ('Legal Ops - LTA','Legal Ops - Claims')
AND hierarchylevel2hist =@Division
AND CONVERT(DATE,date_opened_case_management,103) BETWEEN CONVERT(DATE,@DateFrom,103) AND CONVERT(DATE,@DateTo,103)
END 
GO

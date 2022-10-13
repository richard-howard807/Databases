SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[AJGallagherMatters]
AS
BEGIN
SELECT Associates.contName AS [Associate Name]
,Associates.assocType AS [Associate Capacity]
,ISNULL(Associates.addLine1,'') + ' ' +
ISNULL(Associates.addLine2,'') + ' ' +
ISNULL(Associates.addLine3,'') + ' ' +
ISNULL(Associates.addLine4,'') + ' ' +
ISNULL(Associates.addLine5,'') + ' ' +
ISNULL(Associates.addPostcode,'') AS [Associate Address]
,client_code AS [Client]
,matter_number AS [Matter]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Created Date]
,matter_owner_full_name AS [Case Handler]
,present_position AS [Present Position]
,CASE WHEN date_opened_case_management BETWEEN DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0) AND DATEADD (dd, -1, DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) + 1, 0)) THEN 1 ELSE 0 END AS TabNo

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN (SELECT fileID,contName,assocType
,addLine1
,addLine2
,addLine3
,addLine4
,addLine5
,addPostcode
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
LEFT OUTER JOIN ms_prod.dbo.dbAddress
 ON contDefaultAddress=addID
WHERE UPPER(contName) LIKE 'AJG%' 
OR UPPER(contName)='AJ GALLAGHER'
OR UPPER(contName)='A J GALLAGHER') AS Associates
 ON ms_fileid=Associates.fileID
WHERE ISNULL(present_position,'Claim and costs outstanding')='Claim and costs outstanding'
AND date_closed_case_management IS NULL
END
GO

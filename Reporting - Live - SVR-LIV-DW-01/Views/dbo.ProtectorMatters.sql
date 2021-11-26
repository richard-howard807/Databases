SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW  [dbo].[ProtectorMatters]

AS 


SELECT DISTINCT dim_matter_header_curr_key
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN (SELECT DISTINCT fileID FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocActive=1
AND UPPER(contName) LIKE '%PROTECTOR%') AS MSAssoc
 ON ms_fileid=MSAssoc.fileID --Non Exist in FED

WHERE (date_closed_case_management IS NULL OR date_closed_case_management>='2018-07-01')
AND master_client_code='W15442'
AND MSAssoc.fileID IS NOT NULL --Halton BC
UNION
SELECT DISTINCT dim_matter_header_curr_key
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN (SELECT DISTINCT fileID FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocActive=1
AND (UPPER(contName) LIKE '%SEDGWICK%' OR UPPER(contName) LIKE '%CUNNINGHAM LINDSEY%')) AS MSAssoc
 ON ms_fileid=MSAssoc.fileID  --NON Exist in FED

WHERE (date_closed_case_management IS NULL OR date_closed_case_management>='2018-07-01')
AND master_client_code='W15632'
AND MSAssoc.fileID IS NOT NULL
UNION
SELECT dim_matter_header_current.dim_matter_header_curr_key FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE master_client_code='W20163'
AND does_claimant_have_personal_injury_claim='Yes' -- FCC Environmental
AND incident_date>='2018-07-14'
UNION
SELECT dim_matter_header_curr_key FROM red_dw.dbo.dim_matter_header_current WHERE master_client_code='W15366'
AND master_matter_number IN 
('4482','4532','4553','4552','4594','4560','4601','4611','4628','4663','4678','4720'
,'4733','4750','4756','4770','4773','4779','4780','4783','4784','4785','4786','4790'
,'4792','4804','4813','4825','4826','4831','4834','4851','4852','4855','4863'
,'4864','4867','4870','4872','4874','4884','4885','4892','4896','4895' --

) -- Broadspire
UNION
SELECT dim_matter_header_curr_key FROM red_dw.dbo.dim_matter_header_current WHERE master_client_code='W17427' --Protector


GO

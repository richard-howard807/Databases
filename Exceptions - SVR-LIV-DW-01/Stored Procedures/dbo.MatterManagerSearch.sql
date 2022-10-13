SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MatterManagerSearch] -- EXEC [dbo].[MatterManagerSearch]  'CDR Liverpool'
(
@Team AS VARCHAR(MAX)
,@FeeEarner AS VARCHAR(MAX)
)
AS



BEGIN
SELECT ListValue  INTO #Team FROM 	Reporting.dbo.udt_TallySplit(',', @Team)
SELECT ListValue  INTO #FE FROM 	Reporting.dbo.udt_TallySplit(',', @FeeEarner)

SELECT 
[MS Client]
,[MS Matter]
,[FED Client]
,[FED Matter]
,[MS Partner Initials] 
,[MS Partner Name] 
,[MS FE Initials] 
,[MS FE Name] 
,[MS BCM initials]
,[MS BCM Name]
,mg_feearn AS [FED FE Initials]
,FEDFE.name AS [FED FE Name]
,mg_parter AS [FED Partner Initial]
,FEDPart.name AS [FED Partner Name]
,[FED BCM initials]
,BCMFED.name AS [FED BCM Name]
,hierarchy.hierarchylevel4hist AS Team
,[Matter Description]
,[status].[status]
FROM 
(
SELECT 
            clNo AS [MS Client]
            ,fileNo AS [MS Matter]
            ,RTRIM(LEFT(FEDCode, CHARINDEX('-', FEDCode) - 1)) AS [FED Client] 
        ,SUBSTRING(FEDCode, CHARINDEX('-', FEDCode)  + 1, LEN(FEDCode)) AS [FED Matter]
,part.usrInits  [MS Partner Initials] 
,part.usrFullName AS [MS Partner Name] 
,fee.usrInits AS [MS FE Initials] 
,fee.usrFullName AS [MS FE Name] 
,bcm.usrInits AS [MS BCM initials]
,bcm.usrFullName AS [MS BCM Name] 
,fileDesc AS [Matter Description]
FROM MS_PROD.config.dbClient c
inner join MS_PROD.config.dbFile f on c.clid = f.clid
inner join MS_PROD.dbo.dbBranch b on b.brid = f.brid
inner join  MS_PROD.dbo.dbUser fee on fee.usrID = f.filePrincipleID
inner join  MS_PROD.dbo.dbFileType ft on ft.typeCode = f.fileType
inner join  MS_PROD.dbo.udExtFile ef on ef.fileid = f.fileid
inner join  MS_PROD.dbo.dbUser part on part.usrID = ef.[cboPartner]
inner join  MS_PROD.dbo.dbUser bcm on bcm.usrID = f.fileResponsibleID
WHERE fileStatus='LIVE'
AND fileNo<>'0'
) AS MS
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS hierarchy
 ON [MS FE Initials]=hierarchy.fed_code collate database_default and hierarchy.dss_current_flag='Y'
INNER JOIN #Team AS Team ON Team.ListValue COLLATE database_default = hierarchy.hierarchylevel4hist COLLATE database_default

INNER JOIN #FE AS FE ON FE.ListValue COLLATE database_default = hierarchy.fed_code COLLATE database_default


LEFT OUTER JOIN axxia01.dbo.camatgrp
 ON [FED Client]=mg_client collate database_default AND [FED Matter]=mg_matter collate database_default
LEFT OUTER JOIN (SELECT client,matter,personnel_code AS [FED BCM initials] FROM axxia01.dbo.cashdr
				 INNER JOIN axxia01.dbo.casper
				  ON cashdr.case_id=casper.case_id
				 WHERE capacity_code='GEN01001'
				 ) AS FEDBCM
				  ON [FED Client]=FEDBCM.client collate database_default AND [FED Matter]=FEDBCM.matter collate database_default
				  
LEFT JOIN red_dw.dbo.dim_detail_core_details [status] ON [FED Client]=[status].client_code collate database_default AND [FED Matter]=[status].matter_number  collate database_default
LEFT OUTER  JOIN red_dw.dbo.dim_fed_hierarchy_history AS FEDFE
 ON mg_feearn=FEDFE.fed_code collate database_default and FEDFE.dss_current_flag='Y'
LEFT OUTER  JOIN red_dw.dbo.dim_fed_hierarchy_history AS FEDPart
 ON mg_parter=FEDPart.fed_code collate database_default and FEDPart.dss_current_flag='Y'
LEFT OUTER  JOIN red_dw.dbo.dim_fed_hierarchy_history AS BCMFED
 ON [FED BCM initials]=BCMFED.fed_code collate database_default and BCMFED.dss_current_flag='Y'
ORDER BY [MS Client]
,[MS Matter]
END


--SELECT * FROM red_dw.dbo.dim_fed_hierarchy_history
GO

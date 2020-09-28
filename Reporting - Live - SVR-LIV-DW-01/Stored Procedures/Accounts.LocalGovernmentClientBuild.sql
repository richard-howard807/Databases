SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [Accounts].[LocalGovernmentClientBuild]

AS 


SELECT  client AS Client,
        matter AS Matter,
        RTRIM(case_text) AS SectorName
INTO #LocalGovClients    
FROM    [SVR-LIV-SQL-04\LEGACYREADONLY].axxia01.dbo.casdet AS casdet WITH ( NOLOCK )
        INNER JOIN   [SVR-LIV-SQL-04\LEGACYREADONLY].axxia01.dbo.cashdr AS cashdr WITH ( NOLOCK ) ON casdet.case_id = cashdr.case_id
        INNER JOIN   [SVR-LIV-SQL-04\LEGACYREADONLY].axxia01.dbo.caclextn AS caclextn WITH ( NOLOCK ) ON client = cx_accode AND cx_colnum = '102'
        INNER JOIN   [SVR-LIV-SQL-04\LEGACYREADONLY].axxia01.dbo.cadescrp AS cadescrp WITH ( NOLOCK ) ON cx_data = ds_reckey
                                                              AND ds_rectyp = 'XX'
                                                              AND ds_descrn IN ('Local and Central Government','Insurance')
        
WHERE   case_detail_code = 'NMI086'
        AND RTRIM(case_text) = 'Local & Central Government'
        
UNION ALL

SELECT  cx_accode AS Client,
        mg_matter AS Matter,
        RTRIM(ds_descrn) AS SectorName
FROM      [SVR-LIV-SQL-04\LEGACYREADONLY].axxia01.dbo.caclextn AS caclextn WITH ( NOLOCK )
        INNER JOIN   [SVR-LIV-SQL-04\LEGACYREADONLY].axxia01.dbo.cadescrp AS cadescrp WITH ( NOLOCK ) ON cx_data = ds_reckey
                                                              AND ds_rectyp = 'XX'
        INNER JOIN   [SVR-LIV-SQL-04\LEGACYREADONLY].axxia01.dbo.camatgrp AS camatgrp WITH ( NOLOCK ) ON cx_accode = mg_client
WHERE   cx_colnum = '102'
        AND mg_matter NOT LIKE 'ML'
        AND RTRIM(ds_descrn) LIKE 'Local and Central Government'

        
SELECT

Client,
Matter,
SectorName,
ROW_NUMBER() OVER ( PARTITION BY Client, Matter ORDER BY Client, Matter DESC ) AS Ranking
INTO #Ranking
FROM #LocalGovClients
ORDER BY Client, Matter


DROP TABLE Accounts.LocalGovernmentClients

SELECT  Client ,
        Matter ,
        SectorName ,
        Ranking 
INTO Accounts.LocalGovernmentClients
FROM #Ranking
WHERE Ranking = 1
GO

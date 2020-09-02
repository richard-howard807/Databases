SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[FEDDocumentSearch] --'00006864','00005403'
(
@Client AS NVARCHAR(8)
,@Matter AS NCHAR(8)
,@WindowsUserName AS NVARCHAR(100)
)
AS
BEGIN
DECLARE @Filter AS  NVARCHAR(100)

SET @Filter=(SELECT DISTINCT hierarchylevel2hist FROM red_dw.dbo.dim_fed_hierarchy_history
WHERE windowsusername=@WindowsUserName
AND dss_current_flag='Y'
AND ISNUMERIC(fed_code)=1)

PRINT @Filter

DECLARE @MatterOwner AS INT
SET @MatterOwner=(SELECT COUNT(1) FROM axxia01.dbo.cashdr
INNER JOIN axxia01.dbo.camatgrp
 ON mg_client=mg_matter
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=mg_feearn COLLATE DATABASE_DEFAULT AND dss_current_flag='Y' 
WHERE client=@Client AND matter=@Matter
AND windowsusername=@WindowsUserName)

DECLARE @OtherUsers AS INT
SET @OtherUsers=(SELECT COUNT(1) FROM axxia01.dbo.cashdr
INNER JOIN axxia01.dbo.camatgrp
 ON mg_client=mg_matter
INNER JOIN axxia01.dbo.casper
 ON casper.case_id = cashdr.case_id
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
 ON fed_code=personnel_code COLLATE DATABASE_DEFAULT  AND dss_current_flag='Y' 
WHERE client=@Client AND matter=@Matter
AND windowsusername=@WindowsUserName)

DECLARE @IsPrivate AS INT

SET @IsPrivate=(SELECT CASE WHEN case_private_desc1 IS NOT NULL OR case_private_desc2 IS NOT NULL THEN 1 ELSE 0 END  FROM axxia01.dbo.cashdr WHERE client=@Client AND matter=@Matter)


PRINT @MatterOwner 
PRINT @OtherUsers


IF @MatterOwner + @OtherUsers>0  AND @IsPrivate<>0 OR @WindowsUserName='khanse'
BEGIN

SELECT  RTRIM(cashdr.client) AS [Client] ,
        RTRIM(cashdr.matter) AS [Matter] ,
       RTRIM(docbpath.path_name) + RTRIM(cashdr.client) + '\' + RTRIM(cashdr.matter) + '\'
        + CAST(Docs.document_no AS VARCHAR(10)) + (CASE WHEN ISNULL(curver,'y')='y' THEN '' ELSE '_' + CAST(docversion.version_no AS VARCHAR(5)) END)    + '.' + LOWER(COALESCE(CASE WHEN wpdefn.wp_code = 'WORD' THEN 'doc' ELSE wp_extension END,
                                                         Docs.wp_code))  AS [DocumentSource] ,
        ISNULL(docversion.version_no,'1') AS [VersionNumber] ,
        Docs.title AS [DocumentTitle] ,
        casact.activity_desc AS [AlternateDocDescription] ,
        Docs.document_no AS [DocumentNumber] ,
         RTRIM(LOWER(COALESCE(CASE WHEN wpdefn.wp_code = 'WORD' THEN 'doc' ELSE wp_extension END,
                                                              Docs.wp_code)))  AS [DocumentExtension] ,
        mg_feearn AS [Author] ,
        Docs.creation_date AS [CreationDate] ,
        Docs.last_updated_on AS [ModifiedDate]
		,wp_name
		,RTRIM(cashdr.case_public_desc1) AS [Matter Description]
FROM    axxia01.dbo.cashdr AS cashdr
    
        INNER JOIN axxia01.dbo.camatgrp ON cashdr.client = mg_client
                                           AND cashdr.matter = mg_matter
        INNER JOIN axxia01.dbo.casact AS casact ON cashdr.case_id = casact.case_id
        INNER JOIN axxia01.dbo.documt AS Docs ON cashdr.case_id = Docs.case_id
                                                 AND casact.document_no = Docs.document_no
                                                 AND casact.activity_seq = Docs.activity_seq
        LEFT OUTER JOIN ARTIION.axxia01.dbo.docbpath ON Docs.path_no = docbpath.path_no
        LEFT OUTER JOIN ARTIION.axxia01.dbo.docversn AS docversion ON Docs.document_no=docversion.document_no
        LEFT OUTER JOIN ARTIION.axxia01.dbo.wpdefn ON UPPER(RTRIM(Docs.wp_code)) = UPPER(RTRIM(wpdefn.wp_code))
WHERE   casact.document_no > 0
AND cashdr.client=@Client AND cashdr.matter=@Matter
--AND cashdr.date_closed>=CONVERT(DATE,DATEADD(MONTH,-18,GETDATE()),103)
ORDER BY CreationDate DESC 

END 

IF  @IsPrivate=0 
BEGIN

SELECT  RTRIM(cashdr.client) AS [Client] ,
        RTRIM(cashdr.matter) AS [Matter] ,
       RTRIM(docbpath.path_name) + RTRIM(cashdr.client) + '\' + RTRIM(cashdr.matter) + '\'
        + CAST(Docs.document_no AS VARCHAR(10)) + (CASE WHEN ISNULL(curver,'y')='y' THEN '' ELSE '_' + CAST(docversion.version_no AS VARCHAR(5)) END)    + '.' + LOWER(COALESCE(CASE WHEN wpdefn.wp_code = 'WORD' THEN 'doc' ELSE wp_extension END,
                                                         Docs.wp_code))  AS [DocumentSource] ,
        ISNULL(docversion.version_no,'1') AS [VersionNumber] ,
        Docs.title AS [DocumentTitle] ,
        casact.activity_desc AS [AlternateDocDescription] ,
        Docs.document_no AS [DocumentNumber] ,
         RTRIM(LOWER(COALESCE(CASE WHEN wpdefn.wp_code = 'WORD' THEN 'doc' ELSE wp_extension END,
                                                              Docs.wp_code)))  AS [DocumentExtension] ,
        mg_feearn AS [Author] ,
        Docs.creation_date AS [CreationDate] ,
        Docs.last_updated_on AS [ModifiedDate]
		,wp_name
		,RTRIM(cashdr.case_public_desc1) AS [Matter Description]
FROM    axxia01.dbo.cashdr AS cashdr
    
        INNER JOIN axxia01.dbo.camatgrp ON cashdr.client = mg_client
                                           AND cashdr.matter = mg_matter
        INNER JOIN axxia01.dbo.casact AS casact ON cashdr.case_id = casact.case_id
        INNER JOIN axxia01.dbo.documt AS Docs ON cashdr.case_id = Docs.case_id
                                                 AND casact.document_no = Docs.document_no
                                                 AND casact.activity_seq = Docs.activity_seq
        LEFT OUTER JOIN ARTIION.axxia01.dbo.docbpath ON Docs.path_no = docbpath.path_no
        LEFT OUTER JOIN ARTIION.axxia01.dbo.docversn AS docversion ON Docs.document_no=docversion.document_no
        LEFT OUTER JOIN ARTIION.axxia01.dbo.wpdefn ON UPPER(RTRIM(Docs.wp_code)) = UPPER(RTRIM(wpdefn.wp_code))
WHERE   casact.document_no > 0
AND cashdr.client=@Client AND cashdr.matter=@Matter
--AND cashdr.date_closed>=CONVERT(DATE,DATEADD(MONTH,-18,GETDATE()),103)
ORDER BY CreationDate DESC 

END 

END
GO

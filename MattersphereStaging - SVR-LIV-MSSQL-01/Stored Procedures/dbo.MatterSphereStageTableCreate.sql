SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





--Stich the columns back togeter and create a view of it.
CREATE PROCEDURE [dbo].[MatterSphereStageTableCreate]
--exec dbo.[MatterSphereStageTableCreate] 'udMIProcessDTE'
(
@Table VARCHAR(255)
)
AS

--DECLARE @Table VARCHAR(255)
DECLARE @SQL AS VARCHAR(MAX)
--SET @Table = 'udMIProcessTXT'

;WITH CTEWTF AS
(

              SELECT TOP 1
              'FileId BIGINT , ' AS [Select]
              ,STUFF(( SELECT DISTINCT ',' + CONCAT('[',[MScode],'] ',REPLACE(DataType, 'uCodeLookup:','')  ) AS [text()]
                            FROM dbo.CaseDetailsStage
              WHERE [MSTable] =  @Table FOR XML PATH('')), 1, 1, '' ) AS [COLUMNS]
              ,' ,CONSTRAINT [pk_'+@Table+'] PRIMARY KEY CLUSTERED 
			(
			[FileId] ASC
			)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
			) ON [PRIMARY]

			  ' AS [FROM]

                     FROM dbo.CaseDetailsStage
              WHERE [MSTable] =  @Table
              )

SELECT 
@SQL = CONCAT('CREATE TABLE dbo.',@Table,' (', [SELECT],'',[COLUMNS],'',[FROM])
--CONCAT([SELECT],'',[COLUMNS],'',[FROM]) 
FROM
CTEWTF

EXECUTE (@SQL)
--SELECT @SQL



GO

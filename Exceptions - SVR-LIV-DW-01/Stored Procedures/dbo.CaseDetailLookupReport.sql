SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CaseDetailLookupReport]
--EXEC [dbo].[CaseDetailLookupReport] NULL, NULL, NULL, NULL, 'N'

( @FEDCode NVARCHAR(40),
  @FieldName Nvarchar(40),
  @FieldID  NVARCHAR(40),
  @MSDesc NVARCHAR(40) ,
  @Transformed  NVARCHAR(20) 
)
AS

--/* Testing*/
--DECLARE @FEDCode AS NVARCHAR(40) = NULL
--DECLARE @FieldName AS Nvarchar(40) = NULL
--DECLARE @FieldID AS NVARCHAR(40) = NULL
--DECLARE @MSDesc AS NVARCHAR(40) = NULL
--DECLARE @Transformed AS NVARCHAR(20) = 'N'	

DROP TABLE IF EXISTS #Picklist
  SELECT DISTINCT
        b.[txtMSCode]
	   ,b.[txtMSTable] 
	   ,b.[txtMSCode] + b.[txtMSTable] AS MSCodeMSTable
      
	  INTO #Picklist
 FROM [MS_PROD].dbo.dbCodeLookup a
 JOIN [MS_PROD].[dbo].[udMapDetail] b ON b.[txtLookupCode] = a.cdType
 
  WHERE bitActive = 1
  AND b.txtLookupTable = 'dbCodeLookup'
  


SELECT DISTINCT
       TMP.ID AS field_id,
       TMP.field AS 'FED Detail Code',
       TMP.fieldname,
       TMP.dwh_group AS dwh_table,
       TMP.field AS dwh_field,
       TMP.msphere_detail_table AS msphere_table,
       TMP.msphere_fieldname AS msphere_field,
       TMP.transformed_field_flag AS transformed_field,
       TMP.transformation,udMapDetail.txtDesc AS [MSDesc]
	   ,CASE WHEN MSCodeMSTable IS NOT NULL THEN 'Link' END AS Picklist

FROM
(
    SELECT ID,
           field,
           type,
           fieldname,
           msphere_fieldname,
           msphere_detail_table,
           transformation,
           transformed_field_flag,
           detail_flag,
           process_attribute,
           CASE
               WHEN dwh_group = 'dim_fed_hierarchy_history' THEN
                   'dim_fed_hierarchy_history_matter_owner'
               ELSE
                   CASE
                       WHEN
                       (
                           dwh_group LIKE 'dim%'
                           OR dwh_group LIKE 'fact%'
                       ) THEN
                           dwh_group
                       ELSE
                           'dim_detail_' + dwh_group
                   END
           END AS dwh_group,
           'N' AS fact_finance_ind
    FROM [ReportMapping].dbo.dimension_mapped_fields_master
    WHERE (process_attribute IN ( 'Y', 'M' ) OR field = 'NMI990')
    UNION
    SELECT ID,
           field,
           type,
           fieldname,
           msphere_fieldname,
           msphere_detail_table,
           transformation,
           transformed_field_flag,
           detail_flag,
           process_measure,
           CASE
               WHEN fact_finance_summary_flag = 'N'
                    AND dwh_group LIKE 'fact%' THEN
                   dwh_group
               WHEN fact_finance_summary_flag = 'N'
                    AND dwh_group LIKE 'dim%' THEN
                   dwh_group
               WHEN fact_finance_summary_flag = 'Y'
                    AND dwh_group NOT LIKE 'fact%' THEN
                   'fact_finance_summary'
               ELSE
                   'fact_detail_' + dwh_group
           END AS dwh_group,
           fact_finance_summary_flag
    FROM [ReportMapping].dbo.fact_mapped_fields_master
    WHERE (process_measure IN ( 'Y', 'M' ))
) AS TMP
LEFT OUTER JOIN MS_Prod.dbo.udMapDetail
 ON TMP.msphere_fieldname=txtMSCode COLLATE DATABASE_DEFAULT
  AND TMP.msphere_detail_table=txtMSTable COLLATE DATABASE_DEFAULT

LEFT JOIN #Picklist a ON a.txtMSCode = udMapDetail.txtMSCode AND a.txtMSTable = udMapDetail.txtMSTable


WHERE (detail_flag = 'Y')
      AND (CASE
               WHEN @FEDCode IS NULL THEN
                   1
               WHEN @FEDCode = '' THEN
                   1
               WHEN TMP.field LIKE '%' + LOWER(@FEDCode) + '%' THEN
                   1
               ELSE
                   0
           END = 1
          )
      AND (CASE
               WHEN @FieldName IS NULL THEN
                   1
               WHEN @FieldName = '' THEN
                   1
               WHEN TMP.fieldname LIKE '%' + LOWER(@FieldName) + '%' THEN
                   1
               ELSE
                   0
           END = 1
          )
      AND (CASE
               WHEN @FieldID IS NULL THEN
                   1
               WHEN @FieldID = '' THEN
                   1
               WHEN @FieldID = TMP.ID THEN
                   1
               ELSE
                   0
           END = 1
          )
      AND (transformed_field_flag IN ( @Transformed ))
AND (CASE
               WHEN @MSDesc IS NULL THEN
                   1
               WHEN @MSDesc = '' THEN
                   1
               WHEN LOWER(txtDesc) LIKE '%' + LOWER(@MSDesc) + '%' THEN
                   1
               ELSE
                   0
           END = 1

          )

		

		  ORDER BY [FED Detail Code]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [nhs].[NHSRFilesDisbursementsReport] 

--EXEC [nhs].[NHSRFilesDisbursementsReport] '2022-01-01', '2022-05-01', '125409T', '1232'

@Matter AS VARCHAR(10)

AS
/* Testing*/
--DECLARE
--@StartDate AS DATE = '2022-01-01', 
--@EndDate   AS DATE = '2022-05-01', 
--@Client AS VARCHAR(10) = '125409T',
--@Matter AS VARCHAR(10) = NULL --'1232'

--DECLARE @Matter AS VARCHAR(50) = 22141

SELECT DISTINCT 
clnt_matt_code ,
invoice_date	,
vendor_name	  ,
invoice_num	 ,
base_amt	,
inv_amt	  ,
cost_code	,
txt1 
,WardHadaway.master_client_code
,WardHadaway.master_matter_number
FROM 
 [SQLAdmin].[dbo].[NHSRFilesUpload]


 LEFT JOIN 
 (
  SELECT CRSystemSourceID, master_client_code 
  ,master_matter_number FROM 
 ms_prod.dbo.udExtFile
 JOIN red_dw.dbo.dim_matter_header_current
 ON fileID = ms_fileid
 WHERE CRSystemSourceID LIKE 'NHS%'

) WardHadaway ON WardHadaway.CRSystemSourceID = clnt_matt_code


WHERE @Matter LIKE '%'+ WardHadaway.master_matter_number +'%'

ORDER BY 1 
GO

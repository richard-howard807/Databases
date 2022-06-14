SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [nhs].[NHSRFilesDisbursementsReport] 

@Matter AS VARCHAR(10)

AS
/* Testing*/
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
/* PR will request a new data upload. Just nename this one NHSRFilesUploadOld. 
Load in the new data table and label it NHSRFilesUploadNew. 
All field names should be the same but just test the new table
If all ok then just rename [NHSRFilesUploadNew] to [NHSRFilesUpload] and then test the report 
https://bardetail/reports/report/Healthcare/NHSR%20Files%20-%20Disbursements%20Report */
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


WHERE @Matter =  WardHadaway.master_matter_number 

ORDER BY 1 
GO

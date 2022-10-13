SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Sgrego
-- Create date: 2019-10-01
-- Description:	Was a one off but required date paramater so created a report 
-- =============================================
CREATE PROCEDURE [dbo].[ArchiveFilesforRealEstate] 
	-- Add the parameters for the stored procedure here
	(
		@DateFrom AS DATETIME2 = '2018-07-01',
		@DateTo as DATETIME2 = null
	)
AS
BEGIN

SET @DateTo = ISNULL(@DateTo,GETDATE())
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
SELECT header.client_code,header.matter_number, header.matter_description,header.matter_owner_full_name,fed.hierarchylevel4hist team, header.date_closed_case_management,archived.dwArchivedDate

 FROM red_dw.dbo.fact_dimension_main main
 INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
 LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history fed  ON fed.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
 LEFT JOIN 
 ( SELECT  fileid,dwArchivedDate FROM MS_Prod.dbo.udDeedWill WHERE dwArchivedDate >= @DateFrom AND dwArchivedDate <= @DateTo) archived ON header.ms_fileid = archived.fileid
 WHERE fed.hierarchylevel3hist = 'Real Estate'
 --AND fed.hierarchylevel4hist like '%Management%'
 AND fed.hierarchylevel4hist ='Real Estate Manchester'
 AND (header.date_closed_case_management >= @DateFrom AND header.date_closed_case_management <= @DateTo OR archived.dwArchivedDate >= @DateFrom AND archived.dwArchivedDate <= @DateTo) 

END
GO

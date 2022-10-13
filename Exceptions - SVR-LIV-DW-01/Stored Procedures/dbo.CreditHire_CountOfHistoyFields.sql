SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   -- =============================================
-- Author:		<Julie Loughlin>
-- Create date: <01-03-2022,>
-- Description:	<Get a count from the history table to see how offten the below fields change. This is for the repot creidt hire  >
-- =============================================
CREATE PROCEDURE [dbo].[CreditHire_CountOfHistoyFields] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


DROP TABLE IF EXISTS #temp
  ;WITH cte  
   
   AS (
      SELECT DISTINCT
	   fileid
	   ,cbocho
	   ,dtehireenddate
	   ,dtehirestart
	   ,curhireclaimed
	   ,curhirepaid
	   , dim_matter_header_current.client_code+'-'+dim_matter_header_current.matter_number AS [Client/Matter Number]
	   , ROW_NUMBER() OVER (PARTITION BY fileid ORDER BY ds_sh_ms_udhire_history.dss_update_time) AS rn
	

	
     FROM red_dw.dbo.ds_sh_ms_udhire_history
	 LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON ds_sh_ms_udhire_history.fileid = dim_matter_header_current.ms_fileid 

    )
    SELECT DISTINCT 
       --c1.*,
	   c1.[Client/Matter Number]
      , HireEndDate_FieldChangeCount = 
          (CASE WHEN c1.dtehireenddate <> c2.dtehireenddate THEN 1 ELSE 0 END), 
       HireStartDate_FieldChangeCount = 
		 (CASE WHEN c1.dtehirestart <> c2.dtehirestart THEN 1 ELSE 0 END),
		 Cbocho_FieldChangeCount =
		 (CASE WHEN c1.cbocho <> c2.cbocho THEN 1 ELSE 0 END),
		   HireClaimed_FieldChangeCount =
		 (CASE WHEN c1.curhireclaimed <> c2.curhireclaimed THEN 1 ELSE 0 END),
		  HirePaid_FieldChangeCount =
		 (CASE WHEN c1.curhirepaid <> c2.curhirepaid THEN 1 ELSE 0 END)
		 INTO #temp
     FROM cte c1
     LEFT JOIN cte c2 ON c1.fileid = c2. fileid
           AND c2.rn = c1.rn - 1 
   	
  
		   SELECT 
			[Client/Matter Number]
			,sum(HireEndDate_FieldChangeCount) AS HireEndDate_FieldChangeCount
			,sum(HireStartDate_FieldChangeCount)	AS HireStartDate_FieldChangeCount
			,sum(Cbocho_FieldChangeCount)	 AS Cbocho_FieldChangeCount
			,sum(HireClaimed_FieldChangeCount) AS HireClaimed_FieldChangeCount
			,sum(HirePaid_FieldChangeCount) AS HirePaid_FieldChangeCount

			FROM #temp

			GROUP BY
			[Client/Matter Number]


------------------------------------
			   END 



GO

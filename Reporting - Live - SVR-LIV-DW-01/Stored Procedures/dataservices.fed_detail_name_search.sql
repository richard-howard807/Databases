SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		lucy Dickinson
-- Create date: 09/02/2015
-- Description:	Report to help the case team search for fed(axxia01) details
--				LD 20181025 Moved to DWH (Helen Fox's Request Ticket 343364)
-- =============================================
CREATE PROCEDURE [dataservices].[fed_detail_name_search]
	-- Add the parameters for the stored procedure here
	@SearchTerm1 varchar(250),
	@SearchTerm2 varchar(250)
AS
BEGIN
	
	--For testing purposes
	--DECLARE @SearchTerm1 varchar(100) = 'outcome'
	--DECLARE @SearchTerm2 varchar(100) = NULL
	
	
	SET @SearchTerm1 = Upper(@SearchTerm1)
	SET @SearchTerm2 = Upper(@SearchTerm2)


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT  case_detail_code	[Code]
	, case_detail_desc [Description] 
	, caslup.case_detail_rectyp [Record type code]
	, case when caslup.case_detail_rectyp = 'A' Then 'Value'

		when caslup.case_detail_rectyp = 'B' Then 'Text'
		when caslup.case_detail_rectyp = 'I' Then 'Date and Value'
		when caslup.case_detail_rectyp = 'H' Then 'Date'
		when caslup.case_detail_rectyp = 'J' Then 'Date and Text'
		when caslup.case_detail_rectyp = 'C' Then 'Text and Value'

		end  [Record Type Description]
	,CASE WHEN DetCount is null then 'Free text' Else 'Drop down' end [Drop Down]

	FROM axxia01.dbo.caslup caslup
	left join (select sd_detcod, Count(*) [DetCount] from axxia01.dbo.stdetlst group by sd_detcod) desc_list  on caslup.case_detail_code = desc_list.sd_detcod

	
	WHERE 1 = 1 
		AND UPPER(REPLACE(REPLACE(case_detail_desc,'[',''),']','')) like '%'+ ISNULL(@SearchTerm1, UPPER(REPLACE(REPLACE(case_detail_desc,'[',''),']',''))) + '%'
		AND UPPER(REPLACE(REPLACE(case_detail_desc,'[',''),']','')) like '%' +ISNULL(@SearchTerm2, UPPER(REPLACE(REPLACE(case_detail_desc,'[',''),']','')))+ '%'

	ORDER BY caslup.case_detail_Code
END
GO

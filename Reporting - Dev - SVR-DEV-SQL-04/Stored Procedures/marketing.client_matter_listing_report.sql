SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 30/04/2018
-- Description:	Matter Listing Report (report called from within the Client MI Report)
-- =============================================
-- ==============================================

CREATE PROCEDURE [marketing].[client_matter_listing_report]
(
	  @client_group_name VARCHAR(200)
	, @client_name VARCHAR(200)
	
)
AS

/*
	For testing purposes
*/

	
	--DECLARE @client_group_name VARCHAR(200) = 'Zurich'
	--DECLARE @client_name VARCHAR(200) = NULL --'Pro Insurance Solutions Limited'
	


/*
	Set the variables
*/

	IF @client_group_name IS NULL AND @client_name IS NULL
	BEGIN
		RETURN
    END
	ELSE
	BEGIN	
	-- used to get the client numbers
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#clientlist')) 
				DROP TABLE #clientlist
	SELECT client_code,client_name,client_group_name
	INTO #clientlist
	FROM red_dw.dbo.dim_client
	WHERE 
	CASE WHEN @client_group_name IS NOT NULL AND client_group_name = @client_group_name THEN 1
		WHEN @client_name IS NOT NULL AND client_name = @client_name THEN 1
		ELSE 0 END = 1	

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	/*
		query to select matters
	*/
	
	
	SELECT
	    header.client_group_name ,
        header.client_name ,
       	header.client_code,
		header.master_client_code [ms_client_code] ,
        header.master_matter_number [ms_matter_number] ,
		header.matter_number,
		header.matter_description,
		worktype.work_type_name,
		CASE WHEN header.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END [status],
	   
	    header.date_opened_case_management ,
        header.date_closed_case_management ,
	    header.matter_owner_full_name ,
		header.matter_partner_full_name ,
        header.present_position 
        
	FROM red_dw.dbo.dim_matter_header_current header
	INNER JOIN #clientlist client ON client.client_code = header.client_code
	INNER JOIN red_dw.dbo.dim_matter_worktype worktype ON worktype.dim_matter_worktype_key = header.dim_matter_worktype_key
	WHERE header.reporting_exclusions <> 1
	AND header.date_closed_case_management IS NULL 
	ORDER BY client.client_code,header.matter_number

	END
GO

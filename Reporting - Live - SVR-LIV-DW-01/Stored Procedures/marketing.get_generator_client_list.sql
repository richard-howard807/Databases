SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 24/01/2018
-- Description:	Using this while I wait for the warehouse DimClient structure to sort itself out
-- =============================================

--EXEC marketing.get_generator client_list NULL

CREATE PROCEDURE [marketing].[get_generator_client_list]
	@ClientName VARCHAR(1000)
AS
BEGIN
	SET NOCOUNT ON;

    -- For testing purposes
	--DECLARE @clientName VARCHAR(50) =  'Van Ameyde'



	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#GeneratorClients')) 
						DROP TABLE #GeneratorClients



	SELECT DISTINCT
		client.dim_client_key
		,client.client_code
		,matter.master_client_code
		,crm.generator_status_code
		,crm.generator_status
		,master_client.client_name
		,matter.client_group_code
		,matter.client_group_name
	INTO #GeneratorClients
	FROM red_dw.dbo.dim_client client
	INNER JOIN red_dw.dbo.dim_matter_header_current matter ON client.client_code = matter.client_code
	INNER JOIN red_dw.dbo.dim_client_relationship_management crm ON crm.client_code =  CASE WHEN ISNUMERIC(matter.master_client_code) = 1 THEN RIGHT('0000000'+matter.master_client_code,8) ELSE matter.master_client_code END
	LEFT JOIN red_dw.dbo.dim_client master_client ON master_client.client_code = crm.client_code
	WHERE  generator_status_code IS NOT NULL
	AND crm.generator_status_code IN ('0001','0002','0003')
	AND matter.client_group_code IS NULL 
	


				
	IF ISNULL(@ClientName, '') = ''
	BEGIN
		SELECT TOP 1
		CASE
			WHEN @ClientName IS NULL THEN 'All'
			ELSE client.client_code + '    ' + client_name
		END	AS 'Caption'
	
		,CASE
			WHEN @ClientName IS NULL THEN '[Dim Client].[Client Code].[All]'
			ELSE '[Dim Client].[Client Code].&[' + CAST(client.dim_client_key AS VARCHAR(10)) + ']'
		END AS 'Value'
		FROM #GeneratorClients client
	END

	IF ISNULL(@ClientName, '') <> ''
	BEGIN
		SELECT
		CASE WHEN @ClientName IS NULL THEN 'All'
			ELSE client.client_code + '    ' + client_name
		END AS 'Caption',
		CASE WHEN @ClientName IS NULL THEN '[Dim Client]].[Client Code].[All]'
			ELSE '[Dim Client].[Client Code].&[' + CAST(client.dim_client_key AS VARCHAR(10)) + ']'
		END AS 'Value'
		FROM #GeneratorClients client
		--red_dw.dbo.dim_client client
		--INNER JOIN  red_dw.dbo.dim_client_relationship_management crm  ON crm.dim_client_key = client.dim_client_key
		--WHERE generator_status_code IS NOT NULL
		--AND crm.generator_status_code IN ('0001','0002','0003')
		WHERE LOWER(client.client_name) LIKE '%' + LOWER(@ClientName) + '%'

		ORDER BY client.client_code
	END
				



	END


GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-12-31
-- Description: #79131 new report to compare insurerclient associate payors against correct billing addresses provided by Motor senior admin 
-- =============================================
CREATE PROCEDURE [dbo].[motor_bill_address_comparison]

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;


-- for when updating the billing addresses table
--DROP TABLE IF EXISTS  Reporting.dbo.client_billing_addresses

--SELECT *
--FROM Reporting.dbo.client_billing_addresses


SELECT DISTINCT
	dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [MS Ref]
	, client_billing_addresses.Client_Name
	, CONVERT(NVARCHAR(20), dbAssociates.contID) AS [Contact ID]
	, dbAssociates.assocType	AS [Associate Type]
	, IIF(dbAssociates.uIsPayor = 1, 'Yes', 'No')	AS [Is Insurer Client Marked as Payor]
	, dbContact.contName		AS [Insurer Client Name in MS]
	, IIF((dbAddress.addLine1 IS NULL OR dbAddress.addLine1 = ''), '', dbAddress.addLine1 + ',' + CHAR(13) + CHAR(10)) +
		IIF((dbAddress.addLine2 IS NULL OR dbAddress.addLine2 = ''), '', dbAddress.addLine2 + ',' + CHAR(13) + CHAR(10)) +
		IIF((dbAddress.addLine3 IS NULL OR dbAddress.addLine3 = ''), '', dbAddress.addLine3 + ',' + CHAR(13) + CHAR(10)) +
		IIF((dbAddress.addLine4 IS NULL OR dbAddress.addLine4 = ''), '', dbAddress.addLine4 + ',' + CHAR(13) + CHAR(10)) +
		IIF((dbAddress.addLine5 IS NULL OR dbAddress.addLine5 = ''), '', dbAddress.addLine5 + ',' + CHAR(13) + CHAR(10)) +
		IIF((dbAddress.addPostcode IS NULL OR dbAddress.addPostcode = ''), '', dbAddress.addPostcode)		AS [MS Insurer Client Address]
	, client_billing_addresses.bill_contact_name		AS [Correct Bill Contact]
	, IIF((client_billing_addresses.net_bill_address_line_1 IS NULL OR client_billing_addresses.net_bill_address_line_1 = ''), '', client_billing_addresses.net_bill_address_line_1 + ',' + CHAR(13) + CHAR(10)) +
		IIF((client_billing_addresses.net_bill_address_line_2 IS NULL OR client_billing_addresses.net_bill_address_line_2 = ''), '', client_billing_addresses.net_bill_address_line_2 + ',' + CHAR(13) + CHAR(10)) +
		IIF((client_billing_addresses.net_bill_address_line_3 IS NULL OR client_billing_addresses.net_bill_address_line_3 = ''), '', client_billing_addresses.net_bill_address_line_3 + ',' + CHAR(13) + CHAR(10)) +
		IIF((client_billing_addresses.net_bill_address_line_4 IS NULL OR client_billing_addresses.net_bill_address_line_4 = ''), '', client_billing_addresses.net_bill_address_line_4 + ',' + CHAR(13) + CHAR(10)) +
		IIF((client_billing_addresses.net_bill_address_line_5 IS NULL OR client_billing_addresses.net_bill_address_line_5 = ''), '', client_billing_addresses.net_bill_address_line_5 + ',' + CHAR(13) + CHAR(10)) +
		IIF((client_billing_addresses.net_bill_address_post_code IS NULL OR client_billing_addresses.net_bill_address_post_code = ''), '', client_billing_addresses.net_bill_address_post_code)		AS [Correct Billing address]
	, dim_detail_core_details.present_position		AS [Present Position]
--SELECT TOP 100 *
FROM MS_Prod.config.dbAssociates
	INNER JOIN MS_Prod.config.dbContact
		ON dbContact.contID = dbAssociates.contID
	INNER JOIN MS_Prod.config.dbFile
		ON dbFile.fileID = dbAssociates.fileID
	INNER JOIN MS_Prod.config.dbClient
		ON dbClient.clID = dbFile.clID
	LEFT OUTER JOIN MS_Prod.dbo.dbAddress
		ON contDefaultAddress=addID
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.ms_fileid = dbFile.fileID
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
		ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code 
			AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND dim_fed_hierarchy_history.activeud = 1
	INNER JOIN Reporting.dbo.client_billing_addresses
		ON client_billing_addresses.client_number = dim_matter_header_current.master_client_code COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE 1 = 1 
	AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor'
	AND dim_matter_header_current.date_closed_practice_management IS NULL
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dbAssociates.uIsPayor = 1
	AND dbAssociates.assocType = 'INSURERCLIENT'
	AND client_billing_addresses.contact_ids NOT LIKE '%' + CONVERT(NVARCHAR(10), dbAssociates.contID) + '%'
	--AND dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number = 'W15492-1919'
	--AND dim_matter_header_current.master_client_code = '9010359'
ORDER BY
	client_billing_addresses.Client_Name

END	
GO

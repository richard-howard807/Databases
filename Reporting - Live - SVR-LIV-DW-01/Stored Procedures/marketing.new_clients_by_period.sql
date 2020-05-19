SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 09/09/2019
-- Description:	New Clients by period report (was originally in DAX but needed the client referrer stuff which wasn't available at the time of creating this)
--				
-- =============================================
CREATE PROCEDURE [marketing].[new_clients_by_period]
	-- Add the parameters for the stored procedure here
	@StartDate DATE, 
	@EndDate DATE,
	@BusinessSource VARCHAR(4000)
AS

-- For testing purposes
--DECLARE @StartDate DATE = '20190901'
--,@EndDate DATE = '20190930'
--,@BusinessSource VARCHAR(4000) = 'Unknown,WOM'	

SELECT 
	dim_client.client_code,
	dim_client.client_name,
	dim_client.branch,
	 NULLIF(dim_client.client_group_name,'') [client_group_name] ,
     dim_client.client_partner_code ,
        RTRIM(ISNULL(dim_client.client_partner_name,'Unknown')) client_partner_name,
     dim_client.open_date ,
     RTRIM(ISNULL(dim_client.sector,'Unknown')) sector,
     RTRIM(ISNULL(dim_client.sub_sector,'Unknown')) sub_sector,
     RTRIM(ISNULL(dim_client.segment,'Unknown')) segment,
     dim_client.client_type ,
     dim_client.aml_client_type ,
     dim_client.client_group_code ,
     dim_client.postcode ,
     dim_client.business_source ,
     dim_client.referrer_type ,
     dim_client.business_source_name ,
     dim_client.created_by ,
     dim_client.practice_management_client_status ,
     dim_client.client_group_partner ,
     dim_client.client_group_partner_name ,
     dim_client.firm_contact_code ,
     dim_client.firm_contact_name ,
     dim_client.generator_status ,
	 dbClient.Created [Client Opened],
	 udExtClient.txtBusSource [Business Source Text],
	 ISNULL(udExtClient.cboReferralType,'Unknown') [ReferralTypeCode],
	 udReferral.description [Referral Type Description],
	 dbUser.usrFullName [Employee Name],
	 dbContact.contName [Contact Name],
	 matter_count.NoFiles
			
FROM MS_Prod.config.dbClient dbClient
INNER JOIN MS_Prod.dbo.udExtClient udExtClient  ON udExtClient.clID = dbClient.clID
INNER JOIN (SELECT DISTINCT client_code,master_client_code FROM red_dw.dbo.dim_matter_header_current WHERE date_opened_case_management >= @StartDate) mc ON dbClient.clNo = mc.master_client_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_client dim_client ON dim_client.client_code = mc.client_code
LEFT JOIN MS_Prod.dbo.dbUser dbUser ON dbUser.usrID = udExtClient.cboReferralTypeUser
LEFT JOIN MS_Prod.config.dbContact dbContact ON udExtClient.cboReferralTypeContact = dbContact.contID
LEFT JOIN MS_Prod.dbo.udReferral udReferral ON udExtClient.cboReferralType = udReferral.code

OUTER APPLY (SELECT COUNT(dim_matter_header_curr_key) NoFiles FROM red_dw.dbo.dim_matter_header_current a WHERE a.client_code = dim_client.client_code
AND a.reporting_exclusions <> 1) matter_count

WHERE 1=1
--AND b.cboReferralType IS null
AND CAST(dbClient.CREATED AS DATE) BETWEEN @StartDate AND @EndDate 
AND dbClient.clName NOT LIKE '%MS TEST%'
AND UPPER(dbClient.clName) NOT LIKE '%TEST%'
AND UPPER(dbClient.clName) NOT LIKE '%ERROR%'
AND dbClient.clNo NOT LIKE 'EMP%'
AND ISNULL(udExtClient.cboReferralType,'Unknown') IN (SELECT value 

FROM   STRING_SPLIT(@BusinessSource,',') )

--SELECT code,description FROM MS_Prod.dbo.udReferral

		

GO

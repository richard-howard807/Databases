SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[PropertyView]
AS
SELECT TOP 1000 [client_name]
      ,[client_code]
      ,[matter_number]
      ,[clientcontact_name]
      ,[Address ]
      ,[Postcode ]
      ,[date_instructions_received]
      ,[anticipated_completion_date]
      ,[completion_date]
      ,[fixed_fee_amount]
  FROM [Reporting].[dbo].[PropertyViewExcelExtract]
GO

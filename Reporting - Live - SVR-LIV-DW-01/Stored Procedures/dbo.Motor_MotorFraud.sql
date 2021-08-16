SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Motor_MotorFraud]

AS


--Tab 1) "Non SOF" - this is to show all live (not closed in MS)
--files within the Motor Fraud team where the suspicion of fraud field is no or blank. 
--please apply usual exclusions and also remove any where the client is Centrica or Leeds CC

--Tab 2) "Missing Fraud Types" - this is to show all live (not closed in MS) files 
--within the Motor Fraud team where the suspicion of fraud field is yes but 
--Fraud type cboFraudTypeMot  ud type (Motor)  is blank


SELECT 
	[Mattersphere Weightmans Reference], 
	[Matter Description],
	[Client Name], 
	[Case Manager], 
	[Present Position],
	[Date Case Opened], 
	[Date Case Closed], 
	[Suspicion of Fraud?], 
	[Fraud Type] = fraud_type_motor,
	[Sof/Missing Fraud Types] = CASE WHEN ISNULL([Suspicion of Fraud?], 'No') = 'No' THEN 'Non Sof'
	     WHEN [Suspicion of Fraud?] = 'Yes' AND dim_detail_fraud.fraud_type_motor IS NULL THEN 'Missing Fraud Types' END,
    [Outcome of Case]
    
FROM reporting.dbo.selfservice
LEFT JOIN red_dw.dbo.dim_detail_fraud
ON [Client Code] = client_code AND [Matter Number] = matter_number
WHERE 1 =1 

AND reporting_exclusions = 0
AND [Date Case Closed] IS NULL 
AND Team = 'Motor Fraud'
AND [Client Code] NOT IN  ('W15381','W15471' ) -- Centrica, Leeds City Council


GO

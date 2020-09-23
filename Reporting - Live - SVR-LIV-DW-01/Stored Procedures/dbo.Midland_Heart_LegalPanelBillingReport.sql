SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Julie Loughlin>
-- Create date: <22-09-2020>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Midland_Heart_LegalPanelBillingReport] --'2020-05-01','2020-09-22'

(
@StartDate AS DATE
,@EndDate AS DATE
)

AS
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN
--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE

--SET @StartDate='2018-05-01'
--SET @EndDate='2020-09-30'



SELECT 
dim_matter_header_current.client_code
,dim_matter_header_current.client_name AS Client
,CASE WHEN work_type_name IN ('Commercial Contracts', 'Commercial drafting (advice)','Company','Competition Law','Contract','Contract Supplier','Defamation','Direct Selling','Events','Health and Safety - Advisory/Consultancy','Health and Safety - Defending','Health and Safety - Prosecuting','Health and Safety - Training','Injunction','Injunctions','Intellectual property','Judicial Review','Non-contentious IP & IT Contracts',
'Partnership','Partnerships & JVs','Private Equity','Procurement','Recoveries','Share Structures & Company Reorganisatio') THEN 'Contracts, Commercials, Procurement, Health and Safety' 
 WHEN work_type_name IN ('Agency','Automatic unfair dismissal','Capability (inc Occupational health)','Constructive dismissal + discrimination','Constructive unfair dismissal','Contracts/Policies/Procedures(inc hrs wk','Disciplinary process','Discrimination(sex,race,sex orien,disab','Early Conciliation',                      
'Employment Advice Line','EPA Registrations','Equal pay','Failure to inform/consult','General Advice : Employment','Grievance','Holidays (including holiday pay)','HR','HR Rely','Immigration(work permits,regis,points sy','Investigation','Maternity/Paternity (inc flexible working','Mediation',                              
'Pensions','Redundancy','Reorganisation','Restrictive Covenants','Retirement','Settlement Agreements','Trade Union Activities','TUPE','Unfair dismissal','Unfair dismissal and discrimination','Unlawful deductions','Wages (inc minimum wage, notice pay)','Whistleblowing','Working Time Regulations') THEN 'Employment, TUPE, Pension'          
WHEN work_type_name IN ('Ad Hoc Enquiries','Corporate transactions','Data Protection','Database','Environmental','Food safety','GDPR','General Advice','Governance & Regulatory', 'Inquest','Licensing','Prosecution','Public Inquiry','Subject Access Request','Trading standards')  THEN '"Governance, Corporate, Regulatory , Statutory' 
WHEN work_type_name IN ('Comm conveyancing (business premises)',   'Due Dilligence','Landlord & Tenant - Commercial', 'Landlord & Tenant - Disrepair' ,'Landlord & Tenant - Residential' , 'Leases-granting,taking,assigning,renewin','Reactive Training','Remortgage','Residential conveyancing (houses/flats)','Right to buy', 'Social Housing - Property','Training' )  THEN 'Homelessness, Housing Management, Home Ownership, Asset Management'    
WHEN work_type_name IN ('Construction', 'Estate Planning', 'Planning','Plot Sales','Property Dispute Commercial other','Property Dispute Residential other','Property Due Diligence','Property redevelopment') THEN 'Property Development Construction'
WHEN work_type_name IN ('Banking','Consumer debt', 'Debt Recovery','Financial', 'Financial – Criminal Defence', 'Financial – General Advice', 'Insolvency Corporate', 'Insolvency Personal ' , 'Secured lending', 'Share Schemes','Tax Advisory')   THEN 'Treasury and Finance'                        
ELSE 'OTHER' END AS [Lot/Category]
,red_dw.dbo.fact_bill.bill_total AS [Bill Total]
,fact_bill.fees_total AS [Revenue]
,SUM(fact_bill.paid_disbursements + fact_bill.unpaid_disbursements) AS Disbursements
,fact_bill.vat_amount AS VAT
,fees_total AS [Invoice Amount (ex VAT & disbursements)]
,CASE WHEN date_closed_practice_management IS NULL THEN 'N' ELSE 'Y' END  AS [Is matter complete? Y/N]
,[Total Billed FY todate]



FROM red_dw.dbo.dim_matter_header_current
--INNER JOIN #client AS Client ON dim_matter_header_current.client_code=Client.ListValue COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
LEFT OUTER JOIN (
		SELECT 
		SUM(bill_total) AS [Total Billed FY todate],
		 dim_matter_header_curr_key,
		dim_bill_date_key
		FROM red_dw.dbo.fact_bill_matter_detail
		WHERE client_code = 'W23552' 
		AND  bill_date between DATEADD(month,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE())-1,0)) and @EndDate
		GROUP BY dim_matter_header_curr_key,dim_bill_date_key
	 )
	AS billdate

ON billdate.dim_bill_date_key=dim_bill_date.dim_bill_date_key	

WHERE dim_matter_header_current.client_code = 'W23552'
AND dim_bill.bill_number <>'PURGE'
--AND date_opened_case_management >='2020-07-01
AND bill_date BETWEEN @StartDate AND @EndDate 

GROUP BY
dim_matter_header_current.client_code
,dim_matter_header_current.client_name 
,CASE WHEN work_type_name IN ('Commercial Contracts', 'Commercial drafting (advice)','Company','Competition Law','Contract','Contract Supplier','Defamation','Direct Selling','Events','Health and Safety - Advisory/Consultancy','Health and Safety - Defending','Health and Safety - Prosecuting','Health and Safety - Training','Injunction','Injunctions','Intellectual property','Judicial Review','Non-contentious IP & IT Contracts',
'Partnership','Partnerships & JVs','Private Equity','Procurement','Recoveries','Share Structures & Company Reorganisatio') THEN 'Contracts, Commercials, Procurement, Health and Safety' 
WHEN work_type_name IN ('Agency','Automatic unfair dismissal','Capability (inc Occupational health)','Constructive dismissal + discrimination','Constructive unfair dismissal','Contracts/Policies/Procedures(inc hrs wk','Disciplinary process','Discrimination(sex,race,sex orien,disab','Early Conciliation',                      
'Employment Advice Line','EPA Registrations','Equal pay','Failure to inform/consult','General Advice : Employment','Grievance','Holidays (including holiday pay)','HR','HR Rely','Immigration(work permits,regis,points sy','Investigation','Maternity/Paternity (inc flexible working','Mediation',                              
'Pensions','Redundancy','Reorganisation','Restrictive Covenants','Retirement','Settlement Agreements','Trade Union Activities','TUPE','Unfair dismissal','Unfair dismissal and discrimination','Unlawful deductions','Wages (inc minimum wage, notice pay)','Whistleblowing','Working Time Regulations') THEN 'Employment, TUPE, Pension'          
WHEN work_type_name IN ('Ad Hoc Enquiries','Corporate transactions','Data Protection','Database','Environmental','Food safety','GDPR','General Advice','Governance & Regulatory', 'Inquest','Licensing','Prosecution','Public Inquiry','Subject Access Request','Trading standards')  THEN '"Governance, Corporate, Regulatory , Statutory' 
WHEN work_type_name IN ('Comm conveyancing (business premises)',   'Due Dilligence','Landlord & Tenant - Commercial', 'Landlord & Tenant - Disrepair' ,'Landlord & Tenant - Residential' , 'Leases-granting,taking,assigning,renewin','Reactive Training','Remortgage','Residential conveyancing (houses/flats)','Right to buy', 'Social Housing - Property','Training' )  THEN 'Homelessness, Housing Management, Home Ownership, Asset Management'    
WHEN work_type_name IN ('Construction', 'Estate Planning', 'Planning','Plot Sales','Property Dispute Commercial other','Property Dispute Residential other','Property Due Diligence','Property redevelopment') THEN 'Property Development Construction'
WHEN work_type_name IN ('Banking','Consumer debt', 'Debt Recovery','Financial', 'Financial – Criminal Defence', 'Financial – General Advice', 'Insolvency Corporate', 'Insolvency Personal ' , 'Secured lending', 'Share Schemes','Tax Advisory')   THEN 'Treasury and Finance'                        
ELSE 'OTHER' END 
,fact_bill.fees_total
,red_dw.dbo.fact_bill.bill_total 
,fact_bill.vat_amount 
,bill_date 
,dim_bill.bill_number 
,fees_total 
,CASE WHEN date_closed_practice_management IS NULL THEN 'N' ELSE 'Y' END  
,[Total Billed FY todate]

ORDER BY bill_date ASC

END

GO

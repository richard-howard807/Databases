SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CRPDebt]
(
@Partner  AS NVARCHAR(MAX)
)

AS

BEGIN

IF OBJECT_ID('tempdb..#Partner') IS NOT NULL   DROP TABLE #Partner;
SELECT ListValue  INTO #Partner FROM 	dbo.udt_TallySplit('|', @Partner);

SELECT dim_client.client_name AS [Client Name],
       master_client_code + '-' + master_matter_number AS [Matter ID],
       hierarchylevel4hist AS [Matter Owner Team],
       dim_client.credit_specialist AS [Credit Specialist],
       worksforname AS [Team Manager],
       dim_fed_hierarchy_history.name AS [Mtr Owner name],
       matter_description AS [Matter Description],
       dim_bill.bill_number AS [Inv No.],
       dim_payor.payor_name,
       dim_bill_date.bill_date AS [Inv Date],
       DATEDIFF(d, fact_debt.bill_date, GETDATE() - 1) AS [Days],
       ISNULL(client_partner_code, 'Unknown') AS client_partner_code,
       ISNULL(client_partner_name, 'Unknown') AS [Client Partner],
       ISNULL(Email.ClientPartnerEmail, 'Unknown') AS [Client Partner Email],
       fact_debt.total_balance AS [Total Bal £],
       fact_debt.fees_balance outstanding_fees,
       fact_bill.vat_amount,
       fact_debt.costs_balanace
FROM red_dw.dbo.fact_payor_debt_detail fact_debt
    INNER JOIN red_dw.dbo.dim_bill
        ON dim_bill.dim_bill_key = fact_debt.dim_bill_key
    INNER JOIN red_dw.dbo.fact_bill
        ON fact_bill.dim_bill_key = dim_bill.dim_bill_key
    INNER JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_debt.dim_matter_header_curr_key
    INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON fee_earner_code = dim_fed_hierarchy_history.fed_code COLLATE DATABASE_DEFAULT
           AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
    LEFT OUTER JOIN red_dw.dbo.dim_bill_date
        ON dim_bill_date.dim_bill_date_key = fact_debt.dim_bill_date_key
    LEFT OUTER JOIN red_dw.dbo.dim_client
        ON dim_client.dim_client_key = fact_debt.dim_client_key
    LEFT OUTER JOIN
    (
        SELECT fed_code,
               workemail AS [ClientPartnerEmail]
        FROM red_dw.dbo.dim_fed_hierarchy_history
            INNER JOIN red_dw.dbo.dim_employee
                ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
        WHERE dss_current_flag = 'Y'
    ) AS Email
        ON Email.fed_code = client_partner_code
    LEFT OUTER JOIN red_dw..dim_payor
        ON dim_payor.dim_payor_key = fact_debt.dim_payor_key
    INNER JOIN #Partner AS [Partner]
        ON [Partner].ListValue COLLATE DATABASE_DEFAULT = ISNULL(client_partner_code, 'Unknown') COLLATE DATABASE_DEFAULT
WHERE bill_reversed = 0
      AND dim_matter_header_current.client_code <> '00030645'
	  AND fact_debt.total_balance <> 0
END; 
GO

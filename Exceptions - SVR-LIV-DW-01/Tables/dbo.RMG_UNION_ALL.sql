CREATE TABLE [dbo].[RMG_UNION_ALL]
(
[BE] [float] NULL,
[BE Bldg RU] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Business Entity Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Street/House No] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[City] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Postcode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delivery Director Area] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Ops Region] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Lead Estate Manager - Business Entity Level] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenure] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[GC no] [float] NULL,
[Contract Type Text] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Contract Classification] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Building] [float] NULL,
[Lease Out No] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Rent Tax Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Net Rent pa] [float] NULL,
[Annual VAT on rent] [float] NULL,
[Gross Rent pa] [float] NULL,
[ERV (gross)] [float] NULL,
[Internal Market Rent] [float] NULL,
[Vacant Market Rent] [float] NULL,
[S/C Tax Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[S/C (net)] [float] NULL,
[VAT on S/C] [float] NULL,
[S/C (Gross)] [float] NULL,
[LL Insurance Tax Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[LL insurance (net)] [float] NULL,
[VAT on LL insurance] [float] NULL,
[LL Insurance (Gross)] [float] NULL,
[Break Date] [datetime] NULL,
[Break Notice] [datetime] NULL,
[Last Rent Review] [datetime] NULL,
[Outstanding Rent Review] [datetime] NULL,
[Next Rent Review ] [datetime] NULL,
[Landlord or Tenant w/o a Vendor/Customer Account] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Partner with a Vendor Account] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Partner with a Customer Account] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[System Start] [datetime] NULL,
[System End] [datetime] NULL,
[Lease Expiry] [datetime] NULL,
[Lease Regear] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Rent Free Period / Rolling Break] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Holding Over] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Account Assignment] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Floor Area sqm] [float] NULL,
[RU] [float] NULL,
[Rental Unit usage type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Rental Unit Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Rental Unit Street] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Rental Unit City] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Rental Unit Pcd] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Workplace] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Ops Region1] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Regional Estate Manager - Rental Unit Level] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Additional Usage Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delivery Director Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO

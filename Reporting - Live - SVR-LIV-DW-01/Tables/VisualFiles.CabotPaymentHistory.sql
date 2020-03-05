CREATE TABLE [VisualFiles].[CabotPaymentHistory]
(
[mt_int_code] [int] NULL,
[MonthNumber] [int] NULL,
[YearNumber] [int] NULL,
[30DayStart] [date] NULL,
[60DayStart] [date] NULL,
[EndDate] [date] NULL,
[ArtiionOpenFile] [int] NOT NULL,
[CaseDateOpened] [date] NULL,
[PaymentArrangementAmount] [money] NULL,
[30Amount] [decimal] (10, 2) NULL,
[60Amount] [decimal] (10, 2) NULL,
[Rehab] [decimal] (10, 2) NULL,
[CurrrentBalance] [decimal] (10, 2) NULL,
[AccountRehabilitated] [int] NOT NULL,
[NoPayment30Days] [int] NOT NULL,
[NoPayment60Days] [int] NOT NULL,
[DefaultedAccount] [int] NOT NULL,
[NumberAccounts] [int] NOT NULL,
[ReportingStartDate] [date] NULL
) ON [PRIMARY]
GO

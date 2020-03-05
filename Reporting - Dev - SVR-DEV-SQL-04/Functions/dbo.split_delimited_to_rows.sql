SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[split_delimited_to_rows]
 (
   @delimited NVARCHAR(MAX),
   @delimiter NVARCHAR(100)
 ) RETURNS @t TABLE
 (
 -- Id column can be commented out, not required for sql splitting string
   id INT IDENTITY(1,1), -- I use this column for numbering splitted parts
   val NVARCHAR(MAX)
 )
 AS
 BEGIN
   DECLARE @xml XML
   SET @xml = N'<root><r>' + REPLACE(@delimited,@delimiter,'</r><r>') + '</r></root>'

   INSERT INTO @t(val)
   SELECT
     r.value('.','varchar(max)') AS item
   FROM @xml.nodes('//root/r') AS records(r)

   RETURN
 END





GO

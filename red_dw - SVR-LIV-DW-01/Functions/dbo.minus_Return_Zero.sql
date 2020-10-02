SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [dbo].[minus_Return_Zero]( @value decimal(10,2))
   returns decimal(10,2)
begin
-- Code used to remove error occuring whilst dividing by 0
   declare @p_product    decimal(10,2);

   select @p_product = @value;

   if ( @value=-1  )
      select @p_product = 0;

   return(@p_product)
end

GO
GRANT EXECUTE ON  [dbo].[minus_Return_Zero] TO [SBC\SQL - LIVE DWH Developers Limited]
GO

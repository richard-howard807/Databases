SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [dbo].[function_proper_case](@Text as nvarchar(50))
returns nvarchar(50)
as
begin
   declare @Reset bit;
   declare @Ret varchar(8000);
   declare @i int;
   declare @c char(1);

   set @Text = lower(rtrim(ltrim(@Text)))
   select @Reset = 1, @i=1, @Ret = '';

   while (@i <= len(@Text))
    select @c= substring(@Text,@i,1),
               @Ret = @Ret + case when @Reset=1 then UPPER(@c) else LOWER(@c) end,
               @Reset = case when @c like '[a-zA-Z]' then 0 else 1 end,
               @i = @i +1
   return @Ret
end

GO

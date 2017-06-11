{------------------------------------------------------------------------------}
{- Unit       : UNIXTIME.PAS                                                  -}
{- Programmer : Todd Fiske                                                    -}
{-                                                                            -}
{- Purpose    : Unix Date/Time conversion routines                            -}
{-                                                                            -}
{- Revision   : 02/13/1994 - first version                                    -}
{- History      01/16/1995 - cleaned up for uploading, added string functions -}
{-              05/16/1996 - fixed bug: secs_per_day was 3660, now 3600       -}
{-              05/16/1996 - fixed bug: PackUnixTime was adding an extra day  -}
{-                           to dates in a leap year but before the leap day  -}
{-                                                                            -}
{- Language   : Turbo Pascal 7.0                                              -}
{-                                                                            -}
{------------------------------------------------------------------------------}

unit unixtime;

{------------------------------------------------------------------------------}
                                   interface
{------------------------------------------------------------------------------}

uses
   dos;

type
   string_2  = string[ 2];
   string_3  = string[ 3];
   string_10 = string[10];

const
   days_per_month : array[0..11] of byte =
      ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

   months : array[0..11] of string_3 =
      ( 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
      'Nov', 'Dec' );

   days : array [0..6] of string_3 =
      ( 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed' );

   secs_per_min   =       60;
   secs_per_hour  =     3600;     { 60 * 60 }
   secs_per_day   =    86400;     { 60 * 60 * 24 }
   secs_per_year  = 31536000;     { 60 * 60 * 24 * 365 }
   secs_per_lyear = 31622400;     { 60 * 60 * 24 * 366 }

   days_per_year  = 365;
   days_per_lyear = 366;

{- Here are some more constants that illustrate another neat phenomenon I
found, namely that "even" decades have 3 leap years/days, and "odd" decades
have 2 leap years/days.

  "odd"    1972   1992
  decades  1976   1996

  "even"   1980   2000
  decades  1984   2004
           1988   2008
-}

   days_per_odd_dec  = 3652;
   days_per_even_dec = 3653;

   secs_per_odd_dec  = 315532800; { (secs_per_year * 10) + (secs_per_day * 2); }
   secs_per_even_dec = 315619200; { (secs_per_year * 10) + (secs_per_day * 3); }

   secs_to_1980      = 315532800; { secs_per_odd_dec }
   secs_to_1990      = 631152000; { secs_to_1980 + secs_per_even_dec; }
   secs_to_2000      = 946684800; { secs_to_1990 + secs_per_odd_dec; }

   {- Jan 01 2000 00:00:00 = 946,684,800 -}

   secs_to_19960101  = 820454400;
   {- 26 years + 6 leap days,
      26 * 365 = 9490,
      9490 + 6 = 9496,
      9496 * 86400 = 820,454,400
   -}

procedure UnpackUnixTime     (t : longint; var dt : DateTime);
procedure PackUnixTime       (dt : DateTime; var t : longint);
function  FormatUnixTime     (t : longint) : string;

function  int2dt             (i : longint) : string_2;
function  int2str            (i : longint; l : integer) : string_10;
function  str2int            (s : string) : longint;

{------------------------------------------------------------------------------}
                                 implementation
{------------------------------------------------------------------------------}

{------------------------------------------------------------------------------}
{-                                                                            -}
{-           Convert Unix Date - number of seconds since Jan 1 1970           -}
{-                                                                            -}
{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{- Unpack Unix Time                                                           -}
{-                                                                            -}
{- converts Unix time longint into a DateTime record                          -}
{------------------------------------------------------------------------------}
procedure UnpackUnixTime(t : longint; var dt : DateTime);
begin
   dt.year  := 0;    { 1970 }
   dt.month := 0;    { January }
   dt.day   := 0;    { First }

   dt.hour  := 0;    { midnight }
   dt.min   := 0;
   dt.sec   := 0;

   {- writeln('Seconds since 1/1/70  ', t:12); -}
          { leap year : 9999  t : 999999999999 }
          { years     : 9999 }
          { months    : 9999 }
          { days      : 9999 }
          { hours     : 9999 }
          { minutes   : 9999 }
          { seconds   : 9999 }

   while (t >= secs_per_year) do begin      { while more than one years worth of seconds left }
      if (((dt.year + 2) mod 4) = 0) then begin   { if its a leap year }
         dec(t, secs_per_day);              { subtract an extra days worth of seconds }
         {- writeln('leap year         t : ', t:12); -}
      end;
      inc(dt.year);                         { add another year }
      dec(t, secs_per_year);                { subtract a years worth of seconds }
      {- writeln('years     : ', dt.year:4, '  t : ', t:12); -}
   end;

   if (((dt.year + 2) mod 4) = 0) then begin      { if its a leap year }
      inc(days_per_month[1]);               { add 1 more day to February }
      {- writeln('leap year, February adjusted'); -}
   end;

   while (t >= (days_per_month[dt.month] * secs_per_day)) do begin { while more than one month }
      dec(t, days_per_month[dt.month] * secs_per_day); { subtract a months worth }
      inc(dt.month);                        { add another month }
      {- writeln('months    : ', dt.month:4, '  t : ', t:12); -}
   end;

   while (t >= secs_per_day) do begin       { while more than one day }
      dec(t, secs_per_day);                 { subtract a days worth }
      inc(dt.day);                          { add another day }
      {- writeln('days      : ', dt.day:4, '  t : ', t:12); -}
   end;

   while (t >= secs_per_hour) do begin      { same for hours and minutes }
      dec(t, secs_per_hour);
      inc(dt.hour);
      {- writeln('hours     : ', dt.hour:4, '  t : ', t:12); -}
   end;

   while (t >= secs_per_min) do begin
      dec(t, secs_per_min);
      inc(dt.min);
      {- writeln('minutes   : ', dt.min:4, '  t : ', t:12); -}
   end;

   dt.sec := t;                             { remaining seconds }
   {- writeln('seconds   : ', dt.sec:4, '  t : ', t:12); -}

   if days_per_month[1] = 29 then dec(days_per_month[1]);

   inc(dt.year, 1970);
   inc(dt.month);
   inc(dt.day);
end;

{------------------------------------------------------------------------------}
{- Pack Unix Time                                                             -}
{-                                                                            -}
{- converts a DateTime record into a Unix time longint                        -}
{------------------------------------------------------------------------------}
procedure PackUnixTime(dt : DateTime; var t : longint);
var
   i              : word;
   days_this_year : word;
   num_leap_years : word;
begin
   dec(dt.year, 1970);
   dec(dt.month);
   dec(dt.day);

   t := dt.sec;
   {- writeln('seconds        : ', t:12); -}

   inc(t, dt.min  * secs_per_min);
   {- writeln('minutes        : ', dt.min * secs_per_min:4); -}
   {- writeln('plus minutes   : ', t:12); -}

   inc(t, longint(dt.hour) * secs_per_hour);
   {- writeln('hours          : ', longint(dt.hour) * secs_per_hour:4); -}
   {- writeln('plus hours     : ', t:12); -}

   {- adjust February days if leap year -}
   if (((dt.year + 2) mod 4) = 0) then begin      { if its a leap year }
      inc(days_per_month[1]);                     { add 1 more day to February }
      {- writeln('leap year, February adjusted'); -}
   end;

   {- get total number of days this year -}
   days_this_year := dt.day;                     { days this month }
   i := 0;
   while (i < dt.month) do begin                 { days in previous months }
      inc(days_this_year, days_per_month[i]);
      inc(i);
   end;
   {- writeln('days this year : ', days_this_year:4); -}
   inc(t, days_this_year * secs_per_day);
   {- writeln('in seconds     : ', t:12); -}

   {- reset February days if adjusted -}
   if days_per_month[1] = 29 then dec(days_per_month[1]);

   inc(t, dt.year * secs_per_year);
   {- writeln('years          : ', dt.year * secs_per_year:4); -}
   {- writeln('plus years     : ', t:12); -}

   num_leap_years := (dt.year + 2) div 4;        { get number of leap days }
   if (((dt.year+2) mod 4) = 0) then begin       { if target year is leap year }
      dec(num_leap_years);                       { back out 1 day }
   end;

   {- writeln('num leap years : ', num_leap_years:4); -}

   inc(t, num_leap_years * secs_per_day);
   {- writeln('plus leap days : ', t:12); -}
end;

(*
   1970
   1971
   1972 l
   1973
   1974
   1975
   1976 l
   1977
   1978
   1979
   1980 l
   1981
   1982
   1983
   1984 l
   1985
   1986
   1987
   1988 l
   1989
   1990
   1991
   1992 l
   1993
   1994
   1995
   1996 l
   1997
   1998
   1999
   2000 l

            years evenly divisible by 4 are leap years

   *except* years evenly divisible by 100 are *NOT* leap years

   *except* years evenly divisible by 400 *ARE* leap years

   So the year 2000 is a leap year, and most of us won't have to worry about
   rewriting the routines in 2100 when the simple-minded "div 4" leap year
   routines start failing!

   BTW, the 21st century doesn't start until 2001. The year 2000 is still the
   20th century.

*)

{------------------------------------------------------------------------------}
{- Format Unix Time                                                           -}
{-                                                                            -}
{- formats a Unix time longint into a string like this:                       -}
{-                                                                            -}
{-    Sun Jan 17 20:09:48 1994                                                -}
{------------------------------------------------------------------------------}
function FormatUnixTime(t : longint) : string;
var
   work : string;
   dt   : DateTime;
begin
   UnpackUnixTime(t, dt);
   FormatUnixTime :=
      int2dt (dt.hour)            +':'+
      int2dt (dt.min)             +' '+
      int2str(dt.day, 2)          +'-'+
      int2str(dt.month,2   )      +'-'+
      int2str(dt.year, 4);
end;

{------------------------------------------------------------------------------}
{- Int2Dt                                                                     -}
{------------------------------------------------------------------------------}
function int2dt(i : longint) : string_2;
var
   s : string_2;
begin
   str(i:2, s);
   if s[1]=' ' then s[1] := '0';
   int2dt := s;
end;

{------------------------------------------------------------------------------}
{- Int2Str                                                                    -}
{------------------------------------------------------------------------------}
function int2str(i : longint; l : integer) : string_10;
var
   s : string_10;
begin
   str(i:l, s);
   int2str := s;
   if s[1]=' ' then s[1]:='0';
end;

{------------------------------------------------------------------------------}
{- Str2Int                                                                    -}
{------------------------------------------------------------------------------}
function str2int(s : string) : longint;
var
   n : longint;
   e : integer;
begin
   val(s, n, e);
   str2int := n;
end;

{------------------------------------------------------------------------------}
end.

{------------------------------------------------------------------------------}
{- EOF : UNIXTIME.PAS                                                         -}
{------------------------------------------------------------------------------}


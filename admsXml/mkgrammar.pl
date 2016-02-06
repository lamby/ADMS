#!perl -w
#
# This file is part of adms - http://sourceforge.net/projects/mot-adms.
#
# adms is a code generator for the Verilog-AMS language.
#
# Copyright (C) 2002-2012 Laurent Lemaitre <r29173@users.sourceforge.net>
#               2014 Guilherme Brondani Torri <guitorri@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

my%Token;
my$atTop=1;
my$atBotton=0;
my@Bottom;
my@allbisonrule;
open OFH, ">verilogaYacc.y";
print OFH "/* File automatically created by " . __FILE__ . " */\n";
print OFH "\n";
while(<>)
{
  $atTop=0 if m/R_admsParse/;
  print OFH if $atTop;
  $atBotton=1 if m/^%%$/;
  push @Bottom,$_ if $atBotton;
  if(/^R_/)
  {
    chop;
    my$bisonrule;
    $bisonrule->{name}=$_;
    push @allbisonrule,$bisonrule;
    $_=<>;
    while(s/^\s+\|\s*//)
    {
      my$bisonalternative;
      NEWALTERNATIVE:
      {
        my%fragment;
        $fragment{precedence}=$1 if s/\s+(\%.*)$//;
        s/^\s+//;
        foreach my$tk(split /\s+/,$_)
        {
          push @{$fragment{child}},$tk;
          $Token{$tk}=1 if ($tk=~/tk_/);
        }
        $_=<>;
        while(s/^(\s+)_/$1 /)
        {
          $fragment{code}.=$_;
          $_=<>;
        }
        push @{$bisonalternative->{child}},\%fragment;
        if(not(m/^\s+;$/ || m/^\s+\|\s*/))
        {
          goto NEWALTERNATIVE;
        }
      }
      push @{$bisonrule->{alternative}},$bisonalternative;
    }
    die "bisonrule should terminate with ';' - see $_" if(not m/^\s+;$/);
  }
}
map {print OFH "\%token <_lexval> $_\n";} keys %Token;
print OFH "\n";
map {print OFH "\%type <_yaccval> $_->{name}\n";} @allbisonrule;
print OFH "\n";
print OFH "%%\n";
foreach my$mybisonrule(@allbisonrule)
{
  print OFH "$mybisonrule->{name}\n";
  my$firstalternative=$mybisonrule->{alternative}->[0];
  my$alterindex=0;
  foreach my$myalter(@{$mybisonrule->{alternative}})
  {
    my$fragmentindex=0;
    my$tokenstart=0;
    foreach my$fragment(@{$myalter->{child}})
    {
      my$child=$fragment->{child};
      my$code=$fragment->{code};
      print OFH " "x8;
      if($alterindex==0 && $fragmentindex==0)
      {
        print OFH ": ";
      }
      elsif($fragmentindex==0)
      {
        print OFH "| ";
      }
      else
      {
        print OFH " ";
      }
      print OFH join " ", @$child if $child;
      print OFH "\n";
      print OFH " "x10 . "{\n";
      if($code)
      {
        my$tkindex=$tokenstart+1;
        foreach my$tk(@$child)
        {
          if(defined($Token{$tk}) && ($code =~ m/mylexval$tkindex/))
          {
            print OFH " "x12 . "char* mylexval$tkindex=((p_lexval)\$$tkindex)->_string;\n";
          }
          $tkindex++;
        }
        print OFH $code;
      }
      my$tkindex=$tokenstart+1;
      foreach my$tk(@$child)
      {
        $tkindex++;
      }
      print OFH " "x10 . "}";
      print OFH " " . $fragment->{precedence} if (defined $fragment->{precedence});
      print OFH "\n";
      $fragmentindex++;
      $tokenstart+=scalar(@$child)+1;
    }
    $alterindex++;
  }
  print OFH " "x8 . ";\n";
}
print OFH @Bottom;
close OFH;
print "created: verilogaYacc.y\n";


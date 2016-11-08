
#    Varamozhi: A tool for transliteration of Malayalam text between
#               English and Malayalam scripts
#
#    Copyright (C) 1998-2008  Cibu C. J. <cibucj@gmail.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#if ($] >= 5.6) {
        require utf8;
#}
#else
#  {
#
#    print "version $]: utf8 not included\n\n";
#  }


#---------------------------------------------------------------------------
#---------------------------------println-----------------------------------
#---------------------------------------------------------------------------

sub println {
     foreach $word (@_) {
          print $word . " ";
     }
     print "\n";
}

#---------------------------------------------------------------------------
#---------------------------------Splits even null fields-------------------
#---------------------------------------------------------------------------

sub mysplit {
     
     my ($pat, $str) = @_;
     my $qpat;
     my @substrs;

     $qpat = $pat;
     $qpat =~ s/([\+\?\.\*\^\$\(\)\[\]\{\}\|"])/\\$1/g;
     $str =~ s/$qpat/ $pat/g;
     $str =~ s/((^|[^\\])(\\\\)*\\) $qpat/$1$pat/g;	
     @substrs = split(" ". $qpat, " " . $str . " ");
     $substrs[0]  =~ s/^ //;
     $substrs[-1] =~ s/ $//;

     return @substrs;
}


sub wordquote {

     # used in "" string.

     my $word = $_[0];

     # Remove blanks.
     $word =~ s/[ \t]+//g;

     $word =~ s/((\\\\)+)/ $1 /g;
     # unquote already quoted things eg: = % # , | except \
     $word =~ s/\\([=%#,\|])/$1/g;
     $word =~ s/ //g;

     # do the conversion from hex to char.
     $word =~ s/(0x[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])/chr(hex($1))/eg; #unicode
     $word =~ s/0x([0-9a-fA-F][0-9a-fA-F])/chr(hex($1))/eg;
     #print "|$word|\n";

     # now quote things like " in string.
     $word =~ s/"/\\"/g;

     #handle blanks \b is blank and \n is newline
     $word =~ s/\\b/ /g;

     return $word;
}

sub symquote {
     
     #output used as lex pattern.

     my @syms = @_;
     my $i;

     for ($i=$#syms; $i>=0; $i--) {

          # Remove blanks.
          $syms[$i] =~ s/[ \t]+//g;

          # unquote already quoted things eg: = % # , | except \
          # (only these need to  be quoted in mapfile)
          # rest of the quoted ones are untouched throughout the process.
          $syms[$i] =~ s/((\\\\)+)/ $1 /g;
          $syms[$i] =~ s/\\([=%#,\|])/$1/g;

	  # do the conversion from hex to char.
	  # print "|$syms[$i]|\n";
	  $syms[$i] =~ s/(0x[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])/" " . chr(hex($1)) . " "/eg; #unicode
	  $syms[$i] =~ s/0x([0-9a-fA-F][0-9a-fA-F])/" " . chr(hex($1)) . " "/eg;

          # now quote things like { $ [ ... for lex
          $syms[$i] =~ s/([\+\?\.\*\^\$\(\)\[\]\{\}\|\/<>"])/\\$1/g;

          # do the conversion from ascii to char.
          $syms[$i] =~ s/\\(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[4-9][0-9]|3[2-9])/" " . chr($1) . " "/eg;

          $syms[$i] =~ s/ \\ / \\\\ /g;
          $syms[$i] =~ s/ //g;


          #handle blanks \b is blank and \n is newline; this is now done later point in lookahead()
          #$syms[$i] =~ s/^((\\b)+)$/"$1"/g;
          $syms[$i] =~ s/\\b/ /g;

          if ($syms[$i] eq "") {
               splice @syms, $i, 1;
          }
     }
     return @syms;
}

sub suffix {
     my $str = "";

     if ($_[0] ne "!") # $! is not what we have in mind when we do this
       {
         foreach $char (keys %{$_[0]}) {
           $str .= $char;
         }
       }

     return ($str ne "") ? "/[^" . $str . "]" : "";
}

sub lookahead {

   my @arr = @_;

   for($i = 0; $i<=$#arr; $i++) {
     $big = $arr[$i]{fontchar};

     for($j = $i+1; $j<=$#arr; $j++){
       $small = $arr[$j]{fontchar};
       if (index($big, $small) == 0){
          $remain = substr($big, length($small));

          for($k = 0; $k<=$#arr; $k++) {
               $second = $arr[$k]{fontchar};

               if ((index($second, $remain) == 0)&&
                   (length($second) == length($remain) + 1)) {

                    $tail = substr($second, length($remain), 1);
                    $$big{$tail} = 1;
               }
          }
       }
     }

     $big = "\"$big\"" if ($big =~ /\s/);

     $arr[$i]{modfontchar} = $big . &suffix($big);
  }

  return @arr;
}

sub compare {
     my ($a, $b) = @_;

     if ($a eq $b) {
          print "Duplication of \'$a\': \n";
          exit;
     }
     elsif (index($b, $a) == 0) {
          return 1;
     }
     elsif (index($a, $b) == 0) {
          return -1;
     }
     else {
          return 0;
     }
}

sub mysort {
     my @arr = @_;
     my $temp;
     my ($i, $j);

     for($i = 0; $i < $#arr; $i++) {
          for($j = $#arr; $j > $i; $j--) {
               if (compare($arr[$i]{fontchar},  $arr[$j]{fontchar}) == 1) {
                    $temp = $arr[$i];
                    $arr[$i] = $arr[$j];
                    $arr[$j] = $temp;
               }
          }
     }

     return @arr;
}


#-------------------------Main--------------------------

$narg = @ARGV;

if ($narg != 3)  {
     print "\nUsage: table.pl <map file> <lex input file> <header file>\n\n";
     exit;
}

$mapfile = $ARGV[0];
$lex_ip_file = $ARGV[1];
$trans = $ARGV[2];
$secnum = 0;
@section = (
            INFO,        # info
            SYMBOL,      # Double Quote
            SYMBOL,      # Single Quote
            SYMBOL,      # Symbols
            AAA,         # letter a
            BASIC_V,     # Vowels
            CONJUNCT_V,  # Consonant+Vowel
            SAMV,        # samvr^thOkaaram
            GEN,         # General Letters
            GEN,         # Sa, sa and ga
            GEN,         # Ta vargaakshrangaL
            GEN,         # letter Da
            CHIL,        # letter Na
            GEN,         # tha vargaakshrangaL
            CHIL,        # letter na
            GEN,         # letters zha and  ya
            CHIL,        # letter ma
            CHIL,        # letter La
            CHIL,        # letter la
            CHIL,        # letters ra rra
            GEN,         # letter va
            GEN,         # kooTTaksharangngaL
            MACRO);

open(FH, "<$mapfile") or die "Can't open $mapfile: $!: ";

while (<FH>) {
     chomp;

     next if /(^[ \t]*#|^[ \t]*$)/;

     if (/^[ \t]*%%/) {
          $secnum++;
          next;
     }
     next if ($section[$secnum] eq "INFO");

#----------------------------------------------------------------------
#-------------------- extracting the fields ---------------------------
#----------------------------------------------------------------------

     @wlist = mysplit('=', $_);
     $engword = wordquote($wlist[0]);

     @slist = mysplit(',', $wlist[-1]);

     @purearr  = (defined($slist[0])) ? symquote(mysplit("|", $slist[0])) : ();
     @leftarr  = (defined($slist[1])) ? symquote(mysplit("|", $slist[1])) : ();
     @rightarr = (defined($slist[2])) ? symquote(mysplit("|", $slist[2])) : ();
     @chilarr  = (defined($slist[3])) ? symquote(mysplit("|", $slist[3])) : ();
     @rdotarr  = (defined($slist[4])) ? symquote(mysplit("|", $slist[4])) : ();

     @chilarr = () if ($section[$secnum] eq "BASIC_V");

#----------------------------------------------------------------------
#-------------------- Generating the tables ---------------------------
#----------------------------------------------------------------------

#----------------------------------------------------------------------
#--- if section is SYMBOL and not null then class is SYMBOL
#---                                    else class is NIL
#--- if section is VOWEL or AAA then class is VOWEL
#--- if section is Y or Rl or V then class is YVRlPURE
#--- other wise it is PURE (all remaining characters)
#----------------------------------------------------------------------

     for $fontsym (@purearr) {

          $prelextbl{$fontsym} =
                    { class   => $section[$secnum] eq "SYMBOL" &&
                                 $engword ne ""                  ? SYMBOL:

                                 $section[$secnum] eq "SYMBOL" &&
                                 $engword eq ""                  ? NIL:

                                 $section[$secnum] eq "BASIC_V" ||
                                 $section[$secnum] eq "AAA"      ? BASIC_V :

                                 $section[$secnum] eq "CONJUNCT_V"? CONJUNCT_V :

                                 ($section[$secnum] eq "GEN"  ||
                                  $section[$secnum] eq "CHIL")   &&
                                 ($#leftarr >=0               ||
                                  $#rightarr >=0)                ? FRACPURE : PURE,

                      english => $engword
                    };
     }

#----------------------------------------------------------------------
#--- if the character has left part OR right part
#--- then it can be part of a vowel or yvrl.
#----------------------------------------------------------------------

     if ($#rightarr < 0) {
          for $fontsym (@leftarr) {

               $prelextbl{$fontsym} =
                    { class   => ($section[$secnum] eq "BASIC_V")||
                                 ($section[$secnum] eq "CONJUNCT_V")||
                                 ($section[$secnum] eq "AAA") ?       VLEFT:FRACLEFT,
                      english => $engword
                    };
          }
     }

#----------------------------------------------------------------------
#--- if the character has left part OR right part
#--- then it can be part of a vowel or yvrl.
#----------------------------------------------------------------------

     if ($#leftarr < 0) {
          for $fontsym (@rightarr) {

               $prelextbl{$fontsym} =
                    { class   => ($section[$secnum] eq "BASIC_V")||
                                 ($section[$secnum] eq "CONJUNCT_V")||
                                 ($section[$secnum] eq "AAA") ||
                                 ($section[$secnum] eq "SAMV")?       VRIGHT : FRACRIGHT,
                      english => $engword
                    };
          }
     }

#----------------------------------------------------------------------
#--- if the character has left part AND right part
#--- then it can be parts of a vowel (o or O) or double or single quote
#----------------------------------------------------------------------

     if (($#leftarr >= 0) && ($#rightarr >= 0)) {
          for $leftsym (@leftarr) {
               for $rightsym (@rightarr) {
                    if (($section[$secnum] eq "BASIC_V")||
                        ($section[$secnum] eq "CONJUNCT_V")) {

                         push @yacctbl, ({   left      => $leftsym,
                                             right     => $rightsym,
                                             english   => $engword
                                        });
                    } else {

                         $prelextbl{$leftsym} =
                              { class   => SYMBOL,
                                english => $engword
                              };

                         $prelextbl{$rightsym} =
                              { class   => SYMBOL,
                                english => $engword
                              };
                    }
               }
          }
     }

#----------------------------------------------------------------------
#--- if the character has last font part then it is CHIL
#----------------------------------------------------------------------

     for $fontsym (@chilarr) {

          $prelextbl{$fontsym} =
                    { class   => CHIL,
                      english => $engword
                    };
     }

#----------------------------------------------------------------------
#--- if the character has rdot (repha)
#----------------------------------------------------------------------

     for $fontsym (@rdotarr) {

          $prelextbl{$fontsym} =
                    { class   => RDOT,
                      english => $engword
                    };
     }

#----------------------------------------------------------------------
#--- Finding out which is samvr^thOkaaram
#----------------------------------------------------------------------

     if ($section[$secnum] eq "SAMV") {
          for $fontsym (@purearr) {
               $prelextbl{$fontsym} =
                    { class   => SAMV,
                      english => $engword
                    };
          }
          $samvrutho = $engword;
     }

#----------------------------------------------------------------------
#--- Finding out which is the letter a
#----------------------------------------------------------------------

     if ($section[$secnum] eq "AAA") {
          $letter_a = $engword;
     }

#----------------------------------------------------------------------
#--- finding out which is false blank
#----------------------------------------------------------------------

     if (($section[$secnum] eq "SYMBOL") && ($#purearr < 0)) {
          $false_blank = $engword;
     }

#----------------------------------------------------------------------
#--- finding out which is zero width character
#----------------------------------------------------------------------

     if (($section[$secnum] eq "GEN") && ($#purearr < 0)) {
          $zwc = $engword;
     }
}

close(FH);

#----------------------------------------------------------------------
#-------------------- converting hash into array ----------------------
#----------------------------------------------------------------------

@keylist = keys %prelextbl;
foreach $key (@keylist) {
     push @lextbl, ({ fontchar => $key,
                      class    => $prelextbl{$key}{class},
                      english  => $prelextbl{$key}{english},
                    });
}

@lextbl = lookahead(mysort(@lextbl));

#----------------------------------------------------------------------
#-------------------- Generating the lex input file--------------------
#----------------------------------------------------------------------

open(LEX, ">$lex_ip_file");

open(PRE, "<./lam.lex.pre");
while (<PRE>) {print LEX;}
close(PRE);

foreach $row (@lextbl) {
if ($row->{class} eq "NIL") {
print LEX <<EOF;
$row->{modfontchar}
EOF
} else {
print LEX <<EOF;
$row->{modfontchar}           { yylval.str = (char *)strdup("$row->{english}"); return $row->{class}; }
EOF
}
}

open(POST, "<./lam.lex.post");
while (<POST>) {print LEX;}
close(POST);

close(LEX);

#----------------------------------------------------------------------
#-------------------- Generating the yacc table -----------------------
#----------------------------------------------------------------------

open(TRANS, ">$trans");

$false_blank = defined($false_blank) ? $false_blank : "";
$letter_a    = defined($letter_a)    ? $letter_a    : "";
$samvrutho   = defined($samvrutho)   ? $samvrutho   : "";
$zwc         = defined($zwc)         ? $zwc         : "";

print TRANS <<EOF;
#define FALSEBLANK  "$false_blank"
#define AAA         "$letter_a"
#define SAMVRUTHO   "$samvrutho"
#define ZWC         "$zwc"

static char* combfont[][2] =  {
EOF


foreach $row (@yacctbl) {

print TRANS <<EOF;
     { "$prelextbl{$row->{left}}{english}$prelextbl{$row->{right}}{english}", "$row->{english}"},
EOF
}

print TRANS <<EOF;
     { "", ""}};
EOF

close(TRANS);

#----------------------------------------------------------------------
#-------------------- End ---------------------------------------------
#----------------------------------------------------------------------

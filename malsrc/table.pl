
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

require utf8;
if ($] >= 5.6) {
}

#---------------------------------------------------------------------------
#---------------------------------Splits even null fields-------------------
#---------------------------------------------------------------------------

sub mysplit {
	
	my ($pat, $str) = @_;
	my $qpat;
	my @substrs;

	$qpat = $pat;
	$qpat =~ s/([\+\?\.\*\^\$\(\)\[\]\{\}\|\"])/\\$1/g; #"
	#print "str1 = $str\n";
	$str =~ s/$qpat/ $pat/g;
	#print "str2 = $str\n";
	$str =~ s/((^|[^\\])(\\\\)*\\) $qpat/$1$pat/g;	
	#print "str3 = $str\n";
	@substrs = split(" ". $qpat, " " . $str . " ");
	$substrs[0]  =~ s/^ //;
	$substrs[-1] =~ s/ $//;

	return \@substrs;
}


sub unquote {

	#remove all quotings

	my $str = $_[0];

	# Remove blanks.
	$str =~ s/\s//g;

	# unquote already quoted things eg: = % # , | except \
	# (only these need to  be quoted in mapfile)
	# rest of the quoted ones are untouched throughout the process.
	$str =~ s/((\\\\)+)/ $1 /g;
	$str =~ s/\\([=%\#,\|])/$1/g;

	# do the conversion from ascii to char.
	$str =~ s/\\(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[4-9][0-9]|3[2-9])/" " . chr($1) . " "/eg;

	# do the conversion from hex to char.{4} does not work in utf8
	$str =~ s/(0x[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])/" " . chr(hex($1)) . " "/eg; #unicode
	$str =~ s/0x([0-9a-fA-F][0-9a-fA-F])/" " . chr(hex($1)) . " "/eg;
	$str =~ s/ //g;

	return $str;
}

sub wordquote {

	#output used as lex pattern

	my $str = $_[0];

	# now quote things like { $ [ ... for lex
	$str =~ s/([\+\?\.\*\^\$\(\)\[\]\{\}\|\/<>\\"])/\\$1/g; #"

	#handle blanks \b is blank and \n is newline
	#$str =~ s/^((\\b)+)$/"$1"/g;
	$str =~ s/\\b/ /g;
	$str =~ s/\\t/\t/g;

        $str = '"' . $str . '"' if ($str =~ /\s|[\/]/);

	return $str;
}

sub arrquote {
	
	my @word = @_;
	my $i;

	for($i = 0; $i <= $#word; $i++) {
		$word[$i]{modified} = wordquote($word[$i]{word});
	}

	return @word;
}

sub symquote {

	#used in "" string.

	my $sym = $_[0];

	# Remove blanks.
	$sym =~ s/[ \t]+//g;

	$sym =~ s/((\\\\)+)/ $1 /g;
	# unquote already quoted things  = % # , | except \
	$sym =~ s/\\([=%#,\|])/$1/g;

	# do the conversion from ascii to char.
	$sym =~ s/\\(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[4-9][0-9]|3[2-9])/" " . chr($1) . " "/eg;

	# do the conversion from hex to char.{4} does not work in utf8
	$sym =~ s/(0x[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])/" " . chr(hex($1)) . " "/eg; #unicode
	$sym =~ s/0x([0-9a-fA-F][0-9a-fA-F])/" " . chr(hex($1)) . " "/eg;


	#again removing the spaces and quoting newly generated \
	$sym =~ s/ \\ / \\\\ /g; 
	$sym =~ s/ //g;

	# now quote things like " in string.
	$sym =~ s/"/\\"/g;   #"

	#handle blanks \b is blank and \n is newline
	$sym =~ s/\\b/ /g;

	return $sym;
}

sub suffix {
	my $str = "";

        if ($_[0] ne "!") # $! is not what we have in mind when we do this
          {
            foreach $char (keys %{$_[0]})
              {
		$str .= wordquote($char);
              }
          }

	return ($str ne "") ? "/[^" . $str . "]" : "";
}

sub lookahead {

   my @word = @_;


#     j
#   small   remain
#   +---+   +----+
#   |   |   |    |
#    ch       ch    h
#   |            |
#   +------------+
#      big  |         |
#       i   +---------+
#              second
#                k

# test 'ruu', 'lppa', 'kkr^', 'thna', chhra (in matweb)

# doubled koottaksharams are prefered,
# if they does not increase the number of componants.

# if second is prefred, look ahead is added
# if big is prefred, logic is skipped by 'next'



   for($i = 0; $i<=$#word; $i++) {
	$big = $word[$i]{word};

   	for($j = $i+1; $j<=$#word; $j++){
	  $small = $word[$j]{word};

	  # we should take care for empty strings also
	  if (index($big, $small) == 0 && length($small) != 0 ){
		$remain = substr($big, length($small));

   		for($k = 0; $k<=$#word; $k++) {
			$second = $word[$k]{word};




                        $matched_pair = (   (index($second, $remain) == 0)  &&
                                            (length($second) > length($remain)) );


                        # acceptable only if $second is conjunct
                        $accept_big_double = (   ($big =~ /^(.*)\1$/) &&
                                                 (   ($word[$k]{section} eq "KOOTTAM") ||
                                                     ($word[$k]{section} eq "SVARKOOT")));


                        # acceptable only if $big is conjunct
                        $accept_second_double = (   ($second =~ /^(.*)\1$/) &&
                                                    (   ($word[$i]{section} eq "KOOTTAM") ||
                                                        ($word[$i]{section} eq "SVARKOOT")));

                        $acceptable_big = ($word[$i]{section} eq "VOWEL");

                        $acceptable_second = (  ($word[$k]{section} ne "AAA")	   &&
                                                ($word[$k]{section} ne "KOOTTAM")  &&
                                                ($word[$k]{section} ne "SVARKOOT")  );


                        if (  $matched_pair &&
                              !$accept_big_double &&
                              !$acceptable_big &&
                              (  $accept_second_double ||
                                 $acceptable_second)
                          )
                          {

                            $tail = substr($second, length($remain), 1);
                            $$big{$tail} = 1;

                            #print "second=$second remain=$remain tail=$tail\n" if ($big =~ /chh/ && $second =~ /hr/);
                          }
                      }
              }
	}

	$word[$i]{modified} .= suffix($big);
  }

  return @word;
}

sub compare {
	my ($a, $b) = @_;

	if ($a eq $b) {
		print "Duplication of \'$a\'\n";
		exit 1;
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
	my @word = @_;
	my $temp;
	my ($i, $j);

	for($i = 0; $i < $#word; $i++) {
	  #print "word: $word[$i]{word}\n";
	  #if (!$word[$i]{word}) {
	  #  print "null word********************\n";
	  #}
	  for($j = $#word; $j > $i; $j--) {
	    #print "comparing: $word[$i]{word}, $word[$j]{word}\n";
	    if (compare($word[$i]{word},  $word[$j]{word}) == 1) {
	      $temp = $word[$i];
	      $word[$i] = $word[$j];
	      $word[$j] = $temp;
	    }
	  }
	}

	return @word;
}


#-------------------------Main--------------------------

$narg = @ARGV;

if ($narg != 3)  {
	print "\nUsage: table.pl <map file> <lex input file> <mydefault file>\n\n";
	exit;
}

$mapfile      =  $ARGV[0];
$mapname      =  $mapfile;
$mapname      =~ s|.*?([^/]*)\.map|$1|;
$macroname    =  "macro_${mapname}";
$macrolexfile =  "${macroname}.l";
$lex_ip_file  =  $ARGV[1];
$mydefault    =  $ARGV[2];
$symcount     =  0;
$secnum       =  0;
$samindex     =  0;

$carrycomment =  0;
$allowRdot    =  0;

@section = (INFO,       # info
            DQ,         # Double Quote
            SQ,         # Single Quote
            SYMBOL,     # Symbols
            AAA,        # letter a
            VOWEL,      # Vowels
            SVARKOOT,   # Consonant+Vowel
            SAMVRUTHO,  # samvr^thOkaaram
            BAKKI,      # General Letters
            GSs,        # Sa, sa and ga
            DA,         # Ta vargaakshrangaL
            DDD,        # letter Da
            NNN,        # letter Na
            THA,        # tha vargaakshrangaL
            "nnn",      # letter na
            YZH,        # letters zha and  ya
            MMM,        # letter ma
            LLL,        # letter La
            "lll",      # letter la
            RRR,        # letters ra rra
            VVV,        # letter va
            KOOTTAM,    # kooTTaksharangngaL
            MACRO);

open(FH, "<$mapfile") or die "Can't open $mapfile: $!: ";
$commentpat = '^\s*(\#|$)';
while (<FH>)
{
    chomp;

    # don't add s/#.*$//; because this will destroy
    # `#' as font chars

    next if ($_ =~ /$commentpat/) ;
        
    if (/^\s*%%/)
    {
        $secnum++;
        next;
    }

    if ($section[$secnum] eq "INFO") {

#----------------------------------------------------------------------
#-------------------- Extracting Comment Characters -------------------
#----------------------------------------------------------------------
        
        if (s/^\s*comment\s*=\s*//i)
        {
            @comment	   = @{mysplit(",", $_)};
            $leftcomment   = wordquote(unquote($comment[0]));
            $rightcomment  = wordquote(unquote($comment[1]));
            $crightcomment = $rightcomment;
            $crightcomment =~ s/\\//;

            next;
        }

#----------------------------------------------------------------------
#--- Deciding whether to carry the comment to next phase --------------
#----------------------------------------------------------------------

        if (/carry\s*comment\s*=\s*yes/i)
        {
            $carrycomment = 1;
        }

#----------------------------------------------------------------------
#--- Deciding whether to carry the comment to next phase --------------
#----------------------------------------------------------------------

        if (/allow\s*r\s*dot\s*=\s*yes/i)
        {
            $allowRdot = 1;
        }
		# Why to process the info section any further ?
        next;
    }

#----------------------------------------------------------------------
#-------------------- extracting the fields ---------------------------
#----------------------------------------------------------------------

    if ($section[$secnum] eq "MACRO")
    {
	@wlist = @{mysplit('=', $_)};
	for($i = 0; $i <$#wlist; $i++)
	{
	  $wlist[-1] =~ s/\"/\\\"/s;
	  #print "pushing $wlist[$i], $wlist[-1]\n";
	  exit 1 if (!$wlist[$i]);
	  push @macrotable, ({word => unquote($wlist[$i]), expansion => unquote($wlist[-1])});
	}
        next;
    }

#----------------------------------------------------------------------
#-------------------- extracting the fields ---------------------------
#----------------------------------------------------------------------

    @wlist = @{mysplit('=', $_)};
    @slist = @{mysplit(',', $wlist[-1])};

    for($i=0; $i<$#wlist; $i++)
    {
        $wlist[$i] = unquote($wlist[$i]);
    }

    for($i=0; $i<=$#slist; $i++)
    {
        $slist[$i] = symquote(${mysplit("\|", $slist[$i])}[0]);
    }

#----------------------------------------------------------------------
#-------------------- Generating the tables ---------------------------
#----------------------------------------------------------------------

     for($i = 0; $i<$#wlist; $i++)
     {
         $pretable{$wlist[$i]} = {  symbol  => $symcount,
                                    section => $section[$secnum],
                                };
     }

     $symbol[$symcount] = {
         full   => ($#slist >= 0) ? $slist[0] : "",
         left   => ($#slist >= 1) ? $slist[1] : "",
         right  => ($#slist >= 2) ? $slist[2] : "",
         frac   => ($#slist >= 3) ? $slist[3] : "",
         nondef => ($#slist >= 4) ? $slist[4] : "",
     };


     #
     # This is for samvr^thOkaaram only. It is put just after all vowels. */
     #

     if ($section[$secnum] eq "SAMVRUTHO")
     { 
         $samindex = $symcount;
     }

     $symcount++;
}

close(FH);

#----------------------------------------------------------------------
#-------------------- processing Macro --------------------------------
#----------------------------------------------------------------------

@macrotable = mysort( @macrotable );

open( MACROLEX,  ">$macrolexfile" );
open( MACROTMPL, "<macro.l.tmpl"  );

while( <MACROTMPL> )
{
    last if (/insert\s*here/);
    print MACROLEX;
}

# reached the position where rules to be inserted

foreach $macro (@macrotable)
{
    if ( $macro->{word} =~ s/^\^// )
    {
        $nonstart = "FALSE";
    }
    elsif ( $macro->{word} =~ s/^\?// )
    {
        $nonstart = "TRUE";
    }
    else
    {
	$nonstart = "DONTCARE";
    }

    $macro->{word} =~ s/\$$/\/{SPACE}/;

    my ($tmp_word, $tmp_expansion) = ($macro->{word}, $macro->{expansion});

    if ( $nonstart ne "TRUE") #has ^ or ? as the first char
    {

      print MACROLEX <<EOF;
$tmp_word               {
                           BEGIN(NONSTART);
                           if (debug)
                           {
                                fprintf(stderr, "$tmp_word => $tmp_expansion\\n");
                           }
	                   str_append( halfcooked, "$tmp_expansion");
                        }
EOF

    }

    if ( $nonstart ne "FALSE") #first char is not ^; but it may be `?'
    {
      print MACROLEX <<EOF;
<NONSTART>$tmp_word     {
                           if (debug)
                           {
                               fprintf(stderr, "$tmp_word => $tmp_expansion\\n");
                           }
                           str_append( halfcooked, "$tmp_expansion");
                        }
EOF
    }
}


# append the remaining portion

while( <MACROTMPL> )
{
    print MACROLEX;
}

close( MACROLEX );
close( MACROTMPL );

#----------------------------------------------------------------------
#-------------------- converting hash into array ----------------------
#----------------------------------------------------------------------

@keylist = keys %pretable;
foreach $key (@keylist) {
	push @word, ({ word	=> $key,
                       section	=> $pretable{$key}{section},
                       symbol	=> $pretable{$key}{symbol},
                   });
       
}


@word = lookahead(arrquote(mysort(@word)));

#----------------------------------------------------------------------
#-------------------- Generating the lex file -------------------------
#----------------------------------------------------------------------

open(LEX, ">$lex_ip_file");

open(PRE, "<./lex.pre.tmplt");
while (<PRE>) { print LEX; }
close(PRE);

if (0 && defined($leftcomment)) {

print LEX <<EOF;

$leftcomment\[\^$rightcomment\]\*\(\\\\$rightcomment\[\^$rightcomment\]\*\)\*$rightcomment {
			  int i, j;

			  yylval.str = yytext;
			 
			  if (!carrycomment) {
				/* '\\' should be removed form all '$rightcomment' */
				for (j=0, i=1; yytext[i+1] != 0; i++) {
					if (!((yytext[i] == '\\\\') && (yytext[i+1] == '$crightcomment')))
						yylval.str[j++] = yytext[i];
				}
				yylval.str[j] = 0;
			  }
			  return ENGLISH;
			}

EOF

}

for $row (@word) {

	#putting KOOTTAM back to BAKKI and etc.
	if ($row->{section} eq "KOOTTAM")     { $row->{section} = "BAKKI";    }
	if ($row->{section} eq "SAMVRUTHO")   { $row->{section} = "VOWEL";    }
	if ($row->{section} eq "SVARKOOT")    { $row->{section} = "SVARKOOT"; }

	if ($row->{modified} ne "") {
print LEX <<EOF;
$row->{modified}		{yylval.val = $row->{symbol}; return $row->{section};}
EOF
	}
}

open(POST, "<./lex.post.tmplt");
while (<POST>) {print LEX;}
close(POST);

close(LEX);

#----------------------------------------------------------------------
#-------------------- Generating the header file mydefault.h ----------
#----------------------------------------------------------------------

open(DEFAULT, ">$mydefault");

print DEFAULT <<EOF;
\#include "mal-type.h"
char* mal_parse(char* mal_in_text, long flags);
static MapTable map =  {
EOF

for($i=0; $i<$symcount; $i++) {

  #i could have used EOF
  #but \\ in the string causes some chr eg: 176 behave insane!
  print DEFAULT "	{\"$i\", ";
  print DEFAULT "\"$symbol[$i]{full}\", ";
  print DEFAULT "\"$symbol[$i]{left}\", ";
  print DEFAULT "\"$symbol[$i]{right}\", ";
  print DEFAULT "\"$symbol[$i]{frac}\", ";
  print DEFAULT "\"$symbol[$i]{nondef}\" },\n";
}

print DEFAULT <<EOF;
				  { "","", "", "", ""}
				};

extern Private                 private;

extern int                     ${mapname}lex(void);
extern struct yy_buffer_state* ${mapname}_scan_bytes();
extern void                    ${mapname}_switch_to_buffer();
extern void                    ${mapname}_delete_buffer();

extern int                     ${macroname}lex(void);
extern struct yy_buffer_state* ${macroname}_scan_bytes();
extern void                    ${macroname}_switch_to_buffer();
extern void                    ${macroname}_delete_buffer();

char *${mapname}_parse(char *str, long flags)
{
    
    private.map                 = \&map;
    private.samindex            = $samindex;

    private.yylex               = ${mapname}lex;
    private.yy_scan_bytes       = ${mapname}_scan_bytes;
    private.yy_switch_to_buffer = ${mapname}_switch_to_buffer;
    private.yy_delete_buffer    = ${mapname}_delete_buffer;

    private.macrolex               = ${macroname}lex;
    private.macro_scan_bytes       = ${macroname}_scan_bytes;
    private.macro_switch_to_buffer = ${macroname}_switch_to_buffer;
    private.macro_delete_buffer    = ${macroname}_delete_buffer;

    return mal_parse(str, flags);
}

EOF

close(DEFAULT);



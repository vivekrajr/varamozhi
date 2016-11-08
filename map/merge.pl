
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

#---------------------------------------------------------------------------
#---------------------------------Splits even null fields-------------------
#---------------------------------------------------------------------------

sub mysplit {
	
	my ($pat, $str) = @_;
	my $qpat;
	my @substrs;

	$qpat = $pat;
	$qpat =~ s/([\+\?\.\*\^\$\(\)\[\]\{\}\|"])/\\$1/g; #"
	$str =~ s/$qpat/ $pat/g;
	$str =~ s/\\ $qpat/\\$pat/g;	
	@substrs = split(" ". $qpat, " " . $str . " ");

	$substrs[0]  =~ s/^ //;
	$substrs[-1] =~ s/ $//;

	return \@substrs;
}

sub uniq {
    my @uniq_values;
    my $prev_v;
    
    foreach $v (@_){
        if (!defined($prev_v) || ($prev_v ne $v)) {
            push @uniq_values, $v;
            $prev_v = $v;
        }
    }
    return \@uniq_values;
}

#-------------------------Main--------------------------

$narg = @ARGV;

if ($narg != 2)  {
    print "\nUsage: merge.pl \<schm_schm map file\> \<schm_font map file\>\n\n";
    exit;
}

$schm_schm_map = $ARGV[0];
$schm_font_map = $ARGV[1];
$secnum = 0;
$macros = "\n";

@section = (INFO,
            DQ,
            SQ,
            SYMBOL,
            AAA,
            VOWEL,
            SVARKOOTTAM,
            SAMVRUTHO,
            BAKKI,
            GSs,
            DA,
            DDD,
            NNN,
            THA,
            "nnn",
            YZH,
            MMM,
            LLL,
            "lll",
            RRR,
            VVV,
            KOOTTAM,
            MACRO
            );

open(SS, "$schm_schm_map") or die "Can't open $schm_schm_map: $!: ";

while (<SS>) {

#    print "line: $_";

    chomp;

    if (/(^\s*\#|^\s*$)/) {next;}
    
    if (/^\s*%%/) {
        $secnum++;
        next;
    }

    #-- no information is needed from the info section of schm_schm.

    if ($section[$secnum] eq "INFO") { next }
    if ($section[$secnum] eq "MACRO") { $macros .= "$_\n"; next }

    #-------------------- extracting the fields -------------------
    s/\s+//g;
    $p_wlist = mysplit('=', $_);
    $primary_word = pop @$p_wlist;
    $wlist_hash{$primary_word} = uniq(sort(@$p_wlist));

#        print "$primary_word = " . join(", ", @{$wlist_hash{$primary_word}});
#        print "\n";
}

close(SS);

open(SF, "$schm_font_map") or die "Can't open $schm_font_map: $!: ";

$secnum = 0;
while (<SF>) {

    $line = $_;

    if ($line =~ /(^\s*#|^\s*$)/) { next }
    if ($line =~ /^\s*%%/) {
        $secnum++;
        next;
    }

    #-- nothing to be done on the info sect.

    if ( $section[$secnum] eq "INFO" ||
         $section[$secnum] eq "MACRO" )   { next }

    #-------------------- extracting the fields -------------------
    ($word, $font_chars) = @{mysplit('=', $line)};
    $word =~ s/\s+//g;

    #-------------------- getting equivalent char seq from the hash
    #-------------------- and making a = seperated list with font chars
    #-------------------- at the end.

    if (defined($wlist_hash{$word})) {
        $line = "";
        foreach $eq_word (@{$wlist_hash{$word}}) {
            $line .= "$eq_word = ";
        }
        $line .= "$font_chars\n";
    }
    else
    {
        #print STDERR "no equivalences found for $word\n";
    }
} continue {
    # print modified and unmodified.
    # for each line there will be one and only one output.

    print $line;
}
        
close(SF);

print $macros;

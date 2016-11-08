#!/usr/contrib/bin/perl -w
# windows compilation
#   cd j:/varamozhi/varamozhi/gui
#   perl2exe -perloptions=-p2x_noshow_includes editor.pl
#
# in the new version do
#   perl2exe editor.pl
#perl2exe_exclude "MacPerl.pm"
#perl2exe_include "encoding.pm"

use Tk;
use Tk::ROText;
use Tk::TextUndo;
use Tk::Radiobutton;
use Tk::Checkbutton;
use Tk::Adjuster;
use Tk::Dialog;
use Tk::Photo;
use Tk::Font;
use Tk::Menubutton;
use Tk::Scrollbar;
use FileHandle;
use IPC::Open2;
use IPC::Run3;
use IO::Handle;
use Getopt::Long;
use Cwd;
use File::Basename;
use File::Spec;
use File::DosGlob 'glob';
use Encode;

#---------------------------------------------------------------------
# change version in every release.
#---------------------------------------------------------------------
my $version = "1.08.03";
#---------------------------------------------------------------------


my ($edit, $result);
my $reader;
my $writer;

local $extra_args = "";

my $usage = "$0 [-t|-h|-g] <config file>\n";
my $opt = GetOptions( "t|test",    \$test,
		      "h|help",    \$help
		    );
my $config_file = join " ", @ARGV;

die "$usage" if ( !$opt || $help );

$windows = ($^O eq "MSWin32");
$unix    = !$windows;

$mod         =  'Control';
$tmp_dir    = File::Spec->tmpdir();

debug("tmp path = $tmp_dir");


#print "tmp_dir = $tmp_dir; tmpfile = $tmpfile; config_file = $config_file\n";

if ($windows || $test) {

  $firsttime      = 1;
  $browser        = "explorer";
  $curdir         = Win32::GetCwd();

  if ($test) {
    $progpath     = "test\\";
    $rprogpath    = "lamsrc\\";
    $icon_file    = "gui\\varamozhi-icon.gif";
    $help_dir     = "gui";
    #$tmp_dir      = "tmp";
  }
  else {
    $progpath     = "bin\\";
    $rprogpath    = "bin\\";
    $icon_file    = "icon\\varamozhi-icon.gif";
    $help_dir     = "doc";
    #$tmp_dir      = $curdir;
  }

  $help_lipi_file = "$help_dir\\lipi.png";
  $help_faq_file  = "$help_dir\\faq.html";

  $tmpfile        = "$tmp_dir\\varamozhi-exported-tmp.html";
  $autosavefile   = "$tmp_dir\\varamozhi-autosave.txt";
  $config_file    = "$tmp_dir\\varamozhi-config.pl" if (!$config_file);


}

if ($unix) {

  $curdir         =  getcwd();
  $dist           =  $0;
  $dist           =~ s([^/]*$)(..);
  $dist           =~ s(^(?!/))($curdir/);

  $dist           = '.';

  $progpath       =  "$dist/test/";
  $rprogpath      =  "$dist/lamsrc/";

  $help_dir       =  "$dist/htdocs";
  $help_lipi_file =  "$help_dir/quickref.html";
  $help_faq_file  =  "$help_dir/quickref.html";
  $icon_file      =  "$dist/gui/varamozhi-icon.gif";

  #$tmp_dir        =  "$dist";
  $tmpfile        =  "$tmp_dir/varamozhi-exported-tmp.html";
  $autosavefile   =  "$tmp_dir/varamozhi-autosave.txt";
  $config_file    =  "$ENV{HOME}/varamozhi-config.pl" if (!$config_file);

  $firsttime      =  0;
  $browser        =  "firefox";
}


local $advanced     = 1; #to force context(0) work first time
local $savefilename = "";
local $unsaved      = 0;

local $lockMode     = 'manglish2malayalam';
local $refreshPeriod;
local $autoSavePeriod;

local $mfonttxt;
local $efontsize;

local $height_chars;
local $mwin_width_chars;
local $ewin_width_chars;

local %mfonthash;


sub debug
  {
    if ($extra_args =~ /-g/)
      {
        print @_;
        print "\n";
      }
  }


sub setDefaultSavedConfig
  {
    # default config values
    $mfonttxt     = '';
    $efontsize    = 10;

    $height_chars     = 15;
    $ewin_width_chars = 30;
    $mwin_width_chars = 30;

    # refresh feature: disabled
    #
    # - IE in NT does not refresh
    # - does not seem very useful

    $refreshPeriod  =  0;  #html export refresh in sec
    $autoSavePeriod = 15; #auto save in sec
  }



sub saveConfig {
  my ($tmpdir) = ($curdir);
  $tmpdir  =~ s/\\/\\\\/g;

  open(FD, ">$config_file" );

  print FD <<EOF;
# Configuration for Varamozhi Editor (http://varamozhi.sourceforge.net)
#
# This file is in Perl syntax


# version of the saved configuration
# This value changes when you install newer version of the Editor.
\$config_version    = "$version";

# starting Varamozhi for first time or not
# This value changes when you have run it for once.
\$firsttime         = $firsttime;

# Default directory where files will be saved  in next startup.
# This value changes when you change it runtime.
\$curdir            = "$tmpdir";

# Short name for the Malayalam font to be used in next startup
# one of following short names of Malayalam font:
# chowara, karthika, kerala, manorama, mathrubhumi, thoolika & unicode
# This value changes when you change it runtime.
\$mfonttxt          = "$mfonttxt";

# font size for Manglish window used for next startup.
# This value changes when you change it runtime.
\$efontsize         = $efontsize;

# height of the window in characters
\$height_chars      = $height_chars;

# width of Malayalam window in characters
\$mwin_width_chars  = $mwin_width_chars;

# width of Manglish window in characters
\$ewin_width_chars  = $ewin_width_chars;

# refresh period in seconds for exported HTML/Unicode page
\$refreshPeriod     = $refreshPeriod;

# auto save period in seconds
\$autoSavePeriod    = $autoSavePeriod;

# browser to be used for displaying help or varamozhi site
\$browser           = "$browser";

# extra arguments to be passed down to varamozhi conversion executable
\$extra_args        = "$extra_args";

# Lock or unlock the Malayalam window for reverse conversion to manglish.
\$lockMode          = "$lockMode";

1
EOF


  close(FD);
}

sub setTitle
  {
    $top->configure( -title =>
                     "Varamozhi Editor [" . $mfonthash{$mfonttxt}. " " . get_mfontsize_from_e() . " font] $savefilename");
  }


# get config if config.pl exists
setDefaultSavedConfig();

if (-f $config_file) {
  my $result;
  debug("config_file=$config_file");

  unless ($result = do $config_file ) {
    die "couldn't parse $config_file: $@" if $@;
    #die "couldn't do $config_file: $!"    unless defined $result;
    #die "couldn't run $config_file"       unless $result;
  }
}

if (!$config_version || ($version ne $config_version))
  {
    setDefaultSavedConfig();
    saveConfig();
  }

local $usrArgBasic  = ($extra_args =~ /-b/)? '-b':'';
local $usrArgDebug  = ($extra_args =~ /-g/)? '-g':'';

#print "curdir   = $curdir\n";
#print "mfonttxt = $mfonttxt\n";
#print "esize    = $efontsize\n";

sub nnewlines {

  my ($str) = @_;

  # old way...

  #$oldlen = length($str);
  #$str =~ s/\n//sg;
  #$newlen = length($str);
  #return ($oldlen - $newlen);

  my $count = ($str =~ tr/\n/\n/);
  return $count;
}

sub convert{
  my ($txt) = @_;
  my $mal = "";

  #splitting is required because perl hangs when number of characters in the output buffer
  #is more than some critical limit > 4000 chars

  while ($txt =~ m/\G(.{0,1200}(\s|$))/sg) {

    #\n is for the print which needs atleast a newline.
    my $line = "$1>\n";

    #print "IN: |$line|\n";
    print $writer "$line";

    my $count = nnewlines($line);
    #print "count = $count\n";

    for (my $i = 1; $i <= $count; $i++) {
      $mal .= <$reader>;
      #print "OUT $i: |$mal|\n";
    }

    $mal =~ s/{}//s;#remove {} added by lam as a bug somewhere - may be in flex
    $mal =~ s/(<br\/>)?\n$//s;#remove the extra newline added; <br\/> incase of unicode
    $mal =~ s/>$//s;#remove > added
  }

  #print "OUT: |$mal|\n";
  #print "----------------------------------------------\n";

  return $mal;
}

sub charPart {
  my ($i) = @_;

  $i =~ s/.*\.//;
  return $i;
}

sub linePart {
  my ($i) = @_;

  $i =~ s/\..*//;
  return $i;
}

sub currentLine {
  return linePart($edit->index("insert"));
}

sub delCurrChar {
  # cntl-s puts a box in the windows. delete it.

  $edit->delete("insert - 1 c");
}

sub tagit {

  my $sloc = $edit->index("insert");
  my $line = linePart($sloc);

 
    my $sc = charPart($sloc) + 1;
    my $se = charPart($edit->index("$line.end")) + 1;

    my $de = charPart($result->index("$line.end")) + 1;
    my $dc = int($sc * $de / $se);

    my $startloc = (($dc - 5)  > 0)   ? ($dc - 5) : 0;
    my $endloc   = (($dc + 2 ) < $de) ? ($dc + 2) : $de;

  if ($mfonttxt ne 'unicode') {
    $edit->tagRemove("mcurrent", '0.0', 'end');
    $result->tagRemove("mcurrent", '0.0', 'end');
    $result->tagAdd("mcurrent",
		    "$line.$startloc",
		    "$line.$endloc");
  }

  $result->see("$line.$endloc");
  $edit->see("insert");
}

sub movekey {
  my ($widget, $mode) = @_;
  context($mode);
  tagit();
}

sub oneline {

  return if (($advanced == 1) && ($lockMode eq 'manglish2malayalam'));

  my $line = currentLine();

  $result->delete("$line.0", "$line.end");
  &$convertInsert("$line.0", "$line.end" );
}

sub onelinekey {
  my ($widget, $mode) = @_;

  context($mode);
  oneline();
  tagit();

  $unsaved = 1;
  #print "oneline unsaved = $unsaved\n";
}

sub whole {

  return if (($advanced == 1) && ($lockMode eq 'manglish2malayalam'));

  $result->delete('0.0', 'end');
  &$convertInsert('0.0', 'end');

}

sub wholekey {
  my ($widget, $mode) = @_;

  context($mode);
  whole();
  tagit();

  $unsaved = 1;
  #print "whole unsaved = $unsaved\n";
}

#---------------------------------------------------
# conversion and insertion of Mal text(adv mode)
#---------------------------------------------------
#$counter = 0;
sub convertMinsert {
  #assume it is from '0.0' to 'end'
  my ($start, $end) = @_;
  $loc = $start;

  #print "$start to $end (counter = $counter)\n";
  #$counter++;
  @ranges = $edit->tagRanges("english");

  while(($estart, $eend) = splice(@ranges, 0, 2)) {

    #print "range: $estart $eend\n";
    if ($txt = $edit->get($start, $estart)) {
      #print "malayalm: $loc |$txt|\n";
      $loc = insertM( $loc, $txt );
    }

    if ($txt = $edit->get($estart, $eend)) {
      $len = length($txt) + 2;
      #print "english: $loc |{$txt}|\n";
      $result->insert($loc, "{$txt}");
      $loc = $result->index("$loc + $len chars");
    }
    $start = $eend;
  }

  if ($txt = $edit->get($start, $end)) {
    #print "last malayalm: $loc |$txt|\n";
    $txt =~ s/\s*$//s;
    insertM( $loc, $txt );
  }
}

#---------------------------------------------------
# conversion and insertion of Eng text(non-adv mode)
#---------------------------------------------------
sub insertM {
  my($mloc, $txt) = @_;

  #print "in |$txt|\n";

  if  ($mfonttxt eq "unicode")
  {
     $txt = encode_utf8( $txt );
  }
  else
  {
     # cannot use variable for encoding. pp packager does not like it.
     $txt = Encode::encode( "cp1252", $txt );
     $txt = encode( "cp1252", $txt );
  }

  $mtxt = convert($txt);
  #print "out |$mtxt|\n";

  if  ($mfonttxt eq "unicode")
  {
     $mtxt = decode_utf8( $mtxt );
  }
  else
  {
     $mtxt = decode( "cp1252", $mtxt );
  }

  $mlen = length($mtxt);
  $result->insert($mloc, $mtxt);
  return $result->index("$mloc + $mlen chars");
}

sub insertE {
  my($mloc, $txt) = @_;

#  print "E |$txt|\n";
  $len = length($txt);
  $result->insert($mloc, $txt, "english");
  return $result->index("$mloc + $len chars");
}

sub convertEinsert {
  my ($start, $end) = @_;

  my $mloc = $start;
  $result->tagRemove("english", $start, $end);
  $txt = $edit->get($start, $end);

  if ($mfonttxt ne 'unicode') {
    if ($txt =~ s/^([^{<]*)(}|(>))//s) {
      #print "\$1 = $1; \$3 = $3\n";
      $mloc = insertE($mloc, $3 ? $1.$3 : $1);
    }

    while ($txt =~ s/(}|(>))?(.*?)({|(<))([^}>]*)//s) {
      $mloc = insertE($mloc, $2) if $2;
      $mloc = insertM($mloc, $3);
      $mloc = insertE($mloc, $5 ? $5.$6 : $6);
    }

    $txt =~ s/^}//s;
  }
  else {
    if ($txt =~ /{[^}]*$/s) {
      $txt .= '}'
    }
  }
  $mloc = insertM($mloc, $txt);
}

sub outputToFile {
  # not used now - this is for future. See send2Browser for comments.

  my ($input, $cmd, $out_file) = @_;

  open(OUTFH, ">$out_file");

  $charset = ($mfonttxt eq 'unicode')? 'utf-8' : 'cp1252';

  print OUTFH <<EOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="ml">
  <head>
    <meta http-equiv="Content-Type" content="text/html;charset=$charset"/>
    <title>Varamozhi Editor: Text Exported for Print or Save</title>
  </head>
  <body>
     <p>
EOF
  close OUTFH;

  open(OUTFH, "|$cmd >> $out_file");
  print OUTFH $input;
  close OUTFH;

  open(OUTFH, ">>$out_file");
  print OUTFH <<EOF;
    </p>
  </body>
</html>
EOF
  close OUTFH;
}


sub outputToFile_old {
  my ($input, $cmd, $out_file) = @_;

  debug("cmd=$cmd out_file=$out_file");

  open2(*ReaderFH, *WriterFH, $cmd);

  # store the current value of handles
  my $tmp_reader = $reader;
  my $tmp_writer = $writer;
  $reader = *ReaderFH;
  $writer = *WriterFH;


  open OUTFH, ">", $out_file;

  if ($currRefreshPeriod)
    {
      print OUTFH <<EOF;
<head>
<meta http-equiv=refresh content=$currRefreshPeriod>
</head>
EOF
    }
  print OUTFH convert($input);
  close OUTFH;

  close ReaderFH;
  close WriterFH;

  # restore back
  $reader = $tmp_reader;
  $writer = $tmp_writer;
}

sub writeFile {
  my ($input, $file) = @_;

  open FH, ">$file";
  print FH $input;
  close FH;

  }

sub bgsystem
  {
    my ($cmd) = @_;

    # this crashes in Windows
    #if (fork() == 0)
    #  {
    #     exec("$cmd");
    #  }

    system("$cmd");
  }

sub openBrowser {
  my ($file, $dir) = @_;

  if (($file !~ /http/) && $windows && ((Win32::GetOSVersion())[4] < 2)) {
    $cmd = "$browser \"$dir\"";
  }
  else {
    $cmd = "$browser \"$file\"";
  }
  #print "cmd = |$cmd|\n";
  bgsystem($cmd);

  if ($windows && ((Win32::GetOSVersion())[4] < 2)) {
    $message->configure( -text => "Please double click on \"$file\".",
                         -title => "HTML Export" );
    $message->Show();
  }
}


local $currOutputCmd;
local $refreshTimerId;
local $autoSaveTimerId;
local $currRefreshPeriod;

sub autoSave {

  context(0);
  my $txt = $edit->get("0.0", "end");

  debug("autosaved to $autosavefile");
  writeFile($txt, $autosavefile);
}

sub autoSaveStart {

  if (-f $autosavefile)
    {
      startWithFile($autosavefile);
    }
  debug("autosavefile=$autosavefile  autoSavePeriod=$autoSavePeriod");

  $autoSaveTimerId = $top->repeat($autoSavePeriod * 1000, sub { autoSave(); }) if (!$autoSaveTimerId && $autoSavePeriod != 0);
}

sub stopRefreshExport {

  #print "STOP refreshing refreshTimerId=$refreshTimerId currRefreshPeriod=$currRefreshPeriod\n";


  $currRefreshPeriod = 0; # means no refresh tag
  $top->afterCancel($refreshTimerId);
  undef $refreshTimerId;

  refreshExport();
}

sub refreshExport {

  context(0);
  my $txt = $edit->get("0.0", "end");


#  my $cmd = "$prog_args > $tmpfile";
  #print "$cmd\n";
#  open(FD, "|$cmd" );
#  print FD "$txt\n";
#  close(FD);

  #print "refreshing cmd=$currOutputCmd tmpfile=$tmpfile txt=$txt\n";

  outputToFile($txt, $currOutputCmd, $tmpfile);
}

sub send2Browser {

  $currOutputCmd = $_[-1];

  $currRefreshPeriod = $refreshPeriod;

  # refresh from editor side is disabled:
  # . not very useful because of the delay; even 1sec is too long!
  # . some IE does not do browser refresh
  # . some MSWindows does not do process '|'. So can not use outputToFile_new(). But outputToFile() does not
  #   kill the process even after the close(). So after 5min refreshes, fork resource becomes unavailable.

  #$refreshTimerId = $top->repeat($currRefreshPeriod * 1000, sub { refreshExport(); }) if (! $refreshTimerId);
  #print "started timer with Id=$refreshTimerId tmpfile=$tmpfile tmp_dir=$tmp_dir period=$currRefreshPeriod\n";


  refreshExport();
  openBrowser($tmpfile, $tmp_dir);

}

sub openHTML {
  if ($mfonttxt eq 'unicode') {
    send2Browser("$uprog -u");
  }
  else {
    send2Browser("$prog -h");
  }
}

sub getFontDisplayName {
  my ($fontshortname) = @_;

  #if ($fontshortname eq "unicode")
  #  {
  #    return "Unicode to Manglish";
  #  }
  #else
    {
      $mfonthash{$fontshortname};
    }

}

sub modify_lock_for_unicode
  {

    if ($mfonttxt eq 'unicode')
        {
          $oldLockMode = $lockMode;
          $lockMode    = 'unlocked';
        }
    elsif ($oldmfonttxt && $oldmfonttxt eq 'unicode')
      {
        # putting back what the old lock mode have been

        $lockMode = $oldLockMode;
      }

    $oldmfonttxt = $mfonttxt;
  }

sub show_tip_for_unicode
  {
    if ($mfonttxt eq 'unicode')
      {
        show_tip(
"Editor cannot display Unicode characters. This Font option is for converting UTF8 to Manglish only. For Unicode output in a browser, do File > Export to UTF8
");
      }
    else
      {
        show_tip("");
      }
  }



sub discover_font_longname
  {
    my ($prog) = @_;

    my $longname = `$prog -f`;
    chomp $longname;

    return $longname;
  }

sub discover_font_longname_list
  {
    my $f;
    my $pat;

    $pat  = "${progpath}malvi_mozhi_*";

    debug( "progpath = ${progpath}");
    debug( "pat = ${pat}");

    foreach $f (glob $pat)
      {
        debug( "f = ${f}");
        debug( "windows = ${windows}");
        if ($f !~ /\.o$/ && (($f =~ /\.exe$/) || (!$windows && $f !~ /\.exe$/)))
          {
            $f =~ /malvi_mozhi_([^.]+)/;
            my $shortname = $1;

            $mfonthash{$shortname} = discover_font_longname($f);

            #print "short = $shortname long = ".$mfonthash{$shortname}."\n";
          }
      }

    $mfonttxt = (sort keys %mfonthash)[0] if (!$mfonttxt || !$mfonthash{$mfonttxt});

  if (! $mfonttxt )
    {
      $message->configure( -text => 
                           $unix?
                           "Please execute 'make FONT=unicode; make FONT=mathrubhumi' and reinvoke the editor" :
                           "Please reinstall varamozhi package or notify the problem to cibucj\@gmail.com",
                           -title => "Font Module missing" );
      $message->Show();
      exit;
    }

  }



sub debugFlag
  {
    return  ($debug)? " -g" : "";
  }

sub extra_args
  {
    return  ($extra_args)? " $extra_args" : "";
  }



sub changeFont {

  $prog  = "${progpath}malvi_mozhi_$mfonttxt";
  $rprog = "${rprogpath}lamvi_$mfonttxt";
  $uprog = "${progpath}malvi_mozhi_unicode";

  debug("prog = $prog, rprog = $rprog, uprog = $uprog");

  if (! -f correctExeFilename($prog) || ! -f correctExeFilename($rprog) || ! -f correctExeFilename($uprog) )
    {
      $message->configure( -text => 
                           "One of the following is not executable:\n" .
                           correctExeFilename($prog)  . "\n" .
                           correctExeFilename($rprog) . "\n" .
                           correctExeFilename($uprog) . "\n",
                           -title => "Executable missing" );
      $message->Show();
      exit;
    }

  $prog  .= debugFlag() . extra_args();
  $rprog .= debugFlag();
  $uprog .= debugFlag() . extra_args();



  #modify_lock_for_unicode();
  #show_tip_for_unicode();


  context(0);
  #print "changeFont $mfonttxt\n";
  $mfont = $top->fontCreate(-family => $mfonthash{$mfonttxt}, #getFontLongName($mfonttxt),
			    -size   => get_mfontsize_from_e() );
  $result->configure( -font => $mfont );

  debug("prog = $prog, rprog = $rprog, uprog = $uprog");

  open2(*ReaderE2M, *WriterE2M, "$prog" );
  open2(*ReaderM2E, *WriterM2E, "$rprog" );

  whole();

  saveConfig();
  setTitle();
}

sub resizeFont {

  my $inc = $_[-1]; #last param to avoid use of dummy

  if ($inc) {
    $efontsize += 2 * int( ($efontsize+2)/10 );
  }
  else {
    $efontsize -= 2 * int( $efontsize/10 );
  }
  my $mfontsize = get_mfontsize_from_e();

  
  $mfont->configure(-size => $mfontsize);
  $efont->configure(-size => $efontsize);

  saveConfig();
  setTitle();
}

sub get_mfontsize_from_e {
  $adjust = 0;
  if ($mfonttxt eq 'unicode') {
     $adjust = -1
  }
  elsif ($mfonttxt eq 'mathrubhumi') {
     $adjust = 4 
  }
  
  return $efontsize + $adjust + 1
}

sub firstTimeFontReminder {
  if ($firsttime) {
    $message->configure( -text => "Please install fonts from varamozhi\n".
                         "installation directory by selecting\n\n".
                         "'Start->Settings->Control Panel->\n".
                         "Fonts->File->Install New Font'",
                         -title => "Did you install fonts?" );
    $message->Show();
    $firsttime = 0;
    saveConfig();
  }
}


sub changeLockMode {
  context(0);
  saveConfig();

  return;
}

sub changeArgs {
  $extra_args = " $usrArgBasic $usrArgDebug";
  changeFont();
  return;
}


my $types = [
	     ['Text Files',       ['.txt', '.text']],
	     ['All Files',        '*',             ],
	    ];

sub correctFilename
  {
    my ($file) = @_;

    $file = Win32::GetFullPathName($file) if ($windows);

    return $file;
  }

sub correctExeFilename
  {
    my ($file) = @_;

    $file = Win32::GetFullPathName($file) . ".exe" if ($windows);

    return $file;
  }

sub setFileVars {
  my ($file) = @_;

  #getOpenFile and getSaveFile return unix style paths
  #they have to be converted to windows style without
  #any trailing slashes after directory name.
  $file = correctFilename($file);

  $curdir = dirname($file);
  $savefilename = $file;

  #print "file=|$file| save=|$savefilename| dir=|$curdir|\n";
  saveConfig();
  setTitle();
}

sub saveUnsaved {
  my ($ans) = ("");

  if ($unsaved && ($ans = $unsaved_dialog->Show()) eq "Yes") {
    saveFile();
  }

  return ($ans ne "Cancel"); #return true if ans is not Cancel
}

sub openFile{
#  print "O $curdir\n";

  return if (!saveUnsaved());
  my $file = $top->getOpenFile( -initialdir => $curdir,
				-defaultextension => ".txt",
				-filetypes => $types );
  return if (!$file);
  setFileVars( $file );

  startWithFile($savefilename);
}

sub startWithFile {

  my ($file) = @_;

  open(FD, $file);
  my $txt = join "", <FD>;
  close(FD);

  $edit->delete('0.0', 'end');
  $edit->insert('end', $txt);
  whole();
}

sub saveFile{


  if (!$savefilename) {
#    print "S $curdir\n";
    my $file = $top->getSaveFile( -initialdir => $curdir,
				  -initialfile => $savefilename,
				  -defaultextension => ".txt",
				  -filetypes => $types );
    return if (!$file);
    setFileVars( $file );
  }

  context(0);
  my $txt = $edit->get('0.0', 'end');
  open(FD, ">$savefilename");
  print FD $txt;
  close(FD);
  $unsaved = 0;

  unlink($autosavefile);

  #print "savefile unsaved = $unsaved\n";

}

sub saveAsFile{
#  print "SA dir = |$curdir| file = |$savefilename| \n";
  my $file = $top->getSaveFile( -initialdir => $curdir,
				-initialfile => $savefilename,
				-defaultextension => ".txt",
				-filetypes => $types  );
  return if (!$file);
  setFileVars( $file );
  saveFile();
}

sub safeExit {
  return if (!saveUnsaved());
  exit;
}

sub about {
  $about_dialog->Show()
}

sub show_tip
  {
    my ($msg) = @_;

    $nls = nnewlines($msg);
    $tip_widget->configure(-height => ($nls + 1));

    $tip_widget->delete('0.0', 'end');
    $tip_widget->insert('0.0', $msg);


    #$tip_widget->configure( -text => $msg );
  }

sub colorpicker
  {
    $color = $top->chooseColor(-initialcolor => 'gray',
                             -title => "Choose color");
    print "color=$color\n";
    $mwin->configure(-bg => $color);
  }

#---------------------------------------------
# context switch between English and Malayalam
#---------------------------------------------
sub context_sans_lock {
  my ($newmode) = @_;
  #print "newmode = $newmode; adv = $advanced\n";
  return if ($newmode == $advanced);
  $advanced = $newmode;

  if ($advanced) {
        $edit   = $mwin;
        $result = $ewin;
        $reader = *ReaderM2E;
        $writer = *WriterM2E;
        $convertInsert = \&convertMinsert;
  }
  else {
        $edit   = $ewin;
        $result = $mwin;
        $reader = *ReaderE2M;
        $writer = *WriterE2M;
        $convertInsert = \&convertEinsert;
  }
}


sub context {
  my ($newmode) = @_;

  if (($newmode == 1) && ($lockMode ne 'unlocked'))
    {
      show_tip(
"Malayalam to Manglish conversion example: Lock > Unlocked enables editing in Malayalam window; set Font > ML-TTKarthika; paste text from deepika.com in right window.
") ;

      $mwin->configure(-state => 'disabled');
    }
  else
    {
      $mwin->configure(-state => 'normal');

      show_tip("") if ($mfonttxt ne 'unicode');
    }

  context_sans_lock($newmode);
}


#----------------------------------
# size and resize
#----------------------------------

#old method
#$height = int(200/$fontsize);
#$width  = int(500/$fontsize);


sub storeSize{
  my ($wid) = @_;

  #this is disabled because
  # I didn't find any way to
  # configure Text/Scrolled widget with pixel height/width.
  # a way to get the character height/width of a resized Text Widget is also fine.
  return;

  $height_chars     = $wid->height/13;
  $ewin_width_chars = $ewin->width/7;
  $mwin_width_chars = $mwin->width/9;


  saveConfig();
}


#----------------------------------
# print key event
#----------------------------------

sub print_keysym {
    my($widget) = @_;
    my $e = $widget->XEvent;    # get event object
    my($keysym_text, $keysym_decimal) = ($e->K, $e->N);
    print "keysym=$keysym_text, numeric=$keysym_decimal\n";
}

#----------------------------------
# message in debug console
#----------------------------------

print <<EOF;
Debug Console
-------------
Please use the other window for writing Malayalam.
Questions? please see http://varamozhi.sf.net or email to cibucj\@gmail.com

EOF


#####################################
#
# form the layout
#
#####################################

$top = MainWindow->new( -title => "Varamozhi Editor" );

#------------------------------------------
# setup icon
#------------------------------------------
#print "$icon_file\n";
$top->Photo('icon', -file => $icon_file );
#$top->Icon(-image => 'icon'); #alternate option
$top->update;
$top->iconimage('icon');

#------------------------------------------
# dialogs
#------------------------------------------
$unsaved_dialog = $top->Dialog(
			       -text => 'Save File?',
			       -bitmap => 'question',
			       -title => 'Save File Dialog',
			       -default_button => 'Yes',
			       -buttons => [qw/Yes No Cancel/]
			      );

$about_dialog = $top->Dialog(
			     -text => "
Varamozhi Editor
version $version

by Cibu C J

Contact by Gmail id: cibucj (mail or Google Talk)

http://varamozhi.sf.net",
			     -justify => "center",
			     -bitmap => 'info',
			     -title => "About",
			     -default_button => "OK",
			     -buttons => [qw/OK/]
			    );

$message = $top->Dialog(-justify => "left",
                        -bitmap => 'info',
                        -title => "Message",
                        -default_button => "OK",
                        -buttons => [qw/OK/]
                       );
#------------------------------------------
# font objects
#------------------------------------------

discover_font_longname_list();


$efont = $top->fontCreate(-family => "Courier New",
			  -size => $efontsize);

#------------------------------------------
# Menu Bar
#------------------------------------------

my $toplevel = $top->toplevel;
my $menubar = $toplevel->Menu(-type => 'menubar',
			      -relief => 'raised',
			      -bd => 4
			     );
$toplevel->configure(-menu => $menubar);

# File Menu
my $f = $menubar->cascade(-label => '~File', -tearoff => 0);
$f->command(-label => 'Open ...',                                          -command => \&openFile);
$f->command(-label => 'Save',                    -accelerator => "$mod+s", -command => \&saveFile);
$f->command(-label => 'Save As ...',                                       -command => \&saveAsFile);
$f->separator;
$f->command(-label => 'HTML Export to print',    -accelerator => "$mod+w", -command => \&openHTML);
#$f->command(-label => 'Stop export refresh',     -accelerator => "$mod+r", -command => \&stopRefreshExport);
$f->separator;
$f->command(-label => 'Refresh',                 -accelerator => "$mod+l", -command => \&whole);
$f->command(-label => 'Exit',                    -accelerator => "$mod+q", -command => \&safeExit);

# Font Menu
my $g = $menubar->cascade(-label => '~Font');
foreach $f (sort(keys %mfonthash))
 {
   $g->radiobutton( -label => getFontDisplayName($f),
                    -value => $f,
                    -variable => \$mfonttxt,
                    -command => \&changeFont);

   #print "label=" . getFontDisplayName($f) . " value=$f\n";
 }

$g->separator;
$g->command(-label => 'Smaller', -accelerator => "$mod -", -command => [\&resizeFont, 0] );
$g->command(-label => 'Larger',  -accelerator => "$mod +", -command => [\&resizeFont, 1] );


# Option Menu
my $o = $menubar->cascade(-label => '~Options');
my $ol = $o->checkbutton( -label    => "Unlock Malayalam Pane",
		 -onvalue  => 'unlocked',
		 -offvalue => 'manglish2malayalam',
		 -variable => \$lockMode,
		 -command  => \&changeLockMode);

my $ob = $o->checkbutton( -label    => "Limit to Basic Mozhi",
		 -onvalue  => '-b',
		 -offvalue => '',
		 -variable => \$usrArgBasic,
		 -command  => \&changeArgs);

my $og = $o->checkbutton( -label    => "Enable Debug",
		 -onvalue  => '-g',
		 -offvalue => '',
		 -variable => \$usrArgDebug,
		 -command  => \&changeArgs);



# Help Menu
my $h = $menubar->cascade(-label => '~Help', -tearoff => 0);
$h->command(-label => 'Lipi',   -command => [\&openBrowser, $help_lipi_file, $help_dir]);
$h->command(-label => 'Online', -command => [\&openBrowser, "http://varamozhi.sourceforge.net"]);
$h->separator;
$h->command(-label => 'About',  -command => \&about);

#------------------------------------------
# Text widgets
#------------------------------------------

#print "ewin_width_chars = $ewin_width_chars\n";
#print "mwin_width_chars = $mwin_width_chars\n";
#print "height_chars     = $height_chars\n";

$textframe = $top->Frame()->pack(-fill => 'both', -expand => 1);
$adj = $textframe->Adjuster();

$lframe = $textframe->Frame()->pack(-fill => 'both', -expand => 1, -side => 'left');

$lframe->Label(-text => 'Manglish window')->pack(-anchor => 'nw');

$ewin = $lframe->Scrolled("TextUndo",
                          -font       => $efont,
                          -takefocus  => 1,
                          -scrollbars => "e",
                          -height     => $height_chars,
                          -width      => $ewin_width_chars,
                          #-bg         => '#efdee7acce49 ',
                         )->pack( -fill => 'both', -expand => 1);


$adj->packAfter($lframe, -side => 'left');

# Malayalam Text widget

$rframe = $textframe->Frame()->pack(-fill => 'both', -expand => 1, -side => 'left');

$rframe->Label(-text => 'Malayalam window')->pack(-anchor => 'nw');

$mwin = $rframe->Scrolled("TextUndo",
                          -scrollbars => "e",
                          -height     => $height_chars,
                          -width      => $mwin_width_chars,
                          #-bg         => '#efdece49ce49',
                         )->pack( -fill => 'both', -expand => 1);

$ewin->focus;




# tip showing widget
$tip_widget = $top->ROText(-height => 0, -background => 'grey')->pack( -fill => 'both');



#------------------------------------------
# configure highlights
#------------------------------------------
$mwin->tagConfigure("english",
		    -font => $efont);
$mwin->tagConfigure("mcurrent",
		    -background => "yellow",
		    -foreground => "brown"
		   );

$ewin->tagConfigure("mcurrent",
		    -background => "yellow",
		    -foreground => "brown"
		   );

#------------------------------------------
# set default font & values
#------------------------------------------
context(0); #default mode is not advanced
#firstTimeFontReminder();

my $g_menu = $g->cget(-menu);
$g_menu->invoke(getFontDisplayName($mfonttxt));

autoSaveStart();

#------------------------------------------
# event call backs
#------------------------------------------


# <Control_L> is simple Control key press
for $event ("Key-Left", "Key-Right", "Key-Up", "Key-Down", "Key-End", "Key-Begin", "Button-1", "Control-c", "Control_L") {
  $ewin->bind( "<$event>", [\&movekey, 0] );
  $mwin->bind( "<$event>", [\&movekey, 1] );
}

for $event ("Key-Return",  "Control-v", "Control-x") {
  # "Key-BackSpace" "Key-Delete" "Any-Button" removed to improve speed
  $ewin->bind( "<$event>", [\&wholekey, 0] );
  $mwin->bind( "<$event>", [\&wholekey, 1] );
}

$ewin->bind( "<Any-Key>", [\&onelinekey, 0] );
$mwin->bind( "<Any-Key>", [\&wholekey,   1] );


#to print any key name
#$ewin->bind('<KeyPress>' => \&print_keysym);


# these bindings can not be moved to $top because, <Any-Key> will take effect first
# and control char will be copied to Malayalam window.

# 'g l m r q s u w' are the available control chars
# which does not have any pre-assigned meaning

$ewin->bind( "<$mod-s>", sub { delCurrChar(); saveFile();    } );
$mwin->bind( "<$mod-s>", sub { delCurrChar(); saveFile();    } );

$ewin->bind( "<$mod-q>", sub { delCurrChar(); safeExit();    } );
$mwin->bind( "<$mod-q>", sub { delCurrChar(); safeExit();    } );

$ewin->bind( "<$mod-w>", sub { delCurrChar(); openHTML();    } );
$mwin->bind( "<$mod-w>", sub { delCurrChar(); openHTML();    } );

$ewin->bind( "<$mod-r>", sub { delCurrChar(); stopRefreshExport();    } );
$mwin->bind( "<$mod-r>", sub { delCurrChar(); stopRefreshExport();    } );

$ewin->bind( "<$mod-l>", sub { delCurrChar(); whole();    } );
$mwin->bind( "<$mod-l>", sub { delCurrChar(); whole();    } );

$ewin->bind( "<$mod-a>", sub { $ewin->tagAdd("sel", '0.0', 'end'); } ); #'sel' special tag for selection
$mwin->bind( "<$mod-a>", sub { $mwin->tagAdd("sel", '0.0', 'end'); } );

$ewin->bind('<Configure>' => \&storeSize);
$mwin->bind('<Configure>' => \&storeSize);


#bindings for accelerators
$top->bind("<$mod-minus>" => [\&resizeFont, 0]);
$top->bind("<$mod-plus>"  => [\&resizeFont, 1]);


#catch the window kill
$top->protocol('WM_DELETE_WINDOW', \&safeExit);

Tk::MainLoop;

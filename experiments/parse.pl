#!/usr/bin/perl

use strict; 
use warnings; 

# the big hash contains all the data over all files
# keys are strings of the game name 
# values are references to hashs of strings to strings of the form "alg1-alg2" => "wins1-draws-$losses1"
my %bigHash = (); 

my @algorithms = ("ductmax", "ducb1t", "exp3", "rm", "suctmax"); 

my @games = ( "Battle", "BiddingTicTacToe", "Chinook", "Goofspiel", "OshiZumo", "PawnWhopping", "RacetrackCorridor", "Runners", "Tron"); 

my @csvfiles = ("ductmax_vs_ducb1t.csv", "ductmax_vs_exp3.csv", "ductmax_vs_rm.csv", "ductmax_vs_suctmax.csv", 
  "exp3_cs_suctmax.csv", "exp3_vs_rm.csv", "rm_cs_suctmax.csv"); 

my $NGAMES = 500;

sub addinfo { 
  my ($game, $alg1, $alg2, $wins, $draws, $losses) = @_;


  if (not defined($bigHash{$game})) { 
    my %innerHash = (); 
    $bigHash{$game} = \%innerHash;
  }

  my $innerref = $bigHash{$game}; 

  my $key = "$alg1-$alg2";
  my $entry = "$wins-$draws-$losses"; 

  my $revkey = "$alg2-$alg1";
  my $reventry = "$losses-$draws-$wins";
  
  print "Adding $game $key $entry\n";
  print "Adding $game $revkey $reventry\n";
  
  if (($wins + $draws + $losses) != $NGAMES) { die "wins+draws+losses do not add up to $NGAMES!"; }

  $$innerref{$key} = $entry;
  $$innerref{$revkey} = $reventry;

}

# subroutine.
# parses a single .csv file and adds all the data to the big hash
sub parsefile { 
  my $filename = shift; 
  open(FILE, '<', $filename) or die "Cannot open $filename";
  print "Parsing $filename ...\n";

  # get the player types and check if they're valid 

  $filename =~ s/\.csv//g; 
  my @fparts = split('_', $filename); 

  my $leftplayer = $fparts[0]; 
  my $rightplayer = $fparts[2]; 
  
  if (not ($leftplayer ~~ @algorithms)) { die "$leftplayer not a valid algorithm!"; }
  if (not ($rightplayer ~~ @algorithms)) { die "$leftplayer not a valid algorithm!"; }

  # now parse the file line-by-line
 
  my $rows = 0; 
  my $cols = 0; 
  my %linedata = ();  # key: "row-col" => entry

  for my $line (<FILE>) { 
    chomp($line); 

    my $commas = ($line =~ s/\,/\,/g);
    my @parts = split(',', $line); 
    
    if ($cols == 0) { $cols = $commas + 1; } 

    # split removes empty trailing parts!
    #if (scalar(@parts) != $cols) { die "inconsistent column counts in $filename."; }

    for (my $c = 0; $c < $cols; $c += 1) { 
      my $key = "$rows-$c"; 
      my $value = ""; 

      if ($c < scalar(@parts)) { $value = $parts[$c]; }

      $linedata{$key} = $value; 
    }

    $rows += 1;
  }

  close(FILE); 

  # first: look for the column containing the name of a game
  my $gameCol = -1;
  my $done = 0; 

  for (my $r = 0; $r < $rows and $done == 0; $r += 1) { 
    for (my $c = 0; $c < $cols; $c += 1) { 
      my $key = "$r-$c"; 
      my $entry = $linedata{$key};
      
      if ($entry ~~ @games) { 
        $gameCol = $c; 
        print "found game column, entry = $entry, col = $gameCol\n"; 
        $done = 1; 
        last; 
      }
    }
  }

  # now, fill everything
  my $curGame = "";
  my $curWins = 0; 
  my $curLosses = 0; 
  my $curDraws = 0; 

  for (my $r = 0; $r < $rows; $r += 1) { 
    my $key1 = "$r-$gameCol"; 
    my $key2 = "$r-" . ($gameCol+1); 
    my $entry1 = $linedata{$key1}; 
    my $entry2 = $linedata{$key2}; 

    if ($entry1 ~~ @games) { 

      if (not($curGame eq "")) { 
        addinfo($curGame, $leftplayer, $rightplayer, $curWins, $curDraws, $curLosses); 
      }

      $curGame = $entry1; 
      print "Parsing values for $curGame\n";
    }

    if ($entry1 =~ m/Wins/) { 
      if ($curGame eq "") { die "curGame not set!"; }
      $curWins = $entry2;
    }
    elsif ($entry1 =~ m/Draws/) { 
      if ($curGame eq "") { die "curGame not set!"; }
      $curDraws = $entry2;
    }
    elsif ($entry1 =~ m/Losses/) { 
      if ($curGame eq "") { die "curGame not set!"; }
      $curLosses = $entry2;
    }
  }

  if (not($curGame eq "")) { 
    addinfo($curGame, $leftplayer, $rightplayer, $curWins, $curDraws, $curLosses); 
  }

  print "... done parsing $filename.\n\n";
}

#
# Table A: each algorithm vs. ductmax in each game
# Rows: games
# Cols: algs (other than ductmax)
#
sub print_tableA { 
   
  print "                             ";
  for (my $a = 0; $a < scalar(@algorithms); $a += 1) { 
    my $alg = $algorithms[$a]; 
    if ($alg eq "ductmax") { next; }
    print "$alg\t";
  }
  print "\n"; 

  for (my $g = 0; $g < scalar(@games); $g += 1) { 
    my $game = $games[$g]; 
    my $hashref = $bigHash{$game}; 

    printf("%25s     ", $game);  

    for (my $a = 0; $a < scalar(@algorithms); $a += 1) { 
      my $alg = $algorithms[$a]; 
      if ($alg eq "ductmax") { next; }

      my $key = "$alg-ductmax";
      my $entry = $$hashref{$key}; 

      my ($wins, $draws, $losses) = split('-', $entry); 
      my $rate = ($wins + 0.5*$draws) / ($NGAMES * 1.0); 
      printf("%3.2f\t", $rate); 
    }

    print "\n";
  }
}

### start main part of the program

# Parse all the files, adding all the info
#parsefile("ductmax_vs_ducb1t.csv"); 

for my $filename (@csvfiles) { 
  parsefile($filename); 
}

### produce each table

print_tableA();




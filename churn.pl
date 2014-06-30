#!/usr/bin/env perl
use strict;
use warnings;
use Text::CSV_XS;
use Data::Dump qw( dump );

my @X = qw(0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0);
my @Y = qw(1.25 1.2 1.15 1.1 1.05 1 0.95 0.9 0.85 0.8 0.75);
my @Z = qw(12 13 14 15 16 17 18 20 22 25 27 30);
dump \@X;
dump \@Y;
my $file = shift(@ARGV) or die "$0 file.csv";
my @Ws;
my $csv = Text::CSV_XS->new( { binary => 1, auto_diag => 1 } );
open my $fh, "<:encoding(utf8)", $file or die "can't open $file: $!";
my $i = 0;
my $x = 0;
my $y = 0;
my $z = 0;
ROW: while ( my $row = $csv->getline($fh) ) {

    #dump $row;

    # 11 rows per z-value
    if ( $row->[0] eq '' ) {
        next ROW;
    }
    $x = 0;
    for my $cell (@$row) {
        next unless $cell =~ m/^0\.\d\d\d\d+/;
        push @Ws,
            {
            w => $cell,
            x => $X[ $x++ ],
            y => $Y[$y],
            z => $Z[$z],
            };
    }

    $y++;    # ROW == y

    if ( ++$i == 11 ) {
        $i = 0;
        $x = 0;
        $y = 0;
        $z++;
    }

}
close $fh;

#dump \@Ws;

# (0.392/M-0.2253)LN(x)+(0.001563M-0.07114)y^2+(0.0064-0.003905M)y-0.000727M+0.3773

my $A = 0.44868;
my $B = 0.228363;
my $C = 0.0016869;
my $D = 0.070613;
my $E = 0.006076;
my $F = 0.0039767;
my $G = 0.0007576;
my $H = 0.375929;

sub equation {
    my ( $w, $x, $y, $z ) = @_;
    my $eq
        = ( 0.392 / $z - 0.2253 ) * log($x)
        + ( 0.001563 * $z - 0.07114 ) * $y * $y
        + ( 0.0064 - 0.003905 * $z ) * $y
        - 0.000727 * $z + 0.3773;
    my $err = abs( $w - $eq );
}


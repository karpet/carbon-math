#!/usr/bin/env perl
use strict;
use warnings;
use Text::CSV_XS;
use Data::Dump qw( dump );

#
# usage:
#        perl churn.pl file.csv
#
#

my $file = shift(@ARGV) or die "$0 file.csv";
my @Ws;
my $csv = Text::CSV_XS->new( { binary => 1, auto_diag => 1 } );
open my $fh, "<:encoding(utf8)", $file or die "can't open $file: $!";
ROW: while ( my $row = $csv->getline($fh) ) {

    #dump $row;
    my ( $x, $y, $z, $w ) = @$row;
    push @Ws, { x => $x, y => $y, z => $z, w => $w };

}
close $fh;

#dump \@Ws;

# (0.392/M-0.2253)LN(x)+(0.001563M-0.07114)y^2+(0.0064-0.003905M)y-0.000727M+0.3773

my %C = (
    A => 0.592,
    B => -0.236,
    C => 0.0017,
    D => -0.11,
    E => -0.004,
    F => 0.0729,
    G => -0.00089,
    H => 0.339,
    I => 0.0000049,
    J => .000005,
);
my %Offset = (
    A => 0,
    B => 0,
    C => 0,
    D => 0,
    E => 0,
    F => 0,
    G => 0,
    H => 0,
    I => 0,
    J => 0,
);

sub churn {
    my ( $x, $y, $z, $w ) = @_;
    my $eq
        = ( $C{A} / ($z) + $C{B} ) * log($x)
        + ( $C{I} * ($z) + $C{J} ) * ( $x**7 )
        + ( $C{C} * ($z) + $C{D} ) * ( $y**2 )
        + ( $C{E} * ($z) + $C{F} ) * $y
        + $C{G} * $z
        + $C{H};
    my $err = ( $w - $eq )**2;

    #printf( "%s = %s\n", dump( \@_ ), $err );
    return $err;
}

sub churn_loop {
    my ($prev_err_sum) = @_;

    # apply $mv against each value in %C
    my @errs    = ();
    my $err_sum = 0;
    for my $k ( ( 'A' .. 'J' ) ) {
        my $pre_move = $C{$k};
        for my $move ( ( 0 .. 7 ) ) {
            my $down = 1;
            while ( $down == 1 ) {
                $err_sum = 0;
                my $ck_temp = $C{$k};
                $C{$k} += ( 10**( $Offset{$k} - $move ) );
                for my $row (@Ws) {
                    $err_sum += churn( map { $row->{$_} } qw( x y z w ) );
                }
                if ( $err_sum < $prev_err_sum ) {
                    $prev_err_sum = $err_sum;
                }
                else {
                    $down = 0;
                    $C{$k} = $ck_temp;
                }

                #printf ( "$C{$k}  $err_sum\n");
            }
            $down = 1;
            while ( $down == 1 ) {
                $err_sum = 0;
                my $ck_temp = $C{$k};
                $C{$k} -= ( 10**( $Offset{$k} - $move ) );
                for my $row (@Ws) {
                    $err_sum += churn( map { $row->{$_} } qw( x y z w ) );
                }
                if ( $err_sum < $prev_err_sum ) {
                    $prev_err_sum = $err_sum;
                }
                else {
                    $down = 0;
                    $C{$k} = $ck_temp;
                }

                #printf ( "$C{$k}  $err_sum\n");
            }
        }
        if ( $C{$k} != $pre_move ) {
            $Offset{$k}
                = int( log( abs( $pre_move - $C{$k} ) ) / log(10) ) + 1;
        }
        push @errs, $err_sum;
    }

    #dump \@errs;
    return $prev_err_sum;
}

my $print_sum  = 1;
my $print_diff = 1;
my $err_sum    = churn_loop(1000);
printf( "err_sum=%.8f\n", $err_sum );
printf( "%s\n",           dump( \%C ) );

my $loops = 0;
while ( abs($print_diff) > 0 ) {
    my $before = $err_sum;
    $err_sum = churn_loop($err_sum);
    if ( $before < $err_sum ) {
        $err_sum = churn_loop($err_sum);
    }
    if ( $loops++ % 1 == 0 ) {
        $print_diff = $print_sum - $err_sum;
        printf( "loops = %d\n",       $loops );
        printf( "  err_sum = %.8f\n", $err_sum );
        printf( "  err_dif = %.8f\n", $print_diff );
        printf( "%s\n",               dump( \%C ) );
        $print_sum = $err_sum;
    }
}

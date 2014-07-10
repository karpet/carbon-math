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
    A => 0.645701,
    B => -0.2397,
    C => 0.001689,
    D => -0.070588,
    E => -0.003976,
    F => -0.006069,
    G => -0.0007576,
    H => 0.3759,
);
my %MV = (
    A => 0.001,
    B => 0.001,
    C => 0.001,
    D => 0.001,
    E => 0.001,
    F => 0.001,
    G => 0.001,
    H => 0.001,
);

sub churn {
    my ( $x, $y, $z, $w ) = @_;
    my $eq
        = ( $C{A} / $z + $C{B} ) * log($x)
        + ( $C{C} * $z + $C{D} ) * $y * $y
        + ( $C{E} * $z + $C{F} ) * $y
        + $C{G} * $z
        + $C{H};
    my $err = ( $w - $eq )**2;

    #printf( "%s = %s\n", dump( \@_ ), $err );
    return $err;
}

sub churn_loop {
    my ($prev_err_sum) = @_;

    # apply $mv against each value in %C
    my @errs = ();
    for my $k ( ( 'A' .. 'H' ) ) {
        my $err_sum = 0;
        $C{$k} += ( $MV{$k} );
        for my $row (@Ws) {
            $err_sum += churn( map { $row->{$_} } qw( x y z w ) );
        }
        if ( $err_sum > $prev_err_sum ) {
            my $err_sum = 0;
            $C{$k} += -( $MV{$k} * 2 );
            for my $row (@Ws) {
                $err_sum += churn( map { $row->{$_} } qw( x y z w ) );
            }

            # last sanity check
            if ( $err_sum > $prev_err_sum ) {
                $C{$k} += ( $MV{$k} );
                if ( $MV{$k} > 0.00000001 ) {
                    $MV{$k} = 0.95 * $MV{$k};
                }
            }
        }
        if ( $err_sum < $prev_err_sum ) {
            $prev_err_sum = $err_sum;
        }
        push @errs, $err_sum;
    }

    #dump \@errs;
    return $prev_err_sum;
}

my $err_sum = churn_loop(1);
printf( "err_sum=%.8f\n", $err_sum );
printf( "%s\n",           dump( \%C ) );

my $loops = 0;
while ( $err_sum > 0.01 ) {
    my $before = $err_sum;
    $err_sum = churn_loop($err_sum);
    if ( $before < $err_sum ) {
        $err_sum = churn_loop($err_sum);
    }
    if ( $loops++ % 100 == 0 ) {
        printf( "loops = %d\n",       $loops );
        printf( "  err_sum = %.8f\n", $err_sum );
        printf( "%s\n",               dump( \%C ) );
    }
    if ( $loops++ % 100 == 0 ) {
        for my $k ( ( 'A' .. 'H' ) ) {
            $MV{$k} = 20 * $MV{$k};
        }
    }
}

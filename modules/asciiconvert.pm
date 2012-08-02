#------------------------------------------------------------------------
# ASCII conversions
#
# Usage: "ascii X" or "ord C"
# $Id: asciiconvert.pm,v 1.5 2001/12/04 23:23:16 dagbrown Exp $
#------------------------------------------------------------------------

use strict;
package asciiconvert;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    if (::getparam('allowConv')) {

        if ($message =~ /^\s*(asci*|chr) (\d+)\s*$/) {
            my $num = $2;
            my $res;

            if ($num < 32) {
                $num += 64;
                $res = "^".chr($num);
            } else {
                $res = chr($2);
            }
            if ($num == 0) { $res = "NULL"; } ;
            $callback->("ascii ".$2." is \'".$res."\'");
            return 1;
        }

        if ($message =~ /^\s*ord (.)\s*$/) {
            my $res = $1;
            if (ord($res) < 32) {
                $res = chr(ord($res) + 64);
                if ($res eq chr(64)) {
                    $res = 'NULL';
                } else {
                    $res = '^'.$res;
                }
            }
            $callback->("\'$res\' is ascii ".ord($1));
            return 1;
        }

    }
    return undef;
}

"asciiconvert";

__END__

=head1 NAME

asciiconvert.pm - ASCII conversions

=head1 SYNOPSIS

ascii [number] 

ord [character]

=head1 DESCRIPTION

This module can be invoked in two different ways.

    ascii [number]

Will return the character that corresponds to the ASCII code, from
0 to 127.

    ord [character]

Will return the ASCII code for the character you asked for.

=head1 AUTHORS

Kevin Lenzo (presumably)
Dave Brown (Flooterbuck-ized the module)

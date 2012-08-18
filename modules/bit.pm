# Template infobot extension

use strict;
use feature "switch";

package bit;

#BEGIN {
#	# eval your "use"ed modules here
#}

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # Check $message, if it's what you want, then do stuff with it
    if ($message =~ /^\s*bit(?:,|:|;|-)\s+.*\?$/i) {
        my ($string, $leftside, $rightside, $answer, $reply, $x);        

        $string = $message; #preserve the original string, just in case
    
        $string =~ s/^\s+//; #trim leading whitespace
        $string =~ s/\s+$//; #trim trailing whitespace
        $string =~ s/^bit(?:,|:|;|-)//i; #trim the "bit" and punctuation from the front
        chop($string); #remove the question mark from the end
        $string =~ s/^\s+//; #re-trim leading whitespace
        
        if ($string =~ /^(.+)\sor\s(.+)$/) 
        {
            $leftside = $1;
            $rightside = $2;
            
            $answer = rand() > 0.5 ? $leftside : $rightside;

            given (int(rand(5))) 
            {
                when (1) { $reply = "9 out of 10 bots prefer " . $answer . "."; }
                when (2) { $reply = "The voices in my head say " . $answer . ", " . $who . "."; }
                when (3) { $reply = "I think you should go with " . $answer . ", but that's just my opinion."; }
                when (4) { $reply = $who . ", survey says " . $answer . "."; }
                when (5) { $reply = "Definitely " . $answer . "."; }
                default { $reply = $who . ": " . $answer; }
            }
        } 
        else { 
            $reply = rand() > 0.5 ? "YES" : "NO"; 
        }
               
        $callback->($reply);
        return 1;
    } 
    else {
        return undef;
    }
}

return "bit";

__END__

=head1 NAME

Filename.pm - Description

=head1 PREREQUISITES

	Some::Module

=head1 PARAMETERS

switchname

=over 4

=item value1

Description

=item value2

Description

=back

=head1 PUBLIC INTERFACE

Here you put how you call your sub from the bot user's point of view

=head1 DESCRIPTION

What is it?

=head1 AUTHORS

Who are you?

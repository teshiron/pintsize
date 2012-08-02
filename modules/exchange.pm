#------------------------------------------------------------------------
# "exchange" command, change currencies
#
# $Id: exchange.pm,v 1.15 2007/10/18 22:24:46 rharman Exp $
#------------------------------------------------------------------------

use strict;
package exchange;

# exchange.pl - currency exchange module
#
# Last update: 2003/07/11 -- awh@awh.org, rewrote to use Yahoo.
#

my $no_exchange; 
my $no_posix;

BEGIN {
    eval qq{
        use LWP::UserAgent;
        use HTTP::Request::Common qw(POST GET);
    };

    $no_exchange++ if($@);

    eval qq{
        use POSIX;
    };

    $no_posix++ if ($@);
}

sub getrate {
    my($From, $To) = @_;

    # set up the HTTP connection
    my $ua = new LWP::UserAgent;
    $ua->agent("Mozilla/4.5 " . $ua->agent);        # Let's pretend
    if (my $proxy = main::getparam('httpproxy')) { $ua->proxy('http', $proxy) };
    $ua->timeout(10);

    # request the currency conversion from Yahoo
    my $Converter="http://download.finance.yahoo.com/d/quotes.csv?s=$From$To=X&f=sl1";
    my $req = GET $Converter;
    my $res = $ua->request($req);                   # Submit request

    if (!$res->is_success) {
       return "EXCHANGE: ". $res->status_line;
    }

    my ($symfrom,$symto,$mult) = ($res->as_string =~ m/"(\w{3})(\w{3})=X",([\d.]+)/);

    return wantarray ? ($symfrom,$symto,$mult) : $mult;
}

sub exchange {
    my($From, $To, $Amount) = @_;

    return "exchange.pl: not configured. needs LWP::UserAgent and HTTP::Request::Common" if( $no_exchange );

    # set up the HTTP connection
    my $ua = new LWP::UserAgent;
    $ua->agent("Mozilla/4.5 " . $ua->agent);        # Let's pretend
    if (my $proxy = main::getparam('httpproxy')) { $ua->proxy('http', $proxy) };
    $ua->timeout(10);

    my ($curnamefrom, $curnameto, $mult) = getrate($From,$To);
    &::status("$curnamefrom, $curnameto, $mult");

    my $amount = $Amount * $mult;

    # yay, it matched!
    if ($curnamefrom and $curnameto and $amount) {
        return "$Amount $curnamefrom makes $amount $curnameto";
    }

    # under the old screen format, I could tell which currency symbol
    # was not entered correctly.  Under the new format, anything incorrect
    # just dumps you back to the default page.
    if ((!$curnamefrom) or (!$curnameto) or (!$amount)) {
        return "Either '$From' or '$To' is an invalid currency symbol, or Yahoo changed its screen format for the currency exchanger.  Check http://finance.yahoo.com/currency for the list of supported symbols.";
    }

    # Uh-oh, how did we get here?
    return "Um, something bad has happened.";
}

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # currency exchanger, bobby@bofh.dk
    if( defined(::getparam('exchange'))
            and ::getparam('exchange')
            and ($message =~ /^\s*(?:ex)?change\s+/i)){

        &::status("message($message)");
        my $response='';

        $SIG{CHLD}="IGNORE";
        my $pid=eval { fork(); };         # Don't worry if OS isn't forking
        return 'NOREPLY' if $pid;
        
        if ($message =~ /^\s*(?:ex)?change\s+  # "exchange" 
                         ([\d\.\,]+)           # some number of $CURRENCY
                         \s+                   # (whitespace)
                         (\S+)                 # currency name
                         \s+                   # (more whitespace)
                         (?:into|to|for)       # "into" (or "to" or "for")
                         \s+                   # (more whitespace)
                         (\S+)                 # Other currency name
                         /xi) {
            my($Amount,$From,$To) = ($1,$2,$3);
            $From = uc $From;
            $To = uc $To;
            &::status("calling exchange($From, $To, $Amount) ...");
            $response = &exchange($From, $To, $Amount);
        } else {
            $response = "that doesn't look right";
        }

        &::status("exchange got response($response)");

        if($response =~ /^EXCHANGE: \S*/) {
            &::status($response);
            $callback->("$who: $response");
        } else {
            $callback->("$who: $response");
        }

        # close the child process if we fork()ed before.  Prefer 
        # POSIX::_exit(), but if the person doesn't have POSIX.pm,
        # use perl's built-in exit.
        if (defined($pid))
        {
            exit 0 if ($no_posix);
            POSIX::_exit(0);
        }
    }				# end exchange
    return undef;
}

"exchange";

__END__

=head1 NAME

exchange.pl - Exchange between currencies

=head1 PREREQUISITES

	LWP::UserAgent
	HTTP::Request::Common

=head1 PARAMETERS

exchange

=head1 PUBLIC INTERFACE

	Exchange <amount> <currency> for|[in]to <currency>

=head1 DESCRIPTION

Contacts C<finance.yahoo.com> and grabs the exchange rates.

=head1 AUTHORS

Bobby <bobby@bofh.dk>

Drew Hamilton <awh@awh.org>, rewrote for yahoo



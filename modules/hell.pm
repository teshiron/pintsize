# Template infobot extension

use strict;
use feature "switch";

package hell;

BEGIN {
    eval "use Date::Manip::Date";
    eval "use Date::Manip::Delta";
}

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # Check $message, if it's what you want, then do stuff with it
    if($message =~ /^send .+ to hell.*/i) {
        #debug
        #&main::status("Entering hell module.");

        my ($string, $reply, $phrase, $tag, $return_bool, $return_string, $now);
        my ($return_key, @items, $count, $date, $return_date, $delta, @df, $dstring);
        
        $string = $message; #preserve the original string, just in case

        $string =~ s/^\s+//; #trim leading whitespace
        $string =~ s/\s+$//; #trim trailing whitespace

        $string =~ /^send (.+) to hell(.*)/i; #parse out the thing being sent to hell, and save any tag like "again" or "to stay"
        $phrase = $1;
        $tag = $2;

        #&main::status("phrase is $phrase, tag is $tag");

        $tag =~ s/^\s+//; #trim leading whitespace from tag

        
        #&main::status("Getting keys");
        @items = ::getDBMKeys('hell');
        #&main::status("Got keys");
        $count = scalar(@items);

        &main::status("count is $count");
        
        if ($count > 10) {
            $return_bool = (int(rand(100)) <= 75) ? 1 : 0;
        } elsif ($count >= 4 && $count <= 10) {
            $return_bool = (int(rand(100)) <= 30) ? 1 : 0;
        } elsif ($count < 4) {
            $return_bool = 0;
        }

        $now = time();

        $date = new Date::Manip::Date;
        $date->parse('epoch ' . $now); #what time is it now?
       
 
        #go ahead and store the string, using the stored timestamp as the key and the phrase as the value
        #(using the timestamp as key prevents key collisions)
        ::set('hell', $now, $phrase);

        if ($return_bool) {
            $return_key = @items[int(rand($count))];
            $return_string = ::get('hell', $return_key);
      
            $return_date = $date->new_date();
            $return_date->parse('epoch ' . $return_key); #what was the date the returned object was sent to hell?

            $delta = $date->calc($return_date, 1); #so how old is that? uses a Date::Manip::Delta object
        
            #convert the actual delta (age) of the retrieved item to a fuzzy string
            @df = $delta->value(); #what fields are in the delta?
        
            if (@df[0]) {
                $dstring = $delta->printf('%yv years and %Mv months');
            } elsif (@df[1]) {
                $dstring = $delta->printf('%Mv months and %wv weeks');
            } elsif (@df[2]) {
                $dstring = $delta->printf('%wv weeks and %dv days');
            } elsif (@df[3]) {
                $dstring = $delta->printf('%dv days and %hv hours');
            } elsif (@df[4]) {
                $dstring = $delta->printf('%hv hours and %mv minutes');
            } else {
                $dstring = $delta->printf('%.2mms minutes');
            }

            $reply = "\cAACTION stuffs " . $phrase . " into the closet behind him.\cA";
            $callback->($reply);
            $reply = "\cAACTION dodges " . $return_string . " as it falls out of the closet before he can shut the door.\cA";
            $callback->($reply);
            $reply = "The label on it says it was in the closet for " . $dstring . ".";
            $callback->($reply);

            ::clear('hell', $return_key); #delete from the DB that which fell out
        } else {
            $reply = "\cAACTION stuffs " . $phrase . " into the closet behind him.\cA";
            $callback->($reply);
            $reply = "\cAACTION manages to shut the closet door before anything can fall out.\cA";
            $callback->($reply);
        }       

        return 1;
    } else {
        return undef;
    }
}

return "hell";

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

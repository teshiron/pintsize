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

        my ($string, $reply, $phrase, $tag, $return_bool, $return_string, $now, @dice);
        my ($return_key, @items, $count, $date, $return_date, $delta, @df, $dstring);
        my ($return_bool2, $return_string2, $return_key2, $return_date2, $delta2);         

        $string = $message; #preserve the original string, just in case

        $string =~ s/^\s+//; #trim leading whitespace
        $string =~ s/\s+$//; #trim trailing whitespace

        $string =~ /^send (.+) to hell(.*)/i; #parse out the thing being sent to hell, and save any tag like "again" or "to stay"
        $phrase = $1;
        $tag = $2;

        #&main::status("phrase is $phrase, tag is $tag");

        $tag =~ s/^\s+//; #trim leading whitespace from tag
        $phrase .= ($tag ne "") ? (" (" . $tag . ")") : (""); #if tag is present, append it in parentheses
        
        #&main::status("Getting keys");
        @items = ::getDBMKeys('hell');
        #&main::status("Got keys");
        $count = scalar(@items);

        &main::status("count is $count");

        #roll 2d100 mostly for readability
        $dice[0] = int(rand(100));
        $dice[1] = int(rand(100));
        
        #determine whether 0, 1, or 2 items will fall out of "hell" in return
        if ($count > 100) { #if over 100 items, 95% chance to drop one, 75% to drop second items
            $return_bool = ($dice[0] <= 95) ? 1 : 0;
            $return_bool2 = ($dice[1] <= 75) ? 1 : 0;
        } elsif ($count > 75) { #if between 75 and 100, 85% to drop one, 50% to drop 2nd
            $return_bool = ($dice[0] <= 85) ? 1 : 0;
            $return_bool2 = ($dice[1] <= 50) ? 1 : 0;
        } elsif ($count > 50) { #if between 50 and 75, 85% to drop one, 25% to drop 2nd
            $return_bool = ($dice[0] <= 85) ? 1 : 0;
            $return_bool2 = ($dice[1] <= 25) ? 1 : 0;
        } elsif ($count > 25) { #if between 25 and 50, 70% chance to drop one, 10% for 2nd
            $return_bool = ($dice[0] <= 70) ? 1 : 0;
            $return_bool2 = ($dice[1] <= 10) ? 1 : 0;
        } elsif ($count > 10) { #if between 10 and 25, 50% chance to drop one, 5% for second
            $return_bool = ($dice[0] <= 50) ? 1 : 0;
            $return_bool2 = ($dice[1] <= 5) ? 1 : 0;
        } elsif ($count > 4) { #if between 4 and 10, 25% chance to drop one, 0% for second
            $return_bool = ($dice[0] <= 25) ? 1 : 0;
            $return_bool2 = 0;
        } else { #if 4 or less, don't drop anything
            $return_bool = 0;
            $return_bool2 = 0;
        }

        $now = time();

        $date = new Date::Manip::Date;
        $date->parse('epoch ' . $now); #what time is it now?
 
        #go ahead and store the string, using the stored timestamp as the key and the phrase as the value
        #(using the timestamp as key prevents key collisions)
        ::set('hell', $now, $phrase);

        if ($return_bool) {
            $return_key = @items[int(rand($count - 1))]; #randomly select an item to drop from hell
            $return_string = ::get('hell', $return_key); #retrieve the string for the item being dropped
            ::clear('hell', $return_key); #delete from the DB that which fell out

            if (!$return_bool2) { #if we're not dropping a second item, then parse out the delta string
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

                $reply = "\cAACTION grabs " . $phrase . " and stuffs it into the closet behind him.\cA";
                $callback->($reply);
                sleep 1;
                $reply = "\cAACTION dodges " . $return_string . " as it falls out of the closet before he can shut the door.\cA";
                $callback->($reply);
                sleep 1;
                $reply = "The label on it says it was in the closet for " . $dstring . ".";
                $callback->($reply);
            } else { #$return_bool2 must be true, so we're dropping two items -- no date delta, just get a second item
                ::syncDBM('hell'); #flush deletion to disk so we can re-retrieve keys
                @items = ::getDBMKeys('hell'); #re-retrieve hell items
                $count = scalar(@items); #update count

                $return_key2 = @items[int(rand($count - 1))]; #randomly select a second item to drop from hell
                $return_string2 = ::get('hell', $return_key2); #retrieve the string for the 2nd item
                ::clear('hell', $return_key2); #delete the 2nd item from the db

                $reply = "\cAACTION grabs " . $phrase . " and stuffs it into the closet behind him.\cA";
                $callback->($reply);
                sleep 1;
                $reply = "\cAACTION dodges " . $return_string . " as it falls out of the closet before he can shut the door.\cA";
                $callback->($reply);
                sleep 1;
                $reply = "\cAACTION manages to get the closet door shut, but not before " . $return_string2 . " fell out as well.\cA";
                $callback->($reply);
            }
        } else { #$return_bool is false, so nothing fell out at all
            $reply = "\cAACTION grabs " . $phrase . " and stuffs it into the closet behind him.\cA";
            $callback->($reply);
            sleep 1;
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

#------------------------------------------------------------------------
# NOAA Weather module.
#
# kevin lenzo (C) 1999 -- get the weather forcast NOAA.
# feel free to use, copy, cut up, and modify, but if
# you do something cool with it, let me know.
#
# $Id: weather.pm,v 1.11 2005/01/21 20:58:03 rich_lafferty Exp $
#------------------------------------------------------------------------

package weather;

my $no_weather;
my $default = 'KAGC';

BEGIN {
    $no_weather = 0;
    eval "use LWP::UserAgent";
    $no_weather++ if ($@);
    eval "use Geo::METAR";
    $no_weather++ if ($@);
    eval "use Geo::ICAO qw{:airport}";
    $no_weather++ if ($@);
    eval "use Math::Round";
    $no_weather++ if ($@);
}

sub get_weather {
    	my $site_id = uc($2);
	return "No parameter was passed." if (!$site_id);

	# ICAO airport codes *can* contain numbers, despite earlier claims.
	# Americans tend to use old FAA three-letter codes; luckily we can
	# *usually* guess what they mean by prepending a 'K'. The author,
	# being Canadian, is similarly lazy.
	
	$site_id =~ s/[.?!]$//;
	$site_id =~ s/\s+$//g;
	return "'$site_id' doesn't look like a valid ICAO airport identifier."
	    unless $site_id =~ /^[\w\d]{3,4}$/;
	$site_id = "C" . $site_id if length($site_id) == 3 && $site_id =~ /^Y/;
	$site_id = "K" . $site_id if length($site_id) == 3;
	
	# HELP isn't an airport, so we use it for a reference work.
	return "For weather, ask me 'metar <airport code>'."
	    if $site_id eq 'HELP';
	
	my $metar_url = "http://weather.noaa.gov/cgi-bin/mgetmetar.pl?cccc=$site_id";
	
	# Grab METAR report from Web.   
	my $agent = new LWP::UserAgent;
	if (my $proxy = main::getparam('httpproxy')) { $agent->proxy('http', $proxy) };
	$agent->timeout(10);
	my $grab = new HTTP::Request GET => $metar_url;
	
	my $reply = $agent->request($grab);
	
	# If it can't find it, assume luser error :-)
	return "Either $site_id doesn't exist (try a 4-letter station code like KAGC), or the NOAA site is unavailable right now." 
	    unless $reply->is_success;
	
	# extract METAR from incredibly and painfully verbose webpage
	my $webdata = $reply->as_string;
	$webdata =~ m/($site_id\s\d+Z.*?)</s;    
	my $metar = $1;                       
	$metar =~ s/\n//gm;
	$metar =~ s/\s+/ /g;
	
	# Sane?
	return "I can't find any observations for $site_id." if length($metar) < 10;

	my ($result, $wx, $sky, $remark, $wind, @airport, $location);
	my $m = new Geo::METAR; #decode the METAR data, using a short variable name for convenience
	$m->metar($metar);
	
	@airport = code2airport($m->{SITE});
	$location = length($airport[1]) ? $airport[1] : $airport[0];
	$wx = join(" ", @{$m->{WEATHER}});
	$sky = join(" ", @{$m->{SKY}});
	$remark = join(" ", @{$m->{SKY}});
	$wind = round($m->{WIND_MPH});
	
	$result = "Conditions for " . $location . " as of " . $m->{TIME} . ": Temp: " . $m->{TEMP_F} . "F (" . $m->{TEMP_C} . "C) Wind: " . $wind . " MPH from the " . $m->{WIND_DIR_ABB} . ". Sky/clouds: " . $sky;

	# is there any current weather behavior? if so, add it to the output
	if (length($wx)) {$result .= " Weather: " . $wx};
	
	# are there any remarks? go ahead and display them if so, even if they're not 'readable'
	if (length($remark) && lc($remark) ne lc($sky)) {$result .= " Remarks: " . $remark};
       
	return $result;
}

sub scan (&$$) {
    my ($callback,$message,$who) = @_;

    if (::getparam('weather') 
            and ($message =~ /^\s*(wx|weather)\s+(?:for\s+)?(.*?)\s*\?*\s*$/)) {
        my $code = $2;
        $callback->(get_weather($code));
        return 'NOREPLY';
    }
    return undef;
}


"weather";

__END__

=head1 NAME

weather.pm - Get the weather from a NOAA server

=head1 PREREQUISITES

	LWP::UserAgent

=head1 PARAMETERS

weather

=head1 PUBLIC INTERFACE

	weather [for] <station>

=head1 DESCRIPTION

Contacts C<weather.noaa.gov> and gets the weather report for a given
station.

=head1 AUTHORS

Kevin Lenzo

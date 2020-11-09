use v6;
use Test;
use IO::Socket::SSL;

plan 2;

my IO::Socket $ssl = IO::Socket::SSL.new(:host<github.com>, :port(443));
isa-ok $ssl, IO::Socket::SSL, 'new 1/1';
$ssl.close;

unless %*ENV<NETWORK_TESTING> {
    diag "NETWORK_TESTING was not set";
    skip-rest("NETWORK_TESTING was not set");
    exit;
}

subtest {
    my $ssl;
    lives-ok { $ssl = IO::Socket::SSL.new( :host<google.com>, :port(443)) };
    is $ssl.print("GET / HTTP/1.1\r\nHost:www.google.com\r\nConnection:close\r\n\r\n"), 57;

    my $line-endings = True;
    while my $line = $ssl.get {
        FIRST ok $line ~~ /\s3\d\d\s/|/\s2\d\d\s/;
        last unless $line ~~ /\w/;
        $line-endings = False unless $line.ends-with: "\r";
    }
    ok $line-endings, 'All header lines keep the carriage return';

    $ssl.close;
}, 'google: ssl with nl-in = \n';

subtest {
    my $ssl;
    lives-ok { $ssl = IO::Socket::SSL.new( nl-in => [ "\n", "\r\n" ], :host<google.com>, :port(443)) };
    is $ssl.print("GET / HTTP/1.1\r\nHost:www.google.com\r\nConnection:close\r\n\r\n"), 57;

    my $line-endings = True;
    while my $line = $ssl.get {
        FIRST ok $line ~~ /\s3\d\d\s/|/\s2\d\d\s/;
        $line-endings = False if $line.ends-with: "\r";
    }
    ok $line-endings, 'No lines have a carriage return';

    $ssl.close;
}, 'google: ssl with nl-in = [ \n, \r\n ]';

done-testing;

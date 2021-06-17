package URI::Parse::SearchString;

# DATE
# VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(parse_search_string);

sub import {
    require URI::Parse::SearchString::Plugin::Google;
    URI::Parse::SearchString::Plugin::Google->import;
}

our %HOSTS = (
);

1;
# ABSTRACT: Parse search string in URL

=head1 SYNOPSIS

 use URI::Parse::SearchString qw(parse_search_string);

 my $res = parse_search_string("https://www.google.com/search?safe=off&oq=kathy+griffin");
 # => {name=>"Google", host=>"www.google.com", search_string=>"kathy griffin"}


=head1 DESCRIPTION

This module is an experimental alternative to L<URI::ParseSearchString> with the
following differences:

=over

=item * Modular

Adding detection for more hosts/sites should be no harder than:

 use URI::Parse::SearchString qw(parse_search_string);
 use URI::Parse::SearchString::Plugin::Torrent;
 use URI::Parse::SearchString::Plugin::ID::ECommerce;

=item * More sites/hosts

Aside from search engines, also e-commerce sites, torrent/P2P sites, etc. Look
for plugins under the C<URI::Parse::SearchString::Plugin::*> namespace.

=item * Recognizing search string in URL path instead of query string

Example:

 https://thepiratebay.org/search/some%20query/

=item * Parse additional information other than search string

XXX

=item * No OO interface, only simple functions.

=back

There's no reason why the two modules cannot interoperate or be merged and I
will probably work on it later.


=head1 SEE ALSO

L<URI::ParseSearchString>

=cut

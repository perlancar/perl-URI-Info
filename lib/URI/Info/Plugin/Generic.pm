package URI::Info::Plugin::Generic;

use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

use parent 'URI::Info::PluginBase';

sub meta {
    return {
        summary => 'Extract generic info from URL',
        conf => {
        },
    };
}

sub get_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};
    my $res = $stash->{res};

    $res->{host} = $url->host;

    [200]; # 200=OK, 201=OK & skip the rest of the plugins, 500=error
}

1;
# ABSTRACT:

=for Pod::Coverage .+

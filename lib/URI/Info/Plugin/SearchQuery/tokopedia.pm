package URI::Info::Plugin::SearchQuery::tokopedia;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;

use parent 'URI::Info::PluginBase';

sub meta {
    return {
        summary => 'Extract search query from tokopedia.com URL',
        conf => {
        },
        site => 'tokopedia.com',
    };
}

sub get_site_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};
    if ($url->full_path =~ m!\A/search!) {
        return [200, "OK", {
            search_type  => $url->query_param('st'),
            search_query => $url->query_param('q'),
        }];
    }
    [100];
}

1;
# ABSTRACT:

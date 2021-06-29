package URI::Info::Plugin::SearchQuery::thepiratebay;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;

use parent 'URI::Info::PluginBase';

sub meta {
    return {
        summary => 'Extract search query from thepiratebay.org (and its mirrors) URL',
        conf => {
        },
        site => qr/\A(
                       thepiratebay\.org |
                       www\.piratebaylive\.org
                   )\z/x,
    };
}

sub get_site_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};

    if ($url->full_path =~ m!\A(/search\.php|/s/)!) {
        return [200, "OK", {
            search_type  => $1,
            search_query => $url->query_param('q'),
        }];
    }
    [100];
}

1;
# ABSTRACT:

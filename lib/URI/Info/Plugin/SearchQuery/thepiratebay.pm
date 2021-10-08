package URI::Info::Plugin::SearchQuery::thepiratebay;

use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

use parent 'URI::Info::PluginBase';

sub meta {
    return {
        summary => 'Extract search query from thepiratebay.org (and its mirrors) URL',
        conf => {
        },
        host => [
            'thepiratebay.org',
            'www.piratebaylive.org',
        ],
    };
}

sub get_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};
    my $res = $stash->{res};

    if ($url->full_path =~ m!\A(/search\.php|/s/)!) {
        $res->{is_search} = 1;
        $res->{search_type} = $1;
        $res->{search_query} = $url->query_param('q');
    }
    [200]; # 200=OK, 201=OK & skip the rest of the plugins, 500=error
}

1;
# ABSTRACT:

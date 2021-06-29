package URI::Info::Plugin::SearchQuery::google;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;

use parent 'URI::Info::PluginBase';

sub meta {
    return {
        summary => 'Extract search query from google URL',
        conf => {
        },
        site => sub { $_[0] =~ /\A(www\.)?google\./ },
    };
}

sub get_site_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};

    if ($url->full_path =~ m!\A/(images|search|videosearch|news|maps|blogsearch|books|groups|scholar)!) {
        return [200, "OK", {
            search_type  => $1,
            search_query => $url->query_param('q'),
        }];
    }
    [100];
}

1;
# ABSTRACT:

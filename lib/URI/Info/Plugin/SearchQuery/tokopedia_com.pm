package URI::Info::Plugin::SearchQuery::tokopedia_com;

use strict;
use warnings;

use parent 'URI::Info::PluginBase';

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta {
    return {
        summary => 'Extract search query from tokopedia.com URL',
        conf => {
        },
        host => 'tokopedia.com',
    };
}

sub get_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};
    my $res = $stash->{res};

    if ($url->full_path =~ m!\A/search!) {
        $res->{is_search} = 1;
        $res->{search_type} = $url->query_param('st');
        $res->{search_query} = $url->query_param('q');
    }
    [200]; # 200=OK, 201=OK & skip the rest of the plugins, 500=error
}

1;
# ABSTRACT:

=for Pod::Coverage .+

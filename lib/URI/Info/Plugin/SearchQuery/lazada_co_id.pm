package URI::Info::Plugin::SearchQuery::lazada_co_id;

use strict;
use warnings;

use parent 'URI::Info::PluginBase';

# AUTHORITY
# DATE
# DIST
# VERSION

sub meta {
    return {
        summary => 'Extract search query from lazada.co.id URL',
        conf => {
        },
        host => 'lazada.co.id',
    };
}

sub get_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};
    my $res = $stash->{res};

    if ($url->full_path =~ m!\A/catalog/!) {
        $res->{is_search} = 1;
        $res->{search_type} = 'product';
        $res->{search_query} = $url->query_param('q');
    }
    [200]; # 200=OK, 201=OK & skip the rest of the plugins, 500=error
}

1;
# ABSTRACT:

=for Pod::Coverage .+

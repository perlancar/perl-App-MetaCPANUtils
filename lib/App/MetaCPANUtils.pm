package App::MetaCPANUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

our $release_fields = [
    # name for cli user, source field in API, include by default?
    ['release'     , 'name'        , 1],
    ['date'        , 'date'        , 1],
    ['author'      , 'author'      , 1],
    ['maturity'    , 'maturity'    , 1],
    ['version'     , 'version'     , 1], # main module's $VERSION
    ['first'       , 'first'       , 0], # useless? this field follows version defined in $VERSION so several releases might have first=1 e.g. see releases of XML-API-0.02 to 0.13 where $VERSION is set to 0.02
    ['distribution', 'distribution', 1],
    ['abstract'    , 'abstract'    , 1],

    ['download_url', 'download_url', 0],
];
our %argopt_release_fields = (
    fields => {
        schema => ['array*', of=>['str*', in=>[ map {$_->[0]} @$release_fields ]]],
        default => [ map {$_->[0]} grep {$_->[2]} @$release_fields ],
        cmdline_aliases=>{f=>{}},
        tags => ['category:result'],
    },
);

our %argoptf_author = (
    author => {
        schema => "cpan::pause_id*",
        tags => ['category:filtering'],
    },
);
our %argoptf_distribution = (
    distribution => {
        schema => "cpan::distname*",
        tags => ['category:filtering'],
    },
);
our %argoptf_module = (
    distribution => {
        schema => "cpan::modname*",
        tags => ['category:filtering'],
    },
);

our %argopt_release_sort = (
    sort => {
        schema => ['str*', in=>[qw/release -release date -date/]],
        default => '-date',
    },
);

sub _resultset_to_envres {
    my ($resultset, $wanted_fields) = @_;

    my @rows;
    my $resmeta = {'table.fields' => $wanted_fields};
    while (my $obj = $resultset->next) {
        log_trace("API result: %s", $obj) if $ENV{METACPANUTILS_DUMP_API_RESULT};
        my $row = {};
        if (ref $obj eq 'MetaCPAN::Client::Release') {
            $row->{release}      = $obj->name         if grep {$_ eq 'release'}      @$wanted_fields;
            $row->{date}         = $obj->date         if grep {$_ eq 'date'}         @$wanted_fields;
            $row->{author}       = $obj->author       if grep {$_ eq 'author'}       @$wanted_fields;
            $row->{maturity}     = $obj->maturity     if grep {$_ eq 'maturity'}     @$wanted_fields;
            $row->{version}      = $obj->version      if grep {$_ eq 'version'}      @$wanted_fields;
            $row->{distribution} = $obj->distribution if grep {$_ eq 'distribution'} @$wanted_fields;
            $row->{abstract}     = $obj->abstract     if grep {$_ eq 'abstract'}     @$wanted_fields;
            $row->{first}        = $obj->first        if grep {$_ eq 'first'}        @$wanted_fields;
        } else {
            die "Can't handle result $obj";
        }
        push @rows, $row;
    }
    $resmeta->{'func.num_rows'} = @rows;
    [200, "OK", \@rows, $resmeta];
}

sub _fields_to_source {
    my ($wanted_fields, $fields) = @_;
    my $source = [];
    for my $f (@$fields) {
        if (grep { $_ eq $f->[0] } @$wanted_fields) {
            push @$source, $f->[1];
        }
    }
    $source;
}

$SPEC{list_recent_metacpan_releases} = {
    v => 1.1,
    args => {
        n => {
            schema => 'posint*',
            ## no longer true, will list several days' worth nowadays
#            description => <<'_',
#
#If not specified, will list all releases from today.
#
#_
            pos => 0,
        },
        %argopt_release_fields,
    },
};
sub list_recent_metacpan_releases {
    require MetaCPAN::Client;

    my %args = @_;

    my $mcpan = MetaCPAN::Client->new;
    my $recent = $mcpan->recent($args{n});
    _resultset_to_envres($recent, $args{fields});
}

$SPEC{list_metacpan_releases} = {
    v => 1.1,
    args => {
        %argopt_release_fields,
        %argoptf_author,
        %argoptf_distribution,
        %argopt_release_sort,
    },
};
sub list_metacpan_releases {
    require MetaCPAN::Client;

    my %args = @_;

    my $mcpan = MetaCPAN::Client->new;

    my $query = {all=>[]};
    push @{ $query->{all} }, {author=>$args{author}}             if defined $args{author};
    push @{ $query->{all} }, {distribution=>$args{distribution}} if defined $args{distribution};
    log_trace "MetaCPAN API query: %s", $query;

    my $params = {};
    $params->{_source} = _fields_to_source($args{fields}, $release_fields);
    if (defined $args{sort}) {
        $params->{sort} = [{date=>{order=>'asc'}}]  if $args{sort} eq 'date';
        $params->{sort} = [{date=>{order=>'desc'}}] if $args{sort} eq '-date';
        $params->{sort} = [{name=>{order=>'asc'}}]  if $args{sort} eq 'release';
        $params->{sort} = [{name=>{order=>'desc'}}] if $args{sort} eq '-release';
    }
    log_trace "MetaCPAN API query params: %s", $params;

    my $res = $mcpan->release($query, $params);

    _resultset_to_envres($res, $args{fields});
}


1;
# ABSTRACT: CLI utilities related to MetaCPAN

=head1 DESCRIPTION

This distribution contains CLI utilities related to MetaCPAN:

# INSERT_EXECS_LIST


=head1 ENVIRONMENT

=head2 METACPANUTILS_DUMP_API_RESULT

If set to true, will log the API result at the C<trace> level.


=head1 SEE ALSO

L<https://metacpan.org>

Other distributions providing CLIs for MetaCPAN: L<MetaCPAN::Clients>,
L<App::metacpansearch>.

MetaCPAN API Client: L<MetaCPAN::Client>

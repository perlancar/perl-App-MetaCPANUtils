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
    ['status'      , 'status'      , 1],
    ['maturity'    , 'maturity'    , 1],
    ['version'     , 'version'     , 1], # main module's $VERSION
    ['first'       , 'first'       , 1], # useless? this field follows version defined in $VERSION so several releases might have first=1 e.g. see releases of XML-API-0.02 to 0.13 where $VERSION is set to 0.02
    ['distribution', 'distribution', 1],
    ['abstract'    , 'abstract'    , 1],

    ['download_url', 'download_url', 0],
];

our $distribution_fields = [
    # name for cli user, source field in API, include by default?
    ['distribution', 'name'        , 1],
];

our $module_fields = [
    # name for cli user, source field in API, include by default?
    ['module'      , 'package'     , 1],
    ['date'        , 'date'        , 1],
    ['author'      , 'author'      , 1],
    ['status'      , 'status'      , 1],
    ['maturity'    , 'maturity'    , 1],
    ['version'     , 'version'     , 1], # main module's $VERSION
    ['release'     , 'release'     , 1],
    ['abstract'    , 'abstract'    , 1],
];

our %argopt_release_fields = (
    fields => {
        schema => ['array*', of=>['str*', in=>[ map {$_->[0]} @$release_fields ]]],
        default => [ map {$_->[0]} grep {$_->[2]} @$release_fields ],
        cmdline_aliases=>{f=>{}},
        tags => ['category:result'],
    },
);
our %argopt_distribution_fields = (
    fields => {
        schema => ['array*', of=>['str*', in=>[ map {$_->[0]} @$distribution_fields ]]],
        default => [ map {$_->[0]} grep {$_->[2]} @$distribution_fields ],
        cmdline_aliases=>{f=>{}},
        tags => ['category:result'],
    },
);
our %argopt_module_fields = (
    fields => {
        schema => ['array*', of=>['str*', in=>[ map {$_->[0]} @$module_fields ]]],
        default => [ map {$_->[0]} grep {$_->[2]} @$module_fields ],
        cmdline_aliases=>{f=>{}},
        tags => ['category:result'],
    },
);

our %argopt_release_sort = (
    sort => {
        schema => ['str*', in=>[qw/release -release date -date/]],
        default => '-date',
    },
);
our %argopt_distribution_sort = (
    sort => {
        schema => ['str*', in=>[qw/distribution -distribution/]],
        default => 'distribution',
    },
);
our %argopt_module_sort = (
    sort => {
        schema => ['str*', in=>[qw/module -module date -date author -author/]],
        default => 'module',
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
our %argoptf_from_date = (
    from_date => {
        schema => ["date*", "x.perl.coerce_to" => "DateTime"],
        tags => ['category:filtering'],
    },
);
our %argoptf_to_date = (
    to_date => {
        schema => ["date*", "x.perl.coerce_to" => "DateTime"],
        tags => ['category:filtering'],
    },
);
our %argoptf_release_status = (
    status => {
        schema => ["str*", in=>[qw/latest cpan backpan/]],
        tags => ['category:filtering'],
        cmdline_aliases => {
            latest  => {is_flag=>1, summary=>'Shortcut for --status=latest' , code=>sub { $_[0]{status} = 'latest' }},
            cpan    => {is_flag=>1, summary=>'Shortcut for --status=cpan'   , code=>sub { $_[0]{status} = 'cpan' }},
            backpan => {is_flag=>1, summary=>'Shortcut for --status=backpan', code=>sub { $_[0]{status} = 'backpan' }},
        },
    },
);
our %argoptf_module_status = (
    status => {
        %{ $argoptf_release_status{status} },
        default => 'latest',
    },
);
our %argoptf_first = (
    first => {
        schema => ["bool*"],
        tags => ['category:filtering'],
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
            $row->{status}       = $obj->status       if grep {$_ eq 'status'}       @$wanted_fields;
        } elsif (ref $obj eq 'MetaCPAN::Client::Distribution') {
            $row->{distribution} = $obj->name         if grep {$_ eq 'distribution'} @$wanted_fields;
        } elsif (ref $obj eq 'MetaCPAN::Client::Module') {
            $row->{module}       = $obj->name         if grep {$_ eq 'module'}       @$wanted_fields; # ->package() doesn't work
            $row->{date}         = $obj->date         if grep {$_ eq 'date'}         @$wanted_fields;
            $row->{author}       = $obj->author       if grep {$_ eq 'author'}       @$wanted_fields;
            $row->{maturity}     = $obj->maturity     if grep {$_ eq 'maturity'}     @$wanted_fields;
            $row->{version}      = $obj->version      if grep {$_ eq 'version'}      @$wanted_fields;
            $row->{release}      = $obj->release      if grep {$_ eq 'release'}      @$wanted_fields;
            $row->{abstract}     = $obj->abstract     if grep {$_ eq 'abstract'}     @$wanted_fields;
            $row->{status}       = $obj->status       if grep {$_ eq 'status'}       @$wanted_fields;
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
    examples => [
        {
            summary => 'Show 100 latest releases and show their download URLs',
            src => '[[prog]] 100 -f download_url',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
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
        %argopt_release_sort,

        %argoptf_author,
        %argoptf_distribution,
        %argoptf_from_date,
        %argoptf_to_date,
        %argoptf_release_status,
        %argoptf_first,
    },
    examples => [
        {
            summary => 'Show releases in December 2020',
            src => '[[prog]] --from-date 2020-12-01 --to-date 2020-12-31',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => "Show PERLANCAR's releases, show only their distribution, version, first (whether the release is the first release for the distribution), and download URL",
            src => '[[prog]] --author PERLANCAR -f distribution -f version -f first -f download_url',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_metacpan_releases {
    require MetaCPAN::Client;

    my %args = @_;

    my $mcpan = MetaCPAN::Client->new;

    my $query = {all=>[]};
    push @{ $query->{all} }, {author=>$args{author}}             if defined $args{author};
    push @{ $query->{all} }, {distribution=>$args{distribution}} if defined $args{distribution};
    push @{ $query->{all} }, {status=>$args{status}}             if defined $args{status};
    push @{ $query->{all} }, {first=>$args{first}}               if defined $args{first};
    log_trace "MetaCPAN API query: %s", $query;

    my $params = {};
    $params->{_source} = _fields_to_source($args{fields}, $release_fields);
    $params->{es_filter}{range}{date}{from} = $args{from_date}->ymd if defined $args{from_date};
    $params->{es_filter}{range}{date}{to}   = $args{to_date}  ->ymd if defined $args{to_date};
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

$SPEC{list_metacpan_distributions} = {
    v => 1.1,
    args => {
        %argopt_distribution_fields,
        %argopt_distribution_sort,

        # nothing interesting can be filtered so far
        %argoptf_author,
    },
};
sub list_metacpan_distributions {
    require MetaCPAN::Client;

    my %args = @_;

    my $mcpan = MetaCPAN::Client->new;

    my $query = {all=>[]};
    push @{ $query->{all} }, {author=>$args{author}}             if defined $args{author};
    log_trace "MetaCPAN API query: %s", $query;

    my $params = {};
    $params->{_source} = _fields_to_source($args{fields}, $distribution_fields);
    if (defined $args{sort}) {
        $params->{sort} = [{name=>{order=>'asc'}}]  if $args{sort} eq 'distribution';
        $params->{sort} = [{name=>{order=>'desc'}}] if $args{sort} eq '-distribution';
    }
    log_trace "MetaCPAN API query params: %s", $params;

    my $res = $mcpan->distribution($query, $params);

    _resultset_to_envres($res, $args{fields});
}

$SPEC{list_metacpan_modules} = {
    v => 1.1,
    args => {
        %argopt_module_fields,
        %argopt_module_sort,

        %argoptf_author,
        %argoptf_from_date,
        %argoptf_to_date,
        %argoptf_module_status,
    },
    examples => [
        {
            summary => "Show NEILB's modules",
            src => '[[prog]] --author NEILB',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_metacpan_modules {
    require MetaCPAN::Client;

    my %args = @_;

    my $mcpan = MetaCPAN::Client->new;

    my $query = {all=>[]};
    push @{ $query->{all} }, {author=>$args{author}}             if defined $args{author};
    push @{ $query->{all} }, {status=>$args{status}}             if defined $args{status};
    log_trace "MetaCPAN API query: %s", $query;

    my $params = {};
    $params->{_source} = _fields_to_source($args{fields}, $module_fields);
    $params->{es_filter}{range}{date}{from} = $args{from_date}->ymd if defined $args{from_date};
    $params->{es_filter}{range}{date}{to}   = $args{to_date}  ->ymd if defined $args{to_date};
    if (defined $args{sort}) {
        $params->{sort} = [{date=>{order=>'asc'}}]    if $args{sort} eq 'date';
        $params->{sort} = [{date=>{order=>'desc'}}]   if $args{sort} eq '-date';
        $params->{sort} = [{name=>{order=>'asc'}}]    if $args{sort} eq 'module';
        $params->{sort} = [{name=>{order=>'desc'}}]   if $args{sort} eq '-module';
        $params->{sort} = [{author=>{order=>'asc'}}]  if $args{sort} eq 'author';
        $params->{sort} = [{author=>{order=>'desc'}}] if $args{sort} eq '-author';
    }
    log_trace "MetaCPAN API query params: %s", $params;

    my $res = $mcpan->module($query, $params);

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

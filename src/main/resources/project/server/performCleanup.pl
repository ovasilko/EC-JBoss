=head1 NAME

performCleanup.pl

=head1 DESCRIPTION

Performs cleanup

=head1 COPYRIGHT

Copyright (c) 2014 Electric Cloud, Inc.

=cut

$[/myProject/procedure_helpers/preamble]

my $PROJECT_NAME = '$[/myProject/projectName]';
$|=1;

main();

sub main {
    my $jboss = EC::JBoss->new(
        project_name    =>  $PROJECT_NAME,
    );

    my $params = $jboss->get_params_as_hashref(
        'serverconfig',
        'scriptphysicalpath',
        'cleanup_data',
        'cleanup_tmp'
    );
    # Command for runtime information, that will be used:
    # /core-service=platform-mbean/type=runtime:read-attribute(name=system-properties)
    my $command = '/core-service=platform-mbean/type=runtime:read-attribute(name=system-properties)';
    my %result = $jboss->run_command($command);
    my ($tmp_dir, $data_dir);
    my $errors = {
        count => 0,
        msgs => [],
    };

    if ($params->{cleanup_tmp}) {
        $jboss->out("tmp cleanup requested");
        if ($result{stdout} =~ m/"jboss.server.temp.dir".*?"(.+?)"/is) {
            $tmp_dir = $1;
            $tmp_dir =~ s|\/\s*?$||gs;
            $jboss->out("tmp dir found: ", $tmp_dir);
            my $err;
            File::Path::remove_tree(
                $tmp_dir, {
                    keep_root => 1,
                    error => \$err
                }
            );
            if (!@$err) {
                $jboss->out("tmp dir $tmp_dir was successfully cleared");
            }
            else {
                $errors->{count}++ if @$err;
            }
        }
    }

    if ($params->{cleanup_data}) {
        $jboss->out("data cleanup requested");
        if ($result{stdout} =~ m/"jboss.server.data.dir".*?"(.+?)"/is) {
            $data_dir = $1;
            $data_dir =~ s|\/\s*?$||gs;
            $jboss->out("data dir found: ", $data_dir);
            my $err;
            File::Path::remove_tree(
                $data_dir, {
                    keep_root => 1,
                    error => \$err
                }
            );
            if (!@$err) {
                $jboss->out("data dir $data_dir was successfully cleared");
            }
            else {
                $errors->{count}++;
            }
        }
    }

    if ($errors->{count}) {
        $jboss->bail_out("Error occured during cleanup");
    }
    $jboss->{silent} = 1;
    $jboss->process_response(%result);
    return 1;
}

1;


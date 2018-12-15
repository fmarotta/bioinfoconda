#!/usr/bin/perl

# TODO: find a way to run the commands automatically.

use strict;
use warnings;
use File::Basename;

my $NAME = basename($0);
my $USAGE =<<USAGE;
Usage: $NAME install ...

Options:
        Same as conda create

Notes:
        Heavy artillery to be deployed when "conda install" leads to conflicts. 
        Forces the reinstallation of all the environment's packages at once, 
        attempting to resolve the conflicts.

Reporting bugs:
	federicomarotta AT mail DOT com
USAGE

# Validate syntax
if (scalar(@ARGV) == 0 or $ARGV[0] ne "install")
{
        die $USAGE;
}

# Validate environment
if (! defined $ENV{"BIOINFO_ROOT"} or length($ENV{"BIOINFO_ROOT"}) == 0)
{
        die("ERROR: \$BIOINFO_ROOT is not defined.\n");
}
if (! defined $ENV{"CONDA_PREFIX"} or length($ENV{"CONDA_PREFIX"}) == 0)
{
        die("ERROR: you are not inside a conda environment.\n");
}
my $prjname = basename($ENV{"CONDA_PREFIX"});
my $prjpath = "$ENV{'BIOINFO_ROOT'}/prj/$prjname";
my $history_file = "$ENV{'CONDA_PREFIX'}/conda-meta/history";

# Export conda environment as it is now
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
system("conda env export -f $prjpath/local/ymlfiles/$year-$mon-${mday}_$prjname.yml");

# Get the list of channels
my @list = `conda list`;
my @channels;
foreach (@list)
{
        next if (m/^#/);
        @_ = split(/\s+/);
        push(@channels, $_[3]) if (defined($_[3]));
}
@channels = uniq(@channels);

# Get the specs from history
open HISTORY, "<", $history_file
        or die "Error: could not open $history_file: $!";
my @update_specs;
while (<HISTORY>)
{
        if (m/^# update specs: \[(.*)\]/)
        {
                my @specs = split(/, /, $1);
                foreach my $spec (@specs)
                {
                        push(@update_specs, substr($spec, 1, length($spec) - 2));
                }
        }
        elsif (m/^# remove specs: \[(.*)\]/)
        {
                my @specs = split(/, /, $1);
                foreach my $spec (@specs)
                {
                        $spec = substr($spec, 1, length($spec) - 2);
                        for (my $i = 0; $i <= $#update_specs; $i++)
                        {
                                if ($update_specs[$i] eq $spec)
                                {
                                        splice(@update_specs, $i, 1);
                                }
                        }
                }
        }
}
close(HISTORY);
@update_specs = uniq(@update_specs);

# Generate the conda command line
my $channels_string = "-c " . join(" -c ", @channels);
my $update_specs_string = join(' ', @update_specs);

print "cd outside of the project directory and run the following commands:\n"; 
print "conda env remove -n $prjname\n";
print "conda create --name $prjname $channels_string @ARGV[1 .. $#ARGV] $update_specs_string\n";

exit 0;

# https://stackoverflow.com/questions/7651/how-do-i-remove-duplicate-items-from-an-array-in-perl
sub uniq
{
        my %seen;
        grep !$seen{$_}++, @_;
}

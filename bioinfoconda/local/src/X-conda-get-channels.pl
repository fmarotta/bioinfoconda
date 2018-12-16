#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use YAML::Tiny;

my $NAME = basename($0);
my $USAGE =<<USAGE;
Usage: $NAME -f env_file

Options:
        -f|--file               The yml file containing the environment
	-h|--help       	Print this message.

Notes:
        Prints the channels of the specified environment, in the priority
        order. Remember to export the environment to a file before using
        this script, so that the channel list is updated.

Reporting bugs:
	federicomarotta AT mail DOT com
USAGE

# Parse command line options
my $help = 0;
my $env_file = '';
GetOptions(
        "file|f=s" => \$env_file,
        "help|h" => \$help
);

# Print help message
if ($help)
{
        print $USAGE;
        exit 0;
}

# Validate arguments
if ($env_file eq '')
{
        die "Error: $USAGE";
}
elsif (! -f $env_file)
{
        die "Error: $env_file is not a file.\n";
}

# Open the environment file and parse it
my $yaml = YAML::Tiny->new;
$yaml = YAML::Tiny->read($env_file);
my $channels = $yaml->[0]->{channels};

print "@$channels";

exit 0;

#!/usr/bin/perl

# NOTE: this program is for internal use only.
# Input: a conda history file
# Output: the list of manually installed packages, excluding manually 
# removed packages

use strict;
use warnings;
use File::Basename;
use Getopt::Long;

my $NAME = basename($0);
my $USAGE =<<USAGE;
Usage: $NAME -f history_file

Options:
        -f|--file               The history file of the environment
	-h|--help       	Print this message.

Notes:
        Prints the list of packages to be installed to replicate the
        environment in its current state.

Reporting bugs:
	federicomarotta AT mail DOT com
USAGE

# Parse command line options
my $help = 0;
my $history_file = '';
GetOptions(
        "file|f=s" => \$history_file,
        "help|h" => \$help
);

# Print help message
if ($help)
{
        print $USAGE;
        exit 0;
}

# Validate arguments
if ($history_file eq '')
{
        die "Error: $USAGE";
}
elsif (! -f $history_file)
{
        die "Error: $history_file is not a file.\n";
}

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

print "@update_specs";

exit 0;

# https://stackoverflow.com/questions/7651/how-do-i-remove-duplicate-items-from-an-array-in-perl
sub uniq
{
        my %seen;
        grep !$seen{$_}++, @_;
}

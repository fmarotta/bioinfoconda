#!/usr/bin/perl

use warnings;
use strict;
use Digest::SHA;
use File::Basename;
use File::Find;
use File::Path qw(make_path remove_tree);
use Getopt::Long;

# TODO: implement -R option.

# TODO: accept patterns for http too.

# TODO: check if new dest is overriding something

my $NAME = basename($0);
my $USAGE =<<USAGE;
Usage: $NAME [options] URL

Options:
        -R|--reject=pattern     Reject files matching pattern. (Not yet implemented)
        -f|--fix-index          Attempt to interactively fix the data index
	-h|--help       	Print this message.

Notes:
	URL is the Universal Resource Location of the file to download.
	$NAME can use either the ftp(s) or the http(s) protocol. In the former
	case, URLs can contain patterns (such as [], {}, ? and * elements), so
	that all the files matching the pattern are downloaded.

	The script automatically suggests a possible location to save the
	downloads: for instance, if the URL is http://foo.com/boo/bar/baz.vcf.gz,
	the suggestion will be foo/boo/bar/baz.vcf.gz. You will then be prompted
	for a new location, where you can provide an alternative path.

	If the URL ends with a trailing /, it is interpreted as /*.
	The destination path must be relative to the bioinfo data directory, and
        if it does not exist, then it is created. When the protocol is not
        specified, it is supposed to be http.

        Each time a file is downloaded, an entry to the index is 
        appended so that the user who downloaded the file, the time of the 
        download, the url and the local path are logged. If some files are moved
        or downloaded manually, the index might become unrepresentative, therefore
        it has to be fixed manually.

Reporting bugs:
	federicomarotta AT mail DOT com
USAGE

# Validate environment
if (defined $ENV{"BIOINFO_ROOT"} && length($ENV))
{
        die("ERROR: \$BIOINFO_ROOT is not defined.\n");
}
if (! -d "$ENV{'BIOINFO_ROOT'}/data")
{
        die("ERROR: $ENV{'BIOINFO_ROOT'}/data does not exists.\n")
}
my $data_root = "$ENV{'BIOINFO_ROOT'}/data/";
my $index_file = "$ENV{'BIOINFO_ROOT'}/prj/bioinfoconda/data/data_index";

# Parse command line options
my $help = 0;
my $reject = '';
my $fix_index = 0;
GetOptions(
        "reject|R=s" => \$reject,
        "fix-index|f" => \$fix_index,
        "help|h" => \$help
);

# Print help message
if ($help)
{
        print $USAGE;
        exit 0;
}

# Fix index
if ($fix_index)
{
        if (! index_diverged($index_file))
        {
                print "The index is OK.\n";
                exit 0;
        }

        edit_index($index_file);

        exit 0;
}

# By default, download
# Parse arguments
if (scalar(@ARGV) != 1)
{
        print $USAGE;
        exit 1;
}
my $url = $ARGV[0];

# Parse the URL
my ($protocol, $domain, $port, $path, @params) = parse_url($url);

# Validate the URL
my $v_url = validate_url($protocol, $domain, $port, $path, \@params);

# Find an appropriate destination path
my $dest = find_dest($domain, $path, \@params);
print "\nSaving files to $data_root$dest.\n\n";

# Finally download the files
my @output = ();
if (is_recursive($path))
{
        @output = wget_recursive($v_url, $data_root . $dest);
}
else
{
        @output = wget_simple($v_url, $data_root . $dest);
}

# Add an entry to the index file
if (@output)
{
        print "Updating index...\n";
        update_index(\@output);
}

exit 0;

# Subroutines

sub parse_url
{
        my $url = $_[0];

        my @parsed_url = ($url =~ m#^((.*)://)?(.*?)(:(\d+))?(/.*?)(\?(.+))?$#);

        for (my $i = 0; $i < scalar(@parsed_url); $i++)
        {
                if (! $parsed_url[$i])
                {
                        $parsed_url[$i] = '';
                }
        }
        if (! $parsed_url[1])
        {
                $parsed_url[1] = "http";
        }
        my @params = split(/&/, $parsed_url[6]);

        # The fields are as follows: protocol, domain name, port, path, query parameters
        return ($parsed_url[1], $parsed_url[2], $parsed_url[4], $parsed_url[5], @params);
}

sub validate_url
{
        my $protocol = $_[0];
        my $domain = $_[1];
        my $port = $_[2];
        my $path = $_[3];
        my @params = @{$_[4]};
        my $v_url = '';

        # TODO: other validations

        if ($protocol =~ m/^http/)
        {
                # Path cannot contain patterns
                if ($path =~ m/[\*\?\[\]\{\}]/)
                {
                        die("ERROR: path cannot contain patterns if the protocol is http.\n");
                }
        }
        elsif ($protocol =~ m/^ftp/)
        {
                # If url has a trailing slash, download recursively
                my @path = split(//, $path);
                if ($path[-1] eq '/')
                {
                        $path .= '*';
                }
        }
        else
        {
                die("ERROR: protocol $protocol is not supported.\n");
        }

        # Recompose the URL
        $v_url = $protocol . "://" . $domain;
        if ($port)
        {
                $v_url .= ":" . $port;
        }
        $v_url .= $path;
        if (@params)
        {
                $v_url .= "?" . join('&', @params);
        }

        return $v_url;
}

sub find_dest
{
        my $domain = $_[0];
        my $path = $_[1];
        my @params = @{$_[2]};

        # Extract the first meaningful level domain
        my @levels = split(/\./, $domain);
        my $fld = '';
        for (my $i = 0; $i < scalar(@levels); $i++)
        {
                if (is_prefix($levels[$i]) || is_pseudo($levels[$i]))
                {
                        next;
                }
                else
                {
                        $fld = $levels[$i];
                        last;
                }
        }

        # Extract a path
        my @dirs = split(/\//, $path);
        my $localdirs = '';
        for (my $i = 1; $i < scalar(@dirs); $i++)
        {
                if (is_pseudo($dirs[$i]))
                {
                        next;
                }
                else
                {
                        $localdirs .= '/' . $dirs[$i];
                }
        }

        # Add params
        if (@params)
        {
                for (my $i = 0; $i < scalar(@params); $i++)
                {
                        my @value = split(/=/, $params[$i]);
                        $localdirs .= '/' . $value[1];
                }
        }

        # Recompose the destination path
        my $tmp_dest = $fld . $localdirs;

        # Manually override the proposed destination
        my $dest = edit_dest($tmp_dest);

        return $dest;
}

sub edit_dest
{
        my $dest = $_[0];
        my $tmp_dest = '';

        print "\nThe suggested path for the files is $dest\n";

        print "\nIn order to maintain a systematic ordering of the directories, the \
destination path should be a subpath of the url (for instance, if the url is \
https://www.foo.com/bar/baz/bin/a.txt, a suitable destination could be \
foo/bin/a.txt, if bar/baz is not relevant.\n";

        print "\nEnter an empty line if the suggested path is good, otherwise type a path \
(relative to $data_root):\n";

        while (my $tmp_dest = <STDIN>)
        {
                chomp $tmp_dest;

                if ($tmp_dest ne '')
                {
                        if (is_valid_dest($tmp_dest))
                        {
                                system("echo \"$ENV{USER}: Overridding suggested path $dest with new path $tmp_dest.\" | systemd-cat -t $NAME -p notice");
                                $dest = $tmp_dest;
                                last;
                        }
                        else
                        {
                                print "The path must be relative to 
                                $data_root, and cannot contain 
                                '..'.\nTry again:\n";
                                next;
                        }
                }
                else
                {
                        last;
                }
        }

        return $dest;
}

sub wget_simple
{
        my $url = $_[0];
        my $dest = $_[1];
        my $dirname = dirname($dest);
        my @output = (0);

        unless(-d $dirname or make_path($dirname))
        {
                die("ERROR: cannot make path $dirname.\n");
        }

        open(WGETOUTPUT, "wget -O $dest $url 2>&1 |");
        while (my $line = <WGETOUTPUT>)
        {
                # update the progress line...
                if ($line =~ m/^\s+\d/)
                {
                        chomp $line;
                        print "\r$line";
                        # put back the "\n" to the last line
                        if ($line =~ m/100%/)
                        {
                                print "\n";
                        }
                }
                # ...and append the other lines
                else
                {
                        print $line;
                        # extract the information to be logged
                        if ($line =~ m/ saved \[\d+\]$/)
                        {
                                # We want @output to contain: date, 
                                # hour, url, path. But wget simple 
                                # returns only date, hour, path, so we 
                                # add the url.
                                @output = ($line =~ m/(.*) (.*) \(.*\) - '(.*)' saved \[\d+\]$/);
                                splice(@output, 2, 0, $url);
                        }
                }
        }

        return @output;
}

sub wget_recursive
{
        my $url = $_[0];
        my $dest = $_[1];
        my $dirname = dirname($dest);
        my @output = ();
        my @urldirs = split("/", $url);
        my $cutdirs;

        unless(-d $dirname or make_path($dirname))
        {
                die("ERROR: cannot make path $dirname.\n");
        }

        $cutdirs = $#urldirs-2;
        # we subtract the false dirs generated by ://
        open(WGETOUTPUT, "wget -P $dirname \\
                -N --no-verbose --show-progress \\
                -r -l inf --no-parent \\
                -nH --cut-dirs=$cutdirs \\
                $url 2>&1 |");
        while (my $line = <WGETOUTPUT>)
        {
                # update the progress line...
                if ($line =~ m/^\s+\d/ and $line =~ m/%/)
                {
                        chomp $line;
                        print "\r$line";
                        # put back the "\n" to the last line
                        if ($line =~ m/100%/)
                        {
                                print "\n";
                                # extract the information to be logged
                                if ($line !~ m/.listing/)
                                {
                                        push @output, ($line =~ m/100% .*(....-..-..) (.*) URL: (.*) \[\d+\] -> "(.*)" \[\d+\]$/);
                                }
                        }
                }
                # ...and append the other lines
                else
                {
                        print $line;
                }
        }

        return @output;
}

sub update_index
{
        my @log = @{$_[0]};
        my $sha = Digest::SHA->new(256);

        open(INDEXFILE, ">>", $index_file)
                or die "ERROR: cannot open $index_file.";

        for (my $i = 0; $i < scalar(@log); $i += 4)
        {
                # @log contains, for each file, date, hour, url, path. 
                # Logs for different files are stored sequentially, in a 
                # flat way.

                # Compute SHA for each downloaded file
                $sha->addfile($log[$i+3]);
                my $digest = $sha->hexdigest;

                # Append line to the index
                print INDEXFILE "$log[$i] $log[$i+1]\t$ENV{USER}\t$log[$i+2]\t$log[$i+3]\t$digest\n";
        }
}

sub index_diverged
{
        my $index_file = $_[0];
        my $sha = Digest::SHA->new(256);

	# Actual files under $data_root
        my %tree;
	find(sub {
    		return unless -f;       # Must be a file
		return if /^\./;	# Must not be hidden

                $sha->addfile($File::Find::name);
                my $digest = $sha->hexdigest;

                $tree{$digest} = $File::Find::name;
	}, $data_root);

        # Files in the index
        my %index;
        open(INDEXFILE, "<", $index_file)
        	or die "ERROR: cannot open $index_file.";
	while (<INDEXFILE>)
        {
                chomp;
                $index{$_[$4]} = $_[$3];
        }

        # Find sha's in common and check if they have the same path
        foreach my $sha (keys(%tree))
        {
                if (! exists $index{$sha})
                {
                        print "add $tree{$sha} to the index\n";
                }
                elsif ($tree{$sha} != $index{$sha})
                {
                        # ask to rename the files in the index
                        print "rename $index{$sha} to $tree{$sha}\n";
                }
        }

        # Find sha's only in the index
        foreach my $sha (keys(%index))
        {
                if (! exists($tree{$sha}))
                {
                        # ask to delete the files from the index
                        print "delete $index{$sha} from the index\n";
                }
        }

        # Now check if the files with the same path have actually the 
        # same sha
        %tree = reverse(%tree);
        %index = reverse(%index);
        foreach $path (keys(%tree))
        {
                if ($tree{$path} != $index{$path})
                {
                        # we have a problem: corrupted file
                        print "The file $tree{$path} is corrupted\n";
                }
        }
	
        return 0;
}

sub is_valid_dest
{
        my $dest = $_[0];

        if ($dest =~ m#^/#)
        {
                return 0;
        }
        if ($dest =~ m#\.\./#)
        {
                return 0;
        }

        return 1;
}

sub is_prefix
{
        my $level = $_[0];

        # list of prefixes
        # soe: ucsc
        # cse: ucsc
        my @prefixes = ("www", "ftp", "soe", "cse");

        for (my $i = 0; $i < scalar(@prefixes); $i++)
        {
                if ($level eq $prefixes[$i])
                {
                        return 1;
                }
        }

        return 0;
}

sub is_pseudo
{
        my $dir = $_[0];
        my @pseudodirs = ("pub", ".*?download.*?", "tmp", "files", 
                "goldenPath", "ftp", "databases");

        for (my $i = 0; $i < scalar(@pseudodirs); $i++)
        {
                if ($dir =~ m/$pseudodirs[$i]/i)
                {
                        return 1;
                }
        }

        return 0;
}

sub is_recursive
{
        my $path = $_[0];

        return ($path =~ m/[\*\?\[\]\{\}]/);
}

#!/usr/bin/env perl

# Write STDIN to a log file based on a pattern.  If rotation brings us back
# around to a filename we've used previously, we overwrite it.  Intended to
# allow logging a week's worth of stuff without having to explicitly expire old
# logs (i.e. by just logging using day of the week/month names).
#
# We keep a symlink pointing to the log file currently being written.

use strict;
use POSIX qw(strftime);
use IO::Handle;
use Cwd 'abs_path';

sub main {
     my ($pattern, $symlink_file) = @ARGV;

     if (!$pattern) {
         die "Usage: $0 <strftime pattern> [persistent symlink]"
     }

     my $current_output = "";
     my $fh = undef;

     while (my $line = <STDIN>) {
         my $output = strftime($pattern, localtime());

         if ($current_output ne $output) {
             if ($fh) {
                 close($fh);
                 unlink($output);
             }

             $current_output = $output;
             open($fh, ">>", $output);
             $fh->autoflush;

             if ($symlink_file) {
                 my $symlink_tmp = $symlink_file . "." . scalar(localtime());
                 symlink(abs_path($output), $symlink_tmp);
                 rename($symlink_tmp, $symlink_file);
             }
         }

         print $fh $line;
     }
 }

main();

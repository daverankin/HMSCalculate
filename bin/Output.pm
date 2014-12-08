# ------------------------------------------------------------------------------
#
#    Output.pm
#    Copyright (C) 2009  Field15, Inc.
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    as published by the Free Software Foundation; either version 2
#    of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
#    02110-1301, USA.
#
# ------------------------------------------------------------------------------

package Output;
use strict;

sub new {
    
    my $class = shift;
    my $self = bless {}, $class;
    $self->{TOTAL} = undef;  # in seconds
    $self->{OPERATION} = '+';
    $self->{RESULTS_CACHE} = [];
    return $self;
    
}

sub get_operation {
# Return the current value of Output->{OPERATION}

    my $self = shift;
    return $self->{OPERATION};
    
}

sub set_operation {
# Set the new value of Output->{OPERATION}

    (my $self, my $operation) = @_;
    $self->{OPERATION} = $operation;
    
}

sub all_clear {
# Delete the contents of the output field and reset all values

    (my $self, my $results) = @_;
    
    # Clear the TOTAL and RESULTS_CACHE values
    $self->{TOTAL} = 0;
    $self->{RESULTS_CACHE} = [];
    
    # Reset OPERATION to new state
    $self->{OPERATION} = '+';
    
    # Display the cleared output box
    $self->insert_hms_total($results, '00:00:00');
    $self->insert_hour_total($results, '0');
    $self->insert_minute_total($results, '0');
    $self->insert_second_total($results, '0');
    $self->cache_input($results);
    
}

sub add {
# Accepts input of time in seconds, time as formatted "HH:MM:SS" string, and the
# index of the selected item in the $results results (if any).  If this is a new
# input, add the value to $self->total and insert an anonymous array
# (["$seconds", "$raw_input"]) into $self->{RESULTS_CACHE}.  If this is an edit,
# subtract the old value at the selected index from total, add the new value
# and update $self->{RESULTS_CACHE}.
    
    my ($self, $seconds, $raw_input, $edit_index) = @_;
    if ($edit_index > 3) {
    # Editing a previous input
        $edit_index -= 4;
        my $old_value = $self->{RESULTS_CACHE}[$edit_index]->[0];
        $self->{TOTAL} -= $old_value;
        $self->{TOTAL} += $seconds;
        $self->{RESULTS_CACHE}[$edit_index]->[0] = $seconds;
        $self->{RESULTS_CACHE}[$edit_index]->[1] = '+ ' . $raw_input;
    }
    else {
    # Inserting new input
        $self->{TOTAL} += $seconds;
        push @{$self->{RESULTS_CACHE}}, ["$seconds", "+ $raw_input"];
    }
}

sub subtract {
# Accepts input of time in seconds, time as formatted "HH:MM:SS" string, and the
# index of the selected item in the $results results (if any).  If this is a new
# input, subtract the value from $self->total and insert an anonymous array
# (["$seconds", "$raw_input"]) into $self->{RESULTS_CACHE}.  If this is an edit,
# add the old value at the selected index to total, subtract the new value
# and update $self->{RESULTS_CACHE}.
    
    my ($self, $seconds, $raw_input, $edit_index) = @_;
    if ($edit_index > 3) {
    # Editing a previous input
        $edit_index -= 4;
        my $old_value = $self->{RESULTS_CACHE}[$edit_index]->[0];
        $self->{TOTAL} += $old_value;
        $self->{TOTAL} -= $seconds;
        $self->{RESULTS_CACHE}[$edit_index]->[0] = $seconds;
        $self->{RESULTS_CACHE}[$edit_index]->[1] = '- ' . $raw_input;
    }
    else {
    # Inserting new input
        $self->{TOTAL} -= $seconds;
        push @{$self->{RESULTS_CACHE}}, ["$seconds", "- $raw_input"];
    }
}

sub multiply {
# Accepts input of a floating point integer and the index of the selected item
# in the $results results (if any).  If this is a new input, multiply
# $self->total by the integer and insert an anonymous array
# (["$integer", "x $integer"]) into $self->{RESULTS_CACHE}.  If this is an edit,
# swap out the old value for the new value and re-calculate the entire
# $self->{RESULTS_CACHE} stack.
    
    my ($self, $integer, $edit_index) = @_;
    if ($edit_index > 3) {
    # Editing a previous input.  This is a little tougher with multiply, because
    # you actually need to recalculate the entire Output->{RESULTS_CACHE}
        $edit_index -= 4;

        # Replace the old value with the edited one
        $self->{RESULTS_CACHE}[$edit_index]->[0] = $integer;
        $self->{RESULTS_CACHE}[$edit_index]->[1] = 'x ' . $integer;
        
        # Recalculate entire Output->{RESULTS_CACHE} stack
        my $total = 0;
        foreach my $cache_ref (@{$self->{RESULTS_CACHE}}) {
            (my $input_value, my $string_value) = @$cache_ref;
            $string_value =~ s/x/\*/g; # Multiplication displayed as x but substituted as *
            (my $operation) = $string_value =~ /^(.)/;
            my $calculation = "$total $operation $input_value";
            $total = eval $calculation;
        }
        $self->{TOTAL} = $total;        
    }
    else {
    # Inserting new input
        $self->{TOTAL} *= $integer;
        push @{$self->{RESULTS_CACHE}}, ["$integer", "x $integer"];
    }
}

sub divide {
# Accepts input of a floating point integer and the index of the selected item
# in the $results results (if any).  If this is a new input, divide
# $self->total by the integer and insert an anonymous array
# (["$integer", "x $integer"]) into $self->{RESULTS_CACHE}.  If this is an edit,
# swap out the old value for the new value and re-calculate the entire
# $self->{RESULTS_CACHE} stack.
    
    my ($self, $integer, $edit_index) = @_;
    if ($edit_index > 3) {
    # Editing a previous input.  This is a little tougher with multiply, because
    # you actually need to recalculate the entire Output->{RESULTS_CACHE}
        $edit_index -= 4;
        
        # Replace the old value with the edited one
        $self->{RESULTS_CACHE}[$edit_index]->[0] = $integer;
        $self->{RESULTS_CACHE}[$edit_index]->[1] = '/ ' . $integer;
        
        # Recalculate entire Output->{RESULTS_CACHE} stack
        my $total = 0;
        foreach my $cache_ref (@{$self->{RESULTS_CACHE}}) {
            (my $input_value, my $string_value) = @$cache_ref;
            (my $operation) = $string_value =~ /^(.)/;
            my $calculation = "$total $operation $input_value";
            $total = eval $calculation;
        }
        $self->{TOTAL} = $total;        
    }
    else {
    # Inserting new input
        $self->{TOTAL} /= $integer;
        push @{$self->{RESULTS_CACHE}}, ["$integer", "/ $integer"];
    }
}

sub cache_input {
# Accepts a reference to a results ($results) and insert the current value of
# $self->{RESULTS_CACHE} starting at results[4]

    my ($self, $results) = @_;
    $results->delete(4,'end');
    my @display_results;
    foreach my $result_ref (@{$self->{RESULTS_CACHE}}) {
        push @display_results, $result_ref->[1];
    }
    $results->insert(4,@display_results);

}

sub update_totals {
# Given the current value of $self->{TOTAL}, calculate and display HMS, HOUR,
# MINUTE, and SECOND totals.

    my ($self, $results) = @_;
    
    # Seconds
    my $total_in_seconds = $self->{TOTAL};
    $self->insert_second_total($results, $total_in_seconds);
    
    # Minutes
    my $total_in_minutes = sprintf "%.02f", ($total_in_seconds / 60);
    $self->insert_minute_total($results, $total_in_minutes);
    
    # Hours
    my $total_in_hours = sprintf "%.02f", ($total_in_seconds / 3600);
    $self->insert_hour_total($results, $total_in_hours);
    
    # HMS
    my $hh = '00';
    my $mm = '00';
    my $ss = '00';
    my $remainder = $total_in_seconds;
    my $direction = ($remainder >= 0) ? '' : '- ';
    $remainder = abs $remainder;
    if ($remainder >= 3600) {
        # Calculate hours
        $hh = sprintf "%02u", (int($remainder / 3600));
        $remainder = $remainder % 3600;  
    }
    if ($remainder >= 60) {
        # Calculate minutes
        $mm = sprintf "%02u", (int($remainder / 60));
        $remainder = $remainder % 60;
    }
    $ss = sprintf "%02u", $remainder;
    $self->insert_hms_total($results, "$direction$hh:$mm:$ss");
    
}

sub insert_hms_total {
# Accepts a value in the format hh:mm:ss, deletes $results->(0), and inserts
# the passed value prepended with text.

    my ($self, $results, $hms) = @_;
    return if ($hms !~ /\d+:\d+:\d/);
    $results->delete(0);
    $results->insert(0, "[HMS] $hms");
    
}

sub insert_hour_total {
# Accepts a value in the format d.d, deletes $results->(0), and inserts
# the passed value prepended with text.

    my ($self, $results, $hour) = @_;
    $results->delete(1);
    $results->insert(1, "[HOURS] $hour");
    
}

sub insert_minute_total {
# Accepts a value in the format d.d, deletes $results->(0), and inserts
# the passed value prepended with text.

    my ($self, $results, $minute) = @_;
    $results->delete(2);
    $results->insert(2, "[MINUTES] $minute");
    
}

sub insert_second_total {
# Accepts a value in the format d.d, deletes $results->(0), and inserts
# the passed value prepended with text.

    my ($self, $results, $second) = @_;
    $results->delete(3);
    $results->insert(3, "[SECONDS] $second");
    
}

1;

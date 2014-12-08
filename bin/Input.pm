# ------------------------------------------------------------------------------
#
#    Input.pm
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

package Input;
use strict;

sub new {
    
    my $class = shift;
    my $self = bless {}, $class;
    $self->{HOUR} = undef;
    $self->{MINUTE} = undef;
    $self->{SECOND} = undef;
    $self->{INTEGER} = undef;
    $self->{FOCUS} = undef;
    $self->{HOUR_FIELD} = undef;
    $self->{MINUTE_FIELD} = undef;
    $self->{SECOND_FIELD} = undef;
    $self->{INTEGER_FIELD} = undef;
    return $self;
    
}

sub hour_field {
# Accepts a reference to a Tk::Input object that holds the hour input data.  
# Sets the value of $self->{HOUR_FIELD} to the Tk::Input object.

    my ($self, $field_name) = @_;
    $self->{HOUR_FIELD} = $$field_name;
    
}

sub minute_field {
# Accepts a reference to a Tk::Input object that holds the minute input data.  
# Sets the value of $self->{MINUTE_FIELD} to the Tk::Input object.
    
    my ($self, $field_name) = @_;
    $self->{MINUTE_FIELD} = $$field_name;
    
}

sub second_field {
# Accepts a reference to a Tk::Input object that holds the second input data.  
# Sets the value of $self->{SECOND_FIELD} to the Tk::Input object.

    my ($self, $field_name) = @_;
    $self->{SECOND_FIELD} = $$field_name;
    
}

sub integer_field {
# Accepts a reference to a Tk::Input object that holds the integer input data.  
# Sets the value of $self->{INTEGER_FIELD} to the Tk::Input object.

    my ($self, $field_name) = @_;
    $self->{INTEGER_FIELD} = $$field_name;
    
}

sub get_focus {
# Returns the current value of $self->{FOCUS} which indicates which input
# field currently has focus.

    my $self = shift;
    return $self->{FOCUS};
    
}

sub set_focus {
# Sets the current value of $self->{FOCUS} to indicate which input
# field currently has focus.

    my ($self, $focus) = @_;
    $self->{FOCUS} = $focus;
    return;
    
}

sub buffer {
# Verifies a request to insert a character into the input field that currently
# has focus.  If the character is valid, it's inserted.  If not, the request
# is either ignored (if called from clicking on an interface button) or undone
# (if called from keyboard input).
    
    ## Parse the input
    my ($self, $char) = @_;

    if ($char !~ /BackSpace/ && $char !~ /Delete/ && $char !~ /period/) {
        $char =~ s/[^\d]//g;
        return if ($char !~ /[\d]/);
    }
    my $focus = $self->get_focus;
    return if (! $focus);
    
    ## Find the field that's in focus
    my $field;
    $field = $self->{HOUR_FIELD} if ($focus eq 'hh');
    $field = $self->{MINUTE_FIELD} if ($focus eq 'mm');
    $field = $self->{SECOND_FIELD} if ($focus eq 'ss');
    $field = $self->{INTEGER_FIELD} if ($focus eq 'integer');
    
    ## Check for multiple decimal points
    if ($char =~ /period/) {
    ## Remove multiple decimal points
        $char = '.';
        my $value = $field->get();
        (my @points) = $value =~ /(\.)/g;
        return if ($#points >= 0);
    }
    
    ## Find out if anything in this field is highlighted, if so, clear the
    ## highlighted text and input the new text there; otherwise, input it
    ## at the end of the field.
    if ($field->selectionPresent()) {
        $field->insert('sel.first', $char);
        $field->delete('sel.first', 'sel.last');
    }
    else {
        $field->insert('end', $char);
    }    
}

sub verify {
# Verifies keyboard input into the main input fields.  If the character that
# was inputted is invalid, it's removed.
    
    ## Parse the input
    my ($self, $char) = @_;
    my $focus = $self->get_focus;
    return if (! $focus);
    
    ## Find the field that's in focus
    my $field;
    $field = $self->{HOUR_FIELD} if ($focus eq 'hh');
    $field = $self->{MINUTE_FIELD} if ($focus eq 'mm');
    $field = $self->{SECOND_FIELD} if ($focus eq 'ss');
    $field = $self->{INTEGER_FIELD} if ($focus eq 'integer');
        
    ## Verify $char
    if ($char !~ /BackSpace/ && $char !~ /\bDelete/ && $char !~ /Left/ && $char !~ /Right/) {
        my $value = $field->get();
        if ($char !~ /[\d.]/ && $char !~ /period/) {
        ## Remove any character that isn't a digit or decimal point
            $value =~ s/[^\d.]//g;
            $field->delete(0, 'end');
            $field->insert('end', $value);
        }
        if ($char =~ /period/ || $char =~ /Begin/ || $char =~ /Delete/) {
        ## Remove multiple decimal points
            (my @points) = $value =~ /(\.)/g;
            if ($#points > 0) {
                (my $pre_point, my $post_point) = $value =~ /([^.]+)\.(.+)/;
                $post_point =~ s/\.//g;
                $field->delete(0, 'end');
                $field->insert(0, "$pre_point.$post_point");
            }
        }
    }
}

sub clear {
# Delete the contents of the input box that currently has focus

    my $self = shift;
    my $focus = $self->get_focus;
    return if (! $focus);
    
    ## Find the field that's in focus
    my $field;
    $field = $self->{HOUR_FIELD} if ($focus eq 'hh');
    $field = $self->{MINUTE_FIELD} if ($focus eq 'mm');
    $field = $self->{SECOND_FIELD} if ($focus eq 'ss');
    $field = $self->{INTEGER_FIELD} if ($focus eq 'integer');
    
    ## Delete the contents of that field
    $field->delete(0, 'end');
    
}

sub all_clear {
# Delete the contents of all input boxes and set focus to $mw

    my $self = shift;
    
    ## Delete the contents of all input fields
    my @input_fields = qw(HOUR_FIELD MINUTE_FIELD SECOND_FIELD INTEGER_FIELD);
    foreach my $field_name (@input_fields) {
        my $field = $self->{$field_name};
        $field->delete(0, 'end');
        
    }
}

sub total_in_seconds {
# Convert the HH:MM:SS values in all input boxes to a sum in seconds.

    my $self = shift;
    my $minutes = 0;
    my $seconds = 0;
    
    ## Convert and add hours
    my $hour_field = $self->{HOUR_FIELD};
    my $hours = $hour_field->get();
    if ($hours =~ /\./) {
    ## The hours value contains a decimal point which means it equals
    ## hours.(percent of an hour)  Multiply the whole hours by 3600 and add
    ## that value to $seconds.  Multiply the percent by 60 and add that value
    ## to $minutes to be dealt with in the minute conversion below
        (my $hh, my $percent) = $hours =~ /([^.]+)(.[\d]+)/;
        $seconds += ($hh * 3600);
        my $mm = $percent * 60;
        $minutes += $mm;
    }
    else {
    ## The hours are a whole number
        $seconds += ($hours * 3600);
    }
    
    ## Convert and add minutes
    my $minute_field = $self->{MINUTE_FIELD};
    $minutes += $minute_field->get();
    if ($minutes =~ /\./) {
    ## The minutes value contains a decimal point which means it equals
    ## minutes.(percent of a minute)  Multiply the whole hours by 60 and add
    ## that value to $seconds.  Multiply the percent by 60 and add that value
    ## to $seconds to be dealt with in the second conversion below
        (my $mm, my $percent) = $minutes =~ /([^.]+)(.[\d]+)/;
        $seconds += ($mm * 60);
        my $ss = $percent * 60;
        $seconds += $ss;
    }
    else {
    ## The minutes are a whole number
        $seconds += ($minutes * 60);
    }
    
    ## Convert and add seconds
    my $second_field = $self->{SECOND_FIELD};
    $seconds += $second_field->get();
    if ($seconds =~ /\./) {
    ## The seconds value contains a decimal point wich means it equals
    ## seconds.(percent of a second).  All seconds are simply rounded up,
    ## so round the seconds up or down based on the first significant digit.
        (my $ss, my $sig_num) = $seconds =~ /([^.]+)\.(\d)/;
        $ss += ($sig_num >= 5) ? 1 : 0;
        $seconds = $ss;
    }
    
    return $seconds;

}

sub raw_input {
# Grab the input currently in all three input fields, pad it to at least two
# characters, format it, and return it

    my $self = shift;
    
    my $hour_field = $self->{HOUR_FIELD};
    my $hours = $hour_field->get();
    $hours = sprintf "%02u", $hours if ($hours !~ /\./);
    
    my $minute_field = $self->{MINUTE_FIELD};
    my $minutes = $minute_field->get();
    $minutes = sprintf "%02u", $minutes if ($minutes !~ /\./);
    
    my $second_field = $self->{SECOND_FIELD};
    my $seconds = $second_field->get();
    $seconds = sprintf "%02u", $seconds if ($seconds !~ /\./);
    
    return "$hours:$minutes:$seconds";
    
}

sub integer_input {
# Grab the input currently in integer input field and return it

    my $self = shift;
    
    my $integer_field = $self->{INTEGER_FIELD};
    my $integer = $integer_field->get();
    
    return $integer;
    
}

1;

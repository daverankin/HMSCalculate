#!/usr/bin/perl

# ------------------------------------------------------------------------------
#
#    HMSCalculate
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

# Import 
use strict;
use FindBin;
my $BASE_DIR = substr $FindBin::Bin, 0, ((length $FindBin::Bin) - 4);
use lib "$BASE_DIR/bin/";
use Input;
use Output;
use Helpdoc;
use Tk;
use Tk::Canvas;
use Tk::Photo;
use Tk::PNG;
use subs qw(file_menuitems help_menuitems);


# ------------------------------------------------------------------------------
# Record Keeping
my $APP_NAME = 'HMSCalculate 1.0';
my $LAST_UPDATE = 'Last updated on March 28, 2009';
my $COPYRIGHT = 'Copyright (C) 2009  Field15, Inc.';


# ------------------------------------------------------------------------------
# External paths and files
my $BIN_DIR = "$BASE_DIR/bin/";
my $DOCS_DIR = "$BASE_DIR/docs/";
my $IMAGES_DIR = "$BASE_DIR/images/";
my $SOURCE_DIR = "$BASE_DIR/source/";
my %img;
    

# ------------------------------------------------------------------------------
# Basic screen and geometry setup
my $mw = tkinit;
$mw->title($APP_NAME);
$mw->minsize(qw(284 400));
$mw->maxsize(qw(284 400));
my $mw_x = (($mw->screenwidth()) / 2) - 142;
my $mw_y = (($mw->screenheight()) / 2) - 200;
$mw->geometry("+$mw_x+$mw_y");

# ------------------------------------------------------------------------------
# MW GUI widgets and objects
my %os;    # Populated by mw_version_control() to make OS specific adjustments
mw_load_images();
my $input = Input->new();
my $output = Output->new();
my $helpdoc = ($^O =~ /mswin/i) ?
    Helpdoc->new(\$mw, $DOCS_DIR . 'en-us_help.xml', '', $img{icon}{chrome_icon}) :
    Helpdoc->new(\$mw, $DOCS_DIR . 'en-us_help.xml', \$img{default}{chrome_icon}, $img{mask}{chrome_icon});
my $about_window;

# App background
my $background = $mw->Label(-width=> 284, -height=> 400, -image=> $img{default}{background}, -border=> 0)->place(-x=> 0, -y=>0);

# App menus
my @menus;
my $file_menu = $mw->Menu(-tearoff=> 0, -relief=> 'raised', -foreground=> '#000000', -background=> '#aaaaaa', -activeforeground=> '#ffffff', -activebackground=> '#666666', -activeborderwidth=> 0, -borderwidth=> 1);
$file_menu->command(-label=> 'Exit', -command=> sub {exit(0)});
push @menus, $file_menu;

my $help_menu = $mw->Menu(-tearoff=> 0, -relief=> 'raised', -foreground=> '#000000', -background=> '#aaaaaa', -activeforeground=> '#ffffff', -activebackground=> '#666666', -activeborderwidth=> 0, -borderwidth=> 1);
$help_menu->command(-label=> 'Help', -command=> sub {$helpdoc->show()});
$help_menu->command(-label=> 'About', -command=> \&mw_about);
push @menus, $help_menu;

my $menu_canvas = $mw-> Canvas(-width=> 284, -height=> 20, -highlightthickness=> 0)->place(-x=> 0, -y=> 0);
$menu_canvas-> createImage(0, 0, -image=> $img{default}{menu_background}, -anchor=> 'nw');
my $file_menu_button = $menu_canvas->createImage(10, 4, -image=> $img{default}{file_menu}, -anchor=> 'nw', -tag=> 'file_menu');
$menu_canvas->bind('file_menu', '<ButtonPress>' => sub {mw_manage_menu($file_menu, 10, $os{menu_vertical_offset})});
my $help_menu_button = $menu_canvas->createImage(42, 4, -image=> $img{default}{help_menu}, -anchor=> 'nw', -tag=> 'help_menu');
$menu_canvas->bind('help_menu', '<ButtonPress>' => sub {mw_manage_menu($help_menu, 42, $os{menu_vertical_offset})});


# Input field
my $hms_input_frame = $mw->Frame(-width=> 264, -height=> 24)->place(-x=> 10, -y=> 20);
my $hms_hhframe = $hms_input_frame->Frame(-width=> 84, -height=> 24)->pack(-side=> 'left');
    $hms_hhframe->packPropagate(0);
    my $hh_field = $hms_hhframe->Entry(-validate=>'focusin', -exportselection=> 0, -validatecommand=>sub { $input->set_focus('hh'); })->pack(-expand=> 1, -fill=> 'x');
my $hms_c1frame = $hms_input_frame->Frame(-width=> 6, -height=> 24)->pack(-side=> 'left');
    $hms_c1frame->packPropagate(0);
    my $colon1 = $hms_c1frame->Label(-width=> 2, -height=> 10, -image=> $img{default}{colon}, -border=> 0)->pack(-pady=> 6);
my $hms_mmframe = $hms_input_frame->Frame(-width=> 84, -height=> 24)->pack(-side=> 'left');
    $hms_mmframe->packPropagate(0);
    my $mm_field = $hms_mmframe->Entry(-validate=>'focusin', -exportselection=> 0, -validatecommand=>sub { $input->set_focus('mm') })->pack(-expand=> 1, -fill=> 'x');
my $hms_c2frame = $hms_input_frame->Frame(-width=> 6, -height=> 24)->pack(-side=> 'left');
    $hms_c2frame->packPropagate(0);
    my $colon2 = $hms_c2frame->Label(-width=> 2, -height=> 10, -image=> $img{default}{colon}, -border=> 0)->pack(-pady=> 6);
my $hms_ssframe = $hms_input_frame->Frame(-width=> 84, -height=> 24)->pack(-side=> 'left');
    $hms_ssframe->packPropagate(0);
    my $ss_field = $hms_ssframe->Entry(-validate=>'focusin', -exportselection=> 0, -validatecommand=>sub { $input->set_focus('ss') })->pack(-expand=> 1, -fill=> 'x');
my $dec_input_frame = $mw->Frame(-width=> 264, -height=> 24)->place(-x=> 10, -y=> 20);
    $dec_input_frame->packPropagate(0);
    my $integer_field = $dec_input_frame->Entry(-width=> 5, -validate=>'focusin', -validatecommand=>sub { $input->set_focus('integer') })->pack(-expand=> 1, -fill=> 'x');
$dec_input_frame->placeForget();

$input->hour_field(\$hh_field);
$input->minute_field(\$mm_field);
$input->second_field(\$ss_field);
$input->integer_field(\$integer_field);

# Input buttons
my $button_canvas = $mw-> Canvas(-width=> 284, -height=> 118, -highlightthickness=> 0)->place(-x=> 0, -y=> 54);
$button_canvas-> createImage(0, 0, -image=> $img{default}{button_background}, -anchor=> 'nw');

# ------------------
# ROW 1:  1-2-3-C-AC
my $one_button = $button_canvas->createImage(12, 0, -image=> $img{default}{1}, -anchor=> 'nw', -tag=> 'one_button');
$button_canvas->bind('one_button', '<Enter>' => sub {onMouseO($one_button, $img{over}{1})});
$button_canvas->bind('one_button', '<ButtonPress>' => sub {onPress($one_button, $img{down}{1})});
$button_canvas->bind('one_button', '<ButtonRelease>' =>
	sub {
		onRelease($one_button, $img{default}{1});
		$input->buffer(1);
	});
$button_canvas->bind('one_button', '<Leave>' => sub {onMouseO($one_button, $img{default}{1})});

my $two_button = $button_canvas->createImage(62, 0, -image=> $img{default}{2}, -anchor=> 'nw', -tag=> 'two_button');
$button_canvas->bind('two_button', '<Enter>' => sub {onMouseO($two_button, $img{over}{2})});
$button_canvas->bind('two_button', '<ButtonPress>' => sub {onPress($two_button, $img{down}{2})});
$button_canvas->bind('two_button', '<ButtonRelease>' =>
	sub {
		onRelease($two_button, $img{default}{2});
		$input->buffer(2);
	});
$button_canvas->bind('two_button', '<Leave>' => sub {onMouseO($two_button, $img{default}{2})});

my $three_button = $button_canvas->createImage(112, 0, -image=> $img{default}{3}, -anchor=> 'nw', -tag=> 'three_button');
$button_canvas->bind('three_button', '<Enter>' => sub {onMouseO($three_button, $img{over}{3})});
$button_canvas->bind('three_button', '<ButtonPress>' => sub {onPress($three_button, $img{down}{3})});
$button_canvas->bind('three_button', '<ButtonRelease>' =>
	sub {
		onRelease($three_button, $img{default}{3});
		$input->buffer(3);
	});
$button_canvas->bind('three_button', '<Leave>' => sub {onMouseO($three_button, $img{default}{3})});

my $clear_button = $button_canvas->createImage(174, 0, -image=> $img{default}{c}, -anchor=> 'nw', -tag=> 'clear_button');
$button_canvas->bind('clear_button', '<Enter>' => sub {onMouseO($clear_button, $img{over}{c})});
$button_canvas->bind('clear_button', '<ButtonPress>' => sub {onPress($clear_button, $img{down}{c})});
$button_canvas->bind('clear_button', '<ButtonRelease>' =>
	sub {
		onRelease($clear_button, $img{default}{c});
		mw_clear();
	});
$button_canvas->bind('clear_button', '<Leave>' => sub {onMouseO($clear_button, $img{default}{c})});

my $all_clear_button = $button_canvas->createImage(224, 0, -image=> $img{default}{ac}, -anchor=> 'nw', -tag=> 'all_clear_button');
$button_canvas->bind('all_clear_button', '<Enter>' => sub {onMouseO($all_clear_button, $img{over}{ac})});
$button_canvas->bind('all_clear_button', '<ButtonPress>' => sub {onPress($all_clear_button, $img{down}{ac})});
$button_canvas->bind('all_clear_button', '<ButtonRelease>' =>
	sub {
		onRelease($all_clear_button, $img{default}{ac});
		mw_all_clear();
	});
$button_canvas->bind('all_clear_button', '<Leave>' => sub {onMouseO($all_clear_button, $img{default}{ac})});

# ------------------
# ROW 2:  4-5-6-+-x
my $four_button = $button_canvas->createImage(12, 30, -image=> $img{default}{4}, -anchor=> 'nw', -tag=> 'four_button');
$button_canvas->bind('four_button', '<Enter>' => sub {onMouseO($four_button, $img{over}{4})});
$button_canvas->bind('four_button', '<ButtonPress>' => sub {onPress($four_button, $img{down}{4})});
$button_canvas->bind('four_button', '<ButtonRelease>' =>
	sub {
		onRelease($four_button, $img{default}{4});
		$input->buffer(4);
	});
$button_canvas->bind('four_button', '<Leave>' => sub {onMouseO($four_button, $img{default}{4})});

my $five_button = $button_canvas->createImage(62, 30, -image=> $img{default}{5}, -anchor=> 'nw', -tag=> 'five_button');
$button_canvas->bind('five_button', '<Enter>' => sub {onMouseO($five_button, $img{over}{5})});
$button_canvas->bind('five_button', '<ButtonPress>' => sub {onPress($five_button, $img{down}{5})});
$button_canvas->bind('five_button', '<ButtonRelease>' =>
	sub {
		onRelease($five_button, $img{default}{5});
		$input->buffer(5);
	});
$button_canvas->bind('five_button', '<Leave>' => sub {onMouseO($five_button, $img{default}{5})});

my $six_button = $button_canvas->createImage(112, 30, -image=> $img{default}{6}, -anchor=> 'nw', -tag=> 'six_button');
$button_canvas->bind('six_button', '<Enter>' => sub {onMouseO($six_button, $img{over}{6})});
$button_canvas->bind('six_button', '<ButtonPress>' => sub {onPress($six_button, $img{down}{6})});
$button_canvas->bind('six_button', '<ButtonRelease>' =>
	sub {
		onRelease($six_button, $img{default}{6});
		$input->buffer(6);
	});
$button_canvas->bind('six_button', '<Leave>' => sub {onMouseO($six_button, $img{default}{6})});

my $plus_button = $button_canvas->createImage(174, 30, -image=> $img{default}{plus}, -anchor=> 'nw', -tag=> 'plus_button');
$button_canvas->bind('plus_button', '<Enter>' => sub {onMouseO($plus_button, $img{over}{plus})});
$button_canvas->bind('plus_button', '<ButtonPress>' => sub {onPress($plus_button, $img{down}{plus})});
$button_canvas->bind('plus_button', '<ButtonRelease>' =>
	sub {
		onRelease($plus_button, $img{default}{plus});
		mw_process('+');
	});
$button_canvas->bind('plus_button', '<Leave>' => sub {onMouseO($plus_button, $img{default}{plus})});

my $times_button = $button_canvas->createImage(224, 30, -image=> $img{default}{times}, -anchor=> 'nw', -tag=> 'times_button');
$button_canvas->bind('times_button', '<Enter>' => sub {onMouseO($times_button, $img{over}{times})});
$button_canvas->bind('times_button', '<ButtonPress>' => sub {onPress($times_button, $img{down}{times})});
$button_canvas->bind('times_button', '<ButtonRelease>' =>
	sub {
		onRelease($times_button, $img{default}{times});
		mw_process('x');
	});
$button_canvas->bind('times_button', '<Leave>' => sub {onMouseO($times_button, $img{default}{times})});

# ------------------
# ROW 3:  7-8-9---/
my $seven_button = $button_canvas->createImage(12, 60, -image=> $img{default}{7}, -anchor=> 'nw', -tag=> 'seven_button');
$button_canvas->bind('seven_button', '<Enter>' => sub {onMouseO($seven_button, $img{over}{7})});
$button_canvas->bind('seven_button', '<ButtonPress>' => sub {onPress($seven_button, $img{down}{7})});
$button_canvas->bind('seven_button', '<ButtonRelease>' =>
	sub {
		onRelease($seven_button, $img{default}{7});
		$input->buffer(7);
	});
$button_canvas->bind('seven_button', '<Leave>' => sub {onMouseO($seven_button, $img{default}{7})});

my $eight_button = $button_canvas->createImage(62, 60, -image=> $img{default}{8}, -anchor=> 'nw', -tag=> 'eight_button');
$button_canvas->bind('eight_button', '<Enter>' => sub {onMouseO($eight_button, $img{over}{8})});
$button_canvas->bind('eight_button', '<ButtonPress>' => sub {onPress($eight_button, $img{down}{8})});
$button_canvas->bind('eight_button', '<ButtonRelease>' =>
	sub {
		onRelease($eight_button, $img{default}{8});
		$input->buffer(8);
	});
$button_canvas->bind('eight_button', '<Leave>' => sub {onMouseO($eight_button, $img{default}{8})});

my $nine_button = $button_canvas->createImage(112, 60, -image=> $img{default}{9}, -anchor=> 'nw', -tag=> 'nine_button');
$button_canvas->bind('nine_button', '<Enter>' => sub {onMouseO($nine_button, $img{over}{9})});
$button_canvas->bind('nine_button', '<ButtonPress>' => sub {onPress($nine_button, $img{down}{9})});
$button_canvas->bind('nine_button', '<ButtonRelease>' =>
	sub {
		onRelease($nine_button, $img{default}{9});
		$input->buffer(9);
	});
$button_canvas->bind('nine_button', '<Leave>' => sub {onMouseO($nine_button, $img{default}{9})});

my $minus_button = $button_canvas->createImage(174, 60, -image=> $img{default}{minus}, -anchor=> 'nw', -tag=> 'minus_button');
$button_canvas->bind('minus_button', '<Enter>' => sub {onMouseO($minus_button, $img{over}{minus})});
$button_canvas->bind('minus_button', '<ButtonPress>' => sub {onPress($minus_button, $img{down}{minus})});
$button_canvas->bind('minus_button', '<ButtonRelease>' =>
	sub {
		onRelease($minus_button, $img{default}{minus});
		mw_process('-');
	});
$button_canvas->bind('minus_button', '<Leave>' => sub {onMouseO($minus_button, $img{default}{minus})});

my $divide_button = $button_canvas->createImage(224, 60, -image=> $img{default}{divide}, -anchor=> 'nw', -tag=> 'divide_button');
$button_canvas->bind('divide_button', '<Enter>' => sub {onMouseO($divide_button, $img{over}{divide})});
$button_canvas->bind('divide_button', '<ButtonPress>' => sub {onPress($divide_button, $img{down}{divide})});
$button_canvas->bind('divide_button', '<ButtonRelease>' =>
	sub {
		onRelease($divide_button, $img{default}{divide});
		mw_process('/');
	});
$button_canvas->bind('divide_button', '<Leave>' => sub {onMouseO($divide_button, $img{default}{divide})});

# ------------------
# ROW 4:  0-.-=
my $zero_button = $button_canvas->createImage(62, 90, -image=> $img{default}{0}, -anchor=> 'nw', -tag=> 'zero_button');
$button_canvas->bind('zero_button', '<Enter>' => sub {onMouseO($zero_button, $img{over}{0})});
$button_canvas->bind('zero_button', '<ButtonPress>' => sub {onPress($zero_button, $img{down}{0})});
$button_canvas->bind('zero_button', '<ButtonRelease>' =>
	sub {
		onRelease($zero_button, $img{default}{0});
		$input->buffer(0);
	});
$button_canvas->bind('zero_button', '<Leave>' => sub {onMouseO($zero_button, $img{default}{0})});

my $decimal_button = $button_canvas->createImage(174, 90, -image=> $img{default}{decimal}, -anchor=> 'nw', -tag=> 'decimal_button');
$button_canvas->bind('decimal_button', '<Enter>' => sub {onMouseO($decimal_button, $img{over}{decimal})});
$button_canvas->bind('decimal_button', '<ButtonPress>' => sub {onPress($decimal_button, $img{down}{decimal})});
$button_canvas->bind('decimal_button', '<ButtonRelease>' =>
	sub {
		onRelease($decimal_button, $img{default}{decimal});
		$input->buffer('period');
	});
$button_canvas->bind('decimal_button', '<Leave>' => sub {onMouseO($decimal_button, $img{default}{decimal})});

my $equals_button = $button_canvas->createImage(224, 90, -image=> $img{default}{equals}, -anchor=> 'nw', -tag=> 'equals_button');
$button_canvas->bind('equals_button', '<Enter>' => sub {onMouseO($equals_button, $img{over}{equals})});
$button_canvas->bind('equals_button', '<ButtonPress>' => sub {onPress($equals_button, $img{down}{equals})});
$button_canvas->bind('equals_button', '<ButtonRelease>' =>
	sub {
		onRelease($equals_button, $img{default}{equals});
		mw_process('=');
	});
$button_canvas->bind('equals_button', '<Leave>' => sub {onMouseO($equals_button, $img{default}{equals})});

# Output Fields and Object
my $results_input_frame = $mw->Frame(-width=> 264, -height=> 200)->place(-x=> 10, -y=> 182);
$results_input_frame->packPropagate(0);
my $results = $results_input_frame->Scrolled('Listbox', -scrollbars=>'se', -selectmode=>'single', -width=>33)->pack(-side=>'top', -expand=> 1, -fill=> 'both');
$output->insert_hms_total($results, '00:00:00');
$output->insert_hour_total($results, '0');
$output->insert_minute_total($results, '0');
$output->insert_second_total($results, '0');


# ------------------------------------------------------------------------------
# Global Bindings
$hh_field->bind('<KeyPress>' => sub {
# Tie keyboard numbers to $hh_field

    my $event = $hh_field->XEvent;
    my $key = $event->K;
    $input->verify($key);
    
});

$mm_field->bind('<KeyPress>' => sub {
# Tie keyboard numbers to $mm_field

    my $event = $mm_field->XEvent;
    my $key = $event->K;
    $input->verify($key);
    
});

$ss_field->bind('<KeyPress>' => sub {
# Tie keyboard numbers to $ss_field

    my $event = $ss_field->XEvent;
    my $key = $event->K;
    $input->verify($key);
    
});

$integer_field->bind('<KeyPress>' => sub {
# Tie keyboard numbers to $integer_field

    my $event = $integer_field->XEvent;
    my $key = $event->K;
    $input->verify($key);
    
});

$mw->bind('<KeyPress-plus>' => sub {
# Tie keyboard '+' (shift+=) to $mw
    mw_process('+');
});

$mw->bind('<KeyPress-KP_Add>' => sub {
# Tie keyboard numpad '+' to $mw
    mw_process('+');
});

$mw->bind('<KeyPress-minus>' => sub {
# Tie keyboard '-' (-) to $mw
    mw_process('-');
});

$mw->bind('<KeyPress-KP_Subtract>' => sub {
# Tie keyboard numpad '-' to $mw
    mw_process('-');
});

$mw->bind('<KeyPress-asterisk>' => sub {
# Tie keyboard '*' (shift+8) to $mw
    mw_process('x');
});

$mw->bind('<KeyPress-KP_Multiply>' => sub {
# Tie keyboard numpad '*' to $mw
    mw_process('x');
});

$mw->bind('<KeyPress-slash>' => sub {
# Tie keyboard '/' to $mw
    mw_process('/');
});

$mw->bind('<KeyPress-KP_Divide>' => sub {
# Tie keyboard numpad '/' to $mw
    mw_process('/');
});

$mw->bind('<KeyPress-equal>' => sub {
# Tie keyboard '=' to $mw
    mw_process('=');
});

$mw->bind('<KeyPress-KP_Enter>' => sub {
# Tie keyboard numpad 'Enter' to $mw on non-Windows
    mw_process('=');
});

$mw->bind('<KeyPress-Return>' => sub {
# Tie keyboard numpad 'Enter' to $mw on Windows
    mw_process('=');
});

## For Testing: See which key was pressed
#$mw->bind('<KeyRelease>' => \&print_keysym);
#sub print_keysym {
#    my ($widget) = @_;
#    my $e = $widget->XEvent;
#    my ($keysym_text, $keysym_decimal) = ($e->K, $e->N);
#    print qq(keysym-$keysym_text, numeric=$keysym_decimal\n);
#}

$results->bind('<ButtonRelease-1>' => sub {
# Tie mouse clicks in the $results listbox to re-inserting a cached output
# into the input fields

    
    # Get the value currently selected in $results
    my @selected_value = $results->curselection;
    my $display_string = $results->get($selected_value[0]);
    (my $cached_operation) = $display_string =~ /^(.)/; 
    $display_string =~ s/^[^\d\.]+//g;
    
    # Don't allow clicks on the first 4 options (HMS, Hours, Minutes, Seconds)
    if ($selected_value[0] < 4) {
        $results->selectionClear(0, 'end');
        return;
    }
    
    $input->all_clear();
    
    # If the $cached_operation was +|- do branch A else do branch B.
    if ($cached_operation eq '+' || $cached_operation eq '-') {
        
        # Swap $integer field for the $hh - $ss fields
        $dec_input_frame->placeForget();
        $hms_input_frame->place(-x=> 10, -y=> 20);
        $hh_field->focus();
        
        # Parse the value into $hh, $mm, $ss vars
        my ($hh, $mm, $ss);
        if ($display_string =~ /:/) {
            ($hh, $mm, $ss) = split ':', $display_string;
        }
        else {
            $ss = $display_string;
        }
        
        # Insert $hh, $mm, $ss into input fields
        $hh_field->insert(0, $hh);
        $mm_field->insert(0, $mm);
        $ss_field->insert(0, $ss);
        
        # Set Output->set_operation to $cached_operation so user can press
        # '=' after editing cached input
        $output->set_operation($cached_operation);
        
    }
    else {
        
        # Swap $hh - $ss fields for $integer
        $hms_input_frame->placeForget();
        $dec_input_frame->place(-x=> 10, -y=> 20);
        $integer_field->focus();
        
        # Insert $integer into input field
        $integer_field->insert(0, $display_string);
        
        # Set Output->set_operation to $cached_operation so user can press
        # '=' after editing cached input
        $output->set_operation($cached_operation);
        
    }
});


# ------------------------------------------------------------------------------
# Make OS specific adjustments
mw_version_control();
eval mw_set_icon('mw');


# ------------------------------------------------------------------------------
# MainLoop and Clean-Up
MainLoop;
exit 0;

# ------------------------------------------------------------------------------
# MainWindow Subroutines

sub onMouseO {
# Swap out the graphic being used in $widget for the one passed here

	(my $widget, my $image) = @_;
	$button_canvas->itemconfigure($widget, -image=> $image);
    
}

sub onPress {
# Swap out the graphic being used in $widget for the one passed here

	(my $widget, my $image) = @_;
	$button_canvas->itemconfigure($widget, -image=> $image);

}

sub onRelease {
# Swap out the graphic being used in $widget for the one passed here

	(my $widget, my $image) = @_;
	$button_canvas->itemconfigure($widget, -image=> $image);

}

sub mw_clear {
# Clear the current entries/selection

    $input->all_clear();
    $results->selectionClear(0, 'end');
    $mw->focus;
    
}

sub mw_all_clear {
# Clear all input and output fields and reset all values

    $input->all_clear();
    $output->all_clear($results);
    $hms_input_frame->place(-x=> 10, -y=> 20);
    $dec_input_frame->placeForget();
    $mw->focus;
    
}

sub mw_process {
# When +, -, x, /, or = are pressed, that actually tells the calculator to
# process the last operation command as stored in Output->{OPERATION} and then, 
# when done, reset the value of Output->{OPERATION} to the value of the button
# that was just pressed.

    my $next_operation = shift;
    my $operation = $output->get_operation();
    mw_add() if ($operation eq '+');
    mw_subtract() if ($operation eq '-');
    mw_multiply() if ($operation eq 'x');
    mw_divide() if ($operation eq '/');
    $output->set_operation($next_operation);
    
    if ($next_operation eq 'x' || $next_operation eq '/') {
    # When multiplying/dividing swap the $hh - $ss fields and ':' labels out
    # for the $integer field
    
        $hms_input_frame->placeForget();
        $dec_input_frame->place(-x=> 10, -y=> 20);
        $integer_field->focus();
        
    }
}

sub mw_add {
# Add current input to total

    $output->add($input->total_in_seconds(), $input->raw_input(), $results->curselection);
    $output->cache_input($results);
    $output->update_totals($results);
    $input->all_clear();
    
}

sub mw_subtract {
# Subtract current input from total

    $output->subtract($input->total_in_seconds(), $input->raw_input(), $results->curselection);
    $output->cache_input($results);
    $output->update_totals($results);
    $input->all_clear();
    
}

sub mw_multiply {
# Multiply current input to total

    $output->multiply($input->integer_input(), $results->curselection);
    $output->cache_input($results);
    $output->update_totals($results);
    $input->all_clear();
    
    # Swap $integer field out for $hh - $ss and ':' labels
    $hms_input_frame->place(-x=> 10, -y=> 20);
    $dec_input_frame->placeForget();
    
}

sub mw_divide {
# Divide total by current input

    $output->divide($input->integer_input(), $results->curselection);
    $output->cache_input($results);
    $output->update_totals($results);
    $input->all_clear();
    
    # Swap $integer field out for $hh - $ss and ':' labels
    $hms_input_frame->place(-x=> 10, -y=> 20);
    $dec_input_frame->placeForget();
    
}

sub mw_load_images {
# Define and load all image files

    # background, menu_background, colon, button_canvas, file_menu, help_menu,
    # chrome icon, and about screen icon
    $img{default}{background} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'background.png');
    $img{default}{colon} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'colon.png');
    $img{default}{menu_background} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'menu_background.png');
    $img{default}{button_background} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'button_background.png');
    $img{default}{file_menu} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'file_menu.png');
    $img{default}{help_menu} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'help_menu.png');
    $img{default}{chrome_icon} = $mw-> Photo(-format=> "gif", -file=> $IMAGES_DIR . 'chrome_icon.gif');
    $img{mask}{chrome_icon} = $IMAGES_DIR . 'chrome_icon.xbm';
    $img{icon}{chrome_icon} = $IMAGES_DIR . 'shortcut_32x32.ico';
    $img{default}{about_logo} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'about_logo.png');

    # 0
    $img{default}{0} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '0_default.png');
    $img{over}{0} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '0_over.png');
    $img{down}{0} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '0_down.png');
    # 1
    $img{default}{1} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '1_default.png');
    $img{over}{1} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '1_over.png');
    $img{down}{1} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '1_down.png');
    # 2
    $img{default}{2} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '2_default.png');
    $img{over}{2} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '2_over.png');
    $img{down}{2} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '2_down.png');
    # 3
    $img{default}{3} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '3_default.png');
    $img{over}{3} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '3_over.png');
    $img{down}{3} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '3_down.png');
    # 4
    $img{default}{4} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '4_default.png');
    $img{over}{4} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '4_over.png');
    $img{down}{4} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '4_down.png');
    # 5
    $img{default}{5} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '5_default.png');
    $img{over}{5} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '5_over.png');
    $img{down}{5} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '5_down.png');
    # 6
    $img{default}{6} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '6_default.png');
    $img{over}{6} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '6_over.png');
    $img{down}{6} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '6_down.png');
    # 7 
    $img{default}{7} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '7_default.png');
    $img{over}{7} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '7_over.png');
    $img{down}{7} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '7_down.png');
    # 8
    $img{default}{8} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '8_default.png');
    $img{over}{8} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '8_over.png');
    $img{down}{8} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '8_down.png');
    # 9
    $img{default}{9} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '9_default.png');
    $img{over}{9} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '9_over.png');
    $img{down}{9} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . '9_down.png');
    # ac
    $img{default}{ac} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'ac_default.png');
    $img{over}{ac} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'ac_over.png');
    $img{down}{ac} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'ac_down.png');
    # c
    $img{default}{c} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'c_default.png');
    $img{over}{c} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'c_over.png');
    $img{down}{c} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'c_down.png');
    # decimal
    $img{default}{decimal} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'decimal_default.png');
    $img{over}{decimal} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'decimal_over.png');
    $img{down}{decimal} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'decimal_down.png');
    # divide
    $img{default}{divide} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'divide_default.png');
    $img{over}{divide} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'divide_over.png');
    $img{down}{divide} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'divide_down.png');
    # equals
    $img{default}{equals} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'equals_default.png');
    $img{over}{equals} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'equals_over.png');
    $img{down}{equals} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'equals_down.png');
    # minus
    $img{default}{minus} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'minus_default.png');
    $img{over}{minus} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'minus_over.png');
    $img{down}{minus} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'minus_down.png');
    # plus
    $img{default}{plus} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'plus_default.png');
    $img{over}{plus} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'plus_over.png');
    $img{down}{plus} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'plus_down.png');
    # times
    $img{default}{times} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'times_default.png');
    $img{over}{times} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'times_over.png');
    $img{down}{times} = $mw-> Photo(-format=> "png", -file=> $IMAGES_DIR . 'times_down.png');

}

sub mw_manage_menu {
# Given a menu, display or hide at the appropriate coords

    (my $menu, my $x_shift, my $y_shift) = @_;
    if ($menu->ismapped) {
    # Already visible, so hide
        $menu->unpost;
    }
    else {
    # Hide all menus then display requested $menu
        
        foreach my $m (@menus) {
            $m->unpost;
        }
        my $x = ($mw->x + $x_shift);
        my $y = ($mw->y + $y_shift);
        $menu->post($x,$y);
    }
}

sub mw_about {

    if (! $about_window || ! Exists($about_window)) {
        
        # Create and geometerize the new toplevel
        $about_window = $mw->Toplevel(-background => '#ffffff');
        $about_window->title($APP_NAME);
        eval mw_set_icon('about_window');
        #$about_window->iconimage($img{default}{chrome_icon});
        #$about_window->iconmask('@' . $img{mask}{chrome_icon});
        $about_window->minsize(qw(227 400));
        $about_window->maxsize(qw(227 400));
        my $about_window_x = (($mw->screenwidth()) / 2) - 114;
        my $about_window_y = (($mw->screenheight()) / 2) - 200;
        $about_window->geometry("+$about_window_x+$about_window_y");
        
        # Insert the logo
        $about_window->Label(-width=> 227, -height=> 227, -image=> $img{default}{about_logo}, -border=> 0)->place(-x => 0, -y => 0);
        
        # Insert the text
        my $about_text_frame = $about_window->Frame(-width=> 227, -height=> 173)->place(-x => 0, -y => 227);
        $about_text_frame->packPropagate(0);
        #my $about_rotext = $about_text_frame->Scrolled('ROText', -scrollbars=>'e',
        #    -background=> '#ffffff', -relief=> 'flat', -borderwidth=> 0,
        #    -highlightcolor=> '#ffffff', -wrap=> 'word', -font=> [-size => '8'])->pack(-side=>'top', -expand=> 1, -fill=> 'both');
        my $about_rotext = $about_text_frame->ROText(-background=> '#ffffff', -relief=> 'flat', -borderwidth=> 0,
            -highlightcolor=> '#ffffff', -wrap=> 'word', -font=> [-size => '8'])->pack(-side=>'top', -expand=> 1, -fill=> 'both');
        my $about_text =
            qq($APP_NAME\n) .
            qq($LAST_UPDATE\n) .
            qq($COPYRIGHT\n\n) .
            qq(Designed By: Catharine Rankin\n) .
            qq(Programmed By: Dave Rankin\n\n) .
            qq(For more information about the Standard Edition visit http://www.field15.com\n\n) .
            qq(For more information about the Community Edition visit http://dave.caretcake.com\n\n);
        $about_rotext->insert('end', $about_text);
        
    }
    else {
        $about_window->deiconify();
        $about_window->raise();
    }
}


sub mw_version_control {
## Set OS specific values in %os for:
## menu_vertical_offset - vertical offset for dropdown windows

    $os{menu_vertical_offset} = ($^O =~ /mswin/i) ? 46 : 17; 
    
}


sub mw_set_icon {
## Return OS specific window icon creation code given the string name of
## some toplevel element to apply the icon to.  Eval the returned result
## to display the icon

    my $parent_element = shift;
    my $set_icon_string = ($^O =~ /mswin/i) ?
        'use Tk::Icon;  $' . $parent_element . '->setIcon(-file=> $img{icon}{chrome_icon});' : 
        '$' . $parent_element . '->iconimage($img{default}{chrome_icon}); $' . $parent_element . '->iconmask(\'@\' . $img{mask}{chrome_icon});';
    return $set_icon_string;
    
}
# ------------------------------------------------------------------------------
#
#    Helpdoc.pm
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

package Helpdoc;
use strict;
use Tk;
use Tk::ROText;
use XML::Simple qw(:strict);

sub new {
    
    (my $class, my $parent, my $data_source, my $icon, my $icon_mask) = @_;
    my $self = bless {}, $class;
    $self->{PARENT} = $$parent;
    $self->{DATA_SOURCE} = $data_source;
    $self->{ICON} = ($icon) ? $$icon : undef;
    $self->{ICON_MASK} = ($icon_mask) ? $icon_mask : undef;
    $self->{DATA} = undef;
    $self->{TITLE} = undef;
    $self->{VERSION} = undef;
    $self->{LAST_REVISED} = undef;
    $self->{AUTHOR} = undef;
    $self->{COPYRIGHT} = undef;
    $self->{TOC} = [];
    $self->{WIDTH} = undef;
    $self->{HEIGHT} = undef;
    $self->{ISMAPPED} = undef;
    $self->{MW} = undef;
    return $self;
    
}

sub show {
# Called by parent app.  If Helpdoc window is not mapped, populate and create
# a new Helpdoc window; otherwise, ignore request.

    my ($self, $width, $height) = @_;
    if (! $self->{MW} || ! Exists($self->{MW})) {
        $self->{WIDTH} = $width if ($width);
        $self->{HEIGHT} = $height if ($height);
        $self->populate();  
    }
}

sub hide {
# undef Helpdoc->{ISMAPPED} so that a new Helpdoc window can be called by
# Helpdoc->show() and destroy Helpdoc->{MW}.

    my $self = shift;
    undef $self->{ISMAPPED}; 
    $self->{MW}->destroy;
    
}

sub populate {
# Using the values set during Helpdoc->new(), create and populate a Helpdoc
# window called Helpdoc->{MW}.

    my $self = shift;
    
    # Check that we know where to get the data file and that it actually exists.
    # If not, display an error message.  If so, create the Helpdoc window.
    if (! $self->{DATA_SOURCE}) {
        $self->load_error('No help documentation specified.');
        return;
    }
    
    if (! -e $self->{DATA_SOURCE}) {
        $self->load_error("Help documentation could not be found at\n" . $self->{DATA_SOURCE});
        return;
    }

    # Everything's fine, so create the window and load the data
    my $parent = $self->{PARENT};
    my $mw = $parent->Toplevel();
    $self->{MW} = $mw;
    if ($^O =~ /mswin/i) {
        if ($self->{ICON_MASK}) {
            ## Why eval? Because I develop on Linux and Tk::Icon isn't available there
            eval 'use Tk::Icon;';
            $self->{MW}->setIcon(-file=> $self->{ICON_MASK});
        }
    }
    else {
        $self->{MW}->iconimage($self->{ICON}) if ($self->{ICON});
        $self->{MW}->iconmask('@' . $self->{ICON_MASK}) if ($self->{ICON_MASK});
    }
    $mw->title('Help Documentation');
    my $min_x = ($self->{WIDTH}) ? $self->{WIDTH} : 600;
    my $min_y = ($self->{HEIGHT}) ? $self->{HEIGHT} : 440;   
    $mw->minsize("250", "250");
    # Wanna set the maxsize dynamicall?  Uncomment the line below
#    $mw->maxsize("$min_x", "$min_y");
    my $mw_x = (($mw->screenwidth()) / 2) - (($min_x / 2) + 100);
    my $mw_y = (($mw->screenheight()) / 2) - ($min_y / 2);
    $mw->geometry("+$mw_x+$mw_y");
    
    # Listbox frame
    my $toc_frame_width = $min_x * .35;
    my $toc_frame = $mw->Frame(-width=> $toc_frame_width)->pack(-side=> 'left', -fill=> 'both');
    $toc_frame->packPropagate(0);
    my $toc = $toc_frame->Scrolled('Listbox', -scrollbars=>'se', -selectmode=>'single',
        -background=> '#ffffff', -foreground=> '#000000', -selectbackground=> '#bbbbbb')->pack(-expand=> 1, -fill=>'both');
    $self->load_doc();
    $toc->insert('end', @{$self->{TOC}});
    
    # ROText frame
    my $text_frame_width = $min_x * .65;
    my $text_frame = $mw->Frame(-width=> $text_frame_width)->pack(-side=> 'left',-expand=> 1, -fill=> 'both');
    my $text = $text_frame->Scrolled('ROText', -scrollbars=> 'se', 
        -background=> '#ffffff', -foreground=> '#000000', -selectbackground=> '#bbbbbb',
        -wrap => 'none')->pack(-expand=> 1, -fill=>'both');
    
    # Style tags
    $text->tagConfigure("a", -foreground => "blue");
    $text->tagConfigure("b", -font => [-weight => 'bold']);
    $text->tagConfigure("i", -font => [-slant => 'italic']);
    $text->tagConfigure("u", -underline => 1);
    
    # Two following lines pre-populate $text with the first 'page' of content
    (my $content, my $style_data) = $self->load_page(0);
    $text->insert('end', $content);
    
    # Apply styles
    while ((my $tag, my $unsorted_indecies) = each %$style_data) {
        my @indecies = sort {$a<=>$b} @$unsorted_indecies;
        for (my $i = 0; $i <= $#indecies; $i+=2) {
            my $begin = $indecies[$i];
            my $end = $indecies [$i + 1];
            $text->tagAdd("$tag", "$begin", "$end");
        }
    }

    
    # Bindings
    $toc->bind('<<ListboxSelect>>' =>
        sub {
            (my $content, my $style_data) = $self->load_page($toc->curselection);
            $text->delete('1.0', 'end');
            $text->insert('end', $content);

            # Apply styles
            while ((my $tag, my $unsorted_indecies) = each %$style_data) {
                my @indecies = sort {$a<=>$b} @$unsorted_indecies;
                for (my $i = 0; $i <= $#indecies; $i+=2) {
                    my $begin = $indecies[$i];
                    my $end = $indecies [$i + 1];
                    $text->tagAdd("$tag", "$begin", "$end");
                }
            }
        });
    
    ## If you wanted a button to close the Helpdoc window, you could use this
    #$mw->Button(-text=> 'Close', -command=>
    #    sub {
    #        $self->hide;
    #})->pack;
    
    $self->{ISMAPPED} = 1;
    MainLoop;
    
}

sub load_doc {
# Given the path to an XML file with the expected structure, parse the data
# into key general document datapoints, a TOC, and related help content.
# Set the values of Helpdoc->{DATA_SOURCE}, Helpdoc->{DATA}, Helpdoc->{TITLE}, 
# Helpdoc->{VERSION}, Helpdoc->{LAST_REVISED}, Helpdoc->{AUTHOR},
# Helpdoc->{COPYRIGHT}, and Helpdoc->{TOC}
    
    my $self = shift;
    my $xs = XML::Simple->new(ForceArray => qw(topic), KeepRoot => 1);
    $self->{DATA} = $xs->XMLin($self->{DATA_SOURCE}, KeyAttr => "helpfile");
    
    # General document data
    $self->{TITLE} = $self->{DATA}->{helpfile}[0]->{title}[0];
    $self->{VERSION} = $self->{DATA}->{helpfile}[0]->{version}[0];
    $self->{LAST_REVISED} = $self->{DATA}->{helpfile}[0]->{last_revised}[0];
    $self->{AUTHOR} = $self->{DATA}->{helpfile}[0]->{author}[0];
    $self->{COPYRIGHT} = $self->{DATA}->{helpfile}[0]->{copyright}[0];
    
    # Index    
    my @raw_contents = @{$self->{DATA}->{helpfile}[0]->{topic}};
    $self->{TOC} = [];
    foreach my $record_index (0 .. $#raw_contents) {
        push @{$self->{TOC}}, $raw_contents[$record_index]->{index_title}[0];
    }
}

sub load_page {
# Given a "$page" (the index of the desired content in the selected topic
# element of the XML document), return the value (the documentation itself)

    my ($self, $page) = @_;
    my $raw_content = $self->{DATA}->{helpfile}[0]->{topic}[$page]->{content};
    (my $stylized_content, my $style_data) = $self->transform($raw_content);
    return $stylized_content, $style_data;
        
}

sub load_error {
# Display a popup error message when there's a problem finding/loading
# the specified XML document.

    my ($self, $message) = @_;
    
    my $mw = tkinit;
    $mw->title('ERROR');
    $mw->minsize(qw(400 50));
    my $mw_x = (($mw->screenwidth()) / 2) - 200;
    my $mw_y = (($mw->screenheight()) / 2) - 50;
    $mw->geometry("+$mw_x+$mw_y");
            
    $mw->Label(-textvariable=> \$message)->pack(-side=> 'top');
    $mw->Button(-text=> 'Close', -command=> sub {$mw->destroy})->pack(-side=> 'top');
    MainLoop;
    
}

sub transform {
# Given a string from an Helpdoc DTD XML file's <content> node, parse the
# string for line breaks and style and return the formatted string along with
# reference to %style_tags, which holds a hash of which tags TK should add
# at which indecies in the text widget.  (TK tags are defined above in populate().)

    my ($self, $content) = @_;
    
    # Define known spacing tags for simple substitution
    my %spacing_tags = (
        '<p>'       => '',
        '</p>'      => "\n\n",
        '<br />'    => "\n",
    );
    
    # Define known style tags to be passed back as array references indicating
    # line indecies to start and stop the tags.
    my %style_tags = (
        'a' => [],
        'b' => [],
        'i' => [],
        'u' => [],
    ); 
    
    # Split string into an array
    my @lines = split "\n", $content;
    
    # Translate tags line by line
    my $transformed_content;
    foreach my $index (1 .. $#lines) {
        
        # Define text and line number
        my $line_text = $lines[$index];
        my $line_num = $index;
        
        # Clean up spacing (beginning whitespace, <p> and <br> tags)
        $line_text =~ s/^( |\t)+//g;
        while ((my $tag, my $format) = each %spacing_tags) {
            $line_text =~ s/\Q$tag\E/$format/g;
        }
        
        # Handle style (<b>, <i>, <u>, etc.)
        foreach my $tag (keys %style_tags) {
            $_ = $line_text;
            while (/(<\/?$tag>)/g) {
                my $captured = $1;
                my $char_index = ($captured =~ /\//) ? pos() - 7 : pos() - 3;
                my $sel_index = $line_num . '.' . $char_index;
                push @{$style_tags{$tag}}, $sel_index;
            }
            $line_text =~ s/<\/?$tag>//g;
        }
        
        $transformed_content .= $line_text;
        $transformed_content .= "\n" if ($transformed_content !~ /\n$/);
    }
    
    # Return transformed content
    return $transformed_content, \%style_tags;
    
}

1;


__END__

KNOWN ISSUES:
1. Right now, due to transform() algorithm, you're really limited to one tag
   perl line.  The problem is that the value of $char_index at line 263
   should be calculated dynamically by the number of tags already found on that
   line.

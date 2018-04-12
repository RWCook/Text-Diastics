package Text::Diastics;

use 5.006;
use strict;
use warnings;
use Moo;
use List::Util qw(shuffle);

our $VERSION= '0.01_01';

has seed_text=> (
    is => 'ro',
    required => 0,
    reader=> 'get_seed_text',
    );

has source_text=>(
    is => 'ro',
    required => 0,
    reader=>'get_source_text',
    );

has seed_file=> (
	is => 'ro',
	required => 0,
	);

has source_file=> (
	is => 'ro',
	required => 0,
	);

has reverse_source=> (
    is => 'ro',
    default=> sub { return 'N';},
    reader => 'get_reverse_source',
    );

has shuffle_source => (
    is => 'ro',
    default => sub {return 'N';},
    reader => 'get_shuffle_source',
    );

#has diastic_text=> (
#    is => 'rw',
    #   reader => 'get_diastic_text',
    #);

has cycle=> (
    is => 'rw',
    default=> sub { return 1;},
    reader => 'get_cycle',
    );

has diastic=> (
    is => 'rw',
    reader => 'get_diastic',
);


sub make_diastic {
    my $self=shift;

    if (defined($self->{seed_file})==1 && $self->{seed_file} ne '') {
        $self->{seed_text}= _read_fh($self->{seed_file});
    }

    if (defined($self->{source_file})==1 && $self->{source_file} ne '') {
        $self->{source_text}= _read_fh($self->{source_file});
    }

    my $source_text=_clean_text($self->{source_text});
    my @source_text=split / /,$source_text;

    if ($self->{reverse_source} eq "Y") {
    @source_text=reverse @source_text;
    }

    if ($self->{shuffle_source} eq "Y") {
    	@source_text=shuffle @source_text;
    }

    my @source_words;
    for my $i(1..$self->{cycle}) {
    push @source_words,@source_text;
    }

    my $seed_text=_clean_text($self->{seed_text});
    my @seed_words=split / /,$seed_text;

    $self->{diastic}= _process_text(\@source_words,\@seed_words);
}

sub _read_fh {
my $file=shift;
my $text='';
open my $fh,'<',$file or die "File $file does not exist\n";
while (<$fh>) {
	$text=$text .= $_ . ' ';
}
close $fh;
return $text;
}

sub print_diastic {
my ($self,$options)=@_;
my $lines=0;
my $out;
my $output_file='N';

if (defined($options->{output_file})==1 && $options->{output_file} ne '') {
	open $out,'>',$options->{output_file};
	$output_file='Y';	
}

my @diastic=split(/ /,$self->{diastic});
for my $i (0..$#diastic) {


if (($i+1) % $options->{words_per_line} ==0) {
if ($output_file eq 'Y') {
print $out $diastic[$i] . "\n";
}
else {
print $diastic[$i] . "\n";
}
$lines++;
    if ($lines % $options->{lines_per_stanza}==0) {
	if ($output_file eq 'Y') {
    	print $out "\n";
	}
	else {
    print "\n";
	}
    }
}
else {
	if ($output_file eq "Y") {

	print $out $diastic[$i] . " ";
	}
	else {
print $diastic[$i] . " ";
	}
}

}

if (defined($options->{output_file})==1 && $options->{output_file} ne '') {
close($out);	
}
}

sub _process_text {
my ($source_words,$seed_words)=@_;

my @diastic;

    for my $seed_counter (0..$#{$seed_words}) {
           for my $letter_count (0..length($seed_words->[$seed_counter])-1) {
            my $current_character=substr $seed_words->[$seed_counter],$letter_count,1;

                    my $test_result=0;

			my $loop_counter=0;
                    while ($test_result==0) {
                   	my $word_to_test=$source_words->[$loop_counter];

                    $test_result=_test_word($current_character,$letter_count,$word_to_test);

                        if ($test_result ==1) {
                        push @diastic,$word_to_test;
			for my $i(0..$loop_counter) {

                        	shift @{$source_words};
			}
                        }
                        if ($test_result==2) {   #Has run out of words
                        }
			$loop_counter++;
                    }
            }

    }
my $diastic;
for my $i(0..$#diastic) {
	$diastic.=" " . $diastic[$i];
}
$diastic=~s/ $//;
$diastic=~s/^ //;
return $diastic;
}

sub _test_word {
my ($character_to_check_for,$letter_position,$word_to_test)=@_;
if (defined($word_to_test)==0) {
    return 2;
    }
#print $character_to_check_for . "\t" . $letter_position . "\t" . $word_to_test . "\n";

if ($letter_position > length $word_to_test ) {
    #print "Letter position too great to test\n";
    return 0;
    }

#-1 because substr starts at char 0
if (substr($word_to_test,$letter_position,1) eq $character_to_check_for ) {
    #print "MATCH\n";
    return 1;
    }
    else {
    #print substr($word_to_test,$letter_position-1,1);
    #print "NO MATCH\n";
    return 0;
    }

}

sub _clean_text {
my $text=shift;
$text=~s/[^A-Za-z\- ]//g;
$text=lc $text;
return $text;
}
1;

__END__
=head1 NAME

Text::Diastics 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Module to generate text using the poet Jackson Mac Low's diastics text 
generation method. This uses a seed text and a source text. For each letter
of the seed text, the source text is read until a word is found in which the 
current letter occurs in the same position as in the seed text. Words which 
do not match are effectively discarded as the process takes the next letter
and picks up at the position in the source text where it left off.


    use Text::Diastics;

    my $text = Text::Diastics->new(
			{
			seed_text=> $seed_text,
			source_text=> $source_text,
			shuffle_source=>'Y',
			reverse_source=>'Y',
			cycle => 1,
			}
			);

The source_text is text that is used as a source for the generated text.
The seed text is read through to determine the letters required and their
required position in the source text.

If shuffle_source is set to 'Y' then the source text will be randomised
before the text is generated. If reverse_source is set to 'Y' then the
source text is searched in reverse. Cycle describes the number of times
the seed text is read through against the source.

The field shuffle_source defaults to 'N' if not supplied.

The field reverse_source defaults to 'N' if not supplied.

The field cycle defaults to 1 if not supplied.

=head1 METHODS

=head2 $text->make_diastic();

This generates the text output so is the most important method.

=head2 $text->print_diastic(2,2);

This prints the diastic and takes 2 arguments:

words_per_line
stanza_break_every_x_lines

=head2 $text->get_seed_text();

Returns the seed text.

=head2 $text->get_source_text();

Returns the source text.

=head2 $text->get_shuffle_source();

Returns the value for shuffle_source (i.e. whether the source was shuffled).

=head2 $text->get_reverse_source();

Returns the value for reverse_source (i.e. whether the source was reversed or not.)

=head2 $text->get_cycle();

Returns the number of cycles through the seed text.

=head2 $text->get_diastic();


=cut

=head1 AUTHOR

Robert Cook, C<< <CookR271 at aol.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-diastics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Diastics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Diastics


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Diastics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Diastics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Diastics>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Diastics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Cook.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

 # End of Text::Diastics

package Search::FreeText::LexicalAnalysis::Stem;

# Author: Stuart Watt
# Copyright (c) The Robert Gordon University

use strict;
use warnings;

=head1 NAME

Search::FreeText::LexicalAnalysis::Stem - lexicon interface to Lingua::Stem

=head1 DESCRIPTION

A filter which uses Lingua::Stem to implement the Porter stemming
algorithm.  This can then be included in a search system as a part
of the indexing and query system.  

The filter is wrapped up a bit.  This is because Lingua::Stem 
turns nonwords into absolutely nothing at all.  To overcome this, 
we only stem words, and merge nonwords back in after they have 
been stemmed. 

=head1 SYNOPSIS

 my $stemmer = new Search::FreeText::LexicalAnalysis::Stem ();
 my $words = $lexicaliser->process($oldwords);

=cut

use Lingua::Stem;

sub new {
    my ($classname, @args) = @_;
    my $class = ref($classname) || $classname;
    my $self = { @args };
    $self = bless $self, $class;
    $self->initialize();
    return $self;
};

=head1 METHODS

=over 4

=item $self->initialize();

Called when the lexicon system is initialised.  This method actually
creates and stores the stemmer, and can be overridden if needed.  

=cut

sub initialize {
  my ($self) = @_;
  $self->{_Stemmer} = new Lingua::Stem;
};

=item $self->process($oldwords);

Called to process a reference to an array of words, and returns a 
reference to an array of stemmed words for further processing. Words
that are not stemmable are left in place, which is a slight performance
hit as we need to wrap Lingua::Stem, but these are real words for
indexing so we mustn't just lose them!

=cut

sub process {
  my ($self, $oldwords) = @_;
  my @nonwords = ();
  my @choices = ();
  my @words = grep { my $nextword = $_;
		     my $isword = ($nextword =~ /[A-Za-z]+/);
		     push @choices, $isword;
		     push @nonwords, $nextword unless ($isword);
		     $isword; } @$oldwords; 
  my $words = $self->{_Stemmer}->stem(@words);
  @choices = map { if ($_) { shift @$words; } else { shift @nonwords; } } @choices;
  return \@choices;
};

1;

__END__

=back

=head1 AUTHOR

Stuart Watt <S.N.K.Watt@rgu.ac.uk>

Copyright (c) 2003 The Robert Gordon University.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

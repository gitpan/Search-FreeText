package Search::FreeText::LexicalAnalysis::Heuristics;

# Author: Stuart Watt
# Copyright (c) The Robert Gordon University

use strict;
use warnings;

=head1 NAME

Search::FreeText::LexicalAnalysis::Heuristics - lexical analysis heuristics

=head1 DESCRIPTION

A pseudo-filter which does a bit before we get into the real lexical
analysis system.  This can do full text substitutions and corrections on
the free text.  It's really there to handle a few minor corrections and
linguistic issues which can break the later stages.  The main issue it
handles is prefixes, which are sometimes fixed with a "-" character and
sometimes without.  We fix this. 

=head1 SYNOPSIS

 my $stemmer = new Search::FreeText::LexicalAnalysis::Heuristics();
 my $words = $lexicaliser->process($oldwords);

=cut

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
does very little, although it could compile and cache stuff if it 
seemed appropriate.  

=cut

sub initialize {
  my ($self) = @_;
};

=item $self->process($oldwords);

Called to process a reference to an array containing strings (well, 
one string) which can then be tokenised for further lexical processing.

Heuristics applied include:

=over 4

=item *

Convert a few common prefixes with hyphenations, e.g. re-, pre-, and
so on, into complete words.  This is useful for words where the prefix
affects the sense of the word (other prefixes don't to the same
extent) and where we don't want the prefix treated as a separate word.  
For example "re-cycled" is the same as "recycled", not as "re cycled". 
In comparison, "case-based" should be treated as "case based", not as
"casebased".  

=back

=cut

sub process {
  my ($self, $oldwords) = @_;
  my $string = join("\n", @$oldwords);

  # Handle some prefixes.  
  my $oldstring = $string;
  $string =~ s/\b(re|pre|non|de)\-/$1/egi;
  return [ $string ];
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

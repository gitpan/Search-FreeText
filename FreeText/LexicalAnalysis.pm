package Search::FreeText::LexicalAnalysis;

# Author: Stuart Watt
# Copyright (c) The Robert Gordon University

use strict;
use warnings;

=head1 NAME

Search::FreeText::LexicalAnalysis - basic lexical analyser for the open search system

=head1 DESCRIPTION

An open lexical analysis processor, which you can either override by
subclassing, or which you can add your own filters to.  Each filter is
called with a reference to an array of words, and returns a reference
to a new array of words.  This is the process method, and the base
class Search::FreeText::LexicalAnalysisProcess defines the protocol for
each step in the pipeline.

=head1 SYNOPSIS

 # Selects default filters
 my $lexicalizer = new Search::FreeText::LexicalAnalysis ();
 # Selects named filters only
 my $lexicalizer = new Search::FreeText::LexicalAnalysis 
     (-filters => [ qw(MyLexicalAnalysis::Heuristics
		       Search::FreeText::LexicalAnalysis::Tokenize
		       Search::FreeText::LexicalAnalysis::Stop 
		       Search::FreeText::LexicalAnalysis::Stem) ]);

 my $words = $lexicalizer->process($text);

=head1 METHODS

=over 4

=item new Search::FreeText::LexicalAnalysis( -search => searchmod [, -filters => FilterList] );

This is the main constructor for a lexicon.  The -search parameter
passes the search object instance, and is passed in turn to each of
the filters, allowing them to look inside the search instance for
any additional data if they need to. 

You can use the -filters initialisation key to pass a list of classes
for filters. By default the set of filters implements stemming, a
reasonably complete stop list, and a few heuristics that tighten up
the searching.  the order of the filters is fairly important, and
looks a bit like this:

=over 4

=item Heuristics

Pattern-level heuristics that work on whole strings, implemented 
by default by Search::FreeText::LexicalAnalysis::Heuristics.

=item Tokenize

Splits a set of strings into an array of words.  Implemented by
default by Search::FreeText::LexicalAnalysis::Tokenize.  Before this,
strings represent documents; after this, they represent words,
which is why its position in the list of filters is important. 

=item Stop

Pass the array of words through a stop list filter, removing
words that are likely to be irrelevant.  Implemented by default
by Search::FreeText::LexicalAnalysis::Stop.

=item Stem

Pass the array of words through a stemmer.  Implemented by default
by Search::FreeText::LexicalAnalysis::Stem, which in turn uses 
Lingua::Stem. 

=cut

sub new {
    my ($classname, @args) = @_;
    my $class = ref($classname) || $classname;
    my $self = { -filters => [ qw(Search::FreeText::LexicalAnalysis::Heuristics
				  Search::FreeText::LexicalAnalysis::Tokenize
				  Search::FreeText::LexicalAnalysis::Stop 
				  Search::FreeText::LexicalAnalysis::Stem) ],
		 @args };
    $self = bless $self, $class;
    $self->initialize();
    return $self;
};

=item $self->initialize();

Initializes the lexical analyser, loading any modules that are needed
for the list of filters. 

=cut

sub initialize {
    my ($self) = @_;
    my $search = $self->{-search};
    my @filters = map { 
	my $name = $_;
	my $file = $name;
	$file =~ s|::|/|g;
	$file .= ".pm";
	
	require($file) or die "$!";
	$name->new(-search => $search);
    } @{$self->{-filters}};
    $self->{_Filters} = \@filters;
    return unless ($self->{_Filters});
};

=item $self->process(words...);

Passes the list of words to the filters as a pipeline.  The array of words
usually starts as a single string containing all the words, and one of the
filters (Tokenize) turns this into an array of individual words.  This allows
some processing before words are split, as well as the usual stemming and 
stoplisting afterwards. 

=cut

sub process {
  my ($self, @words) = @_;
  my $oldwords = \@words;
  map { 
    $oldwords = $_->process($oldwords);
  } @{$self->{_Filters}};

  return $oldwords;
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

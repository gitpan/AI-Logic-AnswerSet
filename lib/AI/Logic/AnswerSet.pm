package AI::Logic::AnswerSet;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

sub executeFromFileAndSave {		#Executes DLV with a file as input and saves the output in another file

	open DLVW, ">>", "$_[1]";
	print DLVW $_[2];
	close DLVW;

	open(SAVESTDOUT, ">&STDOUT") or die "Can't save STDOUT: $!\n";
	open(STDOUT, ">$_[0]") or die "Can't open STDOUT to $_[0]", "$!\n";


	my @args = ("./dlv", "$_[1]");
	system(@args) == 0
		or die "system @args failed: $?";

	open(STDOUT,">&SAVESTDOUT"); #close file and restore STDOUT
	close OUTPUT;

}

sub executeAndSave {	#Executes DLV and saves the output of the program written by the user in a file

	open(SAVESTDOUT, ">&STDOUT") or die "Can't save STDOUT: $!\n";
	open(STDOUT, ">$_[0]") or die "Can't open STDOUT to $_[0]", "$!\n";

	my @args = ("./dlv --");
	system(@args) == 0 or die "system @args failed: $?";

	open(STDOUT,">&SAVESTDOUT"); #close file and restore STDOUT
	close OUTPUT;


}


sub iterativeExec {	# Executes an input program with several instances and stores them in a bidimensional array

	my @input = @_;

	my @returned_value;

	if(@input) {
		
		my $option = $input[$#input];

		if($option =~ /^-/) {
			pop(@input);
		}
		else {
			$option = "";
		}

		my $dir = pop(@input);
		my @files = qx(ls $dir);
			
		my $size = @files;

		for(my $i = 0; $i < $size; $i++) {

			my $elem = $files[$i];
			chomp $elem;
			my @args = ("./dlv", "@input", "$dir$elem", "$option");
			my (@out) = `@args`;
			push @{$returned_value[$i]}, @out;
		}
		
	}

	else {
		print "INPUT ERROR\n";
	}

	return @returned_value;

}

sub singleExec {	 # Executes a single input program or opens the DLV terminal and stores it in an array

	my @input = @_;
	my @returned_value;

	if(@input) {


		my @args = ("./dlv", "@input");
		(@returned_value) = `@args`;
		
	}

	else {
		my $command = "./dlv --";
		(@returned_value) = `$command`;		
	}

	return @returned_value;
}

sub selectOutput {	# Select one of the outputs returned by the iterative execution of more input programs 

	my @stdoutput = @{$_[0]};
	my $n = $_[1];

	return @{$stdoutput[$n]};
	
}

sub getFacts {	# Return the facts of the input program

	my $input = shift;

	my @isAFile = stat($input);

	my @facts;

	if(@isAFile) {

		open INPUT, "<", "$input";
		my @rows = <INPUT>;
		foreach my $row (@rows) {
			if($row =~ /^(\w+)(\(((\w|\d|\.)+,?)*\))?\./) {
				push @facts, $row;
			}
		}
		close INPUT;

	}
	else {
		my @str = split /\. /,$input;
		foreach my $elem (@str) {

			if($elem =~ /^(\w+)(\(((\w|\d|\.)+,?)*\))?\.?$/) {
				push @facts, $elem;
			}
		}
	}
	return @facts;
	
}

sub addCode {	#Adds code to input

	my $program = $_[0];
	my $code = $_[1];
	my @isAFile = stat($program);

	if(@isAFile) {
		open PROGRAM, ">>", $program;
		print PROGRAM "$code\n";
		close PROGRAM;
	}

	else {
		$program = \($_[0]);
		$$program = "$$program $code";
	}
		
}

sub getASFromFile {	#Gets the Answer Set from the file where the output was saved

	open RESULT, "<", "$_[0]" or die $!;
	my @result = <RESULT>;
	my @arr;
	foreach my $line (@result) {

		if($line =~ /\{\w*/) {
			$line =~ s/(\{|\})//g;
			#$line =~ s/\n//g;  # delete \n from $line
		        my @tmp = split(', ', $line);
			push @arr, @tmp;
		}

	}

	close RESULT;
	return @arr;
}

sub getAS { #Returns the Answer Sets from the array where the output was saved

	my @result = @_;
	my @arr;

	foreach my $line (@result) {


		if($line =~ /\{\w*/) {
			$line =~ s/(\{|\})//g;
			$line =~ s/(Best model:)//g;
		        my @tmp = split(', ', $line);
			push @arr, @tmp;
		}

	}

	return @arr;
}

sub statistics {	# Return an array of hashes in which the statistics of every predicate of every answerSets are stored
			# If a condition of comparison is specified(number of predicates) it returns the answer sets that satisfy
			# that condition 

	my @as = @{$_[0]};
	my @pred = @{$_[1]};
	my @num = @{$_[2]};
	my @operators = @{$_[3]};

	my @sets;
	my @ans;
	
	my $countAS = 0;
	my @stat;

	my $countPred;

	foreach my $elem (@as) {

		if($elem =~ /(\w+).*\n/) {
			push @{$sets[$countAS]}, $elem;
			if(_existsPred($1,\@pred)) {
				$stat[$countAS]{$1} += 1;
				$countAS += 1;
			}
		}

		elsif($elem =~ /(\w+).*/) {
			push @{$sets[$countAS]}, $elem;
			if(_existsPred($1,\@pred)) {
				$stat[$countAS]{$1} += 1;
			}
		}
	}

	my $comparison = 0;
	if(@num and @operators) {
		$comparison = 1;
	}
	elsif(@num and !@operators) {
		print "Error: comparison element missing";
		return @ans;
	}
	
	

	if($comparison) {
		my $size = @pred;
		my $statSize = @stat;

		for(my $j = 0; $j < $statSize; $j++) {
			for(my $i = 0; $i < $size; $i++) {

				my $t = $stat[$j]{$pred[$i]};

				if(_evaluate($t,$num[$i],$operators[$i])) {
					$countPred++;
				}
				else {
					$countPred = 0;
					break;
				}
			}

			if($countPred == $size) {
				push @ans , $sets[$j];
			}
			$countPred = 0;
		}
		return @ans;

	}

	return @stat;
}

sub _evaluate {		#private use only

	my $value = shift;
	my $num = shift;
	my $operator = shift;

	if($operator eq "==") {
		if($value == $num) {
			return 1;
		}
		return 0;
	}
	elsif($operator eq "!=") {
		if($value != $num) {
			return 1;
		}
		return 0;		
	}
	elsif($operator eq ">") {
		if($value > $num) {
			return 1;
		}
		return 0;
	}
	elsif($operator eq ">=") {
		if($value >= $num) {
			return 1;
		}
		return 0;
	}
	elsif($operator eq "<") {
		if($value < $num) {
			return 1;
		}
		return 0;
	}
	elsif($operator eq "<=") {
		if($value <= $num) {
			return 1;
		}
		return 0;
	}
	return 0;
}

sub mapAS {	#Mapping of the Answer Sets in an array of hashes

	my $countAS = 0;

	my @answerSets = @{$_[0]};

	my @second;
	if($_[1]) {
		@second = @{$_[1]};
	}

	my @third;
	if($_[2]) {
		@third = @{$_[2]};
	}

	my @selectedAS;
	
	my @predList;

	my @pred;

	if(@second) {
		if($second[0] =~ /\d+/) {

			@selectedAS = @second;
			if(@third) {
				@predList = @third;
			}

		}

		else {
			@predList = @second;
			if(@third) {
				@selectedAS = @third;
			}
		}
	}


	foreach my $elem (@answerSets) {


		if($elem =~ /(\w+).*\n/){
			if(@predList) {
				if(_existsPred($1,\@predList)) {
					push @{$pred[$countAS]{$1}}, $elem;
				}
			}
			else {
				push @{$pred[$countAS]{$1}}, $elem;
			}
			$countAS = $countAS + 1;
			
		}

		elsif($elem =~ /(\w+).*/) {
			if(@predList) {
				if(_existsPred($1,\@predList)) {
					push @{$pred[$countAS]{$1}}, $elem;
				}
			}
			else {
				push @{$pred[$countAS]{$1}}, $elem;
			}
		}
		
	}

	if(@selectedAS) {
		
		my $size = @selectedAS;

		my @selectedPred;


		for(my $i = 0; $i < $size; $i++) {
			my $as = $selectedAS[$i];
			push @selectedPred, $pred[$as];
		}

		return @selectedPred;
	}
	return @pred;

}

sub _existsPred {	#Verifies the existence of a predicate (private use only)

	my $pred = $_[0];
	my @predList = @{$_[1]};

	my $size = @predList;

	for(my $i = 0; $i < $size; $i++) {
		if($pred eq $predList[$i]) {
			return 1;
		}
	}
	return 0;
		
}

sub getPred {	#Returns the predicates from the array of hashes

	my @pr = @{$_[0]};
	return @{$pr[$_[1]]{$_[2]}};
}

sub getProjection {	#Returns the values selected by the user

	my @pr = @{$_[0]};
	my @projection;

	my @res = @{$pr[$_[1]]{$_[2]}};
	
	my $size = @res;
	my $fieldsStr;

	for(my $i = 0; $i < $size; $i++) {
		my $pred = @{$pr[$_[1]]{$_[2]}}[$i];
		if($pred =~ /(\w+)\((.+)\)/) {
			$fieldsStr = $2;
		}
		my @fields = split(',',$fieldsStr);
		push @projection , $fields[$_[3]-1];		
			
	}

	return @projection;
}

sub createNewFile {

	my $file = $_[0];
	my $code = $_[1];

	open FILE, ">", $file;
	print FILE "$code\n";
	close FILE;

}

sub addFacts {

	my $name = $_[0];
	my @facts = @{$_[1]};
	my $append = $_[2];
	my $filename = $_[3];
	
	open FILE, $append, $filename;

	foreach my $f (@facts) {
		print FILE "$name($f).\n";
	}
	close FILE;
}


1;
__END__

# 

=head1 NAME

AI::Logic::AnswerSet - Perl extension for embedding ASP (Answer Set Programming) programs in Perl.


=head1 SYNOPSIS

  use AI::Logic::AnswerSet;
  
  # invoke DLV( AnwerSetProgramming-based system) and save the stdoutput
  my @stdoutput = AI::Logic::AnswerSet::singleExec("3-colorability.txt");

  # parse the output
  my @res = AI::Logic::AnswerSet::getAS(@stdoutput);

  # map the results
  my @mappedAS = AI::Logic::AnswerSet::mapAS(\@res);

  # get a predicate from the results
  my @col = AI::Logic::AnswerSet::getPred(\@mappedAS,1,"col");

  # get a term of a predicate
  my @term = AI::Logic::AnswerSet::getProjection(\@mappedAS,1,"col",2);


=head1 DESCRIPTION

This extension allows to interact with DLV, which is a system for Answer Set Programming (ASP).
The DLV system is needed inside the directory in which the perl program is running. 
DLV can be gotten at www.dlvsystem.com .


=head2 Methods

=head3 executeFromFileAndSave

This method allows to execute DLV with and input file and save the output in another file.

AI::Logic::AnswerSet::executeFromFileAndSave("outprog.txt","dlvprog.txt","");

In this case the file "outprog.txt" consists of the result of the DLV invocation with the file "dlvprog.txt".
No code is specified in the third value of the method. It can be used to add code to an existing file or to a new one.

AI::Logic::AnswerSet::executeFromFileAndSave("outprog.txt","dlvprog.txt","b(X):-a(X). a(1).");
  
=head3 executeAndSave

To call DLV without an input file, directly writing code using the DLV terminal, can be done with this method,
passing only the name of the output file.

AI::Logic::AnswerSet::executeAndSave("outprog.txt");

Press Ctrl+d to stop using the DLV terminal and execute the program.

=head3 singleExec

Using this method is possible to execute DLV with many input files, including also the DLV options like "-nofacts".
The output will be stored inside an array.

my @out = AI::Logic::AnswerSet::singleExec("3col.txt","nodes.txt","edges.txt","-nofacts");

This method can be used also like this:

my @out = AI::Logic::AnswerSet::singleExec();

In this way it will work like "executeAndSave" without saving the output in a file.

=head3 iterativeExec

This method allows to call multiples DLV executions for several instances of the same problem.
Suppose you have a program that calculates the 3-colorability of a graph; in this case exists the possibility
to have more than a graph, and each graph's instance can be stored in a different file. A Perl programmer
might want to work with the results of all the graphs he has in his files, so this function will be useful for this purpose.
The way to use it is the following:

my @outputs = AI::Logic::AnswerSet::iterativeExec("3col.txt","nodes.txt","./instances");

In this case the nodes of each graph are the same, but not the edges.
Notice that to use this method correctly, the user must specify the directory's path in which the instances of the program
(the edges in this case) are saved.

The output of the call to this function is a two-dimensional array where each element of the array correspond to the result of each
DLV execution, so is exactly like the result of the function "singleExec".

=head3 selectOutput

This method provides to get one of the result of the "iterativeExec" one.

my @outputs = AI::Logic::AnswerSet::iterativeExec("3col.txt","nodes.txt","./instances");
my @out = AI::Logic::AnswerSet::selectOutput(\@outputs,0);

In this case the selected output is the first one.

=head3 getASFromFile

Parses the output of a DLV execution saved in a file in order to split the answer sets.

AI::Logic::AnswerSet::executeFromFileAndSave("outprog.txt","dlvprog.txt","");
my @result = AI::Logic::AnswerSet::getASFromFile("outprog.txt");

=head3 getAS

Parses the output of a DLV execution in order to split the answer sets.

my @out = AI::Logic::AnswerSet::singleExec("3col.txt","nodes.txt","edges.txt","-nofacts");
my @result = AI::Logic::AnswerSet::getAS(@out);

=head3 mapAS

Parses the new output in order to save and organize the results inside a hashmap(array of hashes).
This module allows to interact with DLV, which is a system for Answer Set Programming (ASP).
The DLV system is needed inside the directory in which the perl program is running. 
DLV can be gotten at www.dlvsystem.com .

About two months ago I published "ASPerl", that was the first name of this module, but the name and other things were bad.
Now I adopted this namespace hoping it is good (also thanks to a previous advice).

I would like to know what you think about it


my @out = AI::Logic::AnswerSet::singleExec("3col.txt","nodes.txt","edges.txt","-nofacts");
my @result = AI::Logic::AnswerSet::getAS(@out);
my @mappedAS = AI::Logic::AnswerSet::mapAS(@result);

The user can decide some constraints about the data to save in the hashmap, such as predicates or answer sets or both.

my @mappedAS = AI::Logic::AnswerSet::mapAS(@result,@predicates,@answerSets);

Again about the 3-colorability problem, imagine to save in the hashmap the edges of the graph.
Now imagine to print the edges of the third answer set returned by DLV; this is an example of the print instruction
that can be useful to understand how the hashmap works:

print "Edges: @{$mappedAS[2]{edge}}\n";

So we are printing the array containing the predicate "edge".

=head3 getPred

Easily manage the hashmap and get the desired predicate(see the print example described in the method before);

my @edges = AI::Logic::AnswerSet::getPred(\@mappedAS,3,"edge");

=head3 getProjection

Returns the projection of the nth term of a specified predicate. Suppose to have the predicate "person" C<person(Name,Surename);> and
want only the surename of all the instances of "person":

my @surenames = AI::Logic::AnswerSet::getProjection(\@mappedAS,3,"person",2);

In order, the elements passed to the method are: hashmap, number of the answer set, name of the predicate, position of the term.

=head3 statistics

This method returns an array of hashes in which the statistics of every predicate of every answer sets are stored.
These statistics are the number of occurrences of the specified predicates of each answer set.
If a condition of comparison is specified(number of predicates) it returns the answer sets that satisfy that condition.

my @res = AI::Logic::AnswerSet::getAS(@output);
my @predicates = ("node","edge");
my @stats = AI::Logic::AnswerSet::statistics(\@res,\@predicates);

In this case the data structure returned is the same as the one returned by C<mapAS>.
So, for each answer set(each element of the array of hashes), the hashmap will be something like this:

{
	node => 6
	edge => 9
}

This means that for a particular answer set we have 6 nodes and 9 edges.
On the other hand, this method can be used with some constraints:

my @res = AI::Logic::AnswerSet::getAS(@output);
my @predicates = ("node,"edge");
my @numbers = (4,15);
my @operators = (">","<");
my @stats = AI::Logic::AnswerSet::statistics(\@res,\@predicates,\@numbers,\@operators);

Now the functions returns the answer sets that satisfy the condition: the number of occurrences of the predicate "node" must be higher than 4, and the number of occurrences of the predicate "edge" must be less than 15.

=head3 getFacts

Get the logic program's facts from a file or a string.

my @facts = AI::Logic::AnswerSet::getFacts($inputFile);

or

my $code = "a(X):-b(X). b(1). b(2).";
my @facts = AI::Logic::AnswerSet::getFacts($code);

There is only a constraint according to the code; use a space between rules or facts.
Example of wrong input code:

my $code = "a(X):-b(X).b(1).b(2).";

=head3 addCode

Use this method to quiclky add new code to a string or a file.

my $code = "a(X):-b(X). b(1). b(2).";
AI::Logic::AnswerSet::addCode($code,"b(3). b(4).");

or

my $file = "myfile.txt";
AI::Logic::AnswerSet::addCode($file,"b(3). b(4).");

=head3 createNewFile

Creates a new file with some code.

AI::Logic::AnswerSet::createNewFile($file,"b(3). b(4).");

=head3 addFacts

Adds facts quickly inside a file. Imagine to have some data(representing facts) acquired before in your program and
stored inside an array; just use this method to put them in a file and give them a name.

AI::Logic::AnswerSet::addFacts("villagers",\@villagers,">","villagersFile.txt");

"villagers" will be the name of the facts(e.g. C<villagers(smith).>), C<@villagers> is the array with the facts,
">" is the file operator(so this is a new file) and "villagersFile.txt" is the file's name.


=head1 SEE ALSO

www.dlvsystem.com

=head1 AUTHOR

Ferdinando Primerano, E<lt>levia@cpan.orgE<gt>
Francesco Calimeri, E<lt>calimeri@mat.unical.itE<gt>

This work started within the bachelor degree thesis program of the
Computer Science course at Department of Mathematics of the University
of Calabria.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Ferdinando Primerano , Francesco Calimeri

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

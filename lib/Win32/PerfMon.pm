package Win32::PerfMon;

# Win32::PerfMon.pm
#       +==========================================================+
#       |                                                          |
#       |                     PerfMon.PM package                   |
#       |                     ---------------                      |
#       |                                                          |
#       | Copyright (c) 2004 Glen Small. All rights reserved. 	   |
#       |   This program is free software; you can redistribute    |
#       | it and/or modify it under the same terms as Perl itself. |
#       |                                                          |
#       +==========================================================+
#
#
#	Use under GNU General Public License or Larry Wall's "Artistic License"
#
#	Check the README.TXT file that comes with this package for details about
#	it's history.
#

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

#our %EXPORT_TAGS = ( 'all' => [ qw() ] );

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#our @EXPORT = qw();

our $VERSION = '0.02';

bootstrap Win32::PerfMon $VERSION;

##########################################
# Constructor
##########################################
sub new
{       
	# The object
	my $self = {};
	
	unless(scalar(@_) == 2)
	{
		croak("You must specify a machine to connect to");
		return(undef);
	}
	
	my($class, $box) = @_;
	
	$self->{'HQUERY'} = undef;
	$self->{'COUNTERS'} = undef;
	$self->{'ERRORMSG'} = undef;
	$self->{'MACHINENAME'} = undef;
	
	bless($self, $class);
	
	$self->{'MACHINENAME'} = $box;
	
        my $res = connect_to_box($self->{'MACHINENAME'}, $self->{'ERRORMSG'});
	
	if($res == 0)
	{
		$self->{'HQUERY'} = open_query();
			
		return $self;
	}
	else
	{
		print "Failed to create object [$self->{'ERRORMSG'}]\n";
		return undef;
	}
}

##########################################
# Destructor
##########################################
sub DESTROY
{
	my $self = shift;
	
	# If we have a query object, make sure we free it off
	if(defined($self->{'HQUERY'}))
	{
		CleanUp($self->{'HQUERY'});
		
		$self->{'HQUERY'} = undef;
	}
}


##########################################
# Function to add a  counter to a query
##########################################
sub AddCounter
{	
	unless(scalar(@_) == 4)
	{
		croak("USAGE: AddCounter(ObjectName, CounterName, InstanceName)");
		return(0);
	}
	
	my ($self, $ObjectName, $CounterName, $InstanceName) = @_;
				
	# go and create the counter ....
        my $NewCounter = add_counter($ObjectName, $CounterName, $InstanceName, $self->{'HQUERY'}, $self->{'ERRORMSG'});
        
        if($NewCounter == -1)
        {			
		return(0);
	}
	# if it all worked, add it to the internal structure
			
        if($InstanceName eq "-1")
        {
                $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{'Object'} = $NewCounter;
        }
        else
        {
                $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$InstanceName}->{'Object'} = $NewCounter;
        }
}

##########################################
# Function to collect the data
##########################################
sub CollectData
{
	my $self = shift;
		
	# Populate the counters associated witht he query object
	my $res = collect_data($self->{'HQUERY'}, $self->{'ERRORMSG'});
	
	if($res == -1)
	{
	    return(0);
	}
	else
	{
	    return(1);
	}
}

##########################################
# Function to return a value
##########################################
sub GetCounterValue
{
	unless(scalar(@_) == 4)
	{
		croak("USAGE: GetCounterValue(ObjectName, CounterName, InstanceName)");
		return(0);
	}
		
	my ($self, $ObjectName, $CounterName, $InstanceName) = @_;
	
	my $RetVal = undef;
		
	# Go and get the value for the reqested counter
	if($InstanceName eq "-1")
	{
		$RetVal = collect_counter_value($self->{'HQUERY'}, $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{'Object'}, $self->{'ERRORMSG'});	
	}
	else
	{
		$RetVal = collect_counter_value($self->{'HQUERY'}, $self->{'COUNTERS'}->{$ObjectName}->{$CounterName}->{$InstanceName}->{'Object'}, $self->{'ERRORMSG'});
	}
	
	return($RetVal);
}

##########################################
# Function to close the query
##########################################
sub CloseQuery
{
	my $self = shift;
}

##########################################
# Function to return the error message
sub GetErrorText
{
	my $self = shift;
	
	return($self->{'ERRORMSG'});
}

###########################################
# Function to list the objects
###########################################
sub GetObjects
{
	my $self = shift;
	
	my $Data = list_objects($self->{'MACHINENAME'});
	
	return $Data;
}

###########################################
# Function to explain a counter
###########################################
sub ExplainCounter()
{
    unless(scalar(@_) == 4)
    {
	croak("USAGE: ExplainCounter(ObjectName, CounterName, InstanceName)");
	return(0);
    }
		
    my ($self, $ObjectName, $CounterName, $InstanceName) = @_;
    
    my $RetVal = explain_counter($self->{'HQUERY'}, $ObjectName, $CounterName, $InstanceName, $self->{'ERRORMSG'});
		    
    return($RetVal);
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Win32::PerfMon - Perl extension for Windows Perf Monitor (NT4 +)

=head1 SYNOPSIS

  use Win32::PerfMon;
  use strict;
  
  my $ret = undef;
  my $err = undef;
  
  my $xxx = Win32::PerfMon->new("\\\\MyServer");
  
  if($xxx != undef)
  {
  	$ret = $xxx->AddCounter("System", "System Up Time", -1);
  	
  	if($ret != 0)
  	{
  		$ret = $xxx->CollectData();
  		
  		if($ret  != 0)
  		{
  			my $secs = $xxx->GetCounterValue("System", "System Up Time", -1);
  			
  			if($secs > -1)
  			{
  				print "Seconds of Up Time = [$secs]\n";
  			}
  			else
  			{
  				$err = $xxx->GetErrorText();
  				
  				print "Failed to get the counter data ", $err, "\n";
  			}
  		}
  		else
  		{
  			$err = $xxx->GetErrorText();
  							
  			print "Failed to collect the perf data ", $err, "\n";
  		}
  	}
  	else
  	{
  		$err = $xxx->GetErrorText();
  						
  		print "Failed to add the counter ", $err, "\n";
  	}
  }
  else
  {				
  	print "Failed to greate the perf object\n";
}

=head1 DESCRIPTION

This modules provides and interface into the Windows Performance Monitor, which
can be found on any Windows Server from NT 4 onwards.  The module allows the programmer
to add miltiple counters to a query object, and then in a loop, gather the data for those
counters.  This mechanism is very similar to the native windows method.


=head1 FUNCTIONS

=head2 NOTE

All funcitons return a non zero value if successful, and zero is they fail, excpet GetCounterValue()
which will return -1 if it fails.

=over 4

=item new($ServerName)

This is the constructor for the PerfMon perl object.  Calling this function will create
a perl object, as well as calling the underlying WIN32 API code to attach the object
to the windows Performance Monitor.  The function takes as a parameter, the name of the server you
wish to get performance counter on.  Remember to include the leading slashes.

	my $PerfObj = Win32::PerfMon->new("\\\\SERVERNAME");

=item $PerfObj->AddCounter($ObjectName, $CounterName, $InstanceName)

This function adds the requested counter to the query obejct.

	$PerfObj->AddCounter("Processor", "% Processor Time", "_Total");
	
Not all counters will have a Instance.  This this case, you would simply substitue the 
Instance with a -1.

This function can be called as many times as is needed, to gather the requested counters.

	$PerfObj->AddCounter("System", "System Up Time", -1);

=item $PerfObj->CollectData()

This function when called, will populate the internal structures with the performance data values.
This function should be called after the counters have been added, and before retrieving the counter
values. 

	$PerfObj->CollectData();

=item $PerfObj->GetCounterValue($ObjectName, $CounterName, $InstanceName);

This function returns a scaler containing the numeric value for the requested counter.  Befoer calling this
function, you should call CollectData, to populate the internal structures with the relevent data.

	$PerfObj->GetCounterValue("System", "System Up Time", -1);
	
Note that if the counter in question does not have a Instance, you should pass in -1;
You should call this function for every counter you have added, in between calls to CollectData();

GetCounterValue() can be called in a loop and in conjunction with CollectData(), if you wish to gather
a series of data, over a period of time.

	# Get the initial values
	$PerfObj->CollectData();
	
	for(1..60)
	{
		# Store the value in question
		my $value = $PerfObj->GetCounterValue("Web", "Current Connections", "_Total");
		
		# Do something with $value - e.g. store it in a DB
		
		# Now update the counter value, so that the next call to GetCounterValue has
		# the updated values
		$PerfObj->CollectData();
	}

=item $PerfObj->GetErrorText()

Returns the error message from the last failed function call.

	my $err = $PerfObj->GetErrorText();


=back

=head1 AUTHOR

Glen Small <perl.dev@cyberex.org.uk>



=head1 SEE ALSO



=cut


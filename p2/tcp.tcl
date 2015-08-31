# ======================================================================
# Setup global variables
# ======================================================================
set val(tcpflavor)      [lindex $argv 2]
set val(rseed)          [lindex $argv 1]           ;# random seed
set val(errrate)        [expr [lindex $argv 0]/1000.0]           ;# error rate


# ======================================================================
# Create a simulator object
# ======================================================================
set ns [new Simulator]


# ======================================================================
# Set flow color
# ======================================================================
$ns color 1 Red
$ns color 2 Blue

# ======================================================================
# Open the NAM trace file
# ======================================================================
set nf [open tcp.nam w]
$ns namtrace-all $nf

# open the trace queuen file
set tf [open tcp.tr w]
$ns trace-all $tf

#Create nodes
set S1 [$ns node]  
set S2 [$ns node]
set R1 [$ns node]
set R2 [$ns node]
set R3 [$ns node]
set D1 [$ns node]
set D2 [$ns node]

#Create links between the nodes
$ns duplex-link $S1 $R1 20Mb 2ms DropTail
$ns duplex-link $S2 $R1 10Mb 5ms DropTail
$ns duplex-link $R1 $R2 20Mb 40ms DropTail
$ns duplex-link $R2 $R3 10Mb 45ms DropTail
$ns duplex-link $R3 $D1 20Mb 3ms DropTail
$ns duplex-link $R3 $D2 10Mb 5ms DropTail



#Set link position for nam
$ns duplex-link-op $S1 $R1 orient right-down
$ns duplex-link-op $S2 $R1 orient right-up
$ns duplex-link-op $R1 $R2 orient right
$ns duplex-link-op $R2 $R3 orient right
$ns duplex-link-op $R3 $D1 orient right-up
$ns duplex-link-op $R3 $D2 orient right-down

#Set Queue Size of links to 50
$ns queue-limit $S1 $R1 50
$ns queue-limit $S2 $R1 50
$ns queue-limit $R1 $R2 50
$ns queue-limit $R2 $R3 50
$ns queue-limit $R3 $D1 50
$ns queue-limit $R3 $D2 50

#Set loss model
set lossModel [new ErrorModel]
$lossModel set rate_ $val(errrate)
$lossModel unit packet
$lossModel drop-target [new Agent/Null]
set lossyLink [$ns link $R1 $R2]
$lossyLink install-error $lossModel




#########################################
# Configurations
# tahoe - TCP + TCPSink
# Reno - TCP/Reno + TCPSink
# Newreno - TCP/Newreno + TCPSink
# Sack - TCP/Sack1 + TCPSink/Sack1
#########################################
#Setup TCP connection
if {$val(tcpflavor)=="tahoe"} {
    puts "Run TCP/Tahoe..."

    set tcp1 [new Agent/TCP]
    set tcp2 [new Agent/TCP] 
    set sink1 [new Agent/TCPSink]
    set sink2 [new Agent/TCPSink]

} elseif {$val(tcpflavor)=="reno"} {
    puts "Run TCP/Reno..."

    set tcp1 [new Agent/TCP/Reno]
    set tcp2 [new Agent/TCP/Reno]
    set sink1 [new Agent/TCPSink]
    set sink2 [new Agent/TCPSink]

} elseif {$val(tcpflavor)=="newreno"} {
    puts "Run TCP/Newreno"

    set tcp1 [new Agent/TCP/Newreno]
    set tcp2 [new Agent/TCP/Newreno]
    set sink1 [new Agent/TCPSink]
    set sink2 [new Agent/TCPSink]
} elseif {$val(tcpflavor)=="sack1"} {
    puts "Run TCP/Sack1..."

    set tcp1 [new Agent/TCP/Sack1]
    set tcp2 [new Agent/TCP/Sack1]
    set sink1 [new Agent/TCPSink/Sack1]
    set sink2 [new Agent/TCPSink/Sack1]
} else {
    puts "Unknwon tcp falvor: $val(tcpflavor). TERMINATE NS2!"
    exit 0
}
$ns attach-agent $S1 $tcp1
$tcp1 set window_ 200
$tcp1 set  cwnd_ 200
$tcp1 set packetSize_ 1500
$tcp1 set fid_ 1
$ns attach-agent $D1 $sink1
$ns connect $tcp1 $sink1

$ns attach-agent $S2 $tcp2
$tcp2 set window_ 200
$tcp2 set  cwnd_ 200
$tcp2 set packetSize_ 1500
$tcp2 set fid_ 2
$ns attach-agent $D2 $sink2
$ns connect $tcp2 $sink2

#set LossMonitor for each tcpsink
set lm1 [new Agent/LossMonitor]
$ns attach-agent $D1 $lm1
set lm2 [new Agent/LossMonitor]
$ns attach-agent $D2 $lm2

#Setup FTP over TCP connection
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp1 set type_ FTP
$ftp1 set packet_size_ 1500
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ftp2 set type_ FTP
$ftp2 set packet_size_ 1500


# procedure to plot the congestion window
proc plotWindow {tcpSource outfile} {
    global ns
    set now [$ns now]
    set cwnd [$tcpSource set cwnd_]

    # the data is recorded in a file called congestion.xg (this can be plotted # using xgraph or gnuplot. this example uses xgraph to plot the cwnd_
    puts  $outfile  "$now $cwnd"
    $ns at [expr $now+0.1] "plotWindow $tcpSource  $outfile"
}

set outfile1 [open  "congestion1.xg"  w]
$ns  at  0.0  "plotWindow $tcp1  $outfile1"
set outfile2 [open  "congestion2.xg"  w]
$ns  at  0.0  "plotWindow $tcp2  $outfile2"


#Schedule events for FTP agents
$ns at 0.0 "$ftp1 start"
$ns at 0.0 "$ftp2 start"

#Call the finish procedure after 5 seconds of simulation time
$ns at 100.0 "finish"

#Define a 'finish' procedure
proc finish {} {
    global ns nf tf lm1 lm2

    $ns flush-trace
    close $nf
    close $tf

    $ns halt

    exit 0
}


# ======================================================================
# Set random seed
# ======================================================================
$defaultRNG seed $val(rseed)

# print initial stuffs
puts "\n\[NS2 - run tcp.tcl\]"
puts "TCP1 congestion window: [ $tcp1  set  cwnd_ ]"
puts "TCP2 congestion window: [ $tcp2  set  cwnd_ ]"
puts "Error rate: $val(errrate)"
puts "Random Seed: $val(rseed)"


#Run the simulation
$ns run


# ======================================================================
# Define options/variables
# ======================================================================
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             3                          ;# number of mobilenodes
set val(rp)             DSDV                       ;# routing protocol
set val(x)              500                        ;# topology X-dimension size
set val(y)              500                        ;# topology Y-dimension size
set val(rseed)          [lindex $argv 1]           ;# random seed
set val(errrate)        [expr [lindex $argv 0]/100.0]           ;# error rate


# ====================================================================
# Setting Phy Paramaters
#    - Description of each knob can be found in /ns-2.35/mac/wireless-phy.h 
# ====================================================================
Phy/WirelessPhy set bandwidth_ 1Mb
Phy/WirelessPhy set CSThresh_ 1.7615e-10 ; 
Phy/WirelessPhy set Pt_ 0.282

#disable RTS for 802.11 MAC
Mac/802_11 set RTSThreshold_   3000

# ======================================================================
# Initialize Simulator and output file
# ======================================================================
set ns     [new Simulator]
set tracefd     [open project1.tr w]
$ns trace-all $tracefd
set namtrace [open project1.nam w]
$ns namtrace-all-wireless $namtrace $val(x) $val(y)



# ======================================================================
# set up topography object
# ======================================================================
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)



# ======================================================================
# Create God
# God (General Operations Director) is the object that is used to store global information about the state of the environment, 
# network or nodes that an omniscent observer would have, but that should not be made known to any participant in the simulation.
# ======================================================================
create-god $val(nn)




# ======================================================================
# TODO: Add error model #
# ======================================================================
# create a loss_module and set its packet error rate to 1 percent
proc UniformErr {} {
    global val
    set err [new ErrorModel]
    $err unit packet
    $err set rate_ $val(errrate)
    return $err
}


# ======================================================================
#  Create the specified number of mobilenodes [$val(nn)] and "attach" them
#  to the channel. 
#  Here two nodes are created : node(0) and node(1)
#  Also, configure the nodes according to the project setting
# ======================================================================
set chan_1_ [new $val(chan)]
$ns node-config -adhocRouting $val(rp) \
             -llType $val(ll) \
             -macType $val(mac) \
             -ifqType $val(ifq) \
             -ifqLen $val(ifqlen) \
             -antType $val(ant) \
             -propType $val(prop) \
             -phyType $val(netif) \
             -topoInstance $topo \
             -agentTrace ON \
             -routerTrace ON \
             -macTrace OFF \
             -movementTrace OFF \
             -channel $chan_1_ \
             -IncomingErrProc UniformErr
set node_(0) [$ns node]
set node_(1) [$ns node]
set node_(2) [$ns node]
$node_(0) random-motion 0
$node_(1) random-motion 0
$node_(2) random-motion 0

            

# ======================================================================
# Provide initial (X,Y, for now Z=0) co-ordinates for mobilenodes
# ======================================================================
for {set i 0} {$i < $val(nn)} {incr i} {
        # 20 defines the node size in nam, adjust it according to your scenario size.
        # The function must be called after mobility model is defined
        $ns initial_node_pos $node_($i) 20
}  

$node_(0) set X_ 50.0
$node_(0) set Y_ 50.0
$node_(0) set Z_ 0.0

$node_(1) set X_ 250.0
$node_(1) set Y_ 50.0
$node_(1) set Z_ 0.0

#This is setting Topology 1
$node_(2) set X_ 450.0
$node_(2) set Y_ 50.0
$node_(2) set Z_ 0.0

#This is setting Topology 2
#$node_(2) set X_ 50.0
#$node_(2) set Y_ 100.0
#$node_(2) set Z_ 0.0



# ======================================================================
# Create udp traffic from node0 to node1
# ======================================================================
set udp01 [new Agent/UDP]
$ns attach-agent $node_(0) $udp01
set cbr01 [new Application/Traffic/CBR]
$cbr01 attach-agent $udp01
$cbr01 set packetSize_ 1500
$cbr01 set interval_ 24ms
$cbr01 set random_ 1


# ======================================================================
# Create udp traffic from node2 to node1
# ======================================================================
set udp21 [new Agent/UDP]
$ns attach-agent $node_(2) $udp21
set cbr21 [new Application/Traffic/CBR]
$cbr21 attach-agent $udp21
$cbr21 set packetSize_ 1500
$cbr21 set interval_ 24ms
$cbr21 set random_ 1


# ======================================================================
# Create throughput monitor sink for link 0-> and 2->1
# ======================================================================
set lossMon01 [new Agent/LossMonitor]
$ns attach-agent $node_(1) $lossMon01
$ns connect $udp01 $lossMon01 
set lossMon21 [new Agent/LossMonitor]
$ns attach-agent $node_(1) $lossMon21
$ns connect $udp21 $lossMon21



# ======================================================================
# Set start/stop time of the two traffics
# ======================================================================
$ns at 0.0 "$cbr01 start"
$ns at 0.0 "$cbr21 start"

$ns at 100.0 "$cbr01 stop"
$ns at 100.0 "$cbr21 stop"



# ======================================================================
# Procedue to do after simulation
# ======================================================================
proc finish {} {
    # Extract which global variables to use in this procedure
    global ns tracefd namtrace lossMon01 lossMon21 val

    $ns flush-trace
    close $tracefd
    close $namtrace

    $ns halt

    #Get the current time
    set finish_time [$ns now]
    # Get the arrived bytes
    set nBytes01 [$lossMon01 set bytes_]  
    set nBytes21 [$lossMon21 set bytes_]

     # Get the arrived packets
    set nPkts01 [$lossMon01 set npkts_] 
    set nPkts21 [$lossMon21 set npkts_]
    
    # Get the not-arrived packets
    set nLost01 [$lossMon01 set nlost_] 
    set nLost21 [$lossMon21 set nlost_]

    #Calculate the bandwidth (in MBit/s) and write it to the files

    puts "\n\n\[Output Stats - RandomSeed: $val(rseed), ErrorRate: $val(errrate) \]"
    puts "Finish time - $finish_time seconds"

    puts "\[Link 0->1\]:"
    puts "\tReceived bytes: $nBytes01"
    puts "\tReceived packets: $nPkts01"
    puts "\tLost packets: $nLost01"
    puts "\tBandwidth: [expr $nBytes01*8/$finish_time/1000] Kb/s"


    puts "\[Link 2->1\]:"
    puts "\tReceived bytes: $nBytes21"
    puts "\tReceived packets: $nPkts21"
    puts "\tLost packets: $nLost21"
    puts "\tBandwidth: [expr $nBytes21*8/$finish_time/1000] Kb/s"

    puts "Total Bandwidth: [expr ($nBytes01+$nBytes21)*8/$finish_time/1000] Kb/s"


    # Call xgraph to display the results
#    exec xgraph project1.tr -geometry 800x400 &
    exit 0
}



# ======================================================================
# Set to simulation for 100 seconds and call "finish" after that
# ======================================================================
$ns at 100.0 "finish"



# ======================================================================
# Set random seed
# ======================================================================
$defaultRNG seed $val(rseed)


# ======================================================================
# Start the simulation
# ======================================================================
$ns run

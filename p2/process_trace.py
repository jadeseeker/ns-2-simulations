import matplotlib.pyplot as plt


##############################
# Define Global Variables
##############################
TIME_STEP = 0.5 #sec
CONGESTION_WINDOW = 250




##############################
# trace_class
##############################
class trace_class:
    """A single trace"""
    def __init__(self):
        self.time = -1
        self.link_op = "n/a"
        self.link_src = -1
        self.link_dst = -1
        self.msg_type = "n/a"
        self.size = -1
        self.flow = -1
        self.src = -1
        self.dst = -1
        self.seq = -1
        self.packet = -1
    def __init__(self, trace):
        # Assueme trace format ["+", "4.558384", "2", "1", "ack", "40", "-------", "2", "6.0", "1.0", "128", "2042"]
        self.link_op = trace[0]
        self.time = float(trace[1])
        self.link_src = int(trace[2])
        self.link_dst = int(trace[3])
        self.msg_type = trace[4]
        self.size = int(trace[5])
        self.flow = int(trace[7])
        self.src = int(float(trace[8]))
        self.dst = int(float(trace[9]))
        self.seq = int(trace[10])
        self.packet = int(trace[11])
    def dump(self):
        print self.link_op, self.time, self.link_src, self.link_dst, self.msg_type, self.size, self.flow, self.src, self.dst, self.seq, self.packet




##############################
# Output general stats
##############################
def dump_node_stats(node_name, operation, byte, seq, packets):
     print "[%s]" %node_name
     print "  --", operation, byte, "bytes (including retransmit),"
     print "  --", operation, seq , "unique packets (segments),", packets, "segments in total"


def general_stats(all_traces):
    print "[ general_stats ]"

    S1_tx_bytes = 0
    S2_tx_bytes = 0
    D1_rx_bytes = 0
    D2_rx_bytes = 0
    S1_tx_packets = 0
    S2_tx_packets = 0
    D1_rx_packets = 0
    D2_rx_packets = 0
    S1_max_seq = 0
    S2_max_seq = 0
    D1_max_seq = 0
    D2_max_seq = 0
    
    for trace in all_traces:
        if trace.link_op=="+" and trace.link_src==0:
            S1_tx_bytes += trace.size-40
            S1_tx_packets += 1
            if trace.seq>S1_max_seq:
                S1_max_seq = trace.seq
        elif trace.link_op=="+" and trace.link_src==1:
           S2_tx_bytes += trace.size-40
           S2_tx_packets += 1
           if trace.seq>S2_max_seq:
                S2_max_seq = trace.seq 
        elif trace.link_op=="r" and trace.link_dst==5:
            D1_rx_bytes += trace.size-40
            D1_rx_packets += 1
            if trace.seq>D1_max_seq:
                D1_max_seq = trace.seq
        elif trace.link_op=="r" and trace.link_dst==6:
            D2_rx_bytes += trace.size-40
            D2_rx_packets += 1
            if trace.seq>D2_max_seq:
                D2_max_seq = trace.seq
            
    dump_node_stats("S1", "Transmitted", S1_tx_bytes, S1_max_seq, S1_tx_packets)
    dump_node_stats("S2", "Transmitted", S2_tx_bytes, S2_max_seq, S2_tx_packets) 
    dump_node_stats("D1", "Received", D1_rx_bytes, D1_max_seq, D1_rx_packets) 
    dump_node_stats("D1", "Received", D2_rx_bytes, D2_max_seq, D2_rx_packets) 


##############################
# calculate time vs instantaneous throughput
# instantaneous throught is calculated by recording how much payload of data are received in each 100ms
# The function will output two image files 
##############################
def calculate_throughput(all_traces):
    print "[ calculate_throughput ]"

    current_time = 0

    timestamp = list()
    D1_throughput = list()
    D2_throughput = list()
    D1_rx_bytes = 0
    D2_rx_bytes = 0

#    D1_rx_packets = list()
#    D2_rx_packets = list()


    for trace in all_traces:
        if trace.time > current_time:
            timestamp.append(current_time)
            D1_throughput.append( D1_rx_bytes/TIME_STEP/1024 )
            D2_throughput.append( D2_rx_bytes/TIME_STEP/1024 )

            D1_rx_bytes = 0
            D2_rx_bytes = 0
            current_time += TIME_STEP
#            print "current_time:", current_time


        # Calculate rx data at the receiver
        if trace.link_op=="r" and trace.link_dst==5:
#            if not (trace.seq in D1_rx_packets):
#                D1_rx_packets.append( trace.seq )
                D1_rx_bytes += trace.size
        elif trace.link_op=="r" and trace.link_dst==6:
#            if not (trace.seq in D2_rx_packets):
#                D2_rx_packets.append( trace.seq )
                D2_rx_bytes += trace.size

#        if  len(D1_rx_packets) > CONGESTION_WINDOW:
#            D1_rx_packets.sort()
#            D1_rx_packets.pop(0)
#        if  len(D2_rx_packets) > CONGESTION_WINDOW:
#            D1_rx_packets.sort()
#            D2_rx_packets.pop(0)
  
    return (timestamp, D1_throughput, D2_throughput)

##############################
# calculate time vs. congestion window
# congestion window is calculated by recording how many outstanding packets are at the tx
# an outstanding packet is a packet that has been sent but has not received an ack
##############################
def remove_pending_packets(pending_packets, seq_num):
    pending_packets.sort()
    while True and (len(pending_packets)>0):
        if pending_packets[0] <= seq_num:
            pending_packets.pop(0)
        else:
            return


def read_congestion_window():
    print "[ read_congestion_window ]"

    cw_flow1_fp = open("congestion1.xg", "r") 
    cw_flow2_fp = open("congestion2.xg", "r")   


    timestamp1 = list()
    timestamp2 = list()
    D1_congestion_window = list()
    D2_congestion_window = list()
    
    while True:
        trace = cw_flow1_fp.readline()    
        if not trace:
            break
 
        trace = trace.split()
        timestamp1.append( float(trace[0]) )
        D1_congestion_window.append( float(trace[1]) )

    while True:
        trace = cw_flow2_fp.readline()    
        if not trace:
            break
 
        trace = trace.split()
        timestamp2.append( float(trace[0]) )
        D2_congestion_window.append( float(trace[1]) )

    return (timestamp1, D1_congestion_window, timestamp2, D2_congestion_window)

def calculate_congestion_window(all_traces):
    print "[ calculate_congestion_window ]"

    current_time = 0 

    timestamp = list()
    D1_congestion_window = list()
    D2_congestion_window = list()

    D1_pending_packets = list()
    D2_pending_packets = list()


    for trace in all_traces:
        if trace.time > current_time:
            timestamp.append(current_time)
            D1_congestion_window.append( len(D1_pending_packets) )
            D2_congestion_window.append( len(D2_pending_packets) )
            current_time += TIME_STEP

            if len(D1_pending_packets) >= 195:
                print "current_time:", current_time

        if trace.link_op=="+" and trace.link_src==0:
            if not (trace.seq in D1_pending_packets):
                D1_pending_packets.append( trace.seq ) 
        elif trace.link_op=="r" and trace.link_dst==0 and trace.msg_type=="ack":
            remove_pending_packets(D1_pending_packets, trace.seq)
        elif trace.link_op=="+" and trace.link_src==1:
            if not (trace.seq in D2_pending_packets):
                D2_pending_packets.append( trace.seq ) 
        elif trace.link_op=="r" and trace.link_dst==1 and trace.msg_type=="ack":
            remove_pending_packets(D2_pending_packets, trace.seq)
  
    return (timestamp, D1_congestion_window, D2_congestion_window)


def calculate_acks(all_traces):
    print "[ calculate_acks ]"


    D1_prev_ack = -1
    D2_prev_ack = -1
    D1_ack_counter = 0
    D2_ack_counter = 0
    D1_timestamp = list()
    D2_timestamp = list()
    D1_duplicate_acks = list()
    D2_duplicate_acks = list()

    for trace in all_traces:
        if trace.link_op=="r" and trace.link_dst==0 and trace.msg_type=="ack":
            if trace.seq != D1_prev_ack:
                D1_prev_ack = trace.seq
                D1_ack_counter = 0
            else:
                D1_ack_counter+=1
            D1_timestamp.append(trace.time)   
            D1_duplicate_acks.append(D1_ack_counter) 
        elif trace.link_op=="r" and trace.link_dst==1 and trace.msg_type=="ack":
            if trace.seq != D2_prev_ack:
                D2_prev_ack = trace.seq
                D2_ack_counter = 0
            else:
                D2_ack_counter+=1
            D2_timestamp.append(trace.time)   
            D2_duplicate_acks.append(D2_ack_counter)

  
    return (D1_timestamp, D1_duplicate_acks, D2_timestamp, D2_duplicate_acks)



#################
# main
#i##############
def plot_figures(throughput, congestion_window, acks):
    print "[ plot_figures ]"

    plt.rcParams.update({'font.size': 22})

    # Plot throughput and congestion on the same figure for flow 1
    plt.figure(1, figsize=(22, 12), dpi=200)
    lns1 = plt.plot(throughput[0], throughput[1],'b-.', linewidth=6.0, label='Throughput')
    plt.xlabel('time (s)')
    plt.ylabel('Throughput (KB/s)', color='b')
    plt.twinx()
    lns2 = plt.plot(congestion_window[0], congestion_window[1], 'r-*', linewidth=6.0, label='Congestion Window')
    plt.ylabel('Congestion Window', color='r')
    lns = lns1+lns2
    labs = [l.get_label() for l in lns]
    plt.legend(lns, labs, loc=3, bbox_to_anchor=(0., 1.02, 1., .102), fancybox=True, shadow=True, ncol=2, mode="expand", borderaxespad=0. )
    plt.savefig('Flow1.png', dpi = (200))

    # Plot throughput and congestion on the same figure for flow 2
    plt.figure(2, figsize=(22, 12), dpi=200)
    lns1 = plt.plot(throughput[0], throughput[2], 'b-.', linewidth=6.0, label='Throughput')
    plt.xlabel('time (s)')
    plt.ylabel('Throughput (KB/s)',  color='b')
    plt.twinx()
    lns2 = plt.plot(congestion_window[2], congestion_window[3], 'r-*', linewidth=6.0, label='Congestion Window')
    plt.ylabel('Congestion Window', color='r')
    lns = lns1+lns2
    labs = [l.get_label() for l in lns]
    plt.legend(lns, labs, loc=3, bbox_to_anchor=(0., 1.02, 1., .102), fancybox=True, shadow=True, ncol=2, mode="expand", borderaxespad=0. )
    plt.savefig('Flow2.png', dpi = (200))


    # Plot congestion window on the same figure
    plt.figure(3, figsize=(22, 12), dpi=200)
    lns1 = plt.plot(congestion_window[0], congestion_window[1], 'b-.', linewidth=6.0, label='Flow1_CW')
    lns2 = plt.plot(congestion_window[2], congestion_window[3], 'r-*', linewidth=6.0, label='Flow2_CW')
    plt.xlabel('time (s)')
    plt.ylabel('Congestion Window')
    lns = lns1+lns2
    labs = [l.get_label() for l in lns]
    plt.legend(lns, labs, loc=3, bbox_to_anchor=(0., 1.02, 1., .102), fancybox=True, shadow=True, ncol=2, mode="expand", borderaxespad=0. )
    plt.savefig('CW.png', dpi = (200))


    # Plot throughput for flow 1 and flow 2
    plt.figure(4, figsize=(22, 12), dpi=200)
    lns1 = plt.plot(throughput[0], throughput[1],'b-.', linewidth=6.0, label='Flow1_Throughput')
    lns2 = plt.plot(throughput[0], throughput[2], 'r-*', linewidth=6.0, label='Flow2_Throughput')
    plt.xlabel('time (s)')
    plt.ylabel('Throughput (KB/s)', color='b')
    lns = lns1+lns2
    labs = [l.get_label() for l in lns]
    plt.legend(lns, labs, loc=3, bbox_to_anchor=(0., 1.02, 1., .102), fancybox=True, shadow=True, ncol=2, mode="expand", borderaxespad=0. )
    plt.savefig('Throughput.png', dpi = (200))




###############
# main
#i##############
def main():
    trace_name = "tcp.tr"
    print "[ Reading trace file", trace_name,"]"

    all_traces = list()
    input_fp = open(trace_name, "r")
    output_fp = open("all_throughput.txt", "a")

    while True:
        trace = input_fp.readline()     
        if not trace:
            break
 
        # assuem trace format "+ 4.558384 2 1 ack 40 ------- 2 6.0 1.0 128 2042"
        trace = trace.split()
        if trace[0]=="+" or trace[0]=="r":
            all_traces.append( trace_class(trace) )

    general_stats(all_traces)
    throughput = calculate_throughput(all_traces)
#    congestion_window = calculate_congestion_window(all_traces)
    congestion_window = read_congestion_window()
    acks = calculate_acks(all_traces)

    plot_figures(throughput, congestion_window, acks)

    

    avg_D1_throughput = sum(throughput[1]) / float( len(throughput[1]) )
    avg_D2_throughput = sum(throughput[2]) / float( len(throughput[2]) ) 

    output_fp.write( str(avg_D1_throughput) )
    output_fp.write(" ")
    output_fp.write( str(avg_D2_throughput) )
    output_fp.write("\n")



###############
# Run main()
###############
main()


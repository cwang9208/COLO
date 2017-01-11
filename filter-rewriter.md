# Filter Rewriter
## Sequence and Acknowledgement Numbers
To keep track of the connection, sequence (Seq) and acknowledgement (Ack) numbers stored in the TCP header are used.
### Three way handshake

In the three-way handshake, the client sends a SYN packet with an initial 32-bit sequence number and with an acknowledgement number (Ack) of 0.

```
# Step 1
Client ---> [SYN] Seq=1023645922 Ack=0 ----> Server
```

If the server is listening, it responds back to the client with a packet having the SYN and ACK flags set, and containing its own initial SEQ and an Ack equal to the server's SEQ plus one.

```
# Step 2
Client <--- [SYN, ACK] Seq=2234678799 Ack=1023645923 <---- Server
```

This is telling the server that the next packet it sends had better have a Seq=1023645923. And indeed it does, so the client sends back a packet with just the ACK flag set, and with updated Seq and Ack numbers.

```
# Step 3
Client ---> [ACK] Seq=1023645923 Ack=2234678800 ---> Server
```

The Ack number is the next expected sequence number that one side of a connection expects. Stevens defines it as "the sequence number plus 1 of the successfully received byte of data". During the three-way handshake, since there is no connection yet, no data is yet being sent, so "successfully received byte of data" is 0.

### Data exchange
Once the connection has been established, the client and server can exchange data.  
When data is sent over a connection, the PSH flag in the TCP header gets involved. In most Berkeley-derived implementations, the PSH flag is set by TCP to signal there is no more data to follow, i.e., the packet with the PSH empties the buffer of what is being sent.

#### Payload
Seq and Ack numbers are affected by the payload size.  
The client is sending a help command to the SMTP server. It has the ACK and PSH flags set.

```
# Step 5
Client ---> [ACK, PSH] Seq=1023645923 Ack=2234678893 ---> Server
```

The server's response is to send help information to the user. It sends this data in a packet, also with an [ACK, PSH]:

```
# Step 7
Client <--- [ACK, PSH] Seq=2234678893 Ack=1023645928 <--- Server
```

Step 7's Ack is not one more than the last Seq it received, it is five more than Step 5's Seq. That is because the packet in step 5 sent the four characters "h", "e", "l", "p". The server is acknowledging to the client that it received the four bytes of data by setting its Ack to the last successfully received byte (1023645923 + 4) = 1023645927, plus one to equal 1023645928.

## Filter Rewriter in COLO

handle tcp packet from primary guest
```
static int handle_primary_tcp_pkt(NetFilterState *nf,
                                  Connection *conn,
                                  Packet *pkt)
{
    struct tcphdr *tcp_pkt;

    tcp_pkt = (struct tcphdr *)pkt->transport_header;

    if (((tcp_pkt->th_flags & (TH_ACK | TH_SYN)) == TH_SYN)) {
        /*
         * we use this flag update offset func
         * run once in independent tcp connection
         */
        conn->syn_flag = 1;
    }

    if (((tcp_pkt->th_flags & (TH_ACK | TH_SYN)) == TH_ACK)) {
        if (conn->syn_flag) {
            /*
             * offset = secondary_seq - primary seq
             * ack packet sent by guest from primary node,
             * so we use th_ack - 1 get primary_seq
             */
            conn->offset -= (ntohl(tcp_pkt->th_ack) - 1);
            conn->syn_flag = 0;
        }
        /* handle packets to the secondary from the primary */
        tcp_pkt->th_ack = htonl(ntohl(tcp_pkt->th_ack) + conn->offset);
    }

    return 0;
}
```
handle tcp packet from secondary guest
```
static int handle_secondary_tcp_pkt(NetFilterState *nf,
                                    Connection *conn,
                                    Packet *pkt)
{
    struct tcphdr *tcp_pkt;

    tcp_pkt = (struct tcphdr *)pkt->transport_header;

    if (((tcp_pkt->th_flags & (TH_ACK | TH_SYN)) == (TH_ACK | TH_SYN))) {
        /*
         * save offset = secondary_seq and then
         * in handle_primary_tcp_pkt make offset
         * = secondary_seq - primary_seq
         */
        conn->offset = ntohl(tcp_pkt->th_seq);
    }

    if ((tcp_pkt->th_flags & (TH_ACK | TH_SYN)) == TH_ACK) {
        /* handle packets to the primary from the secondary*/
        tcp_pkt->th_seq = htonl(ntohl(tcp_pkt->th_seq) - conn->offset);
    }

    return 0;
}
```
require  "../src/tuntap"

# This sample shows the most basic usage of the `tuntap` shard.
# It creates a TUN device, adds an IP address and a route to it, and then simply
# prints any received packet to STDOUT.
#
# You can use `ping` to verify this program works:
#  1. Run this program, and keep it running
#  2. Run $ ping 10.0.0.123
#  3. This program should output lines like
#     "Recv 84B 10.0.0.2 -> 10.0.0.123"
#  4. Stop both `ping` and this program with Ctrl-C

# Note: If you encounter any error, make sure to have the required permissions!
#       You need either `CAP_NET_ADMIN` or be root.
#       To run as root: $ sudo crystal simple.cr

# Create TUN device
dev = Tuntap::Device.open flags: LibC::IfReqFlags.flags(Tun, NoPi)

# Bring it up
dev.up!

# Add the IP address 10.0.0.2 to it.  This is "our" address.
dev.add_address "10.0.0.2"

# Add a route from 10.0.0.0/24 to 10.0.0.2 as gateway
dev.add_route(
  destination: "10.0.0.0",
  gateway: "10.0.0.2",
  mask: "255.255.255.0",
  flags: LibC::RtEntryFlags.flags(Up, Gateway)
)

puts "Okay, device is #{dev.name}"

loop do # Receive packets
  packet = dev.read_packet
  puts "Recv #{packet.size}B #{packet.source_address} -> #{packet.destination_address}"
end

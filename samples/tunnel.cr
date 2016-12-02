require  "../src/tuntap"
require "socket"

# This program builds a simple tunnel from a machine to another using TCP.
# To try this, you'll need two machines (or two virtual machines) connected
# over the network to each other.
#
# Then on machine A run: $ crystal tunnel.cr
# Then on machine B run: $ crystal tunnel.cr $MACHINE_A_IP
#
# Machine A's address is 10.0.0.1
# Machine B's address is 10.0.0.2
#
# (This sample only allows a single client)
#
# Both machines will have a TUN device at this point.  You can now use `ping`,
# or any other network program, to talk to the other machine.  The IP address
# of the machine is written to STDOUT.
#
# Tip: You can also use containers instead of full (virtual) machines to test
#      this.

# WARNING: This program is an example.  The connection is NOT secured, and it
# is NOT encrypted!  Do not use it for anything serious.

# Note: If you encounter any error, make sure to have the required permissions!
#       You need either `CAP_NET_ADMIN` or be root.
#       To run as root: $ sudo crystal tunnel.cr

PORT = 7854
SERVER_IP = "10.0.0.1"
CLIENT_IP = "10.0.0.2"

server_address = ARGV[0]?
server_mode = server_address.nil?

if server_address.nil? # Connect to the other computer
  puts "Waiting for client to connect..."
  socket = TCPServer.new("0.0.0.0", PORT).accept
else
  socket = TCPSocket.new(server_address, PORT)
end

# Create TUN device
dev = Tuntap::Device.open flags: LibC::IfReqFlags.flags(Tun, NoPi)
dev.up! # Bring it up

my_ip = server_mode ? SERVER_IP : CLIENT_IP
remote_ip = server_mode ? CLIENT_IP : SERVER_IP
dev.add_address my_ip # Set our IP address

dev.add_route( # Set a route
  destination: "10.0.0.0",
  gateway: my_ip,
  mask: "255.255.255.0",
  flags: LibC::RtEntryFlags.flags(Up, Gateway)
)

puts "Okay, device is #{dev.name}"
puts "      My IP address: #{my_ip}"
puts "  Remote IP address: #{remote_ip}"
puts "Now tunneling data. Hit Ctrl-C to stop."

spawn do # Receive TCP packets
  begin
    loop do
      packet = Bytes.new socket.read_bytes(Int32)
      socket.read_fully packet

      info = Tuntap::IpPacket.new(packet, false)
      puts "-> #{packet.size}B #{info.source_address} -> #{info.destination_address}"

      dev.write packet
    end
  rescue err
    puts err
    exit
  end
end

spawn do # Receive TUN packets
  loop do
    packet = dev.read_packet
    puts "<- #{packet.size}B #{packet.source_address} -> #{packet.destination_address}"
    socket.write_bytes packet.size.to_i32
    socket.write packet.frame
  end
end

sleep # Go!

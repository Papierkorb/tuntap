module Tuntap
  # Provides easy access to the IP header and its payload.
  struct IpPacket

    # The whole packet
    getter frame : Bytes

    # Does the frame has the PI header?
    getter? has_pi : Bool

    # Does the frame have an ethernet header?
    getter? has_ethernet : Bool

    # Encapsulates *frame* as a IPv4 packet with or without the PI header
    # (*has_pi*).  *has_ethernet* commonly refers to the source being a
    # TUN (= `false`) or TAP (= `true`) device.
    def initialize(@frame : Bytes, @has_pi = true, @has_ethernet = false)
    end

    delegate size, :[], to: @frame

    # Returns the PI header.  If this packet does not have it, the returned
    # header will contain junk data.
    def pi : Header::Pi
      ptr = @frame.pointer(sizeof(Header::Pi))
      ptr.as(Header::Pi*).value
    end

    # Returns the ethernet header.  If this packet does not have it, the
    # returned header will contain junk data.
    def ethernet : Header::Ethernet
      ptr = without_pi.pointer(sizeof(Header::Ethernet))
      ptr.as(Header::Ethernet*).value
    end

    # Returns the frame without the PI header (if there is one)
    def without_pi : Bytes
      if @has_pi
        @frame + sizeof(Header::Pi)
      else
        @frame
      end
    end

    # Returns the frame without the ethernet header (if there is one).
    def without_ethernet : Bytes
      bytes = without_pi
      if @has_ethernet
        bytes + sizeof(Header::Ethernet)
      else
        bytes
      end
    end

    # Length of the IP header
    def ip_header_length
      (ipv4.version_ihl & 0x0Fu8).to_u32 * sizeof(UInt32)
    end

    # Returns the IP payload
    def without_ip : Bytes
      without_ethernet + ip_header_length
    end

    # Returns the IPv4 header from the packet.  No check is done if the packet
    # really contains IPv4 data.
    def ipv4 : Header::Ipv4
      ptr = without_ethernet.pointer(sizeof(Header::Ipv4))
      ptr.as(Header::Ipv4*).value
    end

    # The source hardware address.
    def source_mac : String
      ethernet.source.map(&.to_s(16)).join(":")
    end

    # The destination hardware address.
    def destination_mac : String
      ethernet.destination.map(&.to_s(16)).join(":")
    end

    # The source address of the IP header as readable string.
    def source_address : String
      address_string ipv4.source_address
    end

    # The destination address of the IP header as readable string.
    def destination_address : String
      address_string ipv4.destination_address
    end

    private def address_string(addr : Header::V4Address)
      addr.parts.map(&.to_s).join('.')
    end
  end
end

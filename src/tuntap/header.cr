module Tuntap
  lib Header

    # The packet-information header
    @[Packed]
    struct Pi
      flags : UInt16
      proto : UInt16
    end

    # The ethernet header
    @[Packed]
    struct Ethernet
      # Destination MAC address
      destination : UInt8[6]

      # Source MAC address
      source : UInt8[6]

      # The packet type
      type : UInt16
    end

    union V4Address
      parts : UInt8[4]
      network : UInt32
    end

    # The IPv4 header
    @[Packed]
    struct Ipv4
      version_ihl : UInt8
      tos : UInt8
      total_length : UInt16
      identification : UInt16
      offset : UInt16 # Also contains the `flags`
      ttl : UInt8
      protocol : UInt8
      checksum : UInt16
      source_address : V4Address
      destination_address : V4Address
    end
  end
end

# Structures and constants based on `linux/if.h` and `linux/if_tun.h`.
lib LibC

  # Max interface name size
  IFNAMSIZ = 16

  AF_NETLINK = 16
  NETLINK_ROUTE = 0

  # The follwing constants are ioctl() requests
  TUNSETIFF = 1074025674
  SIOCSIFFLAGS = 0x8914
  SIOCSIFADDR = 0x8916
  SIOCADDRT = 0x890B

  union IfSettingsData
    pointer : Void*
  end

  struct IfSettings
    type : UInt32
    size : UInt32
    ifs : IfSettingsData
  end

  struct IfMap
    mem_start : ULong
    mem_end : ULong
    base_addr : UShort
    irq : UChar
    dma : UChar
    port : UChar
  end

  @[Flags]
  enum IfReqFlags : UShort
    # For use with TUNSETIFF
    Tun = 0x0001
    Tap = 0x0002
    NoPi = 0x1000

    OneQueue = 0x2000 # This flag has no real effect
    VnetHdr = 0x4000
    TunExcl = 0x8000
    MultiQueue = 0x0100
    AttachQueue = 0x0200
    DetachQueue = 0x0400

    Persist = 0x0800 # Read-only flag
    NoFilter = 0x1000

    # For use with SIOCSIFFLAGS
    Up = 0x0001
    Broadcast = 0x0002
    Debug = 0x0004
    Loopback = 0x0008
    PointToPoint = 0x0010
    NoTrailers = 0x0020
    Running = 0x0040
    NoArp = 0x0080
    Promisc = 0x0100
    AllMulti = 0x0200
    Master = 0x0400
    Slave = 0x0800
    Multicast = 0x1000
    PortSel = 0x2000
    AutoMedia = 0x4000
    Dynamic = 0x8000
  end

  union IfReqData
    addr : Sockaddr
    dstaddr : Sockaddr
    broadaddr : Sockaddr
    netmask : Sockaddr
    hwaddr : Sockaddr

    flags : IfReqFlags
    ivalue : Int
    mtu : Int

    map : IfMap

    slave : Char[IFNAMSIZ]
    newname : Char[IFNAMSIZ]
    data : Void*

    settings : IfSettings
  end

  struct IfReq
    ifrn_name : Char[IFNAMSIZ]
    ifr : IfReqData
  end

  struct IfAddrs
    next : IfAddrs*
    name : Char*
    flags : UInt
    addr : Sockaddr*
    netmask : Sockaddr*
    dstaddr : Sockaddr*
    data : Void*
  end

  # struct SockaddrNl
  #   nl_family : SaFamilyT
  #   nl_pad : UShort # == 0
  #   nl_pid : UInt32
  #   nl_groups : UInt32
  # end
  #
  # struct IoVec
  #   base : Void*
  #   len : SizeT
  # end
  #
  # struct MsgHdr
  #   name : Void*
  #   name_len : SocklenT
  #
  #   iov : IoVec*
  #   iov_len : SizeT
  #
  #   control : Void*
  #   control_len : SizeT
  #
  #   flags : Int
  # end

  @[Flags]
  enum RtEntryFlags : UShort
    Up = 0x0001
    Gateway = 0x0002
    Host = 0x0004
    Reinstate = 0x0008
    Dynamic = 0x0010
    Modified = 0x0020
    Mtu = 0x0040
    Window = 0x0080
    Irrt = 0x0100
    Reject = 0x0200
  end

  struct RtEntry
    pad1 : ULong
    dst : Sockaddr
    gateway : Sockaddr
    genmask : Sockaddr
    flags : RtEntryFlags
    pad2 : Short
    pad3 : ULong
    pad4 : Void*
    metric : Short # +1 !
    dev : Char*
    mtu : ULong
    window : ULong
    irtt : UShort
  end

  fun ioctl(fd : Int, request : Int, ...) : Int
  fun getifaddrs(ifap : IfAddrs**) : Int
  fun freeifaddrs(ifa : IfAddrs*) : Void
  # fun sendmsg(fd : Int, msg : MsgHdr*, flags : Int) : SSizeT
end

module Tuntap
  # Control class for network interfaces
  class Interface
    # Default value for the MTU
    DEFAULT_MTU = 1500

    UNSET_ADDR = "0.0.0.0"
    DEFAULT_METRIC = 100

    # The MTU
    property mtu : Int32

    # The device name
    getter name : String

    # The file descriptor controlling the device
    getter fd : IO::FileDescriptor

    # Opens the interface *name*
    def self.open(name : String)
      new(create_control_socket, name)
    end

    protected def self.create_control_socket
      sock = LibC.socket(LibC::AF_INET, LibC::SOCK_DGRAM, 0)
      raise Errno.new("socket") if sock < 0
      IO::FileDescriptor.new(sock)
    end

    #
    def initialize(@fd : IO::FileDescriptor, @name : String)
      @mtu = DEFAULT_MTU
    end

    # Closes the device.  If it is not persistent, the system will remove the device entirely.
    def close
      @fd.close
    end

    # Enables the network interface ("Brings it up").
    def up! : Nil
      ioctl(LibC::SIOCSIFFLAGS, ifreq(LibC::IfReqFlags::Up))
    end

    # Disables the network interface ("Brings it down").
    def down! : Nil
      ioctl(LibC::SIOCSIFFLAGS, ifreq(LibC::IfReqFlags::None))
    end

    # Adds an IP address to the interface.  For this to work, the interface has
    # to be up.
    def add_address(address : String) : Nil
      ifr = ifreq
      ifr.ifr = LibC::IfReqData.new(addr: sockaddr(address))

      ioctl LibC::SIOCSIFADDR, ifr
    end

    # Adds a network route to this interface.  Most arguments are optional.
    def add_route(destination : String, gateway : String = UNSET_ADDR,
                  mask : String = UNSET_ADDR, metric = DEFAULT_METRIC,
                  mtu = DEFAULT_MTU, window = 0,
                  flags : LibC::RtEntryFlags = LibC::RtEntryFlags::Up)
      route = LibC::RtEntry.new
      route.dst = sockaddr(destination)
      route.gateway = sockaddr(gateway)
      route.genmask = sockaddr(mask)
      route.flags = flags
      route.metric = LibC::Short.new(metric + 1)
      route.mtu = LibC::ULong.new(mtu)
      route.window = LibC::ULong.new(window)
      route.dev = @name.to_slice.pointer(@name.size)
      ioctl(LibC::SIOCADDRT, route)
    end

    # Runs an `ioctl(3)` on the device.  Raises `Errno` on failure.
    def ioctl(command, argument) : Int32
      LibC.ioctl(@fd.fd, command, pointerof(argument)).tap do |result|
        raise Errno.new("ioctl(#{result})") if result < 0
      end
    end

    # Acquires the list of available interfaces
    def self.names : Array(String)
      ifap = getifaddrs
      ptr = ifap
      ary = Array(String).new

      while ptr
        name = String.new(ptr.value.name)
        ary << name unless ary.includes? name
        ptr = ptr.value.next
      end

      ary
    ensure
      LibC.freeifaddrs(ifap)
    end

    private def self.getifaddrs
      if LibC.getifaddrs(out ifap) == -1
        raise Errno.new("getifaddrs")
      end

      ifap
    end

    private def ifreq(flags = LibC::IfReqFlags::None) : LibC::IfReq
      ifr = LibC::IfReq.new
      ifru = LibC::IfReqData.new(flags: flags)
      name = StaticArray(LibC::Char, LibC::IFNAMSIZ).new(0u8)
      name.to_slice.copy_from(@name.to_slice)
      ifr.ifrn_name = name
      ifr.ifr = ifru
      ifr
    end

    private def sockaddr(address)
      addr = LibC::SockaddrIn.new
      addr.sin_family = Socket::Family::INET.value
      addr.sin_port = 0

      in_addr = uninitialized LibC::InAddr
      LibC.inet_pton(addr.sin_family, address, pointerof(in_addr).as(Void*))
      addr.sin_addr = in_addr

      saddr = LibC::Sockaddr.new
      pointerof(saddr).as(UInt8*)
        .to_slice(sizeof(LibC::Sockaddr))
        .copy_from(pointerof(addr).as(UInt8*).to_slice(sizeof(LibC::SockaddrIn)))
      saddr
    end
  end
end

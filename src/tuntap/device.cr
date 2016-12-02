require "./interface"

module Tuntap

  # Describes a TUN/TAP device.  Some methods may need additional permissions,
  # please make sure to read them before something "doesn't work".
  class Device < Interface
    # Path to the clone device.  May be different for non-Linux systems.
    CLONE_DEVICE = "/dev/net/tun"

    # The handle of the tunnel device, which can be read from and written to.
    getter handle : IO::FileDescriptor

    # The flags this device created with
    getter flags : LibC::IfReqFlags

    # Creates a brand new device or opens an existing one.  To create a new one,
    # the user needs to have one of these:
    # * **root** permissions (The effective UID is `0`, or user is a system user)
    # * the **CAP_NET_ADMIN** permission
    #
    # To open an existing device, the requirements are these:
    # * The device already exists
    # * The device is owned by this process's UNIX user
    # * The user has read/write permissions on `/dev/net/tun`
    # * The *flags* match those used to create the device
    #
    # If creation fails, an `Errno` is raised.
    #
    # If the *device_name* is `nil`, one is automatically chosen by the system.
    # If given, its length must be <= 16.  As for the *flags*, exactly one of
    # `Tun` or `Tap` must be set.  If any of these are violated, an
    # `ArgumentError` is raised.
    def self.open(device_name : String? = nil, flags = LibC::IfReqFlags::Tun) : self
      tun_tap = (flags & LibC::IfReqFlags.flags(Tun, Tap)).value
      if tun_tap == 0 || tun_tap == 3
        raise ArgumentError.new("Exactly one of Tun or Tap flags must be set")
      end

      if device_name && device_name.size > LibC::IFNAMSIZ
        raise ArgumentError.new("Length of device name must be <= #{LibC::IFNAMSIZ}")
      end

      clone_dev = File.open(CLONE_DEVICE, "r+")
      ifr = LibC::IfReq.new
      ifru = LibC::IfReqData.new(flags: flags)
      ifr.ifr = ifru

      if device_name
        name = StaticArray(LibC::Char, LibC::IFNAMSIZ).new(0u8)
        name.to_slice.copy_from(device_name.to_slice)
        ifr.ifrn_name = name
      end

      err = LibC.ioctl(clone_dev.fd, LibC::TUNSETIFF, pointerof(ifr))
      if err < 0
        raise Errno.new("ioctl(#{err})")
      end

      clone_dev.blocking = false
      clone_dev.sync = true
      name_len = (ifr.ifrn_name[LibC::IFNAMSIZ - 1] == 0) ? LibC.strlen(ifr.ifrn_name.to_unsafe) : LibC::IFNAMSIZ
      new(clone_dev, String.new(ifr.ifrn_name.to_unsafe, name_len), flags)
    rescue error
      clone_dev.try(&.close)
      raise error
    end

    def initialize(@handle : IO::FileDescriptor, name : String, @flags : LibC::IfReqFlags)
      super(self.class.create_control_socket, name)
    end

    # Reads from the device, putting the data into *buffer*.  Returns the
    # slice trimmed down to the size of the received packet.
    def read(buffer = Bytes.new(@mtu)) : Bytes
      bytes = @handle.read buffer
      buffer[0, bytes]
    end

    # Reads a packet from the device
    def read_packet : IpPacket
      IpPacket.new(read, !@flags.no_pi?, @flags.tap?)
    end

    # Writes the *packet* into the tunnel device.
    def write(packet : Bytes)
      @handle.write packet
    end

    # ditto
    def write(packet : IpPacket)
      @handle.write packet.frame
    end
  end
end

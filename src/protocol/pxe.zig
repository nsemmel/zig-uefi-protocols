const std = @import("std");
const uefi = std.os.uefi;
const Event = uefi.Event;
const Guid = uefi.Guid;
const Status = uefi.Status;
const cc = uefi.cc;
const Error = Status.Error;
const IpAddress = uefi.IpAddress;
const MacAddress = uefi.MacAddress;

const Dhcp4 = @import("dhcp4.zig").Dhcp4;

const EFI_PXE_BASE_CODE_START = *const fn (*Pxe, bool) callconv(cc) Status;
const EFI_PXE_BASE_CODE_STOP = *const fn (*Pxe) callconv(cc) Status;
const EFI_PXE_BASE_CODE_DHCP = *const fn (*Pxe, bool) callconv(cc) Status;
const EFI_PXE_BASE_CODE_DISCOVER = *const fn (*Pxe, Pxe.BootType, *u16, bool, ?*const Pxe.DiscoverInfo) callconv(cc) Status;
const EFI_PXE_BASE_CODE_MTFTP = *const fn (*Pxe, Pxe.TftpOpcode, [*]u8, bool, *u64, *const u64, *const IpAddress, [*:0]const u8, ?*const Pxe.MtftpInfo, bool) callconv(cc) Status;
const EFI_PXE_BASE_CODE_UDP_WRITE = *const fn (*Pxe, u16, *const IpAddress, *const u16, ?*const IpAddress, ?*const IpAddress, ?*u16, ?*usize, ?*const anyopaque, *usize, *const anyopaque) callconv(cc) Status;
const EFI_PXE_BASE_CODE_UDP_READ = *const fn (*Pxe, u16, ?*IpAddress, ?*u16, ?*IpAddress, ?*u16, ?*const usize, ?*anyopaque, *usize, *anyopaque) callconv(cc) Status;
// TODO: The rest:
const EFI_PXE_BASE_CODE_SET_IP_FILTER = *const fn (*Pxe) callconv(cc) Status;
const EFI_PXE_BASE_CODE_ARP = *const fn (*Pxe) callconv(cc) Status;
const EFI_PXE_BASE_CODE_SET_PARAMETERS = *const fn (*Pxe) callconv(cc) Status;
const EFI_PXE_BASE_CODE_SET_STATION_IP = *const fn (*Pxe) callconv(cc) Status;
const EFI_PXE_BASE_CODE_SET_PACKETS = *const fn (*Pxe) callconv(cc) Status;

pub const Pxe = extern struct {
    revision: u64,
    _start: EFI_PXE_BASE_CODE_START,
    _stop: EFI_PXE_BASE_CODE_STOP,
    _dhcp: EFI_PXE_BASE_CODE_DHCP,
    _discover: EFI_PXE_BASE_CODE_DISCOVER,
    _mtftp: EFI_PXE_BASE_CODE_MTFTP,
    _udp_write: EFI_PXE_BASE_CODE_UDP_WRITE,
    _udp_read: EFI_PXE_BASE_CODE_UDP_READ,
    _set_ip_filter: EFI_PXE_BASE_CODE_SET_IP_FILTER,
    _arp: EFI_PXE_BASE_CODE_ARP,
    _set_parameters: EFI_PXE_BASE_CODE_SET_PARAMETERS,
    _set_station_ip: EFI_PXE_BASE_CODE_SET_STATION_IP,
    _set_packets: EFI_PXE_BASE_CODE_SET_PACKETS,
    mode: *const Mode,

    pub const guid align(8) = Guid{
        .time_low = 0x03C4E603,
        .time_mid = 0xAC28,
        .time_high_and_version = 0x11d3,
        .clock_seq_high_and_reserved = 0x9A,
        .clock_seq_low = 0x2D,
        .node = [_]u8{ 0x00, 0x90, 0x27, 0x3F, 0xC1, 0x4D },
    };

    pub const StartError = uefi.UnexpectedError || error{
        InvalidParameter,
        Unsupported,
        AlreadyStarted,
        DeviceError,
        OutOfResources,
    };
    pub fn start(this: *@This(), use_ipv6: bool) StartError!void {
        switch (this._start(this, use_ipv6)) {
            .success => {},
            .invalid_parameter => return StartError.InvalidParameter,
            .unsupported => return StartError.Unsupported,
            .already_started => return StartError.AlreadyStarted,
            .device_error => return StartError.DeviceError,
            .out_of_resources => return StartError.OutOfResources,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const StopError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        DeviceError,
    };
    pub fn stop(this: *@This()) Status!void {
        switch (this._stop(this)) {
            .success => {},
            .not_started => return StopError.NotStarted,
            .invalid_parameter => return StopError.InvalidParameter,
            .device_error => return StopError.DeviceError,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const DhcpError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        DeviceError,
        OutOfResources,
        Aborted,
        Timeout,
        IcmpError,
        NoResponse,
    };
    pub fn dhcp(this: *@This(), sort_offers: bool) DhcpError!void {
        switch (this._dhcp(this, sort_offers)) {
            .success => {},
            .not_started => return DhcpError.NotStarted,
            .invalid_parameter => return DhcpError.InvalidParameter,
            .device_error => return DhcpError.DeviceError,
            .out_of_resources => return DhcpError.OutOfResources,
            .aborted => return DhcpError.Aborted,
            .timeout => return DhcpError.Timeout,
            .icmp_error => return DhcpError.IcmpError,
            .no_response => return DhcpError.NoResponse,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const DiscoveryError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        DeviceError,
        OutOfResources,
        Aborted,
        Timeout,
        IcmpError,
    };
    pub fn discovery(
        this: *@This(),
        boot_type: BootType,
        layer: *u16,
        use_bis: bool,
        info: ?*const DiscoverInfo,
    ) DiscoveryError!void {
        switch (this._discover(this, boot_type, layer, use_bis, info)) {
            .success => {},
            .not_started => return DiscoveryError.NotStarted,
            .invalid_parameter => return DiscoveryError.InvalidParameter,
            .device_error => return DiscoveryError.DeviceError,
            .out_of_resources => return DiscoveryError.OutOfResources,
            .aborted => return DiscoveryError.Aborted,
            .timeout => return DiscoveryError.Timeout,
            .icmp_error => return DiscoveryError.IcmpError,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const MtftpError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        DeviceError,
        BufferTooSmall,
        Aborted,
        Timeout,
        TftpError,
        IcmpError,
    };
    pub const MtftpOpts = struct {
        overwrite: bool = false,
        dont_use_buffer: bool = false,
        blocksize: ?u32 = null,
    };
    pub const MtfptResult = union(enum) {
        get_file_size: u64,
        read_file: u64,
    };
    pub fn mtftp(
        this: *@This(),
        comptime opcode: TftpOpcode,
        buffer: []u8,
        server_ip: *const IpAddress,
        filename: ?[*:0]const u8,
        info: ?*const MtftpInfo,
        opts: MtftpOpts,
    ) MtftpError!u64 {
        var size: u64 = buffer.len;
        switch (this._mtftp(
            this,
            opcode,
            buffer.ptr,
            opts.overwrite,
            &size,
            opts.blocksize,
            server_ip,
            filename,
            info,
            opts.dont_use_buffer,
        )) {
            .success => return size,
            .not_started => return MtftpError.NotStarted,
            .invalid_parameter => return MtftpError.InvalidParameter,
            .device_error => return MtftpError.DeviceError,
            .buffer_too_small => return MtftpError.BufferTooSmall,
            .aborted => return MtftpError.Aborted,
            .timeout => return MtftpError.Timeout,
            .tftp_error => return MtftpError.TftpError,
            .icmp_error => return MtftpError.IcmpError,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const UdpWriteError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        DeviceError,
        BadBufferSize,
        Aborted,
        Timeout,
        IcmpError,
    };
    pub fn udpWrite(
        this: *@This(),
        op_flags: u16,
        dest_ip: *const IpAddress,
        dest_port: u16,
        gateway_ip: ?*const IpAddress,
        src_ip: ?*const IpAddress,
        src_port: ?*u16,
        header: ?[]const u8,
        buffer: []const u8,
    ) UdpWriteError!void {
        const header_len: usize = if (header) |h| h.len else 0;
        const buffer_len: usize = buffer.len;
        switch (this._udp_write(
            this,
            op_flags,
            dest_ip,
            &dest_port,
            gateway_ip,
            src_ip,
            &src_port,
            if (header != null) &header_len else null,
            header.ptr,
            &buffer_len,
            buffer.ptr,
        )) {
            .success => {},
            .not_started => return UdpWriteError.NotStarted,
            .invalid_parameter => return UdpWriteError.InvalidParameter,
            .device_error => return UdpWriteError.DeviceError,
            .bad_buffer_size => return UdpWriteError.BadBufferSize,
            .aborted => return UdpWriteError.Aborted,
            .timeout => return UdpWriteError.Timeout,
            .icmp_error => return UdpWriteError.IcmpError,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const UdpReadError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        DeviceError,
        BadBufferSize,
        Aborted,
        Timeout,
    };
    pub fn udpRead(
        this: *@This(),
        op_flags: u16,
        dest_ip: ?*IpAddress,
        dest_port: ?*u16,
        src_ip: ?*IpAddress,
        src_port: ?*u16,
        header: ?[]u8,
        buffer: []u8,
    ) UdpReadError!u64 {
        const header_len: usize = if (header) |h| h.len else 0;
        var buffer_len: usize = buffer.len;
        switch (this._udp_write(
            this,
            op_flags,
            dest_ip,
            &dest_port,
            src_ip,
            &src_port,
            if (header != null) &header_len else null,
            header.ptr,
            &buffer_len,
            buffer.ptr,
        )) {
            .success => buffer_len,
            .not_started => return UdpReadError.NotStarted,
            .invalid_parameter => return UdpReadError.InvalidParameter,
            .device_error => return UdpReadError.DeviceError,
            .bad_buffer_size => return UdpReadError.BadBufferSize,
            .aborted => return UdpReadError.Aborted,
            .timeout => return UdpReadError.Timeout,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const Mode = extern struct {
        started: bool,
        ipv6_available: bool,
        ipv6_supported: bool,
        using_ipv6: bool,
        bis_supported: bool,
        bis_detected: bool,
        auto_arp: bool,
        send_guid: bool,
        dhcp_discover_valid: bool,
        dhcp_ack_receivd: bool,
        proxy_offer_received: bool,
        pxe_discover_valid: bool,
        pxe_reply_received: bool,
        pxe_bis_reply_received: bool,
        icmp_error_received: bool,
        tftp_error_received: bool,
        make_callbacks: bool,
        ttl: u8,
        to_s: u8,
        station_ip: IpAddress,
        subnet_mask: IpAddress,
        dhcp_discover: Packet,
        dhcp_ack: Packet,
        proxy_offer: Packet,
        pxe_discover: Packet,
        pxe_reply: Packet,
        pxe_bis_reply: Packet,
        ip_filter: IpFilter,
        arp_cache_entries: u32,
        arp_cache: [MaxArpEntries]ArpEntry,
        route_table_entries: u32,
        route_table: [MaxRouteEntries]RouteEntry,
        icmp_error: IcmpError,
        tftp_error: TftpError,

        pub const MaxArpEntries = 8;
        pub const MaxRouteEntries = 8;
    };

    pub const Packet = extern union {
        raw: [1472]u8,
        dhcpv4: Dhcp4.Packet,
        // TODO: dhcpv6: Dhcp6.Packet,
    };
    pub const IpFilter = extern struct {
        filters: u8,
        ip_count: u8,
        reserved: u16 = 0,
        ip_list: [MaxIpCount]IpAddress,

        pub const MaxIpCount = 8;

        pub const StationIp = 0x0001;
        pub const Broadcast = 0x0002;
        pub const Promiscuous = 0x0004;
        pub const PromiscuousMulticast = 0x0008;
    };
    pub const ArpEntry = extern struct {
        ip_addr: IpAddress,
        mac_addr: MacAddress,
    };
    pub const RouteEntry = extern struct {
        ip_addr: IpAddress,
        subnet_mask: IpAddress,
        gw_addr: IpAddress,
    };

    pub const IcmpError = extern struct {
        type_: u8,
        code: u8,
        checksum: u16,
        data: [494]u8,
        u: extern union {
            reserved: u32,
            mtu: u32,
            pointer: u32,
            echo: extern struct {
                identifier: u16,
                sequence: u16,
            },
        },
    };
    pub const TftpError = extern struct {
        error_code: u8,
        error_string: [127]u8,
    };

    pub const Layer = enum(u16) {
        _,

        pub const mask: @This() = @enumFromInt(0x7FFF);
        pub const init: @This() = @enumFromInt(0);
    };

    pub const BootType = enum(u16) {
        BOOTSTRAP = 0,
        MS_WINNT_RIS = 1,
        INTEL_LCM = 2,
        DOSUNDI = 3,
        NEC_ESMPRO = 4,
        IBM_WSoD = 5,
        IBM_LCCM = 6,
        CA_UNICENTER_TNG = 7,
        HP_OPENVIEW = 8,
        ALTIRIS_9 = 9,
        ALTIRIS_10 = 10,
        ALTIRIS_11 = 11,
        NOT_USED_12 = 12,
        REDHAT_INSTALL = 13,
        REDHAT_BOOT = 14,
        REMBO = 15,
        BEOBOOT = 16,
        // Values 17 through 32767 are reserved.
        // Values 32768 through 65279 are for vendor use.
        // Values 65280 through 65534 are reserved.
        PXETEST = 65535,

        _,
    };
    pub const DiscoverInfo = extern struct {
        use_mcast: bool,
        use_bcast: bool,
        use_ucast: bool,
        must_use_list: bool,
        server_mcast_ip: IpAddress,
        ip_cnt: u16,
        srv_list: [0]SrvList,
    };
    pub const SrvList = extern struct {
        type_: u16,
        accept_any_response: bool,
        _reserved: u8 = 0,
        ip_addr: IpAddress,
    };

    pub const TftpOpcode = enum(usize) {
        TFTP_FIRST,
        TFTP_GET_FILE_SIZE,
        TFTP_READ_FILE,
        TFTP_WRITE_FILE,
        TFTP_READ_DIRECTORY,
        MTFTP_GET_FILE_SIZE,
        MTFTP_READ_FILE,
        MTFTP_READ_DIRECTORY,
        MTFTP_LAST,
    };
    pub const MtftpInfo = extern struct {
        mcast_ip: IpAddress,
        cport: u16,
        sport: u16,
        listen_timeout: u16,
        transit_timeout: u16,
    };
};

const std = @import("std");
const uefi = std.os.uefi;
const cc = uefi.cc;
const Guid = uefi.Guid;
const Status = uefi.Status;
const Error = Status.Error;
const Event = uefi.Event;
const Boolean = bool;
const Time = uefi.Time;
const Ipv4Address = uefi.Ipv4Address;
const SimpleNetwork = uefi.protocol.SimpleNetwork;
const ManagedNetwork = uefi.protocol.ManagedNetwork;

const EFI_IP4_GET_MODE_DATA = *const fn (*Ip4, ?*Ip4.ModeData, ?*ManagedNetwork.Config, ?*SimpleNetwork.Mode) callconv(cc) Status;
const EFI_IP4_CONFIGURE = *const fn (*Ip4, ?*const Ip4.ConfigData) callconv(cc) Status;
const EFI_IP4_GROUPS = *const fn (*Ip4, Boolean, ?*const Ipv4Address) callconv(cc) Status;
const EFI_IP4_ROUTES = *const fn (*Ip4, Boolean, ?*const Ipv4Address, ?*const Ipv4Address, ?*const Ipv4Address) callconv(cc) Status;
const EFI_IP4_TRANSMIT = *const fn (*Ip4, *Ip4.CompletionToken) callconv(cc) Status;
const EFI_IP4_RECEIVE = *const fn (*Ip4, *Ip4.CompletionToken) callconv(cc) Status;
const EFI_IP4_CANCEL = *const fn (*Ip4, ?*Ip4.CompletionToken) callconv(cc) Status;
const EFI_IP4_POLL = *const fn (*Ip4) callconv(cc) Status;

pub const Ip4 = extern struct {
    _get_mode_data: EFI_IP4_GET_MODE_DATA,
    _configure: EFI_IP4_CONFIGURE,
    _groups: EFI_IP4_GROUPS,
    _routes: EFI_IP4_ROUTES,
    _transmit: EFI_IP4_TRANSMIT,
    _receive: EFI_IP4_RECEIVE,
    _cancel: EFI_IP4_CANCEL,
    _poll: EFI_IP4_POLL,

    pub const guid align(8) = Guid{
        .time_low = 0x41d94cd2,
        .time_mid = 0x35b6,
        .time_high_and_version = 0x455a,
        .clock_seq_high_and_reserved = 0x82,
        .clock_seq_low = 0x58,
        .node = .{ 0xd4, 0xe5, 0x13, 0x34, 0xaa, 0xdd },
    };

    pub const ServiceBinding = uefi.protocol.ServiceBinding(.{
        .time_low = 0xc51711e7,
        .time_mid = 0xb4bf,
        .time_high_and_version = 0x404a,
        .clock_seq_high_and_reserved = 0xbf,
        .clock_seq_low = 0xb8,
        .node = .{ 0x0a, 0x04, 0x8e, 0xf1, 0xff, 0xe4 },
    });

    pub const GetModeDataError = uefi.UnexpectedError || error{
        InvalidParameter,
        OutOfResources,
    };
    pub const ModeDataKind = union(enum) {
        ip4_mode_data: ModeData,
        mnp_config: ManagedNetwork.Config,
        snp_mode: SimpleNetwork.Mode,
    };
    pub fn getModeData(
        this: *@This(),
        comptime info: std.meta.Tag(ModeDataKind),
    ) GetModeDataError!@FieldType(ModeDataKind, @tagName(info)) {
        var buffer = std.mem.zeroes(@FieldType(ModeDataKind, @tagName(info)));
        switch (this._get_mode_data(
            this,
            if (info == .ip4_mode_data) &buffer else null,
            if (info == .mnp_config) &buffer else null,
            if (info == .snp_mode) &buffer else null,
        )) {
            .success => return buffer,
            .invalid_parameter => return GetModeDataError.InvalidParameter,
            .out_of_resources => return GetModeDataError.OutOfResources,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const ConfigureError = uefi.UnexpectedError || error{
        NoMapping,
        IpAddressConflict,
        InvalidParameter,
        Unsupported,
        OutOfResources,
        AlreadyStarted,
        DeviceError,
    };
    pub fn configure(this: *@This(), data: ?*const ConfigData) ConfigureError!void {
        switch (this._configure(this, data)) {
            .success => {},
            .already_started => {},
            .no_mapping => return ConfigureError.NoMapping,
            .ip_address_conflict => return ConfigureError.IpAddressConflict,
            .invalid_parameter => return ConfigureError.InvalidParameter,
            .unsupported => return ConfigureError.Unsupported,
            .out_of_resources => return ConfigureError.OutOfResources,
            .device_error => return ConfigureError.DeviceError,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const GroupsError = uefi.UnexpectedError || error{
        InvalidParameter,
        NotStarted,
        NoMapping,
        OutOfResources,
        Unsupported,
        AlreadyStarted,
        NotFound,
        DeviceError,
    };
    pub fn groups(this: *@This(), join_flag: bool, group_address: ?Ipv4Address) GroupsError!void {
        switch (this._groups(this, join_flag, if (group_address) |*ip| ip else null)) {
            .success => {},
            .invalid_parameter => return GroupsError.InvalidParameter,
            .not_started => return GroupsError.NotStarted,
            .no_mapping => return GroupsError.NoMapping,
            .out_of_resources => return GroupsError.OutOfResources,
            .unsupported => return GroupsError.Unsupported,
            .already_started => return GroupsError.AlreadyStarted,
            .not_found => return GroupsError.NotFound,
            .device_error => return GroupsError.Device,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const RoutesError = uefi.UnexpectedError || error{
        NotStarted,
        NoMapping,
        InvalidParameter,
        OutOfResources,
        NotFound,
        AccessDenied,
    };
    pub fn routes(
        this: *@This(),
        delete: bool,
        subnet_address: Ipv4Address,
        subnet_mask: Ipv4Address,
        gateway_address: Ipv4Address,
    ) RoutesError!void {
        switch (this._routes(delete, &subnet_address, &subnet_mask, &gateway_address)) {
            .success => {},
            .not_started => return RoutesError.NotStarted,
            .no_mapping => return RoutesError.NoMapping,
            .invalid_parameter => return RoutesError.InvalidParameter,
            .out_of_resources => return RoutesError.OutOfResources,
            .not_found => return RoutesError.NotFound,
            .access_denied => return RoutesError.AccessDenied,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const TransmitError = uefi.UnexpectedError || error{
        NotStarted,
        NoMapping,
        InvalidParameter,
        AccessDenied,
        NotReady,
        NotFound,
        OutOfResources,
        BufferTooSmall,
        BadBufferSize,
        NoMedia,
    };
    pub fn transmit(this: *@This(), token: *CompletionToken) TransmitError!void {
        switch (this._transmit(this, token)) {
            .success => {},
            .not_started => return TransmitError.NotStarted,
            .no_mapping => return TransmitError.NoMapping,
            .invalid_parameter => return TransmitError.InvalidParameter,
            .access_denied => return TransmitError.AccessDenied,
            .not_ready => return TransmitError.NotReady,
            .not_found => return TransmitError.NotFound,
            .out_of_resources => return TransmitError.OutOfResources,
            .buffer_too_small => return TransmitError.BufferTooSmall,
            .bad_buffer_size => return TransmitError.BadBufferSize,
            .no_media => return TransmitError.NoMedia,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const ReceiveError = uefi.UnexpectedError || error{
        Notstarted,
        NoMapping,
        InvalidParameter,
        OutOfResources,
        DeviceError,
        AccessDenied,
        NotReady,
        IcmpError,
        NoMedia,
    };
    pub fn receive(this: *@This(), token: *CompletionToken) ReceiveError!void {
        switch (this._receive(this, token)) {
            .success => {},
            .not_started => return ReceiveError.Notstarted,
            .no_mapping => return ReceiveError.NoMapping,
            .invalid_parameter => return ReceiveError.InvalidParameter,
            .out_of_resources => return ReceiveError.OutOfResources,
            .device_error => return ReceiveError.DeviceError,
            .access_denied => return ReceiveError.AccessDenied,
            .not_ready => return ReceiveError.NotReady,
            .icmp_error => return ReceiveError.IcmpError,
            .no_media => return ReceiveError.NoMedia,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const CancelError = uefi.UnexpectedError || error{
        InvalidParameter,
        NotStarted,
        NoMapping,
        NotFound,
    };
    pub fn cancel(this: *@This(), token: ?*CompletionToken) CancelError!void {
        switch (this._cancel(this, token)) {
            .success => {},
            .invalid_parameter => return CancelError.InvalidParameter,
            .not_started => return CancelError.NotStarted,
            .no_mapping => return CancelError.NoMapping,
            .not_found => return CancelError.NotFound,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const PollError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        DeviceError,
        NotReady,
        Timeout,
    };
    pub fn poll(this: *@This()) PollError!void {
        switch (this._poll(this)) {
            .success => {},
            .not_started => return PollError.NotStarted,
            .invalid_parameter => return PollError.InvalidParameter,
            .device_error => return PollError.DeviceError,
            .not_ready => return PollError.NotReady,
            .timeout => return PollError.Timeout,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const IcmpType = extern struct {
        type: u8,
        code: u8,
    };

    pub const RouteTable = extern struct {
        subnet_address: Ipv4Address,
        subnet_mask: Ipv4Address,
        gateway_address: Ipv4Address,
    };

    pub const ConfigData = extern struct {
        default_protocol: u8,
        accept_any_protocol: Boolean,
        accept_icmp_errors: Boolean,
        accept_broadcast: Boolean,
        accept_promiscuous: Boolean,
        use_default_address: Boolean,
        station_address: Ipv4Address,
        subnet_mask: Ipv4Address,
        type_of_service: u8,
        time_to_live: u8,
        do_not_fragment: Boolean,
        raw_data: Boolean,
        receive_timeout: u32,
        transmit_timeout: u32,
    };

    pub const ModeData = extern struct {
        is_started: Boolean,
        max_packet_size: u32,
        config_data: ConfigData,
        is_configured: Boolean,
        group_count: u32,
        group_table: ?[*]Ipv4Address,
        route_count: u32,
        route_table: ?[*]RouteTable,
        icmp_type_count: u32,
        icmp_type_list: ?[*]IcmpType,
    };

    /// #pragma pack(1)
    pub const Header = extern struct {
        header_length_and_version: u8,
        type_of_service: u8,
        total_length: u16 align(1),
        identification: u16 align(1),
        fragmentation: u16 align(1),
        time_to_live: u8,
        protocol: u8,
        checksum: u16 align(1),
        source_address: Ipv4Address,
        destination_address: Ipv4Address,
    };

    pub const FragmentData = extern struct {
        fragment_length: u32,
        fragment_buffer: ?*anyopaque,
    };

    pub const ReceiveData = extern struct {
        time_stamp: Time,
        recycle_signal: Event,
        header_length: u32,
        header: ?*Header,
        options_length: u32,
        options: ?*anyopaque,
        data_length: u32,
        fragment_count: u32,
        fragment_table: [1]FragmentData,
    };

    pub const OverrideData = extern struct {
        source_address: Ipv4Address,
        gateway_address: Ipv4Address,
        protocol: u8,
        type_of_service: u8,
        time_to_live: u8,
        do_not_fragment: Boolean,
    };

    pub const TransmitData = extern struct {
        destination_address: Ipv4Address,
        override_data: ?*OverrideData,
        options_length: u32,
        options_buffer: ?*anyopaque,
        total_data_length: u32,
        fragment_count: u32,
        fragment_table: [1]FragmentData,
    };

    pub const CompletionToken = extern struct {
        event: ?Event,
        status: Status,
        packet: extern union {
            rx_data: ?*ReceiveData,
            tx_data: ?*TransmitData,
        },
    };
};

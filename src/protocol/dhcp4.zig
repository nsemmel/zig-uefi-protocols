const std = @import("std");
const uefi = std.os.uefi;
const Event = uefi.Event;
const Guid = uefi.Guid;
const Status = uefi.Status;
const cc = uefi.cc;
const Error = Status.Error;
const Ipv4Address = uefi.Ipv4Address;
const MacAddress = uefi.MacAddress;

const EFI_DHCP4_GET_MODE_DATA = *const fn (*const Dhcp4, *Dhcp4.ModeData) callconv(cc) Status;
const EFI_DHCP4_CONFIGURE = *const fn (*Dhcp4, ?*const Dhcp4.ConfigData) callconv(cc) Status;
const EFI_DHCP4_START = *const fn (*Dhcp4, ?Event) callconv(cc) Status;
const EFI_DHCP4_RENEW_REBIND = *const fn (*Dhcp4, bool, ?Event) callconv(cc) Status;
const EFI_DHCP4_RELEASE = *const fn (*Dhcp4) callconv(cc) Status;
const EFI_DHCP4_STOP = *const fn (*Dhcp4) callconv(cc) Status;
const EFI_DHCP4_BUILD = *const fn (*Dhcp4, *const Dhcp4.Packet, u32, ?[*]const u8, u32, ?[*]const *const Dhcp4.PacketOption, **Dhcp4.Packet) callconv(cc) Status;
const EFI_DHCP4_TRANSMIT_RECEIVE = *const fn (*Dhcp4, *Dhcp4.TransmitReceiveToken) callconv(cc) Status;
const EFI_DHCP4_PARSE = *const fn (*Dhcp4, *const Dhcp4.Packet, *u32, ?[*]*Dhcp4.PacketOption) callconv(cc) Status;

pub const Dhcp4 = extern struct {
    _get_mode_data: EFI_DHCP4_GET_MODE_DATA,
    _configure: EFI_DHCP4_CONFIGURE,
    _start: EFI_DHCP4_START,
    _renew_rebind: EFI_DHCP4_RENEW_REBIND,
    _release: EFI_DHCP4_RELEASE,
    _stop: EFI_DHCP4_STOP,
    _build: EFI_DHCP4_BUILD,
    _transmit_receive: EFI_DHCP4_TRANSMIT_RECEIVE,
    _parse: EFI_DHCP4_PARSE,

    pub const guid align(8) = Guid{
        .time_low = 0x8a219718,
        .time_mid = 0x4ef5,
        .time_high_and_version = 0x4761,
        .clock_seq_high_and_reserved = 0x91,
        .clock_seq_low = 0xc8,
        .node = [_]u8{ 0xc0, 0xf0, 0x4b, 0xda, 0x9e, 0x56 },
    };

    pub const ServiceBinding = uefi.protocol.ServiceBinding(.{
        .time_low = 0x9d9a39d8,
        .time_mid = 0xbd42,
        .time_high_and_version = 0x4a73,
        .clock_seq_high_and_reserved = 0xa4,
        .clock_seq_low = 0xd5,
        .node = [_]u8{ 0x8e, 0xe9, 0x4b, 0xe1, 0x13, 0x80 },
    });

    pub const GetModeDataError = uefi.UnexpectedError || error{
        InvalidParameter,
    };
    pub fn getModeData(this: *const @This()) GetModeDataError!ModeData {
        var mode_data = std.mem.zeroes(ModeData);
        switch (this._get_mode_data(this, &mode_data)) {
            .success => return mode_data,
            .invalid_parameter => return Error.InvalidParameter,
            else => |s| return uefi.unexpectedStatus(s),
        }
    }

    pub const ConfigureError = uefi.UnexpectedError || error{
        AccessDenied,
        InvalidParameter,
        OutOfResources,
        DeviceError,
    };
    pub fn configure(this: *@This(), config_data: ?*const ConfigData) ConfigureError!void {
        switch (this._configure(this, config_data)) {
            .success => {},
            .access_denied => return Error.AccessDenied,
            .invalid_parameter => return Error.InvalidParameter,
            .out_of_resources => return Error.OutOfResources,
            .device_error => return Error.DeviceError,
            else => |s| return uefi.unexpectedStatus(s),
        }
    }

    pub const StartError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        OutOfResources,
        Timeout,
        Aborted,
        AlreadyStarted,
        DeviceError,
        NoMedia,
    };
    pub fn start(this: *@This(), completion_event: ?Event) StartError!void {
        switch (this._start(this, completion_event)) {
            .success => {},
            .not_started => return Error.NotStarted,
            .invalid_parameter => return Error.InvalidParameter,
            .out_of_resources => return Error.OutOfResources,
            .timeout => return Error.Timeout,
            .aborted => return Error.Aborted,
            .already_started => return Error.AlreadyStarted,
            .device_error => return Error.DeviceError,
            .no_media => return Error.NoMedia,
            else => |s| return uefi.unexpectedStatus(s),
        }
    }

    pub const RenewRebindError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        Timeout,
        AccessDenied,
        DeviceError,
    };
    pub fn renewRebind(this: *@This(), rebind_request: bool, completion_event: ?Event) RenewRebindError!void {
        switch (this._renew_rebind(this, rebind_request, completion_event)) {
            .success => {},
            .not_started => return Error.NotStarted,
            .invalid_parameter => return Error.InvalidParameter,
            .timeout => return Error.Timeout,
            .access_denied => return Error.AccessDenied,
            .device_error => return Error.DeviceError,
            else => |s| return uefi.unexpectedStatus(s),
        }
    }

    pub const ReleaseError = uefi.UnexpectedError || error{
        InvalidParameter,
        AccessDenied,
        DeviceError,
    };
    pub fn release(this: *@This()) ReleaseError!void {
        switch (this._release(this)) {
            .success => {},
            .invalid_parameter => return Error.InvalidParameter,
            .access_denied => return Error.AccessDenied,
            .device_error => return Error.DeviceError,
            else => |s| return uefi.unexpectedStatus(s),
        }
    }

    pub const StopError = uefi.UnexpectedError || error{
        InvalidParameter,
        NoMedia,
    };
    pub fn stop(this: *@This()) StopError!void {
        switch (this._stop(this)) {
            .success => {},
            .invalid_parameter => return Error.InvalidParameter,
            .no_media => return Error.NoMedia,
            else => |s| return uefi.unexpectedStatus(s),
        }
    }

    pub const BuildError = uefi.UnexpectedError || error{
        OutOfResources,
        InvalidParameter,
    };
    /// Caller is responsible for freeing the returned packet with `BS.FreePool`.
    pub fn build(
        this: *@This(),
        seed_packet: *const Packet,
        delete_list: []const u8,
        append_list: []const *const PacketOption,
    ) BuildError!*Packet {
        var packet: *Packet = undefined;
        switch (this._build(
            this,
            seed_packet,
            @truncate(delete_list.len),
            delete_list.ptr,
            @truncate(append_list.len),
            append_list.ptr,
            &packet,
        )) {
            .success => return packet,
            .out_of_resources => return Error.OutOfResources,
            .invalid_parameter => return Error.InvalidParameter,
            else => |s| return uefi.unexpectedStatus(s),
        }
    }

    pub const TransmitReceiveError = uefi.UnexpectedError || error{
        InvalidParameter,
        NotReady,
        NoMapping,
        OutOfResources,
        Unsupported,
        NoMedia,
    };
    pub fn transmitReceive(this: *@This(), token: *TransmitReceiveToken) TransmitReceiveError!void {
        switch (this._transmit_receive(this, token)) {
            .success => {},
            .invalid_parameter => return Error.InvalidParameter,
            .not_ready => return Error.NotReady,
            .no_mapping => return Error.NoMapping,
            .out_of_resources => return Error.OutOfResources,
            .unsupported => return Error.Unsupported,
            .no_media => return Error.NoMedia,
            else => |s| return uefi.unexpectedStatus(s),
        }
    }

    pub const ParseError = uefi.UnexpectedError || error{
        InvalidParameter,
        BufferTooSmall,
        OutOfResources,
    };
    pub fn parse(
        this: *@This(),
        packet: *const Packet,
        option_buffer: []*PacketOption,
    ) ParseError![]*PacketOption {
        var len: u32 = @truncate(option_buffer.len);
        switch (this._parse(this, packet, &len, option_buffer.ptr)) {
            .success => return option_buffer[0..len],
            .invalid_parameter => return Error.InvalidParameter,
            .buffer_too_small => return Error.BufferTooSmall,
            .out_of_resources => return Error.OutOfResources,
            else => |s| return uefi.unexpectedStatus(s),
        }
    }

    pub const State = enum(u32) {
        Stopped = 0x0,
        Init = 0x1,
        Selecting = 0x2,
        Requesting = 0x3,
        Bound = 0x4,
        Renewing = 0x5,
        Rebinding = 0x6,
        InitReboot = 0x7,
        Rebooting = 0x8,
    };

    pub const EventKind = enum(u32) {
        SendDiscover = 0x01,
        RcvdOffer = 0x02,
        SelectOffer = 0x03,
        SendRequest = 0x04,
        RcvdAck = 0x05,
        RcvdNak = 0x06,
        SendDecline = 0x07,
        BoundCompleted = 0x08,
        EnterRenewing = 0x09,
        EnterRebinding = 0x0a,
        AddressLost = 0x0b,
        Fail = 0x0c,
    };

    pub const Callback = *const fn (
        *Dhcp4,
        ?*anyopaque,
        State,
        EventKind,
        ?*Packet,
        ?*?*Packet,
    ) callconv(cc) Status;

    pub const ConfigData = extern struct {
        discover_try_count: u32,
        discover_timeout: ?*u32,
        request_try_count: u32,
        request_timeout: ?*u32,
        client_address: Ipv4Address,
        dhcp4_callback: ?Callback,
        callback_context: ?*anyopaque,
        option_count: u32,
        option_list: ?*?*PacketOption,
    };

    pub const ModeData = extern struct {
        state: State,
        config_data: ConfigData,
        client_address: Ipv4Address,
        client_mac_address: MacAddress,
        server_address: Ipv4Address,
        router_address: Ipv4Address,
        subnet_mask: Ipv4Address,
        lease_time: u32,
        reply_packet: ?*Packet,
    };

    /// #pragma pack(1)
    pub const Header = extern struct {
        op_code: u8,
        hw_type: u8,
        hw_addr_len: u8,
        hops: u8,
        xid: u32 align(1),
        seconds: u16 align(1),
        reserved: u16 align(1),
        client_addr: Ipv4Address,
        your_addr: Ipv4Address,
        server_addr: Ipv4Address,
        gateway_addr: Ipv4Address,
        client_hw_addr: [16]u8,
        server_name: [64]u8,
        boot_file_name: [128]u8,
    };

    /// #pragma pack(1)
    pub const Packet = extern struct {
        size: u32 align(1),
        length: u32 align(1),
        dhcp4: extern struct {
            header: Header align(1),
            magik: u32 align(1),
            option: [1]u8 align(1),
        } align(1),
    };

    /// #pragma pack(1)
    pub const PacketOption = extern struct {
        op_code: u8,
        length: u8,
        data: [1]u8,
    };

    pub const ListenPoint = extern struct {
        listen_address: Ipv4Address,
        subnet_mask: Ipv4Address,
        listen_port: u16,
    };

    pub const TransmitReceiveToken = extern struct {
        status: Status,
        completion_event: ?Event,
        remote_address: Ipv4Address,
        remote_port: u16,
        gateway_address: Ipv4Address,
        listen_point_count: u32,
        listen_points: ?*ListenPoint,
        timeout_value: u32,
        packet: *Packet,
        response_count: u32,
        response_list: ?*Packet,
    };
};

const std = @import("std");
const uefi = std.os.uefi;
const Event = uefi.Event;
const Guid = uefi.Guid;
const Status = uefi.Status;
const cc = uefi.cc;
const Error = Status.Error;

const ManagedNetwork = uefi.protocol.ManagedNetwork;
const SimpleNetwork = uefi.protocol.SimpleNetwork;
const Ipv4Address = uefi.Ipv4Address;

const Ip4 = @import("ip4.zig").Ip4;

const EFI_TCP4_GET_MODE_DATA = *const fn (*const Tcp4, ?*Tcp4.State, ?*Tcp4.ConfigData, ?*Ip4.ModeData, ?*ManagedNetwork.Config, ?*SimpleNetwork.Mode) callconv(cc) Status;
const EFI_TCP4_CONFIGURE = *const fn (*Tcp4, ?*const Tcp4.ConfigData) callconv(cc) Status;
const EFI_TCP4_ROUTES = *const fn (*Tcp4, bool, *const Ipv4Address, *const Ipv4Address, *const Ipv4Address) callconv(cc) Status;
const EFI_TCP4_CONNECT = *const fn (*Tcp4, *Tcp4.ConnectionToken) callconv(cc) Status;
const EFI_TCP4_ACCEPT = *const fn (*Tcp4, *Tcp4.ListenToken) callconv(cc) Status;
const EFI_TCP4_TRANSMIT = *const fn (*Tcp4, *Tcp4.IoToken) callconv(cc) Status;
const EFI_TCP4_RECEIVE = *const fn (*Tcp4, *Tcp4.IoToken) callconv(cc) Status;
const EFI_TCP4_CLOSE = *const fn (*Tcp4, *Tcp4.CloseToken) callconv(cc) Status;
const EFI_TCP4_CANCEL = *const fn (*Tcp4, *Tcp4.CompletionToken) callconv(cc) Status;
const EFI_TCP4_POLL = *const fn (*Tcp4) callconv(cc) Status;

pub const Tcp4 = extern struct {
    _get_mode_data: EFI_TCP4_GET_MODE_DATA,
    _configure: EFI_TCP4_CONFIGURE,
    _routes: EFI_TCP4_ROUTES,
    _connect: EFI_TCP4_CONNECT,
    _accept: EFI_TCP4_ACCEPT,
    _transmit: EFI_TCP4_TRANSMIT,
    _receive: EFI_TCP4_RECEIVE,
    _close: EFI_TCP4_CLOSE,
    _cancel: EFI_TCP4_CANCEL,
    _poll: EFI_TCP4_POLL,

    pub const guid align(8) = Guid{
        .time_low = 0x65530BC7,
        .time_mid = 0xA359,
        .time_high_and_version = 0x410f,
        .clock_seq_high_and_reserved = 0xB0,
        .clock_seq_low = 0x10,
        .node = [_]u8{ 0x5A, 0xAD, 0xC7, 0xEC, 0x2B, 0x62 },
    };

    pub const ServiceBinding = uefi.protocol.ServiceBinding(.{
        .time_low = 0x00720665,
        .time_mid = 0x67EB,
        .time_high_and_version = 0x4a99,
        .clock_seq_high_and_reserved = 0xBA,
        .clock_seq_low = 0xF7,
        .node = [_]u8{ 0xD3, 0xC3, 0x3A, 0x1C, 0x7C, 0xC9 },
    });

    pub const ModeData = union(enum) {
        tcp4_state: State,
        tcp4_config: ConfigData,
        ip4_mode_data: Ip4.ModeData,
        mnp_config: ManagedNetwork.Config,
        snp_mode: SimpleNetwork.Mode,
    };
    pub const GetModeDataError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
    };
    pub fn getModeData(
        this: *const @This(),
        comptime info: std.meta.Tag(ModeData),
        buffer: *@FieldType(ModeData, @tagName(info)),
    ) GetModeDataError!void {
        switch (this._get_mode_data(
            this,
            if (info == .tcp4_state) buffer else null,
            if (info == .tcp4_config) buffer else null,
            if (info == .ip4_mode_data) buffer else null,
            if (info == .mnp_config) buffer else null,
            if (info == .snp_mode) buffer else null,
        )) {
            .success => {},
            .not_started => return Error.NotStarted,
            .invalid_parameter => return Error.InvalidParameter,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const ConfigureError = uefi.UnexpectedError || error{
        NoMapping,
        InvalidParameter,
        AccessDenied,
        DeviceError,
        Unsupported,
        OutOfResources,
    };
    pub fn configure(this: *@This(), config: ?*const ConfigData) ConfigureError!void {
        switch (this._configure(this, config)) {
            .success => {},
            .no_mapping => return Error.NoMapping,
            .invalid_parameter => return Error.InvalidParameter,
            .access_denied => return Error.AccessDenied,
            .device_error => return Error.DeviceError,
            .unsupported => return Error.Unsupported,
            .out_of_resources => return Error.OutOfResources,
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
        Unsupported,
    };
    pub fn routes(this: *@This(), delete_route: bool, subnet_address: Ipv4Address, subnet_mask: Ipv4Address, gateway: Ipv4Address) RoutesError!void {
        switch (this._routes(this, delete_route, &subnet_address, &subnet_mask, &gateway)) {
            .success => {},
            .not_started => return Error.NotStarted,
            .no_mapping => return Error.NoMapping,
            .invalid_parameter => return Error.InvalidParameter,
            .out_of_resources => return Error.OutOfResources,
            .not_found => return Error.NotFound,
            .access_denied => return Error.AccessDenied,
            .unsupported => return Error.Unsupported,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }
    pub fn addRoute(this: *@This(), subnet_address: Ipv4Address, subnet_mask: Ipv4Address, gateway: Ipv4Address) RoutesError!void {
        return this.routes(false, subnet_address, subnet_mask, gateway);
    }
    pub fn removeRoute(this: *@This(), subnet_address: Ipv4Address, subnet_mask: Ipv4Address, gateway: Ipv4Address) RoutesError!void {
        return this.routes(true, subnet_address, subnet_mask, gateway);
    }

    pub const ConnectError = uefi.UnexpectedError || error{
        NotStarted,
        AccessDenied,
        InvalidParameter,
        OutOfResources,
        DeviceError,
    };
    pub fn connect(this: *@This(), token: *ConnectionToken) ConnectError!void {
        switch (this._connect(this, token)) {
            .success => @panic("TODO: Tcp4.connect"),
            .not_started => return Error.NotStarted,
            .access_denied => return Error.AccessDenied,
            .invalid_parameter => return Error.InvalidParameter,
            .out_of_resources => return Error.OutOfResources,
            .device_error => return Error.DeviceError,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const AcceptError = uefi.UnexpectedError || error{
        NotStarted,
        AccessDenied,
        InvalidParameter,
        OutOfResources,
        DeviceError,
    };
    pub fn accept(this: *@This(), token: *ListenToken) AcceptError!void {
        switch (this._accept(this, token)) {
            .success => {},
            .not_started => return Error.NotStarted,
            .access_denied => return Error.AccessDenied,
            .invalid_parameter => return Error.InvalidParameter,
            .out_of_resources => return Error.OutOfResources,
            .device_error => return Error.DeviceError,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const TransmitError = uefi.UnexpectedError || error{
        NotStarted,
        NoMapping,
        InvalidParameter,
        AccessDenied,
        NotReady,
        OutOfResources,
        NetworkUnreachable,
        NoMedia,
    };
    pub fn transmit(this: *@This(), token: *IoToken) TransmitError!void {
        switch (this._transmit(this, token)) {
            .success => {},
            .not_started => return Error.NotStarted,
            .no_mapping => return Error.NoMapping,
            .invalid_parameter => return Error.InvalidParameter,
            .access_denied => return Error.AccessDenied,
            .not_ready => return Error.NotReady,
            .out_of_resources => return Error.OutOfResources,
            .network_unreachable => return Error.NetworkUnreachable,
            .no_media => return Error.NoMedia,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const ReceiveError = uefi.UnexpectedError || error{
        NotStarted,
        NoMapping,
        InvalidParameter,
        OutOfResources,
        DeviceError,
        AccessDenied,
        ConnectionFin,
        NotReady,
        NoMedia,
    };
    pub fn receive(this: *@This(), token: *IoToken) ReceiveError!void {
        switch (this._receive(this, token)) {
            .success => {},
            .not_started => return Error.NotStarted,
            .no_mapping => return Error.NoMapping,
            .invalid_parameter => return Error.InvalidParameter,
            .out_of_resources => return Error.OutOfResources,
            .device_error => return Error.DeviceError,
            .access_denied => return Error.AccessDenied,
            .connection_fin => return Error.ConnectionFin,
            .not_ready => return Error.NotReady,
            .no_media => return Error.NoMedia,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const CloseError = uefi.UnexpectedError || error{
        NotStarted,
        AccessDenied,
        InvalidParameter,
        OutOfResources,
        DeviceError,
    };
    pub fn close(this: *@This(), token: *CloseToken) CloseError!void {
        switch (this._close(this, token)) {
            .success => {},
            .not_started => return Error.NotStarted,
            .access_denied => return Error.AccessDenied,
            .invalid_parameter => return Error.InvalidParameter,
            .out_of_resources => return Error.OutOfResources,
            .device_error => return Error.DeviceError,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const CancelError = uefi.UnexpectedError || error{
        InvalidParameter,
        NotStarted,
        NoMapping,
        NotFound,
        Unsupported,
    };
    pub fn cancel(this: *@This(), token: *CompletionToken) CancelError!void {
        switch (this._cancel(this, token)) {
            .success => {},
            .invalid_parameter => return Error.InvalidParameter,
            .not_started => return Error.NotStarted,
            .no_mapping => return Error.NoMapping,
            .not_found => return Error.NotFound,
            .unsupported => return Error.Unsupported,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const PollError = uefi.UnexpectedError || error{
        InvalidParameter,
        DeviceError,
        NotReady,
        Timeout,
    };
    pub fn poll(this: *@This()) PollError!void {
        switch (this._poll(this)) {
            .success => {},
            .invalid_parameter => return Error.InvalidParameter,
            .device_error => return Error.DeviceError,
            .not_ready => return Error.NotReady,
            .timeout => return Error.Timeout,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const State = enum(u32) {
        Closed = 0,
        Listen = 1,
        SynSent = 2,
        SynReceived = 3,
        Established = 4,
        FinWait1 = 5,
        FinWait2 = 6,
        Closing = 7,
        TimeWait = 8,
        CloseWait = 9,
        LastAck = 10,
    };

    pub const ConfigData = extern struct {
        type_of_service: u8,
        time_to_live: u8,
        access_point: AccessPoint,
        control_option: Option,
    };

    pub const Option = extern struct {
        receive_buffer_size: u32,
        send_buffer_size: u32,
        max_syn_back_log: u32,
        connection_timeout: u32,
        data_retries: u32,
        fin_timeout: u32,
        time_wait_timeout: u32,
        keep_alive_probes: u32,
        keep_alive_time: u32,
        keep_alive_interval: u32,
        enable_nagle: bool,
        enable_time_stamp: bool,
        enable_window_scaling: bool,
        enable_selective_ack: bool,
        enable_path_mtu_discovery: bool,
    };

    pub const AccessPoint = extern struct {
        use_default_address: bool,
        station_address: Ipv4Address,
        subnet_mask: Ipv4Address,
        station_port: u16,
        remote_address: Ipv4Address,
        remote_port: u16,
        active_flag: bool,
    };

    pub const CompletionToken = extern struct {
        event: ?Event,
        status: Status,
    };

    pub const ConnectionToken = extern struct {
        token: CompletionToken,

        pub const Error = uefi.UnexpectedError || error{
            ConnectionReset,
            ConnectionRefused,
            Aborted,
            Timeout,
            NetworkUnreachable,
            HostUnreachable,
            ProtocolUnreachable,
            PortUnreachable,
            IcmpError,
            DeviceError,
        };
    };

    pub const ListenToken = extern struct {
        token: CompletionToken,
        new_child: uefi.Handle,

        pub const Error = uefi.UnexpectedError || error{
            ConnectionReset,
            Aborted,
        };
    };

    pub const IoToken = extern struct {
        completion: CompletionToken,
        packet: extern union {
            rx_data: ?*ReceiveData,
            tx_data: ?*TransmitData,
        },

        pub const Error = uefi.UnexpectedError || error{
            ConnectionFin,
            ConnectionReset,
            Aborted,
            Timeout,
            NetworkUnreachable,
            HostUnreachable,
            ProtocoloUnreachable,
            PortUnreachable,
            IcmpError,
            DeviceError,
            NoMedia,
        };
    };

    pub const CloseToken = extern struct {
        completion: CompletionToken,
        abort_on_close: bool,

        pub const Error = uefi.UnexpectedError || error{
            Aborted,
        };
    };

    pub const ReceiveData = extern struct {
        urgent_flag: bool,
        data_length: u32,
        fragment_count: u32,
        fragment_table: [1]FragmentData,
    };

    pub const FragmentData = extern struct {
        fragment_length: u32,
        fragment_buffer: *anyopaque,
    };

    pub const TransmitData = extern struct {
        push: bool,
        urgent: bool,
        data_length: u32,
        fragment_count: u32,
        fragment_table: [1]FragmentData,
    };
};

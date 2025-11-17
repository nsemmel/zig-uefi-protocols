const std = @import("std");
const uefi = std.os.uefi;
const Event = uefi.Event;
const Guid = uefi.Guid;
const Status = uefi.Status;
const cc = uefi.cc;
const Error = Status.Error;
const Ipv4Address = uefi.Ipv4Address;
const Ipv6Address = uefi.Ipv6Address;

const EFI_HTTP_GET_MODE_DATA = *const fn (*Http, *Http.ConfigData) callconv(cc) Status;
const EFI_HTTP_CONFIGURE = *const fn (*Http, ?*Http.ConfigData) callconv(cc) Status;
const EFI_HTTP_REQUEST = *const fn (*Http, *Http.Token) callconv(cc) Status;
const EFI_HTTP_CANCEL = *const fn (*Http, *Http.Token) callconv(cc) Status;
const EFI_HTTP_RESPONSE = *const fn (*Http, *Http.Token) callconv(cc) Status;
const EFI_HTTP_POLL = *const fn (*Http) callconv(cc) Status;

pub const Http = extern struct {
    _get_mode_data: EFI_HTTP_GET_MODE_DATA,
    _configure: EFI_HTTP_CONFIGURE,
    _request: EFI_HTTP_REQUEST,
    _cancel: EFI_HTTP_CANCEL,
    _response: EFI_HTTP_RESPONSE,
    _poll: EFI_HTTP_POLL,

    pub const guid align(8) = Guid{
        .time_low = 0x7A59B29B,
        .time_mid = 0x910B,
        .time_high_and_version = 0x4171,
        .clock_seq_high_and_reserved = 0x82,
        .clock_seq_low = 0x42,
        .node = [_]u8{ 0xA8, 0x5A, 0x0D, 0xF2, 0x5B, 0x5B },
    };

    pub const ServiceBinding = uefi.protocol.ServiceBinding(.{
        .time_low = 0xbdc8e6af,
        .time_mid = 0xd9bc,
        .time_high_and_version = 0x4379,
        .clock_seq_high_and_reserved = 0xa7,
        .clock_seq_low = 0x2a,
        .node = [_]u8{ 0xe0, 0xc4, 0xe7, 0x5d, 0xae, 0x1c },
    });

    pub const GetModeDataError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
    };
    pub fn getModeData(this: *@This()) GetModeDataError!ConfigData {
        var config = std.mem.zeroes(ConfigData);
        switch (this._get_mode_data(this, &config)) {
            .success => return config,
            .not_started => return Error.NotStarted,
            .invalid_parameter => return Error.InvalidParameter,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const ConfigureError = uefi.UnexpectedError || error{
        InvalidParameter,
        AlreadyStarted,
        DeviceError,
        OutOfResources,
        Unsupported,
    };
    pub fn configure(this: *@This(), config: ?*ConfigData) ConfigureError!void {
        switch (this._configure(this, config)) {
            .success => {},
            .invalid_parameter => return Error.InvalidParameter,
            .already_started => return Error.AlreadyStarted,
            .device_error => return Error.DeviceError,
            .out_of_resources => return Error.OutOfResources,
            .unsupported => return Error.Unsupported,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const RequestError = uefi.UnexpectedError || error{
        NotStarted,
        DeviceError,
        Timeout,
        InvalidParameter,
        OutOfResources,
        Unsupported,
    };
    pub fn request(this: *@This(), token: *Token) RequestError!void {
        switch (this._request(this, token)) {
            .success => {},
            .not_started => return Error.NotStarted,
            .device_error => return Error.DeviceError,
            .timeout => return Error.Timeout,
            .invalid_parameter => return Error.InvalidParameter,
            .out_of_resources => return Error.OutOfResources,
            .unsupported => return Error.Unsupported,
            else => |status| {
                status.err() catch |e| {
                    std.log.err("Request Error: {s}", .{@errorName(e)});
                    return uefi.unexpectedStatus(status);
                };
            },
        }
    }

    pub const CancelError = uefi.UnexpectedError || error{
        InvalidParameter,
        NotStarted,
        NotFound,
        Unsupported,
    };
    pub fn cancel(this: *@This(), token: *Token) CancelError!void {
        switch (this._cancel(this, token)) {
            .success => {},
            .invalid_parameter => return Error.InvalidParameter,
            .not_started => return Error.NotStarted,
            .not_found => return Error.NotFound,
            .unsupported => return Error.Unsupported,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const ResponseError = uefi.UnexpectedError || error{
        NotStarted,
        InvalidParameter,
        OutOfResources,
        AccessDenied,
    };
    pub fn response(this: *@This(), token: *Token) ResponseError!void {
        switch (this._response(this, token)) {
            .success => {},
            .not_started => return Error.NotStarted,
            .invalid_parameter => return Error.InvalidParameter,
            .out_of_resources => return Error.OutOfResources,
            .access_denied => return Error.AccessDenied,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const PollError = uefi.UnexpectedError || error{
        InvalidParameter,
        DeviceError,
        NotReady,
        NotStarted,
    };
    pub fn poll(this: *@This()) PollError!void {
        switch (this._poll(this)) {
            .success => {},
            .invalid_parameter => return Error.InvalidParameter,
            .device_error => return Error.DeviceError,
            .not_ready => return Error.NotReady,
            .not_started => return Error.NotStarted,
            else => |status| return uefi.unexpectedStatus(status),
        }
    }

    pub const ConfigData = extern struct {
        http_version: Version,
        time_out_millisec: u32,
        local_address_is_ipv6: bool,
        node: extern union {
            ipv4: *AccessPoint.V4,
            ipv6: *AccessPoint.V6,
        },
    };

    pub const Version = enum(u32) {
        v10,
        v11,
        unsupported,
    };

    pub const AccessPoint = struct {
        pub const V4 = extern struct {
            use_default_address: bool,
            local_address: Ipv4Address,
            local_subnet: Ipv4Address,
            local_port: u16,
        };
        pub const V6 = extern struct {
            local_address: Ipv6Address,
            local_port: u16,
        };
    };

    pub const Token = extern struct {
        event: ?Event,
        status: Status,
        message: *Message,
    };
    pub const Message = extern struct {
        data: extern union {
            request: *RequestData,
            response: *ResponseData,
        },
        header_count: u64,
        headers: ?[*]Header,
        body_length: u64,
        body: ?[*]u8,
    };

    pub const Header = extern struct {
        field_name: [*:0]u8,
        field_value: [*:0]u8,
    };

    pub const RequestData = extern struct {
        method: Method,
        url: [*:0]const u16,
    };

    pub const Method = enum(u32) {
        get,
        post,
        patch,
        options,
        connect,
        head,
        put,
        delete,
        trace,
    };

    pub const ResponseData = extern struct {
        status_code: StatusCode,
    };

    pub const StatusCode = enum(u32) {
        UNSUPPORTED_STATUS = 0,
        _100_CONTINUE,
        _101_SWITCHING_PROTOCOLS,
        _200_OK,
        _201_CREATED,
        _202_ACCEPTED,
        _203_NON_AUTHORITATIVE_INFORMATION,
        _204_NO_CONTENT,
        _205_RESET_CONTENT,
        _206_PARTIAL_CONTENT,
        _300_MULTIPLE_CHOICES,
        _301_MOVED_PERMANENTLY,
        _302_FOUND,
        _303_SEE_OTHER,
        _304_NOT_MODIFIED,
        _305_USE_PROXY,
        _307_TEMPORARY_REDIRECT,
        _400_BAD_REQUEST,
        _401_UNAUTHORIZED,
        _402_PAYMENT_REQUIRED,
        _403_FORBIDDEN,
        _404_NOT_FOUND,
        _405_METHOD_NOT_ALLOWED,
        _406_NOT_ACCEPTABLE,
        _407_PROXY_AUTHENTICATION_REQUIRED,
        _408_REQUEST_TIME_OUT,
        _409_CONFLICT,
        _410_GONE,
        _411_LENGTH_REQUIRED,
        _412_PRECONDITION_FAILED,
        _413_REQUEST_ENTITY_TOO_LARGE,
        _414_REQUEST_URI_TOO_LARGE,
        _415_UNSUPPORTED_MEDIA_TYPE,
        _416_REQUESTED_RANGE_NOT_SATISFIED,
        _417_EXPECTATION_FAILED,
        _500_INTERNAL_SERVER_ERROR,
        _501_NOT_IMPLEMENTED,
        _502_BAD_GATEWAY,
        _503_SERVICE_UNAVAILABLE,
        _504_GATEWAY_TIME_OUT,
        _505_HTTP_VERSION_NOT_SUPPORTED,
        _308_PERMANENT_REDIRECT,
    };
};

pub const Dhcp4 = @import("protocol/dhcp4.zig").Dhcp4;
pub const Ip4 = @import("protocol/ip4.zig").Ip4;
pub const Tcp4 = @import("protocol/tcp4.zig").Tcp4;
pub const Http = @import("protocol/http.zig").Http;
pub const Pxe = @import("protocol/pxe.zig").Pxe;

test {
    _ = Dhcp4;
    _ = Ip4;
    _ = Tcp4;
    _ = Http;
    _ = Pxe;
}

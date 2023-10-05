// Simple Perlin noise library for Zig
// Ported from <https://rosettacode.org/wiki/Perlin_noise#Go>

const std = @import("std");
const math = std.math;
const expect = std.testing.expect;

pub fn Vec(comptime T: type) type {
    return struct {
        x: T,
        y: T = 0,
        z: T = 0,
    };
}

pub fn noise(comptime T: type, opts: Vec(T)) T {
    return noise3D(
        T,

        opts.x,
        opts.y,
        opts.z,
    );
}

fn noise3D(comptime T: type, x: T, y: T, z: T) T {
    // Disable runtime safety to allow the permutation table values to wrap
    @setRuntimeSafety(false);

    // Truncate float to u8 for use as indicies into the permutation table
    const x_i: u8 = @intCast(@as(
        isize,
        @intFromFloat(@floor(x)),
    ) & 255);

    const y_i: u8 = @intCast(@as(
        isize,
        @intFromFloat(@floor(y)),
    ) & 255);

    const z_i: u8 = @intCast(@as(
        isize,
        @intFromFloat(@floor(z)),
    ) & 255);

    const x_r = x - @floor(x);
    const y_r = y - @floor(y);
    const z_r = z - @floor(z);

    const u = fade(T, x_r);
    const v = fade(T, y_r);
    const w = fade(T, z_r);

    const a = permutation[x_i] +% y_i;
    const aa = permutation[a] +% z_i;
    const ab = permutation[a + 1] +% z_i;
    const b = permutation[x_i + 1] +% y_i;
    const ba = permutation[b] +% z_i;
    const bb = permutation[b + 1] +% z_i;

    // Add blended results from all 8 corners of the cube
    return math.lerp(
        math.lerp(
            math.lerp(
                grad3D(T, permutation[aa], x_r, y_r, z_r),
                grad3D(T, permutation[ba], x_r - 1, y_r, z_r),
                u,
            ),
            math.lerp(
                grad3D(T, permutation[ab], x_r, y_r - 1, z_r),
                grad3D(T, permutation[bb], x_r - 1, y_r - 1, z_r),
                u,
            ),
            v,
        ),
        math.lerp(
            math.lerp(
                grad3D(T, permutation[aa + 1], x_r, y_r, z_r - 1),
                grad3D(T, permutation[ba + 1], x_r - 1, y_r, z_r - 1),
                u,
            ),
            math.lerp(
                grad3D(T, permutation[ab + 1], x_r, y_r - 1, z_r - 1),
                grad3D(T, permutation[bb + 1], x_r - 1, y_r - 1, z_r - 1),
                u,
            ),
            v,
        ),
        w,
    );
}

fn grad3D(comptime T: type, h: u8, x: T, y: T, z: T) T {
    return switch (@as(
        u4,
        @truncate(h),
    )) {
        0, 12 => x + y,
        1, 14 => y - x,
        2 => x - y,
        3 => -x - y,
        4 => x + z,
        5 => z - x,
        6 => x - z,
        7 => -x - z,
        8 => y + z,
        9, 13 => z - y,
        10 => y - z,
        11, 15 => -y - z,
    };
}

fn fade(comptime T: type, t: T) T {
    return t * t * t * (t * (6 * t - 15) + 10);
}

// Permutation table from the original Java implementation of Perlin noise
// TODO: Allow this to be overridden
pub const permutation = [256]u8{
    151, 160, 137, 91,  90,  15,  131, 13,  201, 95,  96,  53,  194, 233, 7,   225,
    140, 36,  103, 30,  69,  142, 8,   99,  37,  240, 21,  10,  23,  190, 6,   148,
    247, 120, 234, 75,  0,   26,  197, 62,  94,  252, 219, 203, 117, 35,  11,  32,
    57,  177, 33,  88,  237, 149, 56,  87,  174, 20,  125, 136, 171, 168, 68,  175,
    74,  165, 71,  134, 139, 48,  27,  166, 77,  146, 158, 231, 83,  111, 229, 122,
    60,  211, 133, 230, 220, 105, 92,  41,  55,  46,  245, 40,  244, 102, 143, 54,
    65,  25,  63,  161, 1,   216, 80,  73,  209, 76,  132, 187, 208, 89,  18,  169,
    200, 196, 135, 130, 116, 188, 159, 86,  164, 100, 109, 198, 173, 186, 3,   64,
    52,  217, 226, 250, 124, 123, 5,   202, 38,  147, 118, 126, 255, 82,  85,  212,
    207, 206, 59,  227, 47,  16,  58,  17,  182, 189, 28,  42,  223, 183, 170, 213,
    119, 248, 152, 2,   44,  154, 163, 70,  221, 153, 101, 155, 167, 43,  172, 9,
    129, 22,  39,  253, 19,  98,  108, 110, 79,  113, 224, 232, 178, 185, 112, 104,
    218, 246, 97,  228, 251, 34,  242, 193, 238, 210, 144, 12,  191, 179, 162, 241,
    81,  51,  145, 235, 249, 14,  239, 107, 49,  192, 214, 31,  181, 199, 106, 157,
    184, 84,  204, 176, 115, 121, 50,  45,  127, 4,   150, 254, 138, 236, 205, 93,
    222, 114, 67,  29,  24,  72,  243, 141, 128, 195, 78,  66,  215, 61,  156, 180,
};

test "noise" {
    try expect(noise(f64, .{
        .x = 3.14,
        .y = 42,
        .z = 7,
    }) == 0.13691995878400012);

    try expect(noise(f64, .{
        .x = -4.20,
        .y = 10,
        .z = 6,
    }) == 0.14208000000000043);
}

test "fade" {
    try expect(fade(f64, 0.75) == 0.896484375);
}

test "grad" {
    try expect(grad3D(f64, 69, 3.14, 42, 7) == 3.86);
}

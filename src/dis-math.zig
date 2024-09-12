//! Math type in the Dis language.

const std = @import("std");

/// Dis data type factory.
pub const Data = uint;

/// Dis data type creator.
/// Returns lots of useful functions and members.
pub fn uint(comptime UintT: type, base_: UintT, digit_: UintT) type {
    // Domain things
    if ( @typeInfo(UintT) != .Int ) @compileError("UintT must be unsigned integer");
    if ( std.math.minInt(UintT) < 0 ) @compileError("UintT must be unsigned integer");
    const INT_END_ = std.math.powi(UintT, base_, digit_) catch @compileError("END overflowed");

    return struct {
	const Self = @This();
	pub const base = base_;
	pub const digit = digit_;
	pub const Type = UintT;

        pub const INT_END = INT_END_;
	pub const END = INT_END;

	/// Valid integer shall be 0<=n<=INT_MAX.
	pub const INT_MAX = INT_END_-1;
	pub const MAX = INT_MAX;

	/// Idk if necessary.
	pub fn is_valid_value(x: UintT) bool {
	    return 0 <= x and x <= INT_MAX;
	}

	/// Perform a right-rotate for one digit.
	pub fn rot(x: UintT) UintT {
	    const least_digit = x % Self.base;
	    const head_digits = x / Self.base;
	    const left_shift_mult = Self.INT_END / Self.base;
	    return head_digits + least_digit * left_shift_mult;
	}

        /// For each digit, do subtraction without carry.
	pub fn opr(x: UintT, y: UintT) UintT {
	    if ( x == 0 and y == 0 ) return 0;
	    return base * opr(x / base, y / base) + try opr_(x % base, y % base);
	}

	/// x, y is digit. Digit-subtraction.
	inline fn opr_(x: UintT, y: UintT) !UintT {
	    std.debug.assert(x < base);
	    std.debug.assert(y < base);
	    return (base + x - y) % base;
	}

	pub fn incr(x: UintT) UintT {
	    return (x + 1) % INT_END;
	}

	pub fn increment(x: UintT, y: UintT) UintT {
	    // XXX: efficient algorithm?
	    if ( y == 0 ) return x;
	    return increment(incr(x), y-1);
	}
    };
}

/// Official Dis specification constants.
pub const DEFAULT_BASE = 3;
pub const DEFAULT_DIGIT = 10;
pub const DEFAULT_UINT_T = u16;
pub const DefaultData = uint(DEFAULT_UINT_T, DEFAULT_BASE, DEFAULT_DIGIT);

test DefaultData {
    try std.testing.expect(DefaultData.base == 3);
    try std.testing.expect(DefaultData.digit == 10);
    try std.testing.expect(DefaultData.INT_MAX == 59048);
    try std.testing.expect(DefaultData.INT_END == 59049);
}

test "DefaultData.rot" {
    const rot = DefaultData.rot;

    try std.testing.expect(rot(1) == 19683);
    try std.testing.expect(rot(19683) == 19683/3);
    try std.testing.expect(rot(2) == 19683 * 2);
    try std.testing.expect(rot(4) == 19683 + 1);
}

test "DefaultData.opr" {
    const opr = DefaultData.opr;

    try std.testing.expect(opr(0, 0) == 0);
    try std.testing.expect(opr(0, 1) == 2);
    try std.testing.expect(opr(0, 2) == 1);
    try std.testing.expect(opr(1, 0) == 1);
    try std.testing.expect(opr(1, 1) == 0);
    try std.testing.expect(opr(1, 2) == 2);
    try std.testing.expect(opr(2, 0) == 2);
    try std.testing.expect(opr(2, 1) == 1);
    try std.testing.expect(opr(2, 2) == 0);

    try std.testing.expect(
	opr(1 * 3 + 1 * 1,
	    2 * 3 + 2 * 1)
	==  2 * 3 + 2 * 1);

    {
	const x = 2 * 81 + 1 * 27 + 0 * 9 + 1 * 3 + 2 * 1;
	const y = 0 * 81 + 1 * 27 + 2 * 9 + 2 * 3 + 1 * 1;
	const z = 2 * 81 + 0 * 27 + 1 * 9 + 2 * 3 + 1 * 1;
	const my_result = opr(x, y);
	try std.testing.expect(my_result == z);
    }
}

test "DefaultData.incr" {
    try std.testing.expect(DefaultData.incr(0) == 1);
    try std.testing.expect(DefaultData.incr(59047) == 59048);
    try std.testing.expect(DefaultData.incr(59048) == 0);
}

test "DefaultData.increment" {
    try std.testing.expect(DefaultData.increment(59048, 59048) == 59047);
    try std.testing.expect(DefaultData.increment(2323, 65535) == (2323 + 65535 % 59049));
}

test "Custom data type: base-7 6-digit" {
    const Math7_6 = uint(u17, 7, 6);
    const expect = std.testing.expect;

    try expect(Math7_6.END == 117_649);

    try expect(Math7_6.rot(5 * 7 + 2) == 2 * try std.math.powi(u17, 7, 5) + 5);
    try expect(Math7_6.opr(
	    5 * 49*7 + 3 * 49 + 1 * 7 + 6 * 1,
	    6 * 49*7 + 0 * 49 + 1 * 7 + 2 * 1)
	==  6 * 49*7 + 3 * 49 + 0 * 7 + 4 * 1);
}

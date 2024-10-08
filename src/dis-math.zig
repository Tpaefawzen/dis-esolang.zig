//! Math type in the Dis language.
//! Or a data type in the Dis language.

const std = @import("std");

/// A namespace of arithmetic operators for Dis data type.
/// Specified base and specified digits of unsigned integers.
pub fn Math(
	/// Unsigned integer.
	comptime T_: type,
	/// >= 2
	comptime base_: T_,
	/// >= 1
	comptime digit_: T_
) type {
    // Domain things
    if ( @typeInfo(T_) != .Int ) @compileError("T_ must be unsigned integer");
    if ( std.math.minInt(T_) < 0 ) @compileError("T_ must be unsigned integer");
    if ( base_ <= 1 ) @compileError("base_ must be >=2");
    if ( digit_ == 0 ) @compileError("digit_ must be >=1");

    return struct {
	pub const base: T = base_;
	pub const digit: T = digit_;
	pub const T: type = T_;

	fn getOneBitWider(comptime T0: type) type {
	    const bits = @typeInfo(T0).Int.bits + 1;
	    return @Type(std.builtin.Type {
		.Int = .{ .signedness = .unsigned, .bits = bits, },
	    });
	}

	const end0: ?T = std.math.powi(T, base, digit) catch null;

	/// Type of END.
	/// E.g. Math(u4, 2, 4) => T == u4 && END_T == u5.
	/// E.g. Math(u5, 2, 4) => T == u5 && END_T == u5
	pub const END_T: type = if ( end0 != null ) T else getOneBitWider(T);

	/// std.math.powi(T, base, digit), which MAX + 1 == END.
	/// E.g. powi(u16, 3, 10) == 59049.
	pub const END: END_T = if ( end0 ) |v| v
		else std.math.powi(END_T, base, digit)
		catch @compileError("END overflown; try with larger unsigned type T_");

	/// Maximum value that can be represented in given base and given digits.
	pub const MAX: T = END - 1;

	// Compile-time test.
	comptime {
	    _ = END;
	    _ = MAX;
	}

	/// In specified base and specified digits.
	pub const is_representable = is_valid_value;
	pub fn is_valid_value(x: T) bool {
	    return x <= MAX;
	}

	/// Rotate a value to right by one digit.
	/// E.g. 00000_00001t to 10000_00000t.
	pub fn rot(x: T) T {
	    const least_digit = x % base;
	    const head_digits = x / base;
	    const left_shift_mult = END / base;
	    return @truncate(head_digits + least_digit * left_shift_mult);
	}

        /// For each digit, do subtraction without carry.
        /// Wraps around underflows.
	pub fn opr(x: T, y: T) T {
	    if ( x == 0 and y == 0 ) return 0;
	    return base * opr(x / base, y / base) + opr_(x % base, y % base);
	}

	/// x, y is digit. Digit-subtraction.
	inline fn opr_(x: T, y: T) T {
	    if ( x >= base ) unreachable;
	    if ( y >= base ) unreachable;
	    return (base + x - y) % base;
	}

	/// Add one to x. Overwrapped.
	pub fn incr(x: T) T {
	    if ( T != END_T ) return x+%1; // base is 2,4,8,16,32,...
	    return (x+1)%END;
	}

	comptime {
	    if ( incr(0) != 1 ) unreachable;
	    // @compileLog(T, base, digit, END_T, MAX, incr(MAX));
	    if ( incr(MAX) != 0 ) @compileError("incr(MAX)!=0????");
	}

	/// Add y to x. Overwrapped.
	pub fn increment(x: T, y: T) T {
	    if ( T != END_T ) return x+%y;
	    const x0 = x%END;
	    const y0 = y%END;
	    const z = @addWithOverflow(x0, y0);
	    if ( z[1] == 0 ) return @truncate(z[0]%END);
	    return @truncate((x-(END-y))%END);
	}

	comptime {
	    if ( increment(0, 0) != 0 ) unreachable;
	    if ( increment(1, 0) != 1 ) unreachable;
	    if ( increment(0, 1) != 1 ) unreachable;
	    if ( increment(0, MAX) != MAX ) unreachable;
	    if ( increment(MAX, 0) != MAX ) unreachable;
	    if ( increment(MAX, MAX) != MAX-1 ) unreachable;
	    if ( increment(1, MAX) != 0 ) unreachable;
	    if ( increment(MAX, 1) != 0 ) unreachable;

	    const x = std.math.maxInt(T);
	    const z = increment(x, x);
	    _ = z;
	    const z2 = increment(MAX, MAX);
	    _ = z2;
	    // @compileLog(T, base, digit, END_T, MAX, x, z);
	    // @compileLog(T, base, digit, END_T, MAX, increment(x, MAX));
	    // @compileLog(T, base, digit, END_T, MAX, increment(MAX, x));
	    // @compileLog(T, base, digit, END_T, MAX, increment(MAX, MAX));
	}

	/// Subtract 1 from x. Overwrapped.
	pub fn decr(x: T) T {
	    if ( T != END_T ) return x-%1;
	    return if ( x == 0 ) MAX else (x-1)%END;
	}

	comptime {
	    if ( decr(0) != MAX ) unreachable;
	    if ( decr(MAX) != MAX-1 ) unreachable;
	}

	/// Subtract y from x. Overwrapped.
	pub fn decrement(x: T, y: T) T {
	    if ( T != END_T ) return x-%y;
	    if ( x >= y ) return (x-y)%END;
	    return (x+(END-y%END))%END;
	}

	comptime {
	    if ( decrement(0, 0) != 0 ) unreachable;
	    if ( decrement(1, 0) != 1 ) unreachable;
	    if ( decrement(0, 1) != MAX ) unreachable;
	    if ( decrement(MAX, 0) != MAX ) unreachable;
	    if ( decrement(0, MAX) != 1 ) unreachable;
	    if ( decrement(MAX, MAX) != 0 ) unreachable;
	}
    };
}

/// Official Dis specification constants.
pub const DefaultMath = Math(u16, 3, 10);

test DefaultMath {
    try std.testing.expect(DefaultMath.base == 3);
    try std.testing.expect(DefaultMath.digit == 10);
    try std.testing.expect(DefaultMath.MAX == 59048);
    try std.testing.expect(DefaultMath.END == 59049);
}

test "DefaultMath.rot" {
    const rot = DefaultMath.rot;

    try std.testing.expect(rot(1) == 19683);
    try std.testing.expect(rot(19683) == 19683/3);
    try std.testing.expect(rot(2) == 19683 * 2);
    try std.testing.expect(rot(4) == 19683 + 1);
}

test "DefaultMath.opr" {
    const opr = DefaultMath.opr;

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

test "DefaultMath.incr" {
    try std.testing.expect(DefaultMath.incr(0) == 1);
    try std.testing.expect(DefaultMath.incr(59047) == 59048);
    try std.testing.expect(DefaultMath.incr(59048) == 0);
}

test "DefaultMath.increment" {
    try std.testing.expect(DefaultMath.increment(59048, 59048) == 59047);
    try std.testing.expect(DefaultMath.increment(2323, 65535) == (2323 + 65535 % 59049));
}

test "Custom math type: base-7 6-digit" {
    const Math7_6 = Math(u17, 7, 6);
    const expect = std.testing.expect;

    try expect(Math7_6.END == 117_649);

    try expect(Math7_6.rot(5 * 7 + 2) == 2 * try std.math.powi(u17, 7, 5) + 5);
    try expect(Math7_6.opr(
	    5 * 49*7 + 3 * 49 + 1 * 7 + 6 * 1,
	    6 * 49*7 + 0 * 49 + 1 * 7 + 2 * 1)
	==  6 * 49*7 + 3 * 49 + 0 * 7 + 4 * 1);
}

test "Math(u16, 2, 16)" {
    const M = Math(u16, 2, 16);
    const expect = std.testing.expect;
    try expect(M.T == u16);
    try expect(M.MAX == 65535);
    try expect(M.END == 65536);
}

test "Math(T, 4, 2); powi(4,2) == 16; at least u5" {
    // _ = Math(u3, 4, 2); // Compile-error
    _ = Math(u4, 4, 2); // Ok
    _ = Math(u5, 4, 2); // Obviously Ok
}

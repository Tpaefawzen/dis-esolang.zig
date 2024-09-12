//! The Dis language virtual machine.

const std = @import("std");

const data = @import("dis-math.zig");

/// Make a virtual machine that works on specified Data type.
pub fn Vm(comptime Data: anytype) type {
    const T: type = Data.T;
    return struct {
	/// Accumulator.
	a: T = 0,

	/// Program counter.
	c: T = 0,

	/// Data pointer.
	d: T = 0,

	/// Program memory that shares both code and data.
	mem: [Data.END]T = [_]T{0} ** Data.END,

	/// Running status.
	status: VmStatus = .running,

	// /// Reader for standard input. Byte-oriented.
	// reader: std.io.GenericReader,

	// /// Writer for standard output. Byte-oriented.
	// writer: std.io.GenericWriter,

	/// Increment C and D; the Dis machine increments both registers C, D
	/// after each step.
	pub fn incrementCAndD(self: @This(), y: Data.T) void {
	    const increment = Data.increment;
	    self.c = increment(self.c, y);
	    self.d = increment(self.d, y);
	}

	/// Fetch a command.
	fn fetchCommand(self: @This()) ?(*fn(@This()) void) {
	    return switch ( self.mem[self.c] ) {
	    33	=> halt,	// !
	    42	=> load,	// *
	    62	=> rot,		// >
	    94	=> jmp,		// ^
	    95	=> null,	// _
	    123	=> write,	// {
	    124	=> opr,		// |
	    125 => read,	// }
	    else => null,
	    };
	}

	fn halt(self: @This()) void {
	    self.status = .haltByHaltCommand;
	}

	fn load(self: @This()) void {
	    self.d = self.mem[self.d];
	}

	fn rot(self: @This()) void {
	    const x = self.mem[self.d];
	    const z = Data.rot(x);
	    self.a = z;
	    self.mem[self.d] = z;
	}

	fn jmp(self: @This()) void {
	    self.c = self.mem[self.d];
	}

	fn write(self: @This()) void {
	    const a = self.a;
	    if ( a == Data.MAX ) {
		self.status = .haltByEofWrite;
		return;
	    }

	    self.writer.writeByte(@as(u8, a)) catch |err| {
		self.status = .writeError(err);
	    };
	}

	fn opr(self: @This()) void {
	    const z = Data.opr(self.a, self.mem[self.d]);
	    self.a = z;
	    self.mem[self.d] = z;
	}

	/// Assumes ReadError-s other than EndOfStream are
	/// equivalent to EndOfStream.
	fn read(self: @This()) void {
	    self.a = self.reader.readByte() catch |err| {
		if ( err != error.EndOfStream ) {
		    self.status = .readError(err);
		}
		self.a = Data.MAX;
	    };
	}
    };
}

pub const VmStatus = union(enum) {
    running,
    haltByEofWrite,
    haltByHaltCommand,
    noIoInfiniteLoop,
    writeError: error{},
    readError: error{},
};

/// Officially defined Dis machine.
pub const DefaultVm = Vm(data.DefaultData);

test DefaultVm {
    try std.testing.expect(@hasField(DefaultVm, "a"));
    try std.testing.expect(@hasField(DefaultVm, "mem"));

    const vm = DefaultVm{};
    try std.testing.expect(vm.mem[429] == 0);
}

clean:
	rm -rf .zig-cache zig-out

run:
	zig build run

lib:
	zig build lib

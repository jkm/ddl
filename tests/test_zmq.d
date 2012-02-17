import ddl;

version(ddl) mixin declareLibraryAndAlias!("ZeroMQ.zmq", "zmq");
else import zmq;

unittest
{
	import std.stdio;

	version(ddl)
	{
		assert(!zmq.isLoaded);
		zmq = loadLibrary!(ZeroMQ.zmq)();
		assert(zmq.loadedFunctions == ["zmq_version", "zmq_errno",
				"zmq_strerror", "zmq_msg_init", "zmq_msg_init_size",
				"zmq_msg_init_data", "zmq_msg_close", "zmq_msg_move",
				"zmq_msg_copy", "zmq_msg_data", "zmq_msg_size", "zmq_init",
				"zmq_term", "zmq_socket", "zmq_close", "zmq_setsockopt",
				"zmq_getsockopt", "zmq_bind", "zmq_connect", "zmq_send", "zmq_recv",
				"zmq_poll", "zmq_device"]);
	}

	// usage as usual
	int major, minor, patch;
	zmq_version(&major, &minor, &patch);

	assert(ZMQ_VERSION_MAJOR == major);
	assert(ZMQ_VERSION_MINOR == minor);
	assert(ZMQ_VERSION_PATCH == patch);
}

version(unittest) void main() {}

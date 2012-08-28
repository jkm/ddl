// Copyright Jens K. Mueller
/**
 * The D(eimos) Dynamic Loader portably loads C libraries at run time and binds
 * extern(C) function declared in a module given its module name at compile
 * time. These functions can then be loaded at run time.
 *
 * Loading a library at run time is useful for graceful degradation. First check
 * whether a library exists and then use the provided functionality. Otherwise
 * provide only a basic set of features.
 *
 * For a module name given at compile time its extern(C) functions are loadable
 * at run time. Writing a module containing extern(C) declared functions is
 * easy. Even better there are already modules for the purpose of calling C
 * libraries from within D provided by $(LINK_TEXT https://github.com/D-Programming-Deimos, Deimos).
 * This set of modules is steadily growing and it is easy to add a new module
 * by converting a C library's header file(s) to D.
 *
 * $(B Note, that loading overloaded functions is not possible.) Only the
 * function name is used for loading. This may give surprising results when
 * overloaded functions are loaded.
 *
 * $(B This module is written such that is should work on Windows but has been
 * only compiled and tested on Linux. Please report any issue while trying it
 * out.)
 *
 * Bugs: $(ISSUES)
 * License: $(LICENSE)
 * Version: $(VERSION) ($(B alpha release))
 * Date: $(DATE)
 * $(BR)
 * $(BR)
 * $(BR)
 * Examples:
 *
 * The canonical Hello World loading the C library at run time and calling its
 * printf function.
 *
 * ---
 * unittest
 * {
 *     import ddl;
 *     import std.string : toStringz;
 *     import core.stdc.stdio; // import the module as usual
 *
 *     // load the library C to resolve extern(C) functions declared
 *     // in core.std.stdio, but load no functions yet
 *     auto stdio = loadLibrary!(core.stdc.stdio)(libraryFilename("c")~".6", false);
 *
 *     // not loaded yet
 *     assert(stdio.printf == null);
 *
 *     // load the function printf
 *     stdio.loadFunction!("printf")();
 *     // ... and call it
 *     stdio.printf(toStringz("Hello World.\n"));
 * }
 * ---
 *
 * To give another example we use $(LINK_TEXT http://www.zeromq.org/, ZeroMQ), a
 * asynchronous message library. $(LINK_TEXT https://github.com/D-Programming-Deimos, Deimos)
 * already provides a D module to interface it (see
 * $(LINK_TEXT https://github.com/D-Programming-Deimos/ZeroMQ, Deimos ZeroMQ)).
 * Provided that you pass the path to ZeroMQ/zmq.d to the compiler and the zmq
 * library is loadable the following code works.
 *
 * ---
 * unittest
 * {
 *     import ddl;
 *     import ZeroMQ.zmq; // need to use the directory one above; just zmq won't work
 *
 *     auto zmq = loadLibrary!(ZeroMQ.zmq)("zmq");
 *     assert(zmq.loadedFunctions == ["zmq_version", "zmq_errno",
 *              "zmq_strerror", "zmq_msg_init", "zmq_msg_init_size",
 *              "zmq_msg_init_data", "zmq_msg_close", "zmq_msg_move",
 *              "zmq_msg_copy", "zmq_msg_data", "zmq_msg_size", "zmq_init",
 *              "zmq_term", "zmq_socket", "zmq_close", "zmq_setsockopt",
 *              "zmq_getsockopt", "zmq_bind", "zmq_connect", "zmq_send", "zmq_recv",
 *              "zmq_poll", "zmq_device"]);
 *
 *     int major, minor, patch;
 *     zmq.zmq_version(&major, &minor, &patch);
 *
 *     assert(ZMQ_VERSION_MAJOR == major);
 * }
 * ---
 *
 * To ease switching between loading at run time and linking at compile time the
 * mixin template $(LOCAL_LINK declareLibraryAndAlias) is provided. This mixin
 * constructs aliases for each extern(C) function.
 *
 * If module is compiled with version(ddl) then the library is loaded at run
 * time. Otherwise it is linked at compile time.
 * ---
 * import ddl;
 * // declare either Library!(ZeroMQ.zmq) zmq or import zmq
 * version(ddl) mixin declareLibraryAndAlias!("ZeroMQ.zmq", "zmq");
 * else import zmq;
 *
 * unittest
 * {
 *     version(ddl) zmq = loadLibrary!(ZeroMQ.zmq)();
 *
 *     // use as usual
 *     int major, minor, patch;
 *     zmq_version(&major, &minor, &patch);
 *
 *     assert(ZMQ_VERSION_MAJOR == major);
 * }
 * ---
 *
 * Finally, to show case possible exceptional cases:
 * ---
 * unittest
 * {
 *     import ddl;
 *     import std.string : toStringz;
 *     import core.stdc.stdio;
 *
 *     // throws if some_library could not be loaded
 *     assertThrown!UnsatisfiedLinkException(loadLibrary!(core.stdc.stdio)("some_library", false));
 *     auto stdio = loadLibrary!(core.stdc.stdio)(libraryFilename("c")~".6", false);
 *
 *     // compile error, since foobar is not extern(C) function in core.stdc.stdio
 *     static assert(!__traits(compiles, stdio.loadFunction!("foobar")()));
 *
 *     // stdio.printf is not loaded
 *     assert(stdio.printf == null);
 *     // calling it results in a segfault
 *     //stdio.printf(toStringz("Hello World\n"));
 *
 *     // assuming fun is a extern(C) declared function but not defined
 *     assertThrown!UnsatisfiedLinkException(stdio.loadFunction!("fun")());
 * }
 * ---
 */
module ddl;

// tests assume there is the standard C library
version(unittest) private enum cLibrary = libraryFilename("c")~".6";

unittest
{
	import std.string : toStringz;
	import core.stdc.stdio; // import the module as usual

	// load the C library to resolve extern(C) functions declared
	// in core.std.stdio, but load no functions yet
	auto stdio = loadLibrary!(core.stdc.stdio)(cLibrary, false);

	// not loaded yet
	assert(stdio.printf == null);

	// load the function printf
	stdio.loadFunction!("printf")();
	// ... and call it
	stdio.printf(toStringz("Hello World.\n"));

	// unload
	stdio.unloadFunction!("printf")();
	assert(stdio.printf == null);
}

unittest
{
	import ZeroMQ.zmq; // need to use the directory one above; just zmq won't work

	auto zmq = loadLibrary!(ZeroMQ.zmq)("zmq");
	assert(zmq.loadedFunctions == ["zmq_version", "zmq_errno",
			"zmq_strerror", "zmq_msg_init", "zmq_msg_init_size",
			"zmq_msg_init_data", "zmq_msg_close", "zmq_msg_move",
			"zmq_msg_copy", "zmq_msg_data", "zmq_msg_size", "zmq_init",
			"zmq_term", "zmq_socket", "zmq_close", "zmq_setsockopt",
			"zmq_getsockopt", "zmq_bind", "zmq_connect", "zmq_send", "zmq_recv",
			"zmq_poll", "zmq_device"]);

	int major, minor, patch;
	zmq.zmq_version(&major, &minor, &patch);

	assert(ZMQ_VERSION_MAJOR == major);
}

unittest
{
	version(ddl) mixin declareLibraryAndAlias!("ZeroMQ.zmq", "zmq");
	else import zmq;

	version(ddl) zmq = loadLibrary!(ZeroMQ.zmq)();

	// usage as usual
	int major, minor, patch;
	zmq_version(&major, &minor, &patch);

	assert(ZMQ_VERSION_MAJOR == major);
}

unittest
{
	import std.string : toStringz;
	import core.stdc.stdio;

	// throws if some_library could not be loaded
	assertThrown!UnsatisfiedLinkException(loadLibrary!(core.stdc.stdio)("some_libraryname", false));
	auto stdio = loadLibrary!(core.stdc.stdio)(cLibrary, false);

	// compile error, since foobar is not extern(C) function in core.stdc.stdio
	static assert(!__traits(compiles, stdio.loadFunction!("foobar")()));

	// stdio.printf is not loaded
	assert(stdio.printf == null);
	// calling it results in a segfault
	//stdio.printf(toStringz("Hello World\n"));

	// assuming fun is a extern(C) declared function but not defined
	//assertThrown!UnsatisfiedLinkException(stdio.loadFunction!("fun")());
}

import std.typetuple;
import std.traits;
import std.string;
import std.exception;
import std.conv;
import std.path;
import std.array;
version(Posix)
{
	import core.sys.posix.dlfcn;
	pragma(lib, "dl"); // link statically
}
version(Windows) import core.sys.windows.windows, std.windows.syserror;
debug import std.stdio;

version(Posix)
{
	/// On Posix the libraryFilenamePrefix is "lib". On Windows it is "".
	enum string libraryFilenamePrefix = "lib";

	/// On Posix the libraryFilenameExtension is ".so". On Windows it is ".dll".
	enum string libraryFilenameExtension = ".so";
}
else version(Windows)
{
	enum string libraryFilenamePrefix = "";
	enum string libraryFilenameExtension = ".dll";
}
else static assert(0);


/// Returns: true if libraryFilename is a library filename on this system.
bool isLibraryFilename(string libraryFilename) pure
in
{
	assert(isValidFilename(libraryFilename));
}
body
{
	// strip any extension after libraryFilenameExtension
	while (!extension(libraryFilename).empty &&
	       extension(libraryFilename) != libraryFilenameExtension)
	{
		libraryFilename = stripExtension(libraryFilename);
	}

	return extension(libraryFilename) == libraryFilenameExtension &&
	       startsWith(libraryFilename, libraryFilenamePrefix);
}

unittest
{
	version(Posix)
	{
		assert(isLibraryFilename("libtest.so"));
		assert(isLibraryFilename("libtest-2.13.so"));
		assert(isLibraryFilename("libc.so.6"));
	}
	else version(Windows)
	{
		assert(libraryFilename("test.dll"));
		assert(libraryFilename("test-2.13.dll"));

		assert(!libraryFilename("C:\\Lib\\test.dll"));
		assert(!libraryFilename(".\\test-2.13.dll"));
	}
}

/**
 * Returns: the system specific filename of libraryName.
 *
 * E.g. on Posix the library name "c" has the filename "libc.so". On Windows the
 * library "c" has the filename "c.dll".
 */
string libraryFilename(string libraryName) nothrow pure
in
{
	assert(baseName(libraryName) == libraryName);
}
out(result)
{
	assert(isLibraryFilename(result));
}
body
{
	return libraryFilenamePrefix ~ libraryName ~ libraryFilenameExtension;
}

unittest
{
	version(Posix)
	{
		assert(libraryFilename("test") == "libtest.so");
		assert(libraryFilename("test-2.13") == "libtest-2.13.so");
	}
	else version(Windows)
	{
		assert(libraryFilename("test") == "test.dll");
		assert(libraryFilename("test-2.13") == "test-2.13.dll");
	}
}

/// Returns: true if libraryPath is a library path name for this system. It does
/// not check that the library path actually exists on this system.
bool isLibraryPath(string libraryPath)
in
{
	assert(isValidPath(libraryPath));
	assert(isLibraryFilename(baseName(libraryPath)));
}
body
{
	return isValidPath(libraryPath) && isLibraryFilename(baseName(libraryPath));
}

unittest
{
	version(Posix)
	{
		assert(isLibraryPath("/lib/x86_64-linux-gnu/libc.so.6"));
		assert(isLibraryPath("/usr/lib/libtest.so"));
		assert(isLibraryPath("./libtest-2.13.so"));
		assert(isLibraryPath("../libtest-2.13.so"));
	}
	else version(Windows)
	{
		assert(isLibraryPath("C:\\Lib\\test.dll"));
		assert(isLibraryPath("..\\test-2.13.dll"));
		assert(isLibraryPath(".\\test-2.13.dll"));
	}
}

/// Returns: true if libraryName is loadable on this system.
bool isLoadable(string libraryName) nothrow
{
	try loadLibrary!ddl(libraryName, false);
	catch (UnsatisfiedLinkException e)
		return false;
	catch (Exception e)
		assert(0);

	return true;
}

unittest
{
	assert(isLoadable(cLibrary));
	assert(!isLoadable("unknown-library"));

	assert(isLoadable("libc.so.6"));
	assert(isLoadable(libraryFilename("c")~".6"));
}

// helper for libraryPath
private version(Posix)
{
	extern(C) int dlinfo(void* handle, int request, void* arg);
	struct link_map
	{
		int l_addr; // TODO this is not correct
		char* l_name;
		void* l_ld; // TODO this is not correct
		link_map* l_next, l_prev;
	}
	enum RTLD_DI_LINKMAP = 2;
}

/**
 * Returns: the absolute library path for the given library name on this system.
 *
 * Note, that the library will be loaded.
 *
 * Throws: $(LOCAL_LINK UnsatisfiedLinkException) if libraryName could not be loaded.
 */
string libraryPath(string libraryName)
out(result)
{
	assert(isLibraryPath(result));
	assert(isAbsolute(result));
}
body
{
	auto lib = loadLibrary!ddl(libraryName, false);
	version(Posix)
	{
		link_map* map;
		// TODO
		// throw proper exceptions
		enforce(dlinfo(lib._handle, RTLD_DI_LINKMAP, &map) == 0,
		        new Exception(to!string(dlerror())));
		enforce(map);
		return absolutePath(to!string(map.l_name));
	}
	else version(Windows)
	{
		char path[200];
		auto len = GetModuleFileNameA(lib._handle, path, path.length);
		enforce(len);
		// TODO
		// check for errors
		//new UnsatisfiedLinkException(sysErrorString(GetLastError())));
		return path[0 .. len].idup;
	}
	else static assert(0);
}

unittest
{
	version(Posix)
	{
		assert(libraryPath(cLibrary) == "/lib/x86_64-linux-gnu/libc.so.6");
	}
	else version(Windows)
	{
		assert(libraryPath("test") == "C:\\Lib\\test.dll");
	}
}

// TODO
// library search path could also be implemented
// using dlinfo


/**
 * $(ANCHOR loadLibraryWithName)
 * Returns: a $(LOCAL_LINK_TEXT Library, Library!moduleName) loading library libraryName and
 * all extern(C) functions declared in module moduleName by default.
 *
 * Params:
 * moduleName  = is the module name those extern(C) functions will be loaded
 * libraryName = is the library name to load
 *
 * Throws: $(LOCAL_LINK UnsatisfiedLinkException) if libraryName or a
 *         function (if requested) could not be loaded.
 */
auto loadLibrary(alias moduleName)(string libraryName, bool loadAllNow = true)
{
	return Library!moduleName(libraryName, loadAllNow);
}

unittest
{
	import tests.dl;
	auto lib = loadLibrary!(tests.dl)("dl", false);
	assert(lib.isLoaded);

	assertThrown!UnsatisfiedLinkException(loadLibrary!(ddl)("unknown-library", false));
}

/**
 * Same as $(LOCAL_LINK_TEXT loadLibraryWithName, above) but the library name is
 * inferred from the module name.
 *
 * Examples:
 * ---
 * import ZeroMQ.zmq;
 * auto zmq = loadLibrary!(ZeroMQ.zmq); // loads library with name "zmq"
 * ---
 *
 */
auto loadLibrary(alias moduleName)(bool loadAllNow = true)
{
	return Library!moduleName(moduleName.stringof[7 .. $], loadAllNow);
}

unittest
{
	import tests.dl;
	auto lib = loadLibrary!(tests.dl)(false);
	assert(lib.isLoaded);
}

/**
 * Imports moduleName, declares Library!(moduleName) and alias to all the
 * libraries extern(C) functions.
 *
 * Params:
 * moduleName  = is the module name those extern(C) functions will be loaded
 * as          = is the variable name used when declaring Library!(moduleName)
 *
 * Examples:
 * ---
 * mixin declareLibraryAndAlias!("ZeroMQ.zmq", "zmq");
 * ---
 *
 */
mixin template declareLibraryAndAlias(alias moduleName, alias as)
{
	// create aliases for each function
	private string aliasFunctions(string libraryVariable, Functions...)(Functions functions)
	{
		string str = "";
		foreach (f; functions)
		{
			str ~= "alias " ~ libraryVariable ~ "." ~ f ~ " " ~ f ~ ";";
		}
		return str;
	}

	mixin("import " ~ moduleName ~ ";");
	mixin("alias Library!( " ~ moduleName ~ ") Lib" ~ ";");
	mixin("Lib " ~ as ~ ";");
	mixin(aliasFunctions!(as)(Lib.ExternCFunctions));
}

unittest
{
	mixin declareLibraryAndAlias!("ZeroMQ.zmq", "zmq");
	zmq = loadLibrary!(ZeroMQ.zmq)();

	// usage as usual
	int major, minor, patch;
	zmq_version(&major, &minor, &patch);

	assert(ZMQ_VERSION_MAJOR == major);
}

/**
 * A Library is capable of loading all extern(C) functions declared in module
 * moduleName.
 *
 * On construction a given library will be loaded which is unloaded on
 * destruction. $(B Note, that all instances of a Library share the extern(C)
 * functions as these are declared as static member variables.)
 *
 * Params:
 * moduleName  = is the module name those extern(C) functions will be loaded
 */
struct Library(alias moduleName)
{
	mixin("import module_ = " ~ fullyQualifiedName!(moduleName) ~ ";");
	private alias TypeTuple!(__traits(allMembers, module_)) AllModuleMembers;

	private template isExternCFunction(alias name)
	{
		static if (mixin("__traits(compiles, isSomeFunction!(module_."~name~")) &&
		                  isSomeFunction!(module_."~name~") &&
		                  functionLinkage!(module_."~name~") == \"C\""))
			enum isExternCFunction = true;
		else
			enum isExternCFunction = false;
	}

	/**
	 * ExternCFunctions is a $(PHOBOS_MODULE_LINK std_typetuple, TypeTuple)
	 * containing the names of all extern(C) functions declared in moduleName.
	 */
	alias staticFilter!(isExternCFunction, AllModuleMembers) ExternCFunctions;

	private mixin template SelectiveImportNonExternCFunctions(Symbol...)
	{
		static if (Symbol.length != 0)
		{
			static if (mixin("__traits(compiles, module_." ~ Symbol[0] ~ ")") &&
			           (staticIndexOf!(Symbol[0], ExternCFunctions) == -1))
			{
				mixin("import " ~ fullyQualifiedName!(moduleName) ~ " : " ~ Symbol[0] ~ ";");
			}
			mixin SelectiveImportNonExternCFunctions!(Symbol[1 .. $]);
		}
	}
	private mixin SelectiveImportNonExternCFunctions!(AllModuleMembers);

	private mixin template FunctionDeclarations(Functions...)
	{
		static if (Functions.length != 0)
		{
			enum str2 = functionTypeAsString!(mixin("module_."~Functions[0]))();
			enum str = stripExternC(str2);
			mixin(str ~ " " ~ Functions[0] ~ ";");
			mixin FunctionDeclarations!(Functions[1 .. $]);
		}
	}

	/**
	 * All functions in $(LOCAL_LINK ExternCFunctions) are declared as static
	 * variables.
	 *
	 * TODO
	 * documenting mixin does not work yet
	 */
	extern(C) static mixin FunctionDeclarations!(ExternCFunctions);

	/**
	 * Loads the library with given name.
	 *
	 * A loaded library is unloaded on destruction. $(B Note, that loaded
	 * functions are not unset), which can be a source of errors.
	 *
	 * Params:
	 * libraryName = specifies the library to load. libraryName may either be a
	 *               library name, a filename, or a path to a library.
	 * loadAllNow  = specifies whether all functions should be loaded.
	 *
	 * Throws: $(LOCAL_LINK UnsatisfiedLinkException) if libraryName or a
	 *         function (if requested) could not be loaded.
	 */
	this(string libraryName, bool loadAllNow)
	{
		if (isLibraryFilename(baseName(libraryName)))
			load(libraryName);
		else
			load(libraryFilename(libraryName));

		if (loadAllNow) loadAllFunctions();
	}

	unittest
	{
		{
			auto libc = Library!(core.stdc.stdio)(cLibrary, false);
			assert(libc.isLoaded);
		}

		version(X86_64)
		{
			auto libc = Library!(core.stdc.stdio)("/lib/x86_64-linux-gnu/libc.so.6", false);
			assert(libc.isLoaded);
		}

		assertThrown!UnsatisfiedLinkException(Library!(core.stdc.stdio)("unknown_library", false));
	}

	~this()
	{
		unload();
	}

	unittest
	{
		auto lib = Library!(core.stdc.stdio)(cLibrary, false);
		assert(lib.isLoaded);
		clear(lib);
		assert(!lib.isLoaded);
	}

	@disable
	static void opCall();

	unittest
	{
		static assert(!__traits(compiles, {Library!(core.stdc.stdio)();}));
	}

	@disable
	this(this);

	unittest
	{
		auto lib = Library!(core.stdc.stdio)(cLibrary, false);
		static assert(!__traits(compiles, {auto lib2 = lib;}));
	}

	/// Returns: true, if this Library is loaded. Otherwise false.
	@property
	bool isLoaded() nothrow
	{
		return _handle != null;
	}

	unittest
	{
		auto lib = Library!(core.stdc.stdio)(cLibrary, false);
		assert(lib.isLoaded);
		clear(lib);
		assert(!lib.isLoaded);
	}

	/**
	 * Load function with given functionName.
	 *
	 * After successful execution the function with name functionName is loaded
	 * and accessible by all instances of this Library.
	 *
	 * Fails at compile time, if functionName is not declared in moduleName.
	 *
	 * Params:
	 * functionName = is the name of the extern(C) function to load.
	 *
	 * Throws: $(LOCAL_LINK UnsatisfiedLinkException) if functionName could not
	 *         be loaded from libraryName.
	 */
	void loadFunction(string functionName)()
	{
		static assert(staticIndexOf!(functionName, ExternCFunctions) != -1,
		              "No extern(C) function " ~ functionName ~ " in " ~ moduleName.stringof);

		assert(_handle, "There was no library loaded.");

		mixin("alias " ~ functionName ~ " name;");
		// already loaded
		if (name != null)
			return;

		version(Posix)
		{
			// clear previous errors
			char* error = dlerror();
			assert(!error);

			name = cast(typeof(name)) enforce(dlsym(_handle, toStringz(functionName)),
			                                  new UnsatisfiedLinkException(to!string(dlerror())));
		}
		else version(Windows)
		{
			name = cast(typeof(name)) enforce(GetProcAddress(_handle, toStringz(functionName)),
			                                  new UnsatisfiedLinkException(sysErrorString(GetLastError())));
		}
		else static assert(0);
	}

	/**
	 * Unload function with given functionName.
	 *
	 * Note, that the function is unavailable for all instances of this Library
	 * after unloading.
	 *
	 * Fails at compile time, if functionName is not declared in moduleName.
	 *
	 * Params:
	 * functionName = is the name of the extern(C) function to unload.
	 */
	void unloadFunction(string functionName)() nothrow
	{
		static assert(staticIndexOf!(functionName, ExternCFunctions) != -1,
		              "No extern(C) function " ~ functionName ~ " in " ~ moduleName.stringof);

		mixin(functionName ~ " = null;");
	}

	unittest
	{
		{
			auto lib = Library!(core.stdc.stdio)(cLibrary, false);
			assert(lib.isLoaded);

			assert(lib.fclose == null);
			lib.loadFunction!("fclose")();
			assert(lib.fclose != null);
			lib.unloadFunction!("fclose")();
			assert(lib.fclose == null);
		}

		{
			import tests.dl;
			auto lib = Library!(tests.dl)("dl", false);
			// compile time error for non-declared extern(C) functions
			static assert(!__traits(compiles, {lib.loadFunction!("bar")();}));
			static assert(!__traits(compiles, {lib.unloadFunction!("bar")();}));
			// run-time exception for unavailable functions
			assertThrown!UnsatisfiedLinkException(lib.loadFunction!("foo")());
		}
	}

	/**
	 * Load all functions.
	 *
	 * It calls $(LOCAL_LINK loadFunction) for each $(LOCAL_LINK
	 * ExternCFunctions).
	 *
	 * Throws: $(LOCAL_LINK UnsatisfiedLinkException) if a function could not
	 *         be loaded.
	 */
	void loadAllFunctions()
	{
		foreach(functionName; ExternCFunctions)
		{
			loadFunction!(functionName)();
		}
	}

	/**
	 * Unload all functions by calling $(LOCAL_LINK unloadFunction) for each
	 * $(LOCAL_LINK ExternCFunctions).
	 */
	void unloadAllFunctions() nothrow
	{
		foreach(functionName; ExternCFunctions)
		{
			unloadFunction!(functionName)();
		}
	}

	/**
	 * Returns: all loaded functions of Library.
	 *
	 * Note, this is a static property as it is independent of the instance.
	 */
	@property
	static string[] loadedFunctions()
	{
		string[] loaded;
		foreach(functionName; ExternCFunctions)
		{
			if (mixin(functionName)) loaded ~= functionName;
		}
		return loaded;
	}

	unittest
	{
		{
			auto lib = Library!(core.stdc.stdio)(cLibrary, true);
			assert(lib.loadedFunctions == ["remove", "rename", "tmpfile",
			        "tmpnam", "fclose", "fflush", "fopen", "freopen", "setbuf",
			        "setvbuf", "fprintf", "fscanf", "sprintf", "sscanf",
			        "vfprintf", "vfscanf", "vsprintf", "vsscanf", "vprintf",
			        "vscanf", "printf", "scanf", "fgetc", "fputc", "fgets",
			        "fputs", "gets", "puts", "ungetc", "fread", "fwrite",
			        "fgetpos", "fsetpos", "fseek", "ftell", "rewind",
			        "clearerr", "feof", "ferror", "fileno", "snprintf",
			        "vsnprintf", "perror"]);

			lib.unloadAllFunctions();
			assert(lib.loadedFunctions == []);
		}
	}

	private:

	// Load library with given filename.
	void load(string libraryFilename)
	{
		version(Posix)
		{
			_handle = dlopen(toStringz(libraryFilename), RTLD_NOW);
			enforce(_handle, new UnsatisfiedLinkException(to!string(dlerror())));
		}
		else version(Windows)
		{
			_handle = LoadLibrary(toStringz(libraryFilename));
			enforce(_handle, new UnsatisfiedLinkException(sysErrorString(GetLastError())));
		}
		else static assert(0);
	}

	// Unload library.
	void unload()
	{
		if (_handle)
		{
			version(Posix)
			{
				int ret = dlclose(_handle);
				enforce(!ret, new UnsatisfiedLinkException(to!string(dlerror())));
			}
			else version(Windows)
			{
				bool ret = FreeLibrary(_handle);
				enforce(ret, new UnsatisfiedLinkException(sysErrorString(GetLastError())));
			}
			else static assert(0);

			_handle = null;
		}
	}

	version(Posix) void* _handle;
	version(Windows) HINSTANCE _handle;
}

unittest
{
	// needed to run Library's unittests
	auto lib = Library!(core.stdc.stdio)(cLibrary, false);
}

/// Exception that is thrown if a library or function could not be loaded.
class UnsatisfiedLinkException : Exception
{
	this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
	{
		super(msg, file, line, next);
	}
}

private:

// TODO
// move to std.typetuple
template staticFilter(alias F, T...)
{
	static if (T.length == 0)
		alias TypeTuple!() staticFilter;
	else static if (F!(T[0]))
		alias TypeTuple!(T[0], staticFilter!(F, T[1 .. $])) staticFilter;
	else
		alias TypeTuple!(      staticFilter!(F, T[1 .. $])) staticFilter;
}

string functionTypeAsString(alias functionName)()
{
	alias ReturnType!functionName RT;
	alias ParameterTypeTuple!functionName Parameters;
	enum ret = RT.stringof ~ " function" ~ Parameters.stringof;

	// TODO
	// we throw the function attributes away
	// but nothrow, pure, @trusted are important

	// fixup for variadic functions (not handled by ParameterTypeTuple)
	static if (variadicFunctionStyle!functionName == Variadic.c)
		return ret[0 .. $ - 1] ~ ",...)";
	else
		return ret;
}

unittest
{
	import core.stdc.stdio;
	assert(functionTypeAsString!(core.stdc.stdio.printf)() == "int function(const(char*),...)");
	static assert(functionTypeAsString!(core.stdc.stdio.printf)() == "int function(const(char*),...)");
	// TODO
	//assert(functionTypeAsString!(core.stdc.stdio.printf)() == "nothrow extern (C) int function(const(char*),...)");

	extern(C) int function(int) function(int, int function(int)) bar;

	assert(functionTypeAsString!(bar)() == "extern (C) int function(int) function(int, extern (C) int function(int))");
	static assert(functionTypeAsString!(bar)() == "extern (C) int function(int) function(int, extern (C) int function(int))");
}

string stripExternC(string str)
{
	enum externCString = "extern (C) ";

	if (str.length == 0)
		return "";
	else if (str.startsWith(externCString))
		return stripExternC(str[externCString.length .. $]);
	else return str[0] ~ stripExternC(str[1 .. $]);
}

unittest
{
	extern(C) int function(int) function(int, int function(int)) bar;
	static assert(stripExternC(functionTypeAsString!(bar)()) == "int function(int) function(int, int function(int))");
}

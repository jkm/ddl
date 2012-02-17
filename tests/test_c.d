import std.string : toStringz;
import ddl;

version(ddl) mixin declareLibraryAndAlias!("core.stdc.stdio", "stdio");
else import core.stdc.stdio;

unittest
{
	version(ddl) stdio = loadLibrary!(core.stdc.stdio)("c-2.13", true);

	printf(toStringz("Hello World.\n"));

	version(ddl) stdio.unloadAllFunctions();
}

version(unittest) void main() {}

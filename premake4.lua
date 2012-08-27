solution "ddl"
	language       "D"
	location       (_OPTIONS["to"])
	targetdir      (_OPTIONS["to"])
	flags          { "ExtraWarnings", "Symbols" }
	buildoptions   { "-wi -property" }
	configurations { "Optimize", "Tests" }
	platforms      { "Native", "x32", "x64" }

	configuration "*Optimize*"
		flags          { "Optimize" }
		buildoptions   { "-noboundscheck", "-inline" }

	configuration "*Tests*"
		buildoptions   { "-unittest" }
		includedirs    { "tests/" }

	project "ddl"
		kind              "StaticLib"
		files             { "src/*.d", "docs/*.d*" }
		buildoptions      { "-Dddocs/html" }

		-- documentation
		postbuildcommands { string.format("cp -a %s/docs/bootDoc/assets/* docs/html/", os.getcwd()) }
		postbuildcommands { string.format("cp -a %s/docs/bootDoc/bootdoc.css docs/html/", os.getcwd()) }
		postbuildcommands { string.format("cp -a %s/docs/bootDoc/bootdoc.js docs/html/", os.getcwd()) }
		postbuildcommands { string.format("cp -a %s/docs/bootDoc/ddoc-icons docs/html/", os.getcwd()) }

	project "test"
		kind              "ConsoleApp"
		includedirs       { "src/", "tests/" }
		files             { "tests/test_c.d", "tests/test_zmq.d" }
		links             { "ddl", "dl", "zmq" }
		defines           { "ddl" }
		postbuildcommands { "./test" }

	newoption {
		trigger = "to",
		value   = "path",
		description = "Set the output location for the generated files"
	}

	if _ACTION == "clean" then
		os.rmdir("obj")
		os.rmdir("docs/html")
	end
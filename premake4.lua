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
		includedirs    { "tests/openssl" }

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
		includedirs       { "src/", "tests/openssl" }
		files             { "src/ddl.d" } -- to run the unittests in ddl
		files             { "tests/test_c.d", "tests/test_openssl.d" }
		links             { "ddl", "dl", "ssl" }
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

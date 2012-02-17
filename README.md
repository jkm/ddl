DDL - D(eimos) Dynamic Loader
=============================

The D(eimos) Dynamic Loader allows loading dynamic C libraries at run time.
Consult its [documentation](http://jkm.github.com/ddl/ddl.html) for more information.

Dependencies
============

On Posix systems you need to link against libdl. libdl's license must permit
linking considering ddl's license. A libdl implementation licensed under LGPL is
fine.

There are no dependencies on Windows systems.

Usage
=====

Posix systems (Linux, Mac OSX, FreeBSD, etc.)
---------------------------------------------

    $ dmd path/to/ddl.d /path/to/libdl.a -L-ldl your_module.d

Note, that libdl must be linked statically and dynamically.

Windows
-------

    $ dmd path/to/ddl.d your_module.d

Testing
=======

See directory tests/ for some usage examples.

The tests assume that there is the standard C library and the ZeroMQ library on
your system.

Unfortunately the tests are not portable. So be prepared for seeing them fail on
your system.

    $ dmd -unittest -version=ddl -Ipath/to/ddl/tests /path/to/libdl.a -L-ldl path/to/ddl.d -run tests/test_c.d
    $ dmd -unittest -version=ddl -Ipath/to/ddl/tests /path/to/libdl.a -L-ldl path/to/ddl.d -run tests/test_zmq.d

Note this also runs ddl's unittests. Further, ```-version=ddl``` is needed to
verify the example in the [documentation](http://jkm.github.com/ddl/ddl.html).

To run the tests on Windows leave linking of dl out.

Issues
======

See [issues](https://github.com/jkm/ddl/issues) on github.

Licence
=======

This software is released under the [Boost License
1.0](http://www.boost.org/LICENSE_1_0.txt).

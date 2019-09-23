<div align="center"> <img src="images/logo.png" alt="Revise.jl" width="420"></img></div>

**NOTE: this page is for Julia 0.7.0 and higher. For Julia 0.6 [see this branch](https://github.com/timholy/Revise.jl/tree/v0.6)**

[![Build Status](https://travis-ci.org/timholy/Revise.jl.svg?branch=master)](https://travis-ci.org/timholy/Revise.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/e1xnsj4e5q9308y6/branch/master?svg=true)](https://ci.appveyor.com/project/timholy/revise-jl/branch/master)
[![codecov.io](http://codecov.io/github/timholy/Revise.jl/coverage.svg?branch=master)](http://codecov.io/github/timholy/Revise.jl?branch=master)

`Revise.jl` allows you to modify code and use the changes without restarting Julia.
With Revise, you can be in the middle of a session and then update packages, switch git branches,
and/or edit the source code in the editor of your choice; any changes will typically be incorporated
into the very next command you issue from the REPL.
This can save you the overhead of restarting Julia, loading packages, and waiting for code to JIT-compile.

See the [documentation](https://timholy.github.io/Revise.jl/stable):

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://timholy.github.io/Revise.jl/stable)

In particular, most users will probably want to alter their `.julia/config/startup.jl` file
to run Revise automatically, as described in the "Configuration" section of the documentation.

## Credits

Revise became possible because of Jameson Nash's fix of [Julia issue 265](https://github.com/JuliaLang/julia/issues/265).
[Juno](http://junolab.org/) is an IDE that offers an editor-based mechanism for achieving some
of the same aims.

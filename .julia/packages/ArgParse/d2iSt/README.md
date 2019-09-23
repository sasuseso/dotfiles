# ArgParse.jl

| **Documentation**                                                               | **PackageEvaluator**                                            | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:---------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-latest-img]][docs-latest-url] | [![][pkg-0.5-img]][pkg-0.5-url] [![][pkg-0.6-img]][pkg-0.6-url] | [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] [![][codecov-img]][codecov-url] |

ArgParse.jl is a package for parsing command-line arguments to
[Julia][julia] programs.

### Installation and usage

To install the module, use Julia's package manager. In Julia 0.7/1.0 and later, start pkg mode by pressing `]`
and then enter:

```
(v1.0) pkg> add ArgParse
```

In Julia 0.6, enter this instead:

```
julia> Pkg.add("ArgParse")
```

Dependencies will be installed automatically.
The module can then be loaded like any other Julia module:

```
julia> using ArgParse
```

### Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of the documentation.**
- [**LATEST**][docs-latest-url] &mdash; *in-development version of the documentation.*

See also the examples in the [examples directory](examples).

## Changes in release 0.6.2

* Fix a remaining compatibility issue (`@warn`)

## Changes in release 0.6.1

* Testing infrastructure update, tiny docs fixes

## Changes in release 0.6.0

* Added support for Julia v0.7, dropped support for Julia v0.5.
* Added `exit_after_help` setting to control whether to exit julia after help/version info is displayed
  (which is still the defult) or to just abort the parsing and return `nothing` instead.

## Changes in release 0.5.0

* Added support for Julia v0.6, dropped support for Julia v0.4.
* The default output type is now `Dict{String,Any}`, as stated in the docs,
  rather than `Dict{AbstractString,Any}`.
* Added docstrings, moved documentation to Documenter.jl

## Changes in release 0.4.0

### New features

* Added support for vectors of METAVAR names (see [#33][PR33])

### Other changes

* Support for Julia v0.3 was dropped.

## Changes in release 0.3.1

### New available settings

* `fromfile_prexif_chars` (see [#27][PR27])
* `preformatted_desciption`/`preformatted_epilog` (see [#28][PR28])

## Changes in release 0.3.0

### Breaking changes

Upgrading from versions 0.2.X to 0.3.X, the following API changes were made,
which may break existing code:

* Option arguments are no longer evaluated by default. This is for security
  reasons. Evaluation can be forced on a per-option basis with the
  `eval_arg=true` setting (although this is discuraged).
* The syntax of the `add_arg_table` function has changed, it now takes a `Dict`
  object instead of an `@options` opbject, since the dependency on the
  Options.jl module was removed. (The `@add_arg_table` macro is unchanged
  though.)

### Other changes

* Documented that overloading the function `ArgParse.parse_item` can be used to
  instruct ArgParse on how to parse custom types. Parse error reporting was
  also improved
* Removed dependecy on the Options.jl module
* Enabled precompilation on Julia 0.4


[Julia]: http://julialang.org

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://carlobaldassi.github.io/ArgParse.jl/stable
[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://carlobaldassi.github.io/ArgParse.jl/latest

[travis-img]: https://travis-ci.org/carlobaldassi/ArgParse.jl.svg?branch=master
[travis-url]: https://travis-ci.org/carlobaldassi/ArgParse.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/5c81omg867fu2gfy/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/carlobaldassi/argparse-jl/branch/master

[codecov-img]: https://codecov.io/gh/carlobaldassi/ArgParse.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/carlobaldassi/ArgParse.jl

[pkg-0.5-img]: http://pkg.julialang.org/badges/ArgParse_0.5.svg
[pkg-0.5-url]: http://pkg.julialang.org/?pkg=ArgParse
[pkg-0.6-img]: http://pkg.julialang.org/badges/ArgParse_0.6.svg
[pkg-0.6-url]: http://pkg.julialang.org/?pkg=ArgParse

[PR27]: https://github.com/carlobaldassi/ArgParse.jl/pull/27
[PR28]: https://github.com/carlobaldassi/ArgParse.jl/pull/28
[PR33]: https://github.com/carlobaldassi/ArgParse.jl/pull/33

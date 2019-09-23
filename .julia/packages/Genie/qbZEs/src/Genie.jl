"""
Loads dependencies and bootstraps a Genie app. Exposes core Genie functionality.
"""
module Genie

push!(LOAD_PATH, @__DIR__)

include("Configuration.jl")
include("constants.jl")

const config = Configuration.Settings(app_env = ENV["GENIE_ENV"])

using Revise
using Logging

isfile(joinpath(CONFIG_PATH, "plugins.jl")) && include(joinpath(CONFIG_PATH, "plugins.jl"))

push!(LOAD_PATH,  joinpath(@__DIR__, "cache_adapters"),
                  joinpath(@__DIR__, "session_adapters"),
                  RESOURCES_PATH, HELPERS_PATH)

include(joinpath(@__DIR__, "genie_types.jl"))

include("HTTPUtils.jl")
include("Exceptions.jl")
include("App.jl")
include("Inflector.jl")
include("Util.jl")
include("FileTemplates.jl")
include("Toolbox.jl")
include("Tester.jl")
include("Generator.jl")
include("Encryption.jl")
include("Cookies.jl")
include("Sessions.jl")
include("Input.jl")
include("Flax.jl")
include("Renderer.jl")
include("Assets.jl")
include("Router.jl")
include("WebChannels.jl")
include("AppServer.jl")
include("Commands.jl")
include("Cache.jl")
include("Responses.jl")
include("Requests.jl")
include("Flash.jl")
include("Plugins.jl")

using .HTTPUtils
using .App
using .Inflector, .Util
using .FileTemplates, .Toolbox, .Generator, .Tester, .Encryption, .Cookies, .Sessions
using .Input, .Renderer, .Assets, .Router, .Commands
using .Flax, .AppServer, .Plugins

export startup, serve, up


"""
    serve(path::String = DOC_ROOT_PATH, params...; kwparams...)

Serves a folder of static files located at `path`. Allows Genie to be used as a static files web server.
The `params` and `kwparams` arguments are forwarded to `Genie.startup()`.

# Arguments
- `path::String`: the folder of static files to be served by the server
- `params`: additional arguments which are passed to `Genie.startup` to control the web server
- `kwparams`: additionak keyword arguments which are passed to `Genie.startup` to control the web server

# Examples
```julia-repl
julia> Genie.serve("public", 8888, async = false, verbose = true)
[ Info: Ready!
2019-08-06 16:39:20:DEBUG:Main: Web Server starting at http://127.0.0.1:8888
[ Info: Listening on: 127.0.0.1:8888
[ Info: Accept (1):  🔗    0↑     0↓    1s 127.0.0.1:8888:8888 ≣16
```
"""
function serve(path::String = DOC_ROOT_PATH, params...; kwparams...)
  route("/") do
    serve_static_file("index.html", root = path)
  end
  route(".*") do
    serve_static_file(@params(:REQUEST).target, root = path)
  end

  Genie.startup(params...; kwparams...)
end


### NOT EXPORTED ###


"""
    newapp(path::String = "."; autostart::Bool = true, fullstack::Bool = false, dbsupport::Bool = false, mvcsupport::Bool = false) :: Nothing

Scaffolds a new Genie app, setting up the file structure indicated by the various arguments.

# Arguments
- `path::String`: the name of the app and the path where to bootstrap it
- `autostart::Bool`: automatically start the app once the file structure is created
- `fullstack::Bool`: the type of app to be bootstrapped. The fullstack app includes MVC structure, DB connection code, and asset pipeline files.
- `dbsupport::Bool`: bootstrap the files needed for DB connection setup via the SearchLight ORM
- `mvcsupport::Bool`: adds the files used for Flax view templates rendering and working with resources

# Examples
```julia-repl
julia> Genie.newapp("MyGenieApp")
2019-08-06 16:54:15:INFO:Main: Done! New app created at MyGenieApp
2019-08-06 16:54:15:DEBUG:Main: Changing active directory to MyGenieApp
2019-08-06 16:54:15:DEBUG:Main: Installing app dependencies
 Resolving package versions...
  Updating `~/Dropbox/Projects/GenieTests/MyGenieApp/Project.toml`
  [c43c736e] + Genie v0.10.1
  Updating `~/Dropbox/Projects/GenieTests/MyGenieApp/Manifest.toml`

2019-08-06 16:54:27:INFO:Main: Starting your brand new Genie app - hang tight!
 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|

┌ Info:
│ Starting Genie in >> DEV << mode
└
[ Info: Logging to file at MyGenieApp/log/dev.log
[ Info: Ready!
2019-08-06 16:54:32:DEBUG:Main: Web Server starting at http://127.0.0.1:8000
2019-08-06 16:54:32:DEBUG:Main: Web Server running at http://127.0.0.1:8000
```
"""
const newapp = Generator.newapp


"""
    loadapp(path::String = "."; autostart::Bool = false) :: Nothing

Loads an existing Genie app from the file system, within the current Julia REPL session.

# Arguments
- `path::String`: the path to the Genie app on the file system.
- `autostart::Bool`: automatically start the app upon loading it.

# Examples
```julia-repl
shell> tree -L 1
.
├── Manifest.toml
├── Project.toml
├── bin
├── bootstrap.jl
├── config
├── env.jl
├── genie.jl
├── log
├── public
├── routes.jl
└── src

5 directories, 6 files

julia> using Genie

julia> Genie.loadapp(".")
 _____         _
|   __|___ ___|_|___
|  |  | -_|   | | -_|
|_____|___|_|_|_|___|

┌ Info:
│ Starting Genie in >> DEV << mode
└
[ Info: Logging to file at MyGenieApp/log/dev.log
```
"""
function loadapp(path::String = "."; autostart::Bool = false) :: Nothing
  Core.eval(Main, Meta.parse("using Revise"))
  Core.eval(Main, Meta.parse("""include(joinpath("$path", "$(Genie.BOOTSTRAP_FILE_NAME)"))"""))
  Core.eval(Main, Meta.parse("Revise.revise()"))
  Core.eval(Main, Meta.parse("using Genie"))

  Core.eval(Main.UserApp, Meta.parse("Revise.revise()"))
  Core.eval(Main.UserApp, Meta.parse("$autostart && Genie.startup()"))

  nothing
end


"""
    startup(port::Int = Genie.config.server_port, host::String = Genie.config.server_host;
        ws_port::Int = Genie.config.websocket_port, async::Bool = ! Genie.config.run_as_server) :: Nothing

Starts the web server. Alias for `AppServer.startup`

# Arguments
- `port::Int`: the port used by the web server
- `host::String`: the host used by the web server
- `ws_port::Int`: the port used by the Web Sockets server
- `async::Bool`: run the web server task asynchronously

# Examples
```julia-repl
julia> startup(8000, "0.0.0.0", async = false)
[ Info: Ready!
Web Server starting at http://0.0.0.0:8000
```
"""
const startup = AppServer.startup
const up = startup


### PRIVATE ###


"""
    run() :: Nothing

Runs the Genie app by parsing the command line args and invoking the corresponding actions.
Used internally to parse command line arguments.
"""
function run() :: Nothing
  Commands.execute(Genie.config)

  nothing
end

end

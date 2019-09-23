"""
Generates various Genie files.
"""
module Generator

using Revise, SHA, Dates, Pkg, Logging
using Genie, Genie.FileTemplates, Genie.Inflector, Genie.Configuration, Genie.Tester, Genie.Util, Genie.FileTemplates


const JULIA_PATH = joinpath(Sys.BINDIR, "julia")


"""
    newcontroller(cmd_args::Dict{String,Any}) :: Nothing

Generates a new Genie controller file and persists it to the resources folder.
"""
function newcontroller(cmd_args::Dict{String,Any}; path::String = ".", pluralize::Bool = true) :: Nothing
  resource_name = cmd_args["controller:new"]
  Genie.Inflector.is_singular(resource_name) && pluralize && (resource_name = Inflector.to_plural(resource_name) |> Base.get)
  resource_name = uppercasefirst(resource_name)

  resource_path = setup_resource_path(resource_name, path = path)
  cfn = controller_file_name(resource_name)
  write_resource_file(resource_path, cfn, resource_name, :controller, pluralize = pluralize) &&
    @info "New controller created at $(joinpath(resource_path, cfn))"

  nothing
end


"""
    newresource(cmd_args::Dict{String,Any}, config::Settings) :: Nothing

Generates all the files associated with a new resource and persists them to the resources folder.
"""
function newresource(cmd_args::Dict{String,Any}; path::String = ".", pluralize::Bool = true) :: Nothing
  resource_name = uppercasefirst(cmd_args["resource:new"])

  if Genie.Inflector.is_singular(resource_name) && pluralize
    resource_name = Genie.Inflector.to_plural(resource_name) |> Base.get
  end

  resource_path = setup_resource_path(resource_name, path = path)
  for (resource_file, resource_type) in [(controller_file_name(resource_name), :controller)]
    write_resource_file(resource_path, resource_file, resource_name, resource_type, pluralize = pluralize) &&
      @info "New $resource_file created at $(joinpath(resource_path, resource_file))"
  end

  views_path = joinpath(resource_path, "views")
  isdir(views_path) || mkpath(views_path)

  runtests()

  isdir(Genie.TEST_PATH_UNIT) || mkpath(Genie.TEST_PATH_UNIT)
  test_file = resource_name * Genie.TEST_FILE_IDENTIFIER |> lowercase
  write_resource_file(Genie.TEST_PATH_UNIT, test_file, resource_name, :test, pluralize = pluralize) &&
    @info "New $test_file created at $(joinpath(Genie.TEST_PATH_UNIT, test_file))"

  nothing
end


function runtests() :: Nothing
  testfile = joinpath(Genie.TEST_PATH, Genie.TESTS_FILE_NAME)

  if ! isfile(testfile)
    open(testfile, "w") do f
      write(f, Genie.FileTemplates.runtests())
    end
  else
    @error "File $testfile already exists"
  end

  nothing
end


"""
    newresource(resource_name::Union{String,Symbol}) :: Nothing

Generates all the files associated with a new resource and persists them to the resources folder.
"""
function newresource(resource_name::Union{String,Symbol}; path::String = ".", pluralize::Bool = true) :: Nothing
  newresource(Dict{String,Any}("resource:new" => string(resource_name)), path = path, pluralize = pluralize)
end


"""
    setup_resource_path(resource_name::String) :: String

Computes and creates the directories structure needed to persist a new resource.
"""
function setup_resource_path(resource_name::String; path::String = ".") :: String
  isdir(Genie.APP_PATH) || Genie.Generator.mvc_support(path)

  resource_path = joinpath(path, Genie.RESOURCES_PATH, lowercase(resource_name))

  if ! isdir(resource_path)
    mkpath(resource_path)
    push!(LOAD_PATH, resource_path)
  end

  resource_path
end


"""
    write_resource_file(resource_path::String, file_name::String, resource_name::String) :: Bool

Generates all resouce files and persists them to disk.
"""
function write_resource_file(resource_path::String, file_name::String, resource_name::String, resource_type::Symbol; pluralize::Bool = true) :: Bool
  resource_name = (pluralize ? Base.get(Inflector.to_plural(resource_name)) : resource_name) |> Inflector.from_underscores

  try
    if resource_type == :controller
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        write(f, Genie.FileTemplates.newcontroller(resource_name))
      end
    end
  catch ex
    @error ex
  end

  try
    if resource_type == :test
      resource_does_not_exist(resource_path, file_name) || return true
      open(joinpath(resource_path, file_name), "w") do f
        name = pluralize ? Base.get(Inflector.to_singular(resource_name)) : resource_name
        write(f, Genie.FileTemplates.newtest(resource_name,  name))
      end
    end
  catch ex
    @error ex
  end

  try
    Genie.load_resources()
  catch ex
    @error ex
  end

  true
end


"""
    setup_windows_bin_files(path::String = ".") :: Nothing

Creates the bin/server and bin/repl binaries for Windows
"""
function setup_windows_bin_files(path::String = ".") :: Nothing
  open(joinpath(path, Genie.BIN_PATH, "repl.bat"), "w") do f
    write(f, "$JULIA_PATH --color=yes --depwarn=no -q -i -- ../$(Genie.BOOTSTRAP_FILE_NAME) %*")
  end

  open(joinpath(path, Genie.BIN_PATH, "server.bat"), "w") do f
    write(f, "$JULIA_PATH --color=yes --depwarn=no -q -i -- ../$(Genie.BOOTSTRAP_FILE_NAME) s %*")
  end

  open(joinpath(path, Genie.BIN_PATH, "serverinteractive.bat"), "w") do f
    write(f, "$JULIA_PATH --color=yes --depwarn=no -q -i -- ../$(Genie.BOOTSTRAP_FILE_NAME) si %*")
  end

  nothing
end


"""
    setup_nix_bin_files(app_path::String = ".") :: Nothing

Creates the bin/server and bin/repl binaries for *nix systems
"""
function setup_nix_bin_files(app_path::String = ".") :: Nothing
  chmod(joinpath(app_path, Genie.BIN_PATH, "server"), 0o700)
  chmod(joinpath(app_path, Genie.BIN_PATH, "repl"), 0o700)

  nothing
end


"""
    resource_does_not_exist(resource_path::String, file_name::String) :: Bool

Returns `true` if the indicated resources does not exists - false otherwise.
"""
function resource_does_not_exist(resource_path::String, file_name::String) :: Bool
  if isfile(joinpath(resource_path, file_name))
    @warn "File already exists, $(joinpath(resource_path, file_name)) - skipping"
    return false
  end

  true
end


"""
    controller_file_name(resource_name::Union{String,Symbol})

Computes the controller file name based on the resource name.
"""
function controller_file_name(resource_name::Union{String,Symbol}) :: String
  string(resource_name) * Genie.GENIE_CONTROLLER_FILE_POSTFIX
end


"""
    secret_token() :: String

Generates a random secret token to be used for configuring the SECRET_TOKEN const.
"""
function secret_token() :: String
  sha256("$(randn()) $(Dates.now())") |> bytes2hex
end


"""
Generates a valid secrets.jl file with a random SECRET_TOKEN.
"""
function write_secrets_file(app_path::String = ".") :: Nothing
  open(joinpath(app_path, Genie.CONFIG_PATH, Genie.SECRETS_FILE_NAME), "w") do f
    write(f, """const SECRET_TOKEN = "$(secret_token())" """)
  end

  nothing
end


"""
    fullstack_app(app_path::String = ".") :: Nothing

Writes the files necessary to create a full stack Genie app.
"""
function fullstack_app(app_path::String = ".") :: Nothing
  cp(joinpath(@__DIR__, "..", Genie.NEW_APP_PATH), app_path)

  nothing
end


"""
    microstack_app(app_path::String = ".") :: Nothing

Writes the file necessary to create a microstack app.
"""
function microstack_app(app_path::String = ".") :: Nothing
  mkdir(app_path)

  for f in [Genie.BIN_PATH, Genie.CONFIG_PATH, Genie.DOC_ROOT_PATH, Genie.SRC_PATH,
            Genie.GENIE_FILE_NAME, Genie.ROUTES_FILE_NAME,
            ".gitattributes", ".gitignore"]
    cp(joinpath(@__DIR__, "..", Genie.NEW_APP_PATH, f), joinpath(app_path, f))
  end

  remove_fingerprint_initializer(app_path)

  nothing
end


"""
    mvc_support(app_path::String = ".") :: Nothing

Writes the files used for rendering resources using the MVC stack and the Flax templating system.
"""
function mvc_support(app_path::String = ".") :: Nothing
  cp(joinpath(@__DIR__, "..", Genie.NEW_APP_PATH, Genie.APP_PATH), joinpath(app_path, Genie.APP_PATH))

  nothing
end


"""
    db_support(app_path::String = ".") :: Nothing

Writes files used for interacting with the SearchLight ORM.
"""
function db_support(app_path::String = ".") :: Nothing
  cp(joinpath(@__DIR__, "..", Genie.NEW_APP_PATH, Genie.DB_PATH), joinpath(app_path, Genie.DB_PATH))

  initializer_path = joinpath(app_path, Genie.INITIALIZERS_PATH, Genie.SEARCHLIGHT_INITIALIZER_FILE_NAME)
  isfile(initializer_path) || cp(joinpath(@__DIR__, "..", Genie.NEW_APP_PATH, Genie.INITIALIZERS_PATH, Genie.SEARCHLIGHT_INITIALIZER_FILE_NAME), initializer_path)

  nothing
end


"""
    write_app_custom_files(path::String, app_path::String) :: Nothing

Writes the Genie app main module file.
"""
function write_app_custom_files(path::String, app_path::String) :: Nothing
  moduleinfo = FileTemplates.appmodule(path)

  open(joinpath(app_path, Genie.SRC_PATH, moduleinfo[1] * ".jl"), "w") do f
    write(f, moduleinfo[2])
  end

  open(joinpath(app_path, Genie.BOOTSTRAP_FILE_NAME), "w") do f
    write(f,
    """
      cd(@__DIR__)
      using Pkg
      pkg"activate ."

      function main()
        include(joinpath("$(Genie.SRC_PATH)", "$(moduleinfo[1]).jl"))
      end; main()
    """)
  end

  nothing
end


"""
    install_app_dependencies(app_path::String = ".") :: Nothing

Installs the application's dependencies using Julia's Pkg
"""
function install_app_dependencies(app_path::String = ".") :: Nothing
  @info "Installing app dependencies"
  pkg"activate ."

  pkg"add Genie#master"
  pkg"add JSON"
  pkg"add Millboard"
  pkg"add Revise"
  pkg"add LoggingExtras"

  nothing
end


"""
    autostart_app(autostart::Bool = true) :: Nothing

If `autostart` is `true`, the newly generated Genie app will be automatically started.
"""
function autostart_app(autostart::Bool = true) :: Nothing
  if autostart
    @info "Starting your brand new Genie app - hang tight!"
    Genie.loadapp(".", autostart = autostart)
  else
    @info("Your new Genie app is ready!
        Run \njulia> Genie.loadapp() \nto load the app's environment
        and then \njulia> Genie.startup() \nto start the web server on port 8000.")
  end

  nothing
end


"""
    remove_fingerprint_initializer(app_path::String = ".") :: Nothing

Removes the asset fingerprint initializers if it's not used
"""
function remove_fingerprint_initializer(app_path::String = ".") :: Nothing
  rm(joinpath(app_path, Genie.INITIALIZERS_PATH, Genie.ASSETS_FINGERPRINT_INITIALIZER_FILE_NAME), force = true)

  nothing
end


"""
    remove_searchlight_initializer(app_path::String = ".") :: Nothing

Removes the SearchLight initializer file if it's unused
"""
function remove_searchlight_initializer(app_path::String = ".") :: Nothing
  rm(joinpath(app_path, Genie.INITIALIZERS_PATH, Genie.SEARCHLIGHT_INITIALIZER_FILE_NAME), force = true)

  nothing
end


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
function newapp(path::String = "."; autostart::Bool = true, fullstack::Bool = false, dbsupport::Bool = false, mvcsupport::Bool = false) :: Nothing
  app_path = abspath(path)

  fullstack ? fullstack_app(app_path) : microstack_app(app_path)

  dbsupport ? (fullstack || db_support(app_path)) : remove_searchlight_initializer(app_path)

  mvcsupport && (fullstack || mvc_support(app_path))

  write_secrets_file(app_path)

  write_app_custom_files(path, app_path)

  Sys.iswindows() ? setup_windows_bin_files(app_path) : setup_nix_bin_files(app_path)

  @info "Done! New app created at $(abspath(path))"

  @info "Changing active directory to $app_path"
  cd(path)

  install_app_dependencies(app_path)

  autostart_app(autostart)

  nothing
end


end

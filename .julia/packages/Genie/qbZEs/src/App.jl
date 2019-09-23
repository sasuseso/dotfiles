"""
App level functionality -- loading and managing app-wide components like configs, models, initializers, etc.
"""
module App

using Revise
using Genie

const ASSET_FINGERPRINT = ""


### PRIVATE ###


"""
    bootstrap(context::Union{Module,Nothing} = nothing) :: Nothing

Kickstarts the loading of a Genie app by loading the environment settings.
"""
function bootstrap(context::Union{Module,Nothing} = Genie.default_context(context)) :: Nothing
  if haskey(ENV, "GENIE_ENV") && isfile(joinpath(Genie.ENV_PATH, ENV["GENIE_ENV"] * ".jl"))
    isfile(joinpath(Genie.ENV_PATH, Genie.GLOBAL_ENV_FILE_NAME)) && Base.include(context, joinpath(Genie.ENV_PATH, Genie.GLOBAL_ENV_FILE_NAME))
    isfile(joinpath(Genie.ENV_PATH, ENV["GENIE_ENV"] * ".jl")) && Base.include(context, joinpath(Genie.ENV_PATH, ENV["GENIE_ENV"] * ".jl"))
  else
    ENV["GENIE_ENV"] = Genie.Configuration.DEV
    Core.eval(context, Meta.parse("const config = Configuration.Settings(app_env = Configuration.DEV)"))
  end

  for f in fieldnames(typeof(context.config))
    setfield!(Genie.config, f, getfield(context.config, f))
  end

  printstyled("""

   _____         _
  |   __|___ ___|_|___
  |  |  | -_|   | | -_|
  |_____|___|_|_|_|___|

  """, color = :red, bold = true)

  printstyled("| Web: https://genieframework.com\n", color = :light_black, bold = true)
  printstyled("| GitHub: https://github.com/genieframework/Genie.jl\n", color = :light_black, bold = true)
  printstyled("| Docs: https://genieframework.github.io/Genie.jl\n", color = :light_black, bold = true)
  printstyled("| Gitter: https://gitter.im/essenciary/Genie.jl\n", color = :light_black, bold = true)
  printstyled("| Twitter: https://twitter.com/GenieMVC\n\n", color = :light_black, bold = true)

  printstyled("Genie v$(Genie.Configuration.GENIE_VERSION)\n", color = :green, bold = true)
  printstyled("Active env: $(ENV["GENIE_ENV"] |> uppercase)\n\n", color = :light_blue, bold = true)

  nothing
end

end


### THIS IS LOADED INTO the Genie module !!!


using Logging
using .Configuration


### PUBLIC ###


"""
    newmodel(model_name::String; context::Union{Module,Nothing} = nothing) :: Nothing

Creates a new SearchLight `model` file.
"""
function newmodel(model_name::String; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  try
    Core.eval(context, :(SearchLight.Generator.newmodel($model_name)))

    load_resources()
  catch ex
    @error ex
  end

  nothing
end


"""
    newcontroller(controller_name::String) :: Nothing

Creates a new `controller` file. If `pluralize` is `false`, the name of the controller is not automatically pluralized.
"""
function newcontroller(controller_name::String; pluralize::Bool = true) :: Nothing
  Generator.newcontroller(Dict{String,Any}("controller:new" => controller_name), pluralize = pluralize)
  load_resources()

  nothing
end


"""
    newresource(resource_name::String; pluralize::Bool = true, context::Union{Module,Nothing} = nothing) :: Nothing

Creates all the files associated with a new resource.
If `pluralize` is `false`, the name of the resource is not automatically pluralized.
"""
function newresource(resource_name::String; pluralize::Bool = true, context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  Generator.newresource(Dict{String,Any}("resource:new" => resource_name), pluralize = pluralize)

  try
    pluralize || error("SearchLight resources need to be pluralized")
    Core.eval(context, :(SearchLight.Generator.newresource(uppercasefirst($resource_name)))) # SearchLight resources don't work on singular
  catch ex
    @error ex
    @warn "Skipping SearchLight"
  end

  load_resources()

  nothing
end


"""
    newmigration(migration_name::String, context::Union{Module,Nothing} = nothing) :: Nothing

Creates a new SearchLight migration file.
"""
function newmigration(migration_name::String; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  try
    Core.eval(context, :(SearchLight.Generator.new_migration(Dict{String,Any}("migration:new" => $migration_name))))
  catch ex
    @error ex
  end

  nothing
end


"""
    newtablemigration(migration_name::String, context::Union{Module,Nothing} = nothing) :: Nothing

Creates a new migration prefilled with code for creating a new table.
"""
function newtablemigration(migration_name::String; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  try
    Core.eval(context, :(SearchLight.Generator.new_table_migration(Dict{String,Any}("migration:new" => $migration_name))))
  catch ex
    @error ex
  end

  nothing
end


"""
    newtask(task_name::String) :: Nothing

Creates a new Genie `Task` file.
"""
function newtask(task_name::String) :: Nothing
  endswith(task_name, "Task") || (task_name = task_name * "Task")
  Genie.Toolbox.new(Dict{String,Any}("task:new" => task_name), Genie.config)

  nothing
end


### PRIVATE ###


"""
    load_libs(root_dir::String = Genie.LIB_PATH) :: Nothing

Recursively adds subfolders of `lib/` to LOAD_PATH.
The `lib/` folder, if present, is designed to host user code in the form of .jl files.
This function loads user code into the Genie app.
"""
function load_libs(root_dir::String = Genie.LIB_PATH) :: Nothing
  isdir(root_dir) || return nothing

  push!(LOAD_PATH, root_dir)

  for (root, dirs, files) in walkdir(root_dir)
    for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, p)
    end
  end

  nothing
end


"""
    load_resources(root_dir::String = RESOURCES_PATH) :: Nothing

Recursively adds subfolders of `resources/` to LOAD_PATH.
"""
function load_resources(root_dir::String = Genie.RESOURCES_PATH) :: Nothing
  isdir(root_dir) || return nothing

  push!(LOAD_PATH, root_dir)

  for (root, dirs, files) in walkdir(root_dir)
    for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, joinpath(root, dir))
    end
  end

  nothing
end


"""
    load_helpers(root_dir::String = HELPERS_PATH) :: Nothing

Recursively adds subfolders of `helpers/` to LOAD_PATH.
"""
function load_helpers(root_dir::String = Genie.HELPERS_PATH) :: Nothing
  isdir(root_dir) || return nothing

  push!(LOAD_PATH, root_dir)

  for (root, dirs, files) in walkdir(root_dir)
    for dir in dirs
      p = joinpath(root, dir)
      in(p, LOAD_PATH) || push!(LOAD_PATH, joinpath(root, dir))
    end
  end

  nothing
end


"""
    load_configurations(root_dir::String = CONFIG_PATH; context::Union{Module,Nothing} = nothing) :: Nothing

Loads (includes) the framework's configuration files into the app's module `context`.
The files are set up with `Revise` to be automatically reloaded.
"""
function load_configurations(root_dir::String = Genie.CONFIG_PATH; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  secrets_path = joinpath(root_dir, Genie.SECRETS_FILE_NAME)
  isfile(secrets_path) && Revise.track(context, secrets_path, define = true)

  nothing
end


"""
    load_initializers(root_dir::String = CONFIG_PATH; context::Union{Module,Nothing} = nothing) :: Nothing

Loads (includes) the framework's initializers.
The files are set up with `Revise` to be automatically reloaded.
"""
function load_initializers(root_dir::String = Genie.CONFIG_PATH; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  dir = joinpath(root_dir, Genie.INITIALIZERS_FOLDER)

  isdir(dir) || return nothing

  f = readdir(dir)
  for i in f
    fi = joinpath(dir, i)
    endswith(fi, ".jl") && Revise.track(context, fi, define = true)
  end

  nothing
end


"""
    load_plugins(root_dir::String = PLUGINS_PATH; context::Union{Module,Nothing} = nothing) :: Nothing

Loads (includes) the framework's plugins initializers.
"""
function load_plugins(root_dir::String = Genie.PLUGINS_PATH; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  isdir(root_dir) || return nothing

  for i in readdir(root_dir)
    fi = joinpath(root_dir, i)
    endswith(fi, ".jl") && Revise.track(context, fi, define = true)
  end

  nothing
end


"""
    load_routes_definitions(routes_file::String = Genie.ROUTES_FILE_NAME; context::Union{Module,Nothing} = nothing) :: Nothing

Loads the routes file.
"""
function load_routes_definitions(routes_file::String = Genie.ROUTES_FILE_NAME; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  isfile(routes_file) && Revise.track(context, routes_file, define = true)

  nothing
end


"""
    secret_token(; context::Union{Module,Nothing} = nothing) :: String

Wrapper around /config/secrets.jl SECRET_TOKEN `const`.
Sets up the secret token used in the app for encryption and salting.
If there isn't a valid secrets file, a temporary secret token is generated for the current session only.
"""
function secret_token(; context::Union{Module,Nothing} = nothing) :: String
  context = default_context(context)

  if isdefined(context, :SECRET_TOKEN)
    context.SECRET_TOKEN
  else
    @warn "SECRET_TOKEN not configured - please make sure that you have a valid secrets.jl file.
          You can generate a new secrets.jl file with a random SECRET_TOKEN using Genie.Generator.write_secrets_file()
          or use the included /app/config/secrets.jl.example file as a model."

    st = Generator.secret_token()
    Core.eval(@__MODULE__, Meta.parse("""const SECRET_TOKEN = "$st" """))

    st
  end
end


"""
    default_context(context::Union{Module,Nothing})

Sets the module in which the code is loaded (the app's module)
"""
function default_context(context::Union{Module,Nothing})
  try
    context === nothing ? Main.UserApp : context
  catch ex
    @error ex
    @__MODULE__
  end
end


"""
    load(; context::Union{Module,Nothing} = nothing) :: Nothing

Main entry point to loading a Genie app.
"""
function load(; context::Union{Module,Nothing} = nothing) :: Nothing
  context = default_context(context)

  App.bootstrap(context)

  load_configurations(context = context)

  Core.eval(Genie, Meta.parse("""const SECRET_TOKEN = "$(secret_token(context = context))" """))
  Core.eval(Genie, Meta.parse("""const ASSET_FINGERPRINT = "$(App.ASSET_FINGERPRINT)" """))

  load_initializers(context = context)
  load_helpers()

  load_libs()
  load_resources()

  load_routes_definitions(context = context)

  load_plugins(context = context)

  nothing
end
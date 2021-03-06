const DOCS_REGISTRY = "https://github.com/JuliaDocs/DocumentationGeneratorRegistry.git"

"""
    get_registry(basepath; registry=DOCS_REGISTRY, sync = true)

Clone the DocumentationGenerator registry into `basepath`. No download will occur if `sync == false`
and the registry already exists.

Returns the path to the `Registry.toml` (or `nothing` if an error occured).
"""
function get_registry(basepath; registry=DOCS_REGISTRY, sync = true)
    tomlpath = joinpath(basepath, "DocumentationGeneratorRegistry", "Registry.toml")
    if sync
        try
            rm(joinpath(basepath, "DocumentationGeneratorRegistry"), force = true, recursive = true)
            cd(basepath)
            run(`git clone --depth=1 $(registry) DocumentationGeneratorRegistry`)
            @assert isfile(tomlpath)
            return tomlpath
        catch err
            @warn("Couldn't download docs registry.", exception = err)
        end
    else
        if isfile(tomlpath)
            return tomlpath
        else
            @warn("No registry found at `$(tomlpath)`. Cloning again.")
            return get_registry(basepath; registry = registry, sync = true)
        end
    end
    return nothing
end

"""
    doctype(packagespec, registry)

Gets the doctype for package `packagespec` from the `Registry.toml` at `registry`.
Returns a tuple of `(doctype, uri)`, where `doctype` can be
- `vendored` -- Source code for the docs is located in the package directory. Default.
- `git-repo` -- Source code for the docs is located in the git-repo at `uri`.
- `hosted` -- Built docs are available at `uri`. We won't attempt to build/host them ourselves.
"""
function doctype(packagespec::Pkg.Types.PackageSpec, registry)
    if isfile(registry)
        uuid = string(packagespec.uuid)
        toml = Pkg.TOML.parsefile(registry)
        if haskey(toml, uuid)
            pkg = toml[uuid]
            if haskey(pkg, "method") && haskey(pkg, "location")
                return (pkg["method"], pkg["location"])
            else
                @warn("Invalid registry entry for $(packagespec.name).")
            end
        end
    else
        @warn("No registry found. Falling back to `vendored` docs.")
    end
    return ("vendored", nothing)
end

module FalconMRI


using PlyIO
using Requires


# File IO
export falcon_mesh
export read_falcon_mesh
export write_falcon_mesh
export falcon_cortex
export read_falcon_cortex





# read/write FALCON meshes
include("falcon_mesh.jl")

# draw meshes using Makie
function __init__()
    @require Makie="ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a" @eval begin
        import .Makie
        include("falcon_makie.jl")

        # Drawing using Makie
        export draw_two_hemispheres!
        export draw_multiple_fields
    end
end


end

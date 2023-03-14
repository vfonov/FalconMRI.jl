module FalconMRI


using CairoMakie
using PlyIO


# File IO
export falcon_mesh
export read_falcon_mesh
export write_falcon_mesh
export falcon_cortex
export read_falcon_cortex


# Drawing using Makie
export draw_two_hemispheres!
export draw_multiple_fields



# read/write FALCON meshes
include("falcon_mesh.jl")



end

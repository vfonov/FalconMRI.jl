using FalconMRI
using Test

@testset "FalconMRI.jl" begin
    # Write your tests here.
    @testset "Reading meshes" begin
        brain=read_falcon_cortex("input/mni_icbm152_ics_sm_")
        @test size(brain.LH.V) == (22830, 3)
        @test size(brain.RH.V) == (22810, 3)

        mktempdir() do tmp
            write_falcon_mesh(joinpath(tmp,"LH.ply"),brain.LH)
            write_falcon_mesh(joinpath(tmp,"RH.ply"),brain.RH)

            lh=read_falcon_mesh(joinpath(tmp,"LH.ply"))
            @test size(lh.V) == (22830, 3)
            rh=read_falcon_mesh(joinpath(tmp,"RH.ply"))
            @test size(rh.V) == (22810, 3)
        end
    end
end

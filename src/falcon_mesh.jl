#using Meshes

# helpers
function Base.in(q,ply::Ply) 
    for i in ply
        if plyname(i) == q
            return true
        end
    end
    return false
end


function Base.in(q,ply::Ply) 
    for i in ply
        if plyname(i) == q
            return true
        end
    end
    return false
end


function Base.in(q,ply::PlyElement) 
    for i in ply
        if plyname(i) == q
            return true
        end
    end
    return false
end

"""
Represent generic triangulate mesh generated by FALCON
"""
mutable struct falcon_mesh
    V # Vertex coordinate
    F # Faces index
    E # Edges
    VN # Vertex Normals
    sph # spherical coordinates
    F_rgb # Face color 
    E_face # edge between faces
    V_fld # scals field per vertex
    comments # comments
end

# helper function to read *.ply files
function read_falcon_mesh(fname::String)::falcon_mesh
    ply = load_ply(fname)
    V=[ply["vertex"]["x"] ply["vertex"]["y"] ply["vertex"]["z"]]

    if "vertex_indices" in ply["face"]
        vi = ply["face"]["vertex_indices"]
    elseif "vertex_index" in ply["face"]
        vi = ply["face"]["vertex_index"]
    end

    if "psi" in ply["vertex"] && "the" in ply["vertex"]
        sph = [ply["vertex"]["psi"] ply["vertex"]["the"] ]
    else
        sph = missing
    end

    if "nx" in ply["vertex"] && "ny" in ply["vertex"] && "nz" in ply["vertex"]
        VN = [ply["vertex"]["nx"] ply["vertex"]["ny"] ply["vertex"]["nz"]]
    else
        VN = missing
    end


    V_fld = Dict( plyname(qq)=>qq for qq in ply["vertex"] if !(plyname(qq) in ["x","y","z","psi","the"]))

    F = [ vi[i][j] for i in 1:length(vi),j in 1:length(vi[1]) ] .+ 1
    if "red" in ply["face"] && "green" in ply["face"] && "blue" in ply["face"]
        F_rgb =  [ ply["face"]["red"] ply["face"]["green"] ply["face"]["blue"]]
    else
        F_rgb = missing
    end

    if "edge" in ply && "vertex1" in ply["edge"] && "vertex2" in ply["edge"]
        E = [ ply["edge"]["vertex1"] ply["edge"]["vertex2"] ] .+ 1
    else
        E = missing
    end

    if "edge" in ply && "face1" in ply["edge"] && "face2" in ply["edge"]
        E_face = [ ply["edge"]["face1"] ply["edge"]["face2"] ] .+ 1
    else
        E_face = missing
    end

    comments = [i.comment for i in ply.comments]
    
    return falcon_mesh(V, F, E, VN, sph, F_rgb, E_face, V_fld, comments)
end


function write_falcon_mesh(fname,mesh::falcon_mesh;ascii=false)
    ply = Ply()
    for i in mesh.comments
        push!(ply, PlyComment(i))
    end
    
    vertex_prop = [ ArrayProperty("x", mesh.V[:,1]),
                    ArrayProperty("y", mesh.V[:,2]),
                    ArrayProperty("z", mesh.V[:,3]) ]
    
    if !ismissing(mesh.sph)
        push!(vertex_prop,ArrayProperty("psi", mesh.sph[:,1]))
        push!(vertex_prop,ArrayProperty("the", mesh.sph[:,2]))
    end

    if !ismissing(mesh.VN)
        push!(vertex_prop,ArrayProperty("nx", mesh.VN[:,1]))
        push!(vertex_prop,ArrayProperty("ny", mesh.VN[:,2]))
        push!(vertex_prop,ArrayProperty("nz", mesh.VN[:,3]))
    end

    for i in mesh.V_fld
        @info i[1],length(i[2])
        push!(vertex_prop, ArrayProperty(i[1],i[2]))
    end
    push!(ply, PlyElement("vertex", vertex_prop...))

    
    vertex_index = ListProperty("vertex_index", UInt8, Int32)
    for i=1:size(mesh.F,1)
        push!(vertex_index, mesh.F[i,:] .- 1)
    end

    face_props = []

    if !ismissing(mesh.F_rgb)
        push!(face_props, ArrayProperty("red", mesh.F_rgb[:,1]))
        push!(face_props, ArrayProperty("green", mesh.F_rgb[:,2]))
        push!(face_props, ArrayProperty("blue", mesh.F_rgb[:,3]))
    end
    push!(ply, PlyElement("face", vertex_index, face_props...))

    
    if !ismissing(mesh.E)
        edge_props=[ArrayProperty("vertex1", convert(Array{Int32},mesh.E[:,1].-1)),
                    ArrayProperty("vertex2", convert(Array{Int32},mesh.E[:,2].-1))]

        if !ismissing(mesh.E_face)
            push!(edge_props,ArrayProperty("face1", convert(Array{Int32},mesh.E_face[:,1].-1)))
            push!(edge_props,ArrayProperty("face2", convert(Array{Int32},mesh.E_face[:,2].-1)))
        end
        push!(ply, PlyElement("edge", edge_props...))
    end

    # For the sake of the example, ascii format is used, the default binary mode is faster.
    save_ply(ply, fname; ascii)
end

"""
Represent cortical surfaces (two hemishperes )
produced by FALCON
"""
mutable struct falcon_cortex
    LH::falcon_mesh
    RH::falcon_mesh
end

"""
Read cortical surfaces produced by falcon (will read left and right hemisphere)
"""
function read_falcon_cortex(base_fn)
    return falcon_cortex(read_falcon_mesh("$(base_fn)lt.ply"),
                         read_falcon_mesh("$(base_fn)rt.ply"))
end


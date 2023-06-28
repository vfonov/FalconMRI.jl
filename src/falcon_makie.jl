##### visualization helpers
"""
Make a 8-view of two hemishperes using Makie
return all generated meshes
"""
function draw_two_hemispheres!(layout,V1,F1, V2,F2;
        FLD1=nothing,FLD2=nothing,
        colorrange=nothing,
        colormap=:viridis,
        nan_color=Makie.RGBAf(0,0,0,0),
        compact=false)

    VC=vcat(V1, V2)
    FC=vcat(F1, F2 .+ size(V1,1))

    # try to automatically determine approximate size
    @views ex = extrema.([VC[:,i] for i in 1:3])
    bb = last.(ex) .- first.(ex)


    if isnothing(FLD1) || isnothing(FLD2)
        FLDC=nothing
    else
        FLDC=vcat(FLD1, FLD2)
    end

    if compact
        angles=(
                Left_LH=[0.0,0.0],
                Right_LH=[180.0,0], 

                Left_RH=[0.0,0.0],
                Right_RH=[180.0,0]
            )
    else
        angles=(Back=[-90.0,0.0],
                Front=[90,0.0],

                Left_LH=[0.0,0.0],
                Right_LH=[180.0,0], 

                Left_RH=[0.0,0.0],
                Right_RH=[180.0,0], 

                Top=[0.0,90.0],
                Bottom=[0,-90.0]
            )
    end
    
    m=[]
    for (i,p) in enumerate(pairs(angles))
        (a,rot) = p
        as = String(a)

        ax = Makie.Axis3(layout[fldmod1(i,2)...], 
                    aspect=    :data, 
                    azimuth   = rot[1]*pi/180, 
                    elevation = rot[2]*pi/180, 
                    viewmode  = :fitzoom,
                    xspinesvisible=false,yspinesvisible=false,zspinesvisible=false,
                    xgridvisible=false,  zgridvisible=false,  ygridvisible=false,
                ) 
        if !compact
            Makie.Label( layout[fldmod1(i,2)..., Makie.Bottom()], as, justification = :center, valign = :top)
        end

        Makie.hidedecorations!(ax)
        ax.protrusions = (0, 0, 0, 0)
        
        if isnothing(colorrange)
            opts=(;nan_color,shading=true, colormap = colormap)
        else
            opts=(;nan_color,shading=true, colormap = colormap, colorrange=colorrange)
        end
        
        if endswith(as,"LH")
            push!(m, Makie.mesh!( V1, F1; color=FLD1, opts...))
        elseif endswith(as,"RH")
            push!(m, Makie.mesh!( V2, F2; color=FLD2, opts...))
        else
            push!(m, Makie.mesh!( VC, FC; color=FLDC, opts...))
        end
    end

    # rowsize!(layout, 1, Auto(1))
    # rowsize!(layout, 2, Auto(1))
    # rowsize!(layout, 3, Auto(1))
    # rowsize!(layout, 4, Auto(1))

    # colsize!(layout, 1, Auto(1)) #Aspect(1, 1.0)
    # colsize!(layout, 2, Auto(1)) #Aspect(1, 1.0)

    Makie.colgap!(layout, 0)
    Makie.rowgap!(layout, 0)
    
    return m
end

"""
Convenience function to draw two hemispheres with scalar field
"""
function draw_two_hemispheres!(layout, ctx::falcon_cortex, field; options...)
    @assert length(field)==( size(ctx.LH.V,1)+size(ctx.RH.V,1) )

    return draw_two_hemispheres!(layout, 
            ctx.LH.V, ctx.LH.F, ctx.RH.V, ctx.RH.F;
            FLD1=field[1:size(ctx.LH.V,1)], FLD2=field[size(ctx.LH.V,1)+1:end],
            options...)
end


"""
convenience function to draw multuple scalar fields
"""
function draw_multiple_fields(layout,ctx::falcon_cortex,FIELDS; 
        colorrange=nothing, cols=3, 
        colwidth=nothing, rowheight=nothing, 
        compact = false, col_names=nothing,
        options...)
    
    @assert size(FIELDS,1)==(size(ctx.LH.V,1)+size(ctx.RH.V,1))
    m=[]
    for i in 1:size(FIELDS,2)
        if compact
            g = layout[fldmod1(i,cols)...] = Makie.GridLayout(2, 2, tellwidth=false, tellheigh=false)
        else
            g = layout[fldmod1(i,cols)...] = Makie.GridLayout(4, 2, tellwidth=false, tellheigh=false)
        end
        ####
        #Box(g, color = :transparent, strokewidth = 1)
        push!(m, draw_two_hemispheres!(g, ctx, FIELDS[:,i]; compact, colorrange, options... ))
        
        if !compact
            if isnothing(col_names)
                Makie.Label(g[1,:,Makie.Top()], "$(i)",font=:bold)
            else
                Makie.Label(g[1,:,Makie.Top()], col_names[i],font=:bold)
            end
        end
    end

    if !isnothing(colwidth)
        for i in 1:cols
            Makie.colsize!(layout, i, colwidth)
        end
    end
   
    if !isnothing(rowheight)
        for i in 1:div(size(FIELDS,2),cols, RoundUp)
            Makie.rowsize!(layout, i, rowheight)
        end
    end

   return m
end

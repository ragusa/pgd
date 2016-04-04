# FE solvers for displacement and damage
function solveDisplacementField(u,u_mesh,u_free,u_fe_values,d,d_mesh,d_fe_values,u_mp,b::Vector=zeros(2))
    n_u_free_dofs = length(u_free)
    Δu = zeros(n_u_free_dofs)
    u_tri = zeros(u)

    i = -1
    while true; i += 1
        copy!(u_tri,u)
        u_tri[u_free] += Δu

        g = u_residual(u_tri,u_mesh,u_free,u_fe_values,d,d_mesh,d_fe_values,u_mp,b)
        tol = 1e-7
        if maximum(abs(g)) < tol
            # println("Displacement field, u, converged in $i iterations, r = $(maximum(abs(g))).")
            break
        end

        K = u_jacobian(u_tri,u_mesh,u_free,u_fe_values,d,d_mesh,d_fe_values,u_mp,b)
        ΔΔu = cholfact(Symmetric(K, :U))\g
        Δu -= ΔΔu
        # ΔΔu = -K\g
        # Δu += ΔΔu

        return Δu # Since I know its linear
    end

    return Δu
end


function solveDamageField(d,d_mesh,d_free,d_fe_values,u,u_mesh,u_fe_values,d_mp,Ψ)
    n_d_free_dofs = length(d_free)
    Δd = zeros(n_d_free_dofs)
    d_tri = zeros(d)

    i = -1
    while true; i += 1
        copy!(d_tri,d)
        d_tri[d_free] += Δd

        g = d_residual(d_tri,d,d_mesh,d_free,d_fe_values,u,u_mesh,u_fe_values,d_mp,Ψ)
        # println(norm(g))
        tol = 1e-7
        if maximum(abs(g)) < tol
            # println("Damage field, d, converged in $i iterations, r = $(maximum(abs(g))).")
            break
        end

        K = d_jacobian(d_tri,d,d_mesh,d_free,d_fe_values,u,u_mesh,u_fe_values,d_mp,Ψ)
        ΔΔd = cholfact(Symmetric(K,:U))\g
        Δd -= ΔΔd
        # ΔΔd = -K\g
        # Δd += ΔΔd

        return Δd # Since I know its linear
    end

    return Δd
end

function calculateFreeEnergy(u,u_mesh,u_free,u_fe_values,d,d_mesh,d_fe_values,u_mp,Ψ)

    Ψ_plot = zeros(u_mesh.nEl)
    σe_plot = zeros(u_mesh.nEl)

    for i = 1:u_mesh.nEl
        x = [u_mesh.ex[:,i] u_mesh.ey[:,i]]'
        x = reinterpret(Vec{2,Float64},x,(size(x,2),))
        JuAFEM.reinit!(u_fe_values,x)
        JuAFEM.reinit!(d_fe_values,x)
        u_m = u_mesh.edof[:,i]
        d_m = d_mesh.edof[:,i]

        Ψ[i], σ_e = Ψ_intf(u[u_m],d[d_m],u_fe_values,d_fe_values,u_mp,Ψ[i])
        Ψ_plot[i] = mean(Ψ[i])
        σe_plot[i] = mean(σ_e)
    end

    return Ψ, Ψ_plot, σe_plot
end

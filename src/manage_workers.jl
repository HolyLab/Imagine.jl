set_device(dev_name::T, pid::Int) where {T<:AbstractString} = Distributed.remotecall_eval(ImagineWorker, pid, :(_set_device($dev_name)))

#sets device for driver process and all workers
function set_device(dev_name::T) where T<:AbstractString
    global DEFAULT_DEVICE = String(dev_name)
    map(pid->set_device(dev_name, pid), WORKERS)
end

function load_worker_code(id)
    Distributed.remotecall_eval(Main, id, :(using Pkg))
    Distributed.remotecall_eval(Main, id, :(Pkg.activate(".")))
    Distributed.remotecall_eval(Main, id, :(using ImagineInterface))
    Distributed.remotecall_eval(Main, id, :(using Imagine)) #not sure why this one's needed, but bringing Imagine into scope avoids a cryptic Serialization error
    Distributed.remotecall_eval(Main, id, :(using ImagineWorker))
end

function add_workers(n::Int, dev=DEFAULT_DEVICE)
    ids = addprocs(n; dir=joinpath(@__DIR__, ".."))
    append!(FREE_WORKERS, ids)
    append!(WORKERS, ids)
    @sync begin
        print("Initializing $n new worker processes...\n")
        for i = 1:length(ids)
	    @async load_worker_code(ids[i])
        end
    end
    for i = 1:length(ids)
        set_device(dev, ids[i])
    end
    return ids
end

function get_worker(; dev=DEFAULT_DEVICE)
    proc_id = -1
    if isempty(FREE_WORKERS)
        print("No free workers found.  Adding more.\n")
        add_workers(1, dev)[1]
        proc_id = pop!(FREE_WORKERS)
    else
        proc_id = pop!(FREE_WORKERS)
        set_device(dev, proc_id)
    end
    push!(USED_WORKERS, proc_id)
    return proc_id
end

function free_workers(proc_ids::Vector{Int})
    for proc_id in proc_ids
        if !in(proc_id, WORKERS)
            error("Worker id $proc_id is not in this module's worker pool")
        end
        if length(WORKERS) > NPERSISTENT_WORKERS
            print("Freeing worker AND removing process\n")
            rmprocs(proc_id)
            deleteat!(WORKERS, findall(x->x==proc_id, WORKERS))
            deleteat!(USED_WORKERS, findall(x->x==proc_id, USED_WORKERS))
        else
            push!(FREE_WORKERS, proc_id)
            deleteat!(USED_WORKERS, findall(x->x==proc_id, USED_WORKERS))
        end
    end
    return FREE_WORKERS
end
free_workers(proc_id::Int) = free_workers([proc_id;])

#ImagineWorker._set_device(DEFAULT_DEVICE) #set local device

#TODO? switch to remotecall_eval or @everywhere expr procs? new in julia 0.7.  See Julia #22589 on github
set_device{T<:AbstractString}(dev_name::T, pid::Int) = remotecall_fetch(Core.eval, pid, Main, :(ImagineWorker._set_device($dev_name)))

#sets device for driver process and all workers
function set_device{T<:AbstractString}(dev_name::T)
    global DEFAULT_DEVICE = String(dev_name)
    map(pid->set_device(dev_name, pid), WORKERS)
end

function add_workers(n::Int, dev=DEFAULT_DEVICE)
    ids = addprocs(n)
    append!(FREE_WORKERS, ids)
    append!(WORKERS, ids)
    rslts = Future[]
    for i = 1:length(ids)
        print("Initializing new worker process...\n")
        push!(rslts, remotecall(Core.eval, ids[i], Main, :(import ImagineWorker)))
    end
    map(fetch, rslts)
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
            deleteat!(WORKERS, find(x->x==proc_id, WORKERS))
            deleteat!(USED_WORKERS, find(x->x==proc_id, USED_WORKERS))
        else
            push!(FREE_WORKERS, proc_id)
            deleteat!(USED_WORKERS, find(x->x==proc_id, USED_WORKERS))
        end
    end
    return FREE_WORKERS
end
free_workers(proc_id::Int) = free_workers([proc_id;])
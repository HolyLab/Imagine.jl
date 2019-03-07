#Usually code from RegisterWorker does not run on the driver process
#The only exception is when the user specifies the "run_locally" kwarg, which is only for testing

function output_signals(sigs; dev = DEFAULT_DEVICE, trigger_terminal = "disabled", run_locally = false, clock = "")
    if !all(map(isoutput, sigs))
        error("Please provide only output ImagineCommands")
    end
    sigsa = getanalog(sigs)
    sigsd = getdigital(sigs)
    ready_chans = RemoteChannel{Channel{Int}}[]
    print("Outputting $(length(sigsa)) analog and $(length(sigsd)) digital ImagineSignals\n")
    rslt = []
    srate = samprate(first(sigs))
    nsamps = length(first(sigs))
    bufsz_seconds = 5
    bufsz = min(upreferred(bufsz_seconds*srate*2*Unitful.s), nsamps) #the NIDAQ buffer will be twice this large
    writesz = div(bufsz,2)
    if !isempty(sigsa)
        rchan = RemoteChannel(()->Channel{Int}(1))
        rexp = :(_output_analog_signals($sigsa, $writesz, $trigger_terminal, $rchan, $clock))
        if !run_locally
            id_a = get_worker(;dev=dev)
            tmp = remotecall(Core.eval, id_a, Main, rexp)
            push!(rslt, tmp)
        else
            set_device(dev, myid())
            Core.eval(rexp)
        end
        push!(ready_chans, rchan)
    end
    if !isempty(sigsd)
        rchan = RemoteChannel(()->Channel{Int}(1))
        rexp = :(_output_digital_signals($sigsd, $writesz, $trigger_terminal, $rchan, $clock))
        if !run_locally
            id_d = get_worker(;dev=dev)
            tmp = remotecall(Core.eval, id_d, Main, rexp)
            push!(rslt, tmp)
        else
            set_device(dev, myid())
            Core.eval(rexp)
        end
        push!(ready_chans, rchan)
    end    
    return (ready_chans, rslt)
end
output_signals(sig::ImagineSignal; trigger_terminal = "disabled", run_locally = false, clock = "") =
    output_signals([sig]; dev = DEFAULT_DEVICE, trigger_terminal = trigger_terminal, run_locally = run_locally, clock=clock)

#if base_name is an empty string, then do not use memory mapping for the result array
function record_signals(base_name::AbstractString, sigs, nsamps::Integer; dev=DEFAULT_DEVICE, trigger_terminal = "disabled", run_locally=false, clock="")
    if any(map(isoutput, sigs))
        error("Please provide only input ImagineCommands")
    end
    if !all(map(isempty, sigs))
        error("The provided ImagineSignals must be empty.  Empty them with empty!(sig)")
    end
    sigsa = getanalog(sigs)
    sigsd = getdigital(sigs)
    print("Recording $(length(sigsa)) analog and $(length(sigsd)) digital ImagineSignals\n")
    rslt = []
    ready_chans = RemoteChannel{Channel{Int}}[]
    srate = samprate(first(sigs))
    bufsz_seconds = 5
    bufsz = min(upreferred(bufsz_seconds*srate*2*Unitful.s), nsamps) #the NIDAQ buffer will be twice this large
    readsz = div(bufsz,2)
    if !isempty(sigsa)
        rchan = RemoteChannel(()->Channel{Int}(1))
        file_name = isempty(base_name) ? base_name : base_name * ".ai"
        rexp = :(_record_analog_signals($file_name, $sigsa, $nsamps, $readsz, $trigger_terminal, $rchan, $clock))
        if !run_locally
            id_a = get_worker(;dev=dev)
            tmp = remotecall(Core.eval, id_a, Main, rexp)
            push!(rslt, tmp)
        else
            set_device(dev, myid())
            tmp = remotecall(Core.eval, myid(), Main, rexp)
	    push!(rslt, tmp)
        end
        push!(ready_chans, rchan)
    end
    if !isempty(sigsd)
        rchan = RemoteChannel(()->Channel{Int}(1))
        file_name = isempty(base_name) ? base_name : base_name * ".di"
        push!(ready_refs, RemoteChannel{Int}(1))
        rexp = :(_record_digital_signals($file_name, $sigsd, $nsamps, $readsz, $trigger_terminal, $rchan, $clock))
        if !run_locally
            id_d = get_worker(;dev=dev)
            tmp = remotecall(Core.eval, id_d, Main, rexp)
            push!(rslt, tmp)
        else
            set_device(dev, myid())
            tmp = remotecall(Core.eval, myid(), Main, rexp)
	    push!(rslt, tmp)
        end
        push!(ready_chans, rchan)
    end
    return (ready_chans, rslt)
end
record_signals(base_name::AbstractString, sig::ImagineSignal, nsamps::Integer; trigger_dest = "disabled", run_locally=false, clock="") =
    record_signals(base_name, [sig], nsamps; trigger_terminal = "disabled", run_locally = run_locally, clock = clock)

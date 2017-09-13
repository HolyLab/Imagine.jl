#Note that the duration is software-timed so not precise
function ttl_pulse(;nsecs = 1.0, line_name = "Port0/Line0")
    otsk = NIDAQ.digital_output(DEFAULT_DEVICE*line_name)
    try
        start(otsk)
        write(otsk, [UInt8(true)])
        sleep(nsecs)
        write(otsk, [UInt8(false)])
    finally
        stop(otsk)
        clear(otsk) 
    end
    return 0
end

function run_imagine{T<:AbstractString, S<:ImagineSignal}(base_name::T, sigs::Vector{S}; ai_trig_dest = "disabled", ao_trig_dest = "disabled", trigger_source = "Port0/Line0")
    dev = DEFAULT_DEVICE
    if isempty(sigs)
        error("Empty signal list")
    end
    #Don't require a "sufficient" set of signals for an imaging experiment until this is a fully working alternative to Imagine (easier for testing)
    ImagineInterface.validate_signals(sigs; check_is_sufficient = false)
    ins = getinputs(sigs)
    outs = getoutputs(sigs)
    if isempty(outs)
        error("No output channels found, so unable to guess the number of samples to acquire.  Use the record_signals function instead.")
    end
    if length(WORKERS) < NPERSISTENT_WORKERS #currently we always keep 4 workers ready.  Could instead ready them on demand but so far this seems like a win.
        to_add = NPERSISTENT_WORKERS - length(WORKERS)
        new_workers = add_workers(to_add, dev)
    end
    sigs_out = ImagineSignal[]
    rchans = RemoteChannel{Channel{Int}}[]
    rrs = []
    ids = Int[]
    nsamps = length(first(outs))
    (rchns_o, rr) = output_signals(outs; trigger_terminal = ao_trig_dest)
    append!(rchans, rchns_o)
    append!(rrs, rr)
    if !isempty(ins)
        #TODO: insert more logic for digital signals, di_trig_dest
        (rchns_i, rr) = record_signals(base_name, ins, nsamps; trigger_terminal = ai_trig_dest)
        append!(rchans, rchns_i)
        append!(rrs, rr)
    end
    print("Waiting for all tasks to become triggerable...\n")
    for c in rchans
        push!(ids, take!(c))
    end
    if rig_name(first(sigs)) == "dummy-6002"
        sleep(3.0) #this shouldn't be necessary, but it is (a digital trigger for AI was found inneffective immediately after the CfgDigEdgeStartTrig function returned with usb 6002)
    end
    print("Triggering tasks...\n")
    ttl_pulse(; line_name = trigger_source) #P0.0 is wired to PFI0 and PFI1 for testing with usb 6002
    for i = 1:length(rrs)
        _sigs = fetch(rrs[i])
        print("A task is finished.\n")
        append!(sigs_out, _sigs)
    end
    free_workers(ids)
    return sigs_out
end

#ttl_pulse(; nsecs = 1.0, dev=DEFAULT_DEVICE, line_name="Port0/Line0") = _ttl_pulse(nsecs, line_name)

#This version spawns a worker
#function ttl_pulse(; nsecs = 1.0, dev=DEFAULT_DEVICE, line_name="Port0/Line0") = _ttl_pulse(nsecs, line_name)
#    id = get_worker(;dev=dev)
#    sendto([id;], nsecs=nsecs, line_name=line_name)
#    rslt = @spawnat id _ttl_pulse(nsecs, line_name)
#    fetch(rslt)
#    free_workers(id)
#end

#note: this shows whether start and stop triggering are supported on the device.
#NIDAQ.GetDevAOTrigUsage(r, rslt)
#NIDAQ.GetDevAITrigUsage(r, rslt)
#For USB-6002 devices that clock synchronization is not supported (see list of terminals).  bummer.
#strategy:  for the usb-6002 we can synchronize AO and AI starts by connecting the start-triggers with the PFI0 or PFI1 pins.  Note that the tasks will desynchronize over time since their
#clocks aren't synchronized
#note: with other boards we shouldn't need the PFI pins, maybe can just use the ao or ai start trigger terminals.  Then one needs to be triggered by software, the others can be triggered by its start sig.
#USB-6002 list of terminals (Ctr0Source is mysterious, probably useless) ["/Dev1/PFI0", "/Dev1/PFI1", "/Dev1/ai/StartTrigger", "/Dev1/ao/StartTrigger", "/Dev1/Ctr0Source"]
#will also implement another function that synchronizes the sample clocks of the two (and also of digital channels) for when this is used with a better DAQ
#   TODO: synchronize sample clocks for ai and ao tasks
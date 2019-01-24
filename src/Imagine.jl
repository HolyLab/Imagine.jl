module Imagine

using ImagineInterface, Unitful, Distributed
using ImagineWorker

#ENV["JULIA_PROJECT"] = joinpath(@__DIR__, "..")

@static if (Sys.iswindows() && isfile("C:\\Windows\\System32\\nicaiu.dll"))
    using NIDAQ #just for the trigger pulse
    const NPERSISTENT_WORKERS = 4 #one each for AI, AO, DI, DO, one for PFI pulse
    devs = NIDAQ.devices()
    if isempty(devs)
	error("No NI devices detected")
    end
    DEFAULT_DEVICE = devs[1] * "/" #"Dev1/"
    FREE_WORKERS = Int[]
    USED_WORKERS = Int[]
    WORKERS = Int[]

    export run_imagine,
            set_device,
            record_signals,
            output_signals

    include("manage_workers.jl")
    include("io.jl")
    include("run.jl")
end

@static if !Sys.iswindows()
    @warn("This package only works on Windows")
end

@static if (Sys.iswindows() && !isfile("C:\\Windows\\System32\\nicaiu.dll"))
    @warn("nicaiu.dll not found")
end

end

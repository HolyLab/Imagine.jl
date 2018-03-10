__precompile__(false)

module Imagine

using ImagineInterface, Unitful
import ImagineWorker

if is_windows() && isfile("C:\\Windows\\System32\\nicaiu.dll")
    using NIDAQ #just for the trigger pulse
    const NPERSISTENT_WORKERS = 4 #one each for AI, AO, DI, DO, one for PFI pulse
    DEFAULT_DEVICE = NIDAQ.devices()[1] * "/" #"Dev1/"
    FREE_WORKERS = Int[]
    USED_WORKERS = Int[]
    WORKERS = Int[]

    export run_imagine,
            set_device

    include("manage_workers.jl")
    include("io.jl")
    include("run.jl")
else
    warn("DAQ unavailable. The Imagine package will not work")
end

end

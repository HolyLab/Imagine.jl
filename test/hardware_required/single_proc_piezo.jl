using Unitful, ImagineInterface, Imagine
using Base.Test

#modified from ImagineInterface test
srate = 10000*Unitful.s^-1
pmin = 0.0*Unitful.μm
pmax = 200.0*Unitful.μm
stack_time = 3.0*Unitful.s
reset_time = 2.0*Unitful.s
exp_time = 0.011*Unitful.s
flash_frac = 0.1 #fraction of time to keep laser on during exposure
z_spacing = 3.1*Unitful.μm
z_pad = 5.0*Unitful.μm
nstacks = 10
d = gen_unidirectional_stack(pmin, pmax, z_spacing, stack_time, stack_time, exp_time, srate, flash_frac; z_pad = z_pad)

ocpi2 = rigtemplate("ocpi-2"; sample_rate = srate)
pos = getpositioners(ocpi2)[1]
pos_mon = getname(ocpi2, monitor_name(pos))
append!(pos, "uni_stack_pos", d["positioner"])
replicate!(pos, nstacks-1)
#write_commands("test.json", ocpi2, nstacks, nframes, exp_time; isbidi = false)

aos = [pos;]
#ais = [pos_mon;]
#ais = ImagineSignal[]

#prepare_ao(aos, bufsz::Int, trigger_terminal::String)
ImagineWorker._set_device("Dev2/")
#tsk = ImagineWorker.prepare_ao(aos, 100000, "PFI1")
#print("starting...\n")
#start(tsk)

ready_chan = RemoteChannel(()->Channel{Int}(1))
ImagineWorker._output_analog_signals(aos, 50000, "PFI1", ready_chan)

#and execute this from another julia instance:
#using NIDAQ, Imagine; Imagine.ttl_pulse(; line_name = "Port2/Line0")



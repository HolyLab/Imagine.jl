using Unitful, ImagineInterface, Imagine, Statistics
using Test

#NOTE: the piezo should be turned on, connected, and in closed loop mode in order for this test to pass
srate = 100000*Unitful.s^-1
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
ais = [pos_mon;]

sigs = run_imagine("", vcat(aos,ais); ai_trig_dest = "PFI2", ao_trig_dest = "PFI1", trigger_source = "Port2/Line0")

c = Statistics.cor(ustrip.(get_samples(sigs[1]; sampmap=:volts)), ustrip.(get_samples(pos, sampmap=:volts)))
@test c >= 0.99





#ao2 = getoutputs(getanalog(ocpi2))[2]
#ai = getinputs(getanalog(ocpi2))[3] #This is a generic input.  pos_mon currently has a problem with negative voltages
#ai2 = getinputs(getanalog(ocpi2))[4]

#nsamps_on = 10001
#nsamps_off = 10001
#nsamps_back_on = 10001
#nsamps = nsamps_on+nsamps_off+nsamps_back_on
#append!(pos, "on", fill(3.0*Unitful.V, nsamps_on))
#append!(pos, "off", fill(0.0*Unitful.V, nsamps_off))
#append!(pos, "back_on", fill(3.0*Unitful.V, nsamps_back_on))
#append!(ao2, "on2", fill(3.0*Unitful.V, nsamps_on))
#append!(ao2, "off2", fill(0.0*Unitful.V, nsamps_off))
#append!(ao2, "back_on2", fill(3.0*Unitful.V, nsamps_back_on))
#base_name = "" #"test_imaginectrl5"

#using Plots
#plot(ustrip(get_samples(sigs[1])))

#for testing
#tsk = prepare_ao(aos, 1000, "PFI1")
#tsk2 = prepare_ai(ais, 1000, 3003, "disable")
#After much pain, realized that can only synchronize start of AO and AI acq on usb 6xxx devices by using two different pfi channels
#NIDAQ.catch_error(NIDAQ.ExportSignal(tsk.th, NIDAQ.Val_StartTrigger, b"/Dev1/ai/StartTrigger"))
#rr2 = record_signals(base_name, ais, nsamps; trigger_terminal = "PFI1", run_locally = false)
#rr = output_signals(aos; trigger_terminal = "PFI0", run_locally = false)
#sleep(5.0)
#print("delivering pulses\n")
#ttl_pulse() #P0.0 is wired to PFI0
#(proc_id2, ai_sigs) = fetch(rr2)
#proc_id1 = fetch(rr)
#print("Freeing workers...\n")
#free_workers(proc_id1)
#free_workers(proc_id2)
##print("Loading ai file...\n")
##aidata = ImagineInterface.parse_ai(base_name*".ai", map(daq_channel, ais), "dummy-6002", srate)
#using Plots
#plot(ustrip(get_samples(sigs[1])))

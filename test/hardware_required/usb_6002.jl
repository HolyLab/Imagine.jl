using Unitful, ImagineInterface, Imagine
using Base.Test

srate = 5000*inv(Unitful.s) #this is the max AO rate for the device
dummy = rigtemplate("dummy-6002"; sample_rate = srate)
pos = getpositioners(dummy)[1]
ao2 = getoutputs(getanalog(dummy))[2]
#pos_mon = ImagineInterface.getpositionermonitors(dummy)[1]
ai = getinputs(getanalog(dummy))[3] #This is a generic input.  pos_mon currently has a problem with negative voltages
ai2 = getinputs(getanalog(dummy))[4]

nsamps_on = 10001
nsamps_off = 10001
nsamps_back_on = 10001
nsamps = nsamps_on+nsamps_off+nsamps_back_on
append!(pos, "on", fill(3.0*Unitful.V, nsamps_on))
append!(pos, "off", fill(0.0*Unitful.V, nsamps_off))
append!(pos, "back_on", fill(3.0*Unitful.V, nsamps_back_on))
append!(ao2, "on2", fill(3.0*Unitful.V, nsamps_on))
append!(ao2, "off2", fill(0.0*Unitful.V, nsamps_off))
append!(ao2, "back_on2", fill(3.0*Unitful.V, nsamps_back_on))
base_name = "" #"test_imaginectrl5"
aos = [pos;ao2]
ais = [ai;ai2]

sigs = run_imagine("", vcat(aos,ais); ai_trig_dest = "PFI1", ao_trig_dest = "PFI0", trigger_source = "Port0/Line0")

@test cor(ustrip(get_samples(sigs[1]; sampmap=:volts)), ustrip(get_samples(pos, sampmap=:volts))) >= 0.99

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

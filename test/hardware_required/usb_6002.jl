using Unitful, ImagineInterface, Imagine, Statistics
using Test

srate = 5000*inv(Unitful.s) #this is the max AO rate for the device
dummy = rigtemplate("dummy-6002"; sample_rate = srate)
pos = getpositioners(dummy)[1]
ao2 = getoutputs(getanalog(dummy))[2]
#pos_mon = ImagineInterface.getpositionermonitors(dummy)[1]
ai = getinputs(getanalog(dummy))[3] #AI2. note pos_mon currently has a problem with negative voltages
ai2 = getinputs(getanalog(dummy))[4] #AI3

#error()


nsamps_on = 10001
nsamps_off = 10001
nsamps_back_on = 10001
nsamps = nsamps_on+nsamps_off+nsamps_back_on
append!(pos, "on", fill(3.0*Unitful.V, nsamps_on))
append!(pos, "off", fill(0.0*Unitful.V, nsamps_off))
append!(pos, "back_on", fill(3.0*Unitful.V, nsamps_back_on))
#append!(ao2, "on2", fill(3.0*Unitful.V, nsamps_on))
append!(ao2, "off2", fill(0.0*Unitful.V, nsamps_off))
append!(ao2, "off2")
append!(ao2, "off2")
#append!(ao2, "back_on2", fill(3.0*Unitful.V, nsamps_back_on))
base_name = "" #"test_imaginectrl5"
aos = [pos;ao2]
ais = [ai;ai2]
#aos = [pos]
#ais = [ai]

#hardware setup:
# PFI1 <-> P0.0
# PFI2 <-> P0.0
# AO0 <-> AI2

sigs = run_imagine("",
		   vcat(aos,ais);
		   ai_trig_dest = "PFI1",
		   ao_trig_dest = "PFI0",
		   trigger_source = "Port0/Line0",
		   sync_clocks = false,
		   run_locally = false,
		   skip_validation = true)

@test Statistics.cor(ustrip.(get_samples(sigs[1]; sampmap=:volts)), ustrip.(get_samples(pos, sampmap=:volts))) >= 0.99

#using Plots
#plot(ustrip(get_samples(sigs[1])))

##for testing
#trigger_term_ao = "PFI0"
#trigger_term_ai = "PFI1"
#Imagine.ImagineWorker._set_device("Dev1/")
#tsk = Imagine.ImagineWorker.prepare_ao(aos, 1000, trigger_term_ao, "")
#tsk2 = Imagine.ImagineWorker.prepare_ai(ais, 1000, 3003, trigger_term_ai; clock_source="")
##After much pain, realized that can only synchronize start of AO and AI acq on usb 6xxx devices by using two different pfi channels
##NIDAQ.catch_error(NIDAQ.ExportSignal(tsk.th, NIDAQ.Val_StartTrigger, b"/Dev1/ai/StartTrigger"))
#rr2 = record_signals(base_name, ais, nsamps; trigger_terminal = trigger_term_ai, run_locally = false)
#rr = output_signals(aos; trigger_terminal = trigger_term_ao, run_locally = false)
#sleep(10.0)
#print("delivering pulses\n")
#Imagine.ttl_pulse(;line_name="Port0/line0") #P0.0 is wired to PFI0
#(proc_id2, ai_sigs) = fetch(rr2)
#ai_recs = fetch(ai_sigs[1])
#proc_id1 = fetch(rr[2][1])
#
#print("Freeing workers...\n")
#free_workers(proc_id1)
#free_workers(proc_id2)
##print("Loading ai file...\n")
##aidata = ImagineInterface.parse_ai(base_name*".ai", map(daq_channel, ais), "dummy-6002", srate)
#using Plots
#plot(ustrip(get_samples(sigs[1])))

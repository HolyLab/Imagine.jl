#Setup:
#Connect the BNCH that usually conntects to piezo MOD to the laser AOTF TTL.
#Connect the BNC that usually connects to piezo MON to the laser intensity meter.

#We will deliver 10 pulses each of these durations:
#   0.1s
#   0.01s
#   0.001s
#   0.0001s
#   0.00001s

#Re-run this script 10 times with different laser intensities: 10%, 20%...100%

using Unitful, ImagineInterface, Imagine
import Unitful:s, V

pct_intensity = 10 #percent laser intensity this round
srate = 300000*Unitful.s^-1
npulses_per_condition = 5

ocpi2 = rigtemplate("ocpi-2"; sample_rate = srate)
ao = getpositioners(ocpi2)[1]
ai = getname(ocpi2, monitor_name(ao))

pulse_durations = [1.0; 0.1; 0.01; 0.001; 0.0001; 0.00001] * Unitful.s
pulse_separations = pulse_durations
append!(ao, "nothing", fill(0.0V, 100000))

for (i,dur) in enumerate(pulse_durations)
    nsamps_on = ImagineInterface.calc_num_samps(dur, srate)
    nsamps_off = ImagineInterface.calc_num_samps(pulse_separations[i], srate)
    pt = typeof(0.0V)[]
    for p = 1:npulses_per_condition
        append!(pt, fill(3.3V, nsamps_on))
        append!(pt, fill(0.0V, nsamps_off))
    end
    append!(ao, "$(dur)_duration", pt)
end
    
outbasename = "laser_pct_$pct_intensity"
write_commands(outbasename*".json", ocpi2, 0, 0, 0.0s; isbidi = false, skip_validation=true)
sigs = run_imagine(outbasename, [ao;ai]; ai_trig_dest = "PFI2", ao_trig_dest = "PFI1", trigger_source = "Port2/Line0", skip_validation=true)

ai_sig = parse_ai(outbasename, ["AI0"], "ocpi-2", srate)
smps = get_samples(ai_sig; sampmap=:volts)

#c = cor(ustrip.(get_samples(sigs[1]; sampmap=:volts)), ustrip.(get_samples(pos, sampmap=:volts)))
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

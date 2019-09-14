# Imagine

This package was initially written to support iterative tuning of experimental parameters before running an experiment with [Imagine](https://github.com/HolyLab/Imagine.git).  However in the long term it could develop into an alternative version of Imagine that can run experiments on its own.  Below is what's needed to make that happen.

### Things that are working
- [x] Support executing analog input and output ImagineSignals (see [ImagineInterface](https://github.com/HolyLab/ImagineInterface.git)) with a National Instruments DAQ
- [x] Support streaming analog inputs to a ".ai" file
- [x] Create multi-processing framework for running all IO tasks on remote processes
- [x] Support buffered digital IO
- [x] Synchronize analog and digital input and output clocks when supported by the DAQ

### Things that no one is yet working on (each of these is a lot of work)
- [ ] Communicate with PCO cameras (read and write settings, manage recording state, stream frame data to ".cam" file)
- [ ] Create a GUI that at a minimum supports live image streaming and executing .json command files
- [ ] Lots more testing for each OCPI rig, or at least for the WUCCI OCPI

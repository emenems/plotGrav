FileTools
=========
Matlab GUI tool for processing & visualization of various time series.  
The toolbox was developed for processing of gravimeter time series but can be used for arbitrary input.  

This toolbox allows user to:
* load 4 different data files at once in diverse formats such as [TSoft](http://seismologie.oma.be/en/downloads/tsoft), GGP/[IGETS](http://gfzpublic.gfz-potsdam.de/pubman/faces/viewItemOverviewPage.jsp?itemId=escidoc:1870888), Campbell Logger, or [Dygraphs](http://dygraphs.com/tutorial.html) csv 
* export & print time series 
* use scripts (instead of GUI)
* compute statistics such as correlation
* apply ML methods such as regression or principle component analysis 
* apply corrections (e.g., steps, gaps)
* filter time series 
* compute spectral analysis
* do some algebra on all input series (e.g., add, subtract, divide time series)
* download & process [Atmacs](/http://atmacs.bkg.bund.de) atmospheric model data 
* compute polar motion and length of day gravity effect 
* introduce time shifts and re-sample the data (new temporal resolution) 
* automatically fill missing data (interpolate or set to constant)
* estimate gravimeter calibration parameters 
* superimpose plots with latest Earthquake records 
* stack multiple files into one (for gravimeter records)

### Usage
* Run `plotGrav.m` or see `plotGrav_TestScript.plg` for scripting 


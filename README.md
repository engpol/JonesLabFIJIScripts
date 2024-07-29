# JonesLabFIJIScripts
A place to store and update any and all macros used by the Jones Lab in microscopy image analysis

By default, macros will run in batch mode, meaning ImageJ will not open any images it is doing operations on. Don't worry they are still working. If for some reason, however, you want to see the process happen you'll have to turn batch mode off. To do so, you'll have to change setBatchMode (found towards the top of all macros) to false

You will need some additional ImageJ plugins to run these macros. To download them, open up Fiji/ImageJ then click "Help" -> "Update" -> "Manage Update Sites" -> tick the plugins you want to download -> "Apply and Close". You will need to restart Fiji/ImageJ for the plugins to load. The plugins you need are as follows:

1. BaSiC
2. CSBDeep
3. StarDist


<strong><h2>96-Well-Plate_Live_Cell Macro</strong></h2>

This is a general purpose macro, and can in theory be used for the vast majority of imaging experiments performed in 96-Well plates. Please read below for how to use. 

This one is a little bit complicated, and I'm afraid will require you to download the <a href="https://cran.rstudio.com/">R programming language</a> along with <a href="https://posit.co/download/rstudio-desktop/">RStudio</a>. This shouldn't be too hard, and there are plenty of YouTube tutorials online for every type of OS. 

Apologies for this, for some reason although ImageJ macro in theory supports R scripts, I think this would require everyone to redownload a special release of ImageJ (Bio7) or R itself anyway (Rserve), and as I'm not too familiar with Python (which seems to have much greaater support in ImageJ) this might have to do for now. In the future I might re-write this so everything works from within ImageJ, which would be nice.

After you have succesfully downloaded R and RStudio onto your computer;

Download the "96_Well_Plate_Live_Cell_Fluoresence_Imaging_Macro.ijm" and "For_Well_Analysis_Macro.R".

Open the "96_Well_Plate..." ImageJ macro within ImageJ/Fiji (Make sure you have the required plugins installed as outlined on the top of this README)

Select your experiment folder (folder containing the image stack), and supply information regarding your experiment (Number of wells, timepoints, if you want to correct for drift etc. etc. -  If your experiment only has one channel, please untick the "Use Independent Mask for each Channel" box). 

After this, the Macro will ask you to name the channels from your experiments. (To help you, the macro will open up an example image from each channel)

<b>VERY IMPORTANT</b> - If one of your channels is brightfield, please ensure you name it "Brightfield" - spelled correctly in full.

Provided you have left the "Indepent Mask" box unchecked, the Macro will ask you which Channel you would like to use as a "Mask" - i.e. which channel will be used to segment the cell containing regions. If you have selected Brightfield as your mask, the Macro will use Phantast, otherwise StarDist will be used instead.

After all information fields have been correctly filled, press run. Please give it time, for very large experiments it can take around 5ish minutes to finish running, make sure your laptop doesn't go to sleep.

After the macro is finished running, you should find several folders in your experimental folder. If you have multiple channels, you should see a folder for each channel, inside of which you will find two more folders; "Well Averages" and "Individual Wells". (The first time you test this macro out, I would recommend checking the number of files/folders within matches your number of wells, as a sanity check and to make the macro has worked as intended).

Now open up the "For_Well_Analysis_Macro.R" script in RStudio

Press Ctrl + Shift + Enter

A pop-up menu should show up asking you to select a folder

Select your experiment folder (the same one you selected for the ImageJ macro), and your code should finish running basically instantly

In your experiment folder, you should find a file called "Results_Conc.csv" which will have your final results - This should already be formatted into 4 columns (Well ID, Timepoint, average intensity for the well, and the imaging Channel), ready for you to import into GraphPad prism and plot/analyse. If you would like the un-averaged data for each well+FOV instead of the averages for each well instead, you should find a second csv called "Results_Conc_No_Average.csv", so simply use that one instead.

That should be everything! Please let me know if you would like me to implement any further changes to the Macro, you have any problems following this guide along!

<strong><h2>Receptor_Expression Macro</strong></h2>

Open the macro within ImageJ/Fiji.

Under the "Experiment folder" box click browse and select the folder containing all the experiments you want to analyse. If you only want to analyse one experiment, you still have to make sure the experiment is in its own folder, and select the folder containing the experiment, not the experiment itself.

Then, select whichever Sigma and Epsilon values for PHANTAST you want the macro to use. The values Ben suggested will always be used as default if you don't want them to change.

If your fluorescence channel is in channel 2 as opposed to 1 as it usually is, you can change it using the slider at the bottom.

Then press ok. 

Once the Macro is finished running, it will save your results to a CSV file in every experimental folder titled "Results".

<strong><h2>MESNA Macro</strong></h2>

This macro is for analysing MESNA experiments (i.e. where you want to see difference in fluorescence intensity of cell containing regions before and after administration of some condition. The only key difference here is to select the order of channels. This macro again expects a single image stack. I've had quite a lot of issue with memory leak writing this macro, which I think is caused by running BaSiC on an interleaved stack possibly? I don't what else could have caused it. 

<strong><h2>Live Cell Imaging Macro</strong></h2>

This Macro is for analysing live cell imaging experiments looking at quantifying fluoresence intensity from the cell soma - e.g. Calcium/cAMP(CADDIS) imaging. For it to work off the bat, it expectes a timeseries of N x N grid of fluorescent images. Also, this macro is run on a folder containing single experiment, unlike the receptor expression macro I've written above, so you'll need to run it as a batch process to run it on several experiments. Going forward, I think this makes more sense as it will save shuffling experiments around folders in case you only want to analyse one experiment.

Open the macro within ImageJ/Fiji

Under the "Experiment folder" box click browse and select the folder containing the image stack (.tiff files) of the experiment you want analyse.

Select the number of FOVs (i.e. if you created a 7x7 grid, it would be 49 - For the now the max number of FOVs it accepts is 99, please let me know if you need more than this for some reason), and the number of timepoints.

If you would like to include SIFT drift correction, tick the box at the bottom. I've found running drift correction on experiments which have little to no drift makes the output worse, so I would only tick this if you have to.

Press Run.

Once it has finished running, in the experiment folder all the individual FOVs will be found in the "Individual_FOV" folder, ROIs for the segmented neurons will be in the "StarDistROI" folder, and the fluorescence intensity time series values for the different neurons will be in the "Results" folder. 

<b>IMPORTANT - PLEASE READ</b>

1. The Results are saved in seperate CSV files for each FOV in the Results folder. You can very easily combine them into 1 using not very much R/Python, however combining them in ImageJ would require some additional Jython code which would have to be a seperate Macro. Will probably add this in the future if anyone else decides to use this code and wants to import Results dircetly into GraphPad Prism, however please be aware, as doing this manually would be hell and could lead you to accidently deleting data.

2. By default, this Macro does not perform any filtering on the ROIs (such as for ROI size/presence of control peak etc.) so as to not generate data destructively to save you time having to re-run the macro again. So, YOU WILL HAVE TO FILTER THE RESULTS YOURSELF IN GRAPHPAD/R/WHATEVER SOFTWARE YOU DO ANALYSIS IN. You can add these filters directly into this macro, however this will require a bit of fudging the code so either do this yourself and committ the updated version here (I've added an idea by which this could be coded in the comments), or let me know if this is something you want and I'll find the time to write this myself. If you update the code yourself please update this README.md file to let people know. 


<strong><h2>Stardist Test Macro</strong></h2>

Simple macro which has to be ran on a live cell fluoresence intensity time series from a single FOV. Re-runs StarDist using 20 different values for ProbThreshold, and saves them as an imagestack in a folder called "STARDIST_OUTPUT" so that you can see which values give the best result for your microscopy data. If you want to use the "Live Cell Imaging Macro" on your own microscopy data, at different magnifications/LED power settings, you might have to use this to play around to see which settings work best.


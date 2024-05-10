# JonesLabFIJIScripts
A place to store and update any and all macros used by the Jones Lab in microscopy image analysis

By default, macros will run in batch mode, meaning ImageJ will not open any images it is doing operations on. Don't worry they are still working. If for some reason, however, you want to see the process happen you'll have to turn batch mode off. To do so, you'll have to change setBatchMode (found towards the top of all macros) to false

You will need some additional ImageJ plugins to run these macros. To download them, open up Fiji/ImageJ then click "Help" -> "Update" -> "Manage Update Sites" -> tick the plugins you want to download -> "Apply and Close". You will need to restart Fiji/ImageJ for the plugins to load. The plugins you need are as follows:

1. BaSiC
2. CSBDeep
3. StarDist

<strong><h2>Receptor_Expression Macro</strong></h2>

Open the macro within ImageJ/Fiji.

Under the "Experiment folder" box click browse and select the folder containing all the experiments you want to analyse. If you only want to analyse one experiment, you still have to make sure the experiment is in its own folder, and select the folder containing the experiment, not the experiment itself.

Then, select whichever Sigma and Epsilon values for PHANTAST you want the macro to use. The values Ben suggested will always be used as default if you don't want them to change.

If your fluorescence channel is in channel 2 as opposed to 1 as it usually is, you can change it using the slider at the bottom.

Then press ok. 

Once the Macro is finished running, it will save your results to a CSV file in every experimental folder titled "Results".

<strong><h2>Live Cell Imaging Macro</strong></h2>

This Macro is for analysing live cell imaging experiments looking at quantifying fluoresence intensity from the cell soma - e.g. Calcium/cAMP(CADDIS) imaging. For it to work off the bat, it expectes a timeseries of N x N grid of fluorescent images. Also, this macro is run on a folder containing single experiment, unlike the receptor expression macro I've written above, so you'll need to run it as a batch process to run it on several experiments. Going forward, I think this makes more sense as it will save shuffling experiments around folders in case you only want to analyse one experiment.

Open the macro within ImageJ/Fiji

Under the "Experiment folder" box click browse and select the folder containing the image stack (.tiff files) of the experiment you want analyse.

Select the number of FOVs (i.e. if you created a 7x7 grid, it would be 49 - For the now the max number of FOVs it accepts is 99, please let me know if you need more than this for some reason), and the number of timepoints.

Press Run.

Once it has finished running, in the experiment folder all the individual FOVs will be found in the "Individual_FOV" folder, ROIs for the segmented neurons will be in the "StarDistROI" folder, and the fluorescence intensity time series values for the different neurons will be in the "Results" folder. 

<b>IMPORTANT - PLEASE READ</b>

1. The Results are saved in seperate CSV files for each FOV in the Results folder. You can very easily combine them into 1 using not very much R/Python, however combining them in ImageJ would require some additional Jython code which would have to be a seperate Macro. Will probably add this in the future if anyone else decides to use this code and wants to import Results dircetly into GraphPad Prism, however please be aware, as doing this manually would be hell and could lead you to accidently deleting data.

2. By default, this Macro does not perform any filtering on the ROIs (such as for ROI size/presence of control peak etc.) so as to not generate data destructively to save you time having to re-run the macro again. So, YOU WILL HAVE TO FILTER THE RESULTS YOURSELF IN GRAPHPAD/R/WHATEVER SOFTWARE YOU DO ANALYSIS IN. You can add these filters directly into this macro, however this will require a bit of fudging the code so either do this yourself and committ the updated version here (I've added an idea by which this could be coded in the comments), or let me know if this is something you want and I'll find the time to write this myself. If you update the code yourself please update this README.md file to let people know. 


<strong><h2>Stardist Test Macro</strong></h2>

Simple macro which has to be ran on a live cell fluoresence intensity time series from a single FOV. Re-runs StarDist using 20 different values for ProbThreshold, and saves them as an imagestack in a folder called "STARDIST_OUTPUT" so that you can see which values give the best result for your microscopy data. If you want to use the "Live Cell Imaging Macro" on your own microscopy data, at different magnifications/LED power settings, you might have to use this to play around to see which settings work best.


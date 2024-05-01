# JonesLabFIJIScripts
A place to store and update any and all macros used by the Jones Lab in microscopy image analysis

<strong><h2>Receptor_Expression Macro</strong></h2>

Open the macro within ImageJ/Fiji.

Under the "Experiment folder" box click browse and select the folder containing all the experiments you want to analyse. If you only want to analyse one experiment, you still have to make sure the experiment is in its own folder, and select the folder containing the experiment, not the experiment itself.

Then, select whichever Sigma and Epsilon values for PHANTAST you want the macro to use. The values Ben suggested will always be used as default if you don't want them to change.

If your fluorescence channel is in channel 2 as opposed to 1 as it usually is, you can change it using the slider at the bottom.

Then press ok. 

Once the Macro is finished running, it will save your results to a CSV file in every experimental folder titled "Results".

By default, the macro will run in batch mode, meaning ImageJ will not open any images it is doing operations on. Don't worry its still working. If for some reason, however, you want to see the process happen you'll have to turn batch mode off. To do so, you'll have to change setBatchMode (found towards the top) to false

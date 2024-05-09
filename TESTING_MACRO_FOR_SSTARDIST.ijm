//Testing for different STARDISTS settings for our microscopy data
//Feel free to re-run when testing for your microscopy data
// - - - - - - - -- - -
//Parameters
#@ File(label="Experiment Folder", value = "C:/", style="directory") exfolder
#@ Integer (label="Number of FOVs", value = 49, style="spinner", min = 1, max = 1000) FOV_number
#@ Integer (label="Number of Timepoints", value = 16, style="spinner", min = 1, max = 1000) timepoint_number

run("Fresh Start");
File.mkdir(exfolder + File.separator + "/STARDIST_TEST_OUTPUT"); //Make a folder to hold folders for STARDIST OUTPUT
setBatchMode(false);
	File.openSequence(exfolder,"step=1");
	run("Duplicate...", "title=TEST duplicate range="+timepoint_number);

myarray = newArray(0.051,0.11,0.151,0.201,0.251,0.301,0.351,0.451,0.501,0.551,0.601,0.651,0.701,0.751,0.801,0.851,0.901,0.951,1);


for (i = 0; i < 20; i+=1) {
	selectImage("TEST");
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'TEST', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.8', 'percentileTop':'99.60000000000001', 'probThresh':'"+myarray[i]+"', 'nmsThresh':'0.05', 'outputType':'Label Image', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	selectImage("Label Image");
	save(exfolder + File.separator + "STARDIST_TEST_OUTPUT" + File.separator +"STARDIST_THRESH_"+myarray[i]+"_TEST.tiff");
	selectImage("Label Image");
	print(myarray[i]);
	close();
}


//Seems to be 0.45 is a good value for threshold for our microscopy data, may need to try more on my neurons, as Ionas do vary slightly

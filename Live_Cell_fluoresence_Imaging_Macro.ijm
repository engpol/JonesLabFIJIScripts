//MACRO FOR ANALYSING CADDIS/CALCIUM IMAGING DATA FEATURING FLUORESCENT SOMA
//GENERAL PRINCIPLE:
//1: IMPORT STACK OF NxN GRID MICROSCOPY IMAGES
//2: COMPUTE THE BASIC PROFILE BASED ON SUBSTACK OF IMAGES - TO AID WITH PROCESSING SPEED - THANKS IONA
//3: RUN BASIC PROFILE ON ORIGINAL STACK TO PERFORM BACKGROUND CORRECTION
//4: DEINTERLEAVE GRID STACK INTO X DIFFERENT STACKS BASED ON NUMBER OF FOV
//5: SAVE EACH DEINTERLEAVED STACK INTO ITS OWN FOLDER WITHIN EXPERIMENT FOLDER; CLOSE ALL IMAGES
//6: CREATE A FOR LOOP TO IMPORT ALL FOVS AND FOR EACH:
//   - RUN STARDIST TO CREATE ROIS AROUND FLUORESCENT CELLS (SETTINGS TO BE CALIBRATED TO EXCLUDE TOO LARGE/SMALL CELLS) - USE FINAL IMAGE OF STACK TO GENERATE (ADD AS PARAMETER), WILL HAVE THE GREATEST CONTRAST
//   - DO A NESTED FOR LOOP TO LOOP THROUGH ROIS/NEURONS GENERATED BY STARDIST AND FOR EACH:
//             - TAKE A MEASUREMENT OF MEAN AT START AND MEAN AT GIVEN POSITION (1?) ADD TO AN EMPTY ARRAY (TO_DELETE) IF IS NOT AT LEAST 1.25 X GREATER FLUORESENCE (I.E. REMOVE NEURONS WHICH DONT RESPOND TO CONTROL FLUX AT END OF EXPERIMENT)
//             - DELETE ROIS AT GIVEN POSITION
//             - RENAME ROIS/TAKE MEASUREMENTS AND SAVE TO MEASUREMENTS FOLDER
// 


//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
//Global Parameters 
//- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - -- - - - -- -- - - - - - --
#@ File(label="Experiment Folder", value = "C:/", style="directory") exfolder
#@ Integer (label="Number of Timepoints", value = 16, style="spinner", min = 1, max = 100) timepoint_number
#@ Integer (label="Number of FOVs", value = 49, style="spinner", min = 1, max = 100) FOV_number

run("Fresh Start"); //ALWAYS INCLUDE
setBatchMode(true); //"TRUE" FOR FASTER PROCESSING
run("Set Measurements...", "area mean limit display redirect=None decimal=2"); //Having the right measurements for collecting data - change here if you want to collect any more data

//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -

function ImageFilesOnlyArray (arr) {
	//pass array from getFileList through this e.g. NEWARRAY = ImageFilesOnlyArray(NEWARRAY);
	setOption("ExpandableArrays", true);
	f=0;
	files = newArray;
	for (i = 0; i < arr.length; i++) {
		if(endsWith(arr[i], ".tif") || endsWith(arr[i], ".nd2") || endsWith(arr[i], ".LSM") || endsWith(arr[i], ".czi") || endsWith(arr[i], ".jpg") ) {   //if it's a tiff image add it to the new array
			files[f] = arr[i];
			f = f+1;
		}
	}
	arr = files;
	arr = Array.sort(arr);
	return arr;
}

//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// - VARIABLES 
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - --

FOV_filelist = getFileList(exfolder);
onlyimages = ImageFilesOnlyArray(FOV_filelist);


// - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - --  - - - -- -- - - - - - --
// CODE 
// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --
// BACKGROUND SUBTRACTION AND SPLITTING STACK INTO SEPERATE FOVS
// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --



//print(lengthOf(filelist));
//print(lengthOf(onlyimages)); 

File.openSequence(exfolder,"step=1"); //Import the Experiment Image Stack
rename("expt"); 
run("Slice Keeper", "first=1 last="+FOV_number*timepoint_number+" increment="+(timepoint_number-2)+""); //Ionas idea, make a subset of the stack to compute the BASIC shading profile on, use on full stack after compute - saves run time. Use a smaller increment to timepoint so as to not use only the first frame from each FOV
selectImage("expt kept stack");
run("BaSiC ", "processing_stack=[expt kept stack] flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Manual temporal_drift=Ignore correction_options=[Compute shading only] lambda_flat=4 lambda_dark=0.50"); //Compute shading profile based on the stack subset, you will use this to generate the flat field which will then be ran on the entire experiment stack
selectImage("Flat-field:expt kept stack");
run("BaSiC ", "processing_stack=[expt] flat-field=[Flat-field:expt kept stack] dark-field=None shading_estimation=[Skip estimation and use predefined shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=[Replace with zero] correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50"); //Compute shading profile for entire stack
selectImage("Corrected:expt");
close("\\Others");
run("Add...", "value=1 stack"); //Add 1 to all pixel values as bg has been set to 0 and want to avoid diving by 0 later when calculating dF/F0
rename("Corrected_Flo_Image");
File.mkdir(exfolder + File.separator + "/BaSic_Corrected_Stack"); //Make folder to store Background corrected image stack
selectImage("Corrected_Flo_Image");
//saveAs("Corrected_Flo_Image.tiff", exfolder + File.separator + "/BaSic_Corrected_Stack" + File.separator + "Corrected_Flo_Image.tiff"); //Save Background corrected image stack
run("Image Sequence... ", "dir="+exfolder+File.separator+"/BaSic_Corrected_Stack"+File.separator+" format=TIFF"); //Save the Basic Output as an image stack
File.mkdir(exfolder + File.separator + "/Individual_FOV"); //Make a folder to hold folders for individual FOVs
run("Stack Splitter", "number="+FOV_number);
// - - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - 
//FOR LOOP TO SAVE EACH FOV IN SEPERATE FOLDER - If you have more than 99 FOVs you will need to update this/find a general solution however for now i cba
// - - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - 

for (i = 0; i < FOV_number; i++) { //Loop through each split stack
File.mkdir(exfolder + File.separator + "/Individual_FOV" + File.separator + "FOV_Number_"+(i+1)+""); //Make a folder for the active FOV
if (i < 9){ //Has to be done as for i less than 10 as i will be single digit- i.e. 0001 vs 0010
selectImage("stk_000"+(i+1)+"_Corrected_Flo_Image");
run("Image Sequence... ", "dir="+exfolder + File.separator + "/Individual_FOV" + File.separator + "FOV_Number_"+(i+1)+""+" format=TIFF");
}else {
selectImage("stk_00"+(i+1)+"_Corrected_Flo_Image");
run("Image Sequence... ", "dir="+exfolder + File.separator + "/Individual_FOV" + File.separator + "FOV_Number_"+(i+1)+""+" format=TIFF");
 }
}
close("*"); //Close all open image windows 

// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --
// RUN STARDIST ON EACH FOV, FILTER FOR AVERAGE SIZE, FLUORESENCE DIFFERENCE BETWEEN FIRSST FRAME AND LAST FRAME (CONTROL KCL/FSK ETC.). DELETE ROIS WHICH DONT FIT THE FILTERS 
// My own experiments (on Ionas data) suggest these settings for StarDist to be the best: Percentile Low: 0.08, Percentile High: 99.6, Prob Threshold: 0.45, NMS Threshold: 0.05
// Re-run the TESTING MACRO for all microscopy images to find best settings for Prob Threshold.
// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --

File.mkdir(exfolder + File.separator + "/ResultsTables");
File.mkdir(exfolder + File.separator + "/StarDistROI");

for (i = 0; i < FOV_number; i++) {
    File.openSequence(exfolder + File.separator + "/Individual_FOV" + File.separator + "FOV_Number_"+(i+1)+"","step=1");
	//run("Duplicate...", "title=TEST duplicate range="+timepoint_number); //Take the last image of the experiment to run the StarDist model on, if for some reason the brightest image isnt the final frame, then idk but you'll have to change this perhaps add a parameter specifying the timpoint of maximal fluorescence. Or alternatively add a final frame of maximal excitation or something like that? - Ben suggested using a Max Intensity Projection - GREAT IDEA IMPLEMENT ONCE CONFIRMED VERSION ONE IS EFFECTIVE 
    run("Z Project...", "projection=[Max Intensity]"); //Perform max intensity projecction to run the StarDist macro on, to correct for any slight drift that might have occured
    selectImage("MAX_FOV_Number_"+(i+1)); //select max intensity projection image
    rename("TEST"); //rename to common name cause cba to change code below - targeted by StarDist
    run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'TEST', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.8', 'percentileTop':'99.60000000000001', 'probThresh':'0.45', 'nmsThresh':'0.05', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	to_be_deleted = newArray(); //Make an empty array, to which will be added ROIS which don't pass the filter requirements
	n = roiManager('count'); //n is equal to the number of ROIS in Roi Manager
	selectImage("FOV_Number_"+(i+1));
	
	if (n > 0) { //If there are no valid ROIs generated by StarDist, Multi_Measure will fail as there will be no ROIS to measure. 
		         //This will still bug out if there are ROIS generated by StarDist, however they get deleted by filters, 
		         //solution is to either perform filtering outside the macro, or a really messy thing where you add a temporary ROI to all images
		         //which is then deleted before renaming and saving. First one would probably be better
		
//for (g = 0; g < n; g++) { //NESTED FOR LOOP - FOR EACH ROI GENERATED BY STARDIST - take measurement and apply relevant filters
//    roiManager('select', g);
//    roiManager("Multi Measure");
//    mean1 = getResult("Mean1", (timepoint_number-1));
//    mean2 = getResult("Mean1", 1);
//    area = getResult("Area1", 1);
//    if (mean1 < 1.5*mean2) { //1.5 - 6 x fold change is expected
//    	 to_be_deleted = Array.concat(to_be_deleted, g); 
//    }
//    if (area > 350) { //Might have to change Area values depending on your microscopy - don't think it warrants a parameter tbh (not easily distinguishable from within macro) - maybe a variable???
//    	 to_be_deleted = Array.concat(to_be_deleted, g);
//    }
//}

//roiManager("Select", to_be_deleted); //Select ROIS which dont pass filter requirements
//roiManager("Delete"); //Delete said ROIS
j = roiManager('count'); 

for (k = 0; k < j; k++) { //ROI renaming loop Neuron_1, Neuron_2 etc.
    roiManager('select', k); 
    roiManager("Rename", "Neuron_"+(k+1));
    roiManager("save", exfolder + File.separator + "/StarDistROI" + File.separator + "FOV_Number_"+(i+1)+"_StarDist_ROI.zip");
}

roiManager("deselect"); //I think i remember this makes it select all ROIS for some reason as there is no call for selecting all ROIS
roiManager("multi measure"); //I dont remember the difference exactly (think one measures only one ROI and one does all ROIS) but multi measure and Multi Measure (with capitals) are different ROImanager functions, so don't use these interchangebly!!!!!
saveAs("Results", exfolder + File.separator + "/ResultsTables" + File.separator + "FOV_Number_"+(i+1)+"_Results.csv"); //Save Results within folder

}
	
close("*");
roiManager("reset"); //Delete ROIS from roiManager
}


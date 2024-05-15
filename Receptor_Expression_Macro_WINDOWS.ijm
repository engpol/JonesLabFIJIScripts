//MACRO FOR DETERMINING SURFACE RECEPTOR EXPRESSION ACROSS ALL CELLS IN WELL
//GENERAL PRINCIPLE: 
// 1: SPLIT STACK IN 2: 1 FOR BRIGHTFIELD, 1 FOR FLUORESCENCE INTENSITY
// 2: RUN BASIC ON FLUORESENCE STACK TO CORRECT FOR ILLUMINATION DISCREPANCY
// 3: RUN PHANTAST ON BF TO GENERATE MASK OF CELLS
// 4. MULTIPLY FLUORESENCE STACK BY PHANTAST MASK TO GENERATE A READOUT OF AVERAGE SURFACE EXPRESSION
// 5. SAVE OUTPUT IN CSV/EXCEL FILE


//IN CASE ANY FUNCTION DOESN'T WORK BECAUSE CREATING FOLDERS INSIDE FOLDERS ALREADY CONTAINING TIFF IMAGES - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -
//FUNCTION TAKES AN ARRAY AND ONLY RETURNS ELEMENTS WHICH ARE TIFF IMAGES - I.E. ONLY ACCEPTS MICROSCOPY IMAGES AND IGNORES OTHER RANDOM STUFF

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

//Parameters 
#@ File(label="Experiment folder", value = "C:/", style="directory") exfolder
#@ Float (label="PHANTAST Sigma", value = 4, style="spinner") sigmaint
#@ Float (label="PHANTAST Epsilon", value = 0.5, style="spinner") epsiint
#@ Integer (label="Select Fluorescent Channel", value = 1, style="slider", min = 1, max = 2) flochannel


run("Fresh Start"); //ALWAYS INCLUDE
setBatchMode(true); //"TRUE" FOR FASTER PROCESSING

//Variable for selecting BF channel based on user input for the fluorescence channel
if(flochannel == 1) {
bfchannel = 2;
}else {
bfchannel = 1;
 }

//Cycle through all experiments in folder
filelist = getFileList(exfolder); //Get names of all experiment folders in the main folder
for (i = 0; i < lengthOf(filelist); i++) {
	run("Fresh Start");
	close("*");
	//Make all folders - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	File.mkdir(exfolder + File.separator + filelist[i] + "/Brightfield_Stack"); //Make folder for Brightfield Images in current experiment folder
	File.mkdir(exfolder + File.separator + filelist[i] + "/Phantast_Output"); //Make folder for Phantast Output in current experiment folder
	File.mkdir(exfolder + File.separator + filelist[i] + "/Results"); //Same for results
	results_dir = ""+exfolder+File.separator+filelist[i]+"Results"+""; // same for results
	bf_dir = ""+exfolder+File.separator+filelist[i]+"Brightfield_Stack"+""; //For some reason saving the image sequence command only works if I set the file path as a variable beforehand idk
	phantas_dir = ""+exfolder+File.separator+filelist[i]+"Phantast_Output";
	File.mkdir(exfolder + File.separator + filelist[i] + "/BaSic_Image"); //Make folder for BaSic image to save re-importing image sequence 
	basic_dir = ""+exfolder+File.separator+filelist[i]+"BaSic_Image"+""; //See below
	// - - - - -  - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	File.openSequence(exfolder + File.separator + filelist[i]); //Import image sequence
	rename("expt"); 
	run("Deinterleave", "how=2"); //Split bf and fluoresence stacks
	selectImage("expt #"+bfchannel);
	run("32-bit"); //Convert to 32-bit image for PHANTAST
	run("Image Sequence... ", "dir="+bf_dir+" format=TIFF name=BF");
	selectImage("expt #"+flochannel);
	run("BaSiC ", "processing_stack=[expt #"+flochannel+"] flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Manual temporal_drift=[Replace with zero] correction_options=[Compute shading and correct images] lambda_flat=5 lambda_dark=0.50");  //Run BaSic correction on fluoresence intensity data
	//Close all unimportant windows - - - - - - - - - -
	selectImage("Basefluor");
	close();
	selectImage("Flat-field:expt #"+flochannel);
	close();
	selectImage("expt #"+flochannel);
	close();
	//- - - - - - - - - - - - - - - - - - - - - - - - - - 
	selectImage("Corrected:expt #"+flochannel);
	rename("Corrected_Flo_Image");
	run("Add...", "value=1 stack"); //Add 1 to all pixel values as bg has been set to 0 and want to avoid multiplying by 0 later
	save(basic_dir + File.separator + "Corrected_Flo_Image.tiff"); //Save BaSic image to folder
	close("*");
	phantas_loop = getFileList(bf_dir); //List of all BF images to loop through, run PHANTAS on, and save to PHANTAS folder
	for (j = 0; j < lengthOf(phantas_loop); j++) {
		open(bf_dir+File.separator+phantas_loop[j]); //Open the jth file in the brightfield folder
		rename("Active"+(j)+""); //rename to a convention ActiveBF001 etc.
		run("PHANTAST", "sigma="+sigmaint+" epsilon="+epsiint+" do new"); //Run PHANTAST on open image with sigma and epsilon
		selectImage("PHANTAST - Active"+(j)+""); 
		save(phantas_dir + File.separator + "PHANTAST - Active"+(j)+".tiff"); //Save image to new Phantast_Output folder
		close("*");
	} 
	close("*"); //Justs in case something straggles behind
	//Place to put Debugging commands IGNORE  -- - - -   -- - - -   -- - - -   -- - - -   -- - - -   -- - - -   -- - - -   -- - - -   -- - - -   -- - - - 
	//  - - - - - - - --   -- - - -   -- - - -   -- - - -   -- - - -   -- - - -   -- - - -   -- - - -  
	File.openSequence(phantas_dir); //Import image sequence containing PHANTAS images
	rename("PHANTAST");
	selectImage("PHANTAST");
	run("Invert", "stack"); //Invert PHANTAST stack so cell containing regions are 255 (in 32 bit) and background is 0
	run("Divide...", "value=255 stack"); //Divide by 255 so cell containing regions are 1 and background is 0. Now is a true mask of cell regions
	open(basic_dir + File.separator + "Corrected_Flo_Image.tiff"); //Open background corrected fluoresence data
	imageCalculator("Multiply create stack", "BaSic_Image"+File.separator+"Corrected_Flo_Image.tiff","PHANTAST"); //Multiply Fluoresence stack by mask so only fluoresence from cell containing regions is included
	selectImage("Result of BaSic_Image"+File.separator+"Corrected_Flo_Image.tiff"); //Select output of multiplication
	run("Enhance Contrast", "saturated=0.35"); //? - ask ben, i guess just for maximising bright regions
	setAutoThreshold("Default dark"); //Visualisation?
	setThreshold(1, 65535, "raw"); 
	run("Set Measurements...", "area mean limit display redirect=None decimal=2"); //Set measurements to save from final iamge stack
	run("Measure Stack..."); //obtain results
	selectWindow("Results");
	saveAs("Results.csv",  results_dir + File.separator + "Results.csv"); //Save results as .csv file
}





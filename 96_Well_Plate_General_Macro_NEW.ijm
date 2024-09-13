//MACRO FOR ANALYSING CADDIS/CALCIUM IMAGING DATA FEATURING FLUORESCENT SOMA IN 96 WELL PLATE
//GENERAL PRINCIPLE:
//1: DEFINE HOW MANY WELLS, FOV AND TIME POINTS PRESENT IN EACH WELL
//1: IMPORT STACK OF NxN GRID MICROSCOPY IMAGES
//2: COMPUTE THE BASIC PROFILE BASED ON SUBSTACK OF IMAGES - TO AID WITH PROCESSING SPEED - THANKS IONA
//3: RUN BASIC PROFILE ON ORIGINAL STACK TO PERFORM BACKGROUND CORRECTION
//4: DEINTERLEAVE GRID STACK INTO X DIFFERENT STACKS BASED ON NUMBER OF FOV + WELLS + TIME
//5: SAVE EACH DEINTERLEAVED STACK INTO ITS OWN FOLDER WITHIN EXPERIMENT FOLDER; CLOSE ALL IMAGES
//6: CREATE A FOR LOOP TO IMPORT ALL FOVS AND FOR EACH:
//   - RUN STARDIST TO CREATE ROIS AROUND FLUORESCENT CELLS (SETTINGS TO BE CALIBRATED TO EXCLUDE TOO LARGE/SMALL CELLS) - USE FINAL IMAGE OF STACK TO GENERATE (ADD AS PARAMETER), WILL HAVE THE GREATEST CONTRAST
//   - DO A NESTED FOR LOOP TO LOOP THROUGH ROIS GENERATED BY STARDIST AND FOR EACH:
//             -TURN INTO A MASK BY CREATING A HYPERSTACK OF EQUAL DIMENSIONS, CLICKING FILL, DIVIDING BY MAX PIX INTENSITY AND MULTIPLYING BY ORIGINAL STACK
//             -LOOPING THROUGH ALL SLICES, AND TAKING AVERAGE MEASUREMENT
// 


//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
//Global Parameters 
//- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - -- - - - -- -- - - - - - --
#@ File(label="Experiment Folder", value = "C:/", style="directory") exfolder
#@ Integer (label="Number of Timepoints", value = 16, style="spinner", min = 1, max = 1000) timepoint_number
#@ Integer (label="Number of Channels", value = 1, style="spinner", min = 1, max = 9) Channel_number
#@ Integer (label="Number of FOVs", value = 49, style="spinner", min = 1, max = 99) FOV_number
#@ Integer (label="Number of Wells", value = 49, style="spinner", min = 1, max = 99) well_number
#@ boolean (label = "Correct for Drift with SIFT?") Drift_check
#@ boolean (label = "Use Indepenent Masks for Each Channel?") mask_check

run("Fresh Start"); //ALWAYS INCLUDE
setBatchMode(false); //Leave here as false, important for choosing channels later
setOption("ExpandableArrays",true) //only switch on before and after using the natural_sort func - don't know if it will mess with other arrays
run("Set Measurements...", "area mean display redirect=None decimal=2"); //Having the right measurements for collecting data - change here if you want to collect any more data

//Bullshittery for single timepoint -- - - - - -  - -- -- - - - - - -- -- - - - - -- -- - - - - - -- -- - - - - -- -- - - - - - -- -- - - - - -- -- - - - - - -- -- - - - - -- -- - - - - - -- -- - - - 
if (timepoint_number == 1) { //could have simply done this in code but cant be bothered to change now and it doesnt change anything so oh well. Might as well leave
timepoint_check = false;
real_timepoint_number = 2;
}else{
timepoint_check = true;
real_timepoint_number = timepoint_number;
}
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
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
	
	
	
	function natural_sort(a) { //Essentially a natural sort func for ImageJ - use in strings containing numbers - didnt end up using but useful so will leave here
	arr2 = newArray(); //return array containing digits
	for (i = 0; i < a.length; i++) {
		str = a[i];
		digits = ""; 
		for (j = 0; j < str.length; j++) {
			ch = str.substring(j, j+1);
			if(!isNaN(parseInt(ch)))
				digits += ch;
		}
		arr2[i] = parseInt(digits);
	}
	return arr2;
}
}

//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// - VARIABLES 
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - --

length_filelist = getFileList(exfolder);
images_only = ImageFilesOnlyArray(length_filelist);
filelist_Length = lengthOf(length_filelist);
total_image_number = real_timepoint_number*FOV_number;

Dialog.createNonBlocking("Channel Info"); //Create a dialog box to get names of each channel - will open an image and split it to make it easier to label
open(exfolder + File.separator + images_only[1]);
rename("Channel");
if (Channel_number > 1) {
run("Deinterleave", "how="+Channel_number);
}
Dialog.addMessage("Please write down labels for each channel");
for (i = 1; i <= Channel_number; i++) {
	Dialog.addString("Channel "+i+" Name ?", "GFP");
}
Dialog.show();
Channel_label_array = newArray(Channel_number); //Turn labels into a string array with user input channel labels
for (i = 0; i < Channel_number; i++) {
	temp_string = Dialog.getString();
	Channel_label_array[i] = temp_string;
}

if (mask_check == false) { //Get user input on which channel should be used to create an ROI mask
Dialog.create("Choose Channel");
Dialog.addChoice("Which Channel would you like to use as Mask?", Channel_label_array);
Dialog.show();
chosen_mask = Dialog.getChoice();
}else {
exit("Only 1 Channel - Please Untick Use Independent Masks as Channels Option and run again");
}




if(matches(chosen_mask, "Brightfield") == true){
	Dialog.create("Brightfield Mask Detected");
	Dialog.addMessage("Using Brightfield as Mask, please choose values for Phantast:");
	Dialog.addNumber("Sigma", 4);
	Dialog.addNumber("Epsilon", 0.05);
	Dialog.show();
	Sigma_int = Dialog.getNumber();
    Epsilon_int = Dialog.getNumber();
	}
	
if (mask_check == true || matches(chosen_mask, "Brightfield") != true ) {
Sigma_int = 4;
Epsilon_int = 0.05;
}

// - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - --  - - - -- -- - - - - - --
// CODE 
// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --
// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --
setBatchMode(true); //Change here if wanting to run in non batch mode for some reason

//Code for saving different channels in seperate folders - - -  --  - -  -- - -  -- - -  -- - -  -- - -  -- - -  --
if (Channel_number > 1) { 
Table.create("CHANNELS"); //Create table 
Table.setColumn("CHANNELNAME", Channel_label_array); //The stupid workaround for getting string from array
File.openSequence(exfolder,"step=1"); 
rename("expt");
run("Deinterleave", "how="+Channel_number);
for (i = 0; i < Channel_number; i++) {
channel_name_string = Table.getString("CHANNELNAME", i);
File.mkdir(exfolder + File.separator + channel_name_string);
selectImage("expt #"+(i+1));
run("Image Sequence... ", "dir="+exfolder + File.separator + channel_name_string + ""+" format=TIFF");
}
}

//- -  -- - -  -- - -  -- - -  -- - -  -- - -  --- -  -- - -  -- - -  -- - -  -- - -  -- - -  --- -  -- - -  -- - -  -- - -  -- - -  -- - -  --
//- -  -- - -  -- - -  -- - -  -- - -  -- - -  --- -  -- - -  -- - -  -- - -  -- - -  -- - -  -- - -  -- - -  -- - -  --- -  -- - -  -- - -  -- - -  -- - -  -- - -  -- - -  -- - -  -- - -  --- -  -- - -  -- - -  -- 

if (mask_check == false && (Channel_number > 1)) { //Rearrange Channel order for analysing, so that channel chosen as the mask comes first. This is needed as the mask channel will be required for analysing other channels

Final_array_mask = newArray(1);
Final_array_mask[0] = chosen_mask;
for(n = 0; n < Channel_number; n++) {
	ar_temp = newArray(1);
	le_string = Table.getString("CHANNELNAME", n);
	ar_temp[0] = le_string;
	if (le_string != chosen_mask) {
		Final_array_mask = Array.concat(Final_array_mask, ar_temp);
	}
}
Table.setColumn("CHANNELNAME", Final_array_mask);
}
close("*");

print("Setup OK, running MACRO");
print(""+Channel_number +" Channels Split");

close("CHANNELS");
// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --
//Perform background correction, on each channel
// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --



for (k = 0; k < Channel_number; k++) {
if (Channel_number > 1) {
Table.create("CHANNELS_UNAMBIGOUS"); //Create table
Table.setColumn("CHANNELNAME", Channel_label_array); //set CHANNELname column to the label array generated earlier
if (mask_check == false) {
Table.setColumn("CHANNELNAME", Final_array_mask); //If order of channels had to be changed if mask channel is not first
}
selectWindow("CHANNELS_UNAMBIGOUS");
channel_name_string = Table.getString("CHANNELNAME", k);
print("Working on "+ channel_name_string + " channel");
File.openSequence(exfolder + File.separator + channel_name_string,"step=1"); //Import the Experiment Image Stack
}else { //i.e. if Channel number = 1
channel_name_string = chosen_mask; //CHANNELNAME table does not exist if number of channels is 1 - this throws error later in code
File.openSequence(exfolder, "step=1")
}
rename("expt"); //rename to call easier
selectImage("expt"); //select image


if (timepoint_check == false) {  //Super messy workaround for if only have 1 timepoint. Double up stack to artificially create a second time point - it will be removed in R script anyway
infoArraydouble = newArray(); //This and the following code has to be done because interleave does not transfer image metadata into the combined stack
for (i = 0; i < nSlices; i++) {
testArray = newArray(); //make empty array
setSlice(i+1); //Set to acrive slice
testArray[0] = getMetadata("Info"); //get image label from active slice
infoArraydouble = Array.concat(infoArraydouble, testArray); //Add twice to empty array, as combined stack will have each image added twice, i.e. 1,1,2,2,3,3 etc. 
infoArraydouble = Array.concat(infoArraydouble, testArray);
}
run("Duplicate...", "title=DupliStack duplicate"); //duplicate stack
run("Interleave", "stack_1=expt stack_2=DupliStack"); //re-interleave
selectImage("expt");
//ImageJ macro has essentially no easy way to extract strings from an array - REALLY ANNOYING!!!!! - workaround I've found is to create a table, set a column to the values of my array 
//And then use Table.getstring to extract the string from the index position of the table column. Really really stupid but it will have to do
Table.create("TEXT"); //Create table 
Table.setColumn("METAID", infoArraydouble); //Set table column to my array
for (i = 0; i < nSlices; i++) {
metaidstring = Table.getString("METAID", i); //Get i index string
selectImage("expt");
setSlice(i+1);
setMetadata("Label", metaidstring); //Set image label to string
}
selectImage("DupliStack");
close();
selectImage("expt");
close();
selectImage("Combined Stacks");
rename("expt");


if (channel_name_string != "Brightfield") {
run("Collect Garbage");
run("Slice Keeper", "first=1 last="+FOV_number*timepoint_number*well_number+" increment="+(FOV_number*timepoint_number-1)+""); //Ionas idea, make a subset of the stack to compute the BASIC shading profile on, use on full stack after compute - saves run time. Use a smaller increment to timepoint so as to not use only the first frame from each FOV
selectImage("expt kept stack");
run("BaSiC ", "processing_stack=[expt kept stack] flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Manual temporal_drift=Ignore correction_options=[Compute shading only] lambda_flat=4 lambda_dark=0.50"); //Compute shading profile based on the stack subset, you will use this to generate the flat field which will then be ran on the entire experiment stack
selectImage("Flat-field:expt kept stack");
run("BaSiC ", "processing_stack=[expt] flat-field=[Flat-field:expt kept stack] dark-field=None shading_estimation=[Skip estimation and use predefined shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=[Replace with zero] correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50"); //Compute shading profile for entire stack
selectImage("Corrected:expt");
} 
}

if(timepoint_check == true) {
	
	infoArraydouble = newArray(); //This and the following code has to be done because interleave does not transfer image metadata into the combined stack
for (i = 0; i < nSlices; i++) {
testArray = newArray(); //make empty array
setSlice(i+1); //Set to acrive slice
testArray[0] = getMetadata("Info"); //get image label from active slice
infoArraydouble = Array.concat(infoArraydouble, testArray); 
}
	
	if (channel_name_string != "Brightfield") {
run("Slice Keeper", "first=1 last="+FOV_number*timepoint_number*well_number+" increment="+(FOV_number*timepoint_number-1)+""); //Ionas idea, make a subset of the stack to compute the BASIC shading profile on, use on full stack after compute - saves run time. Use a smaller increment to timepoint so as to not use only the first frame from each FOV
selectImage("expt kept stack");
run("BaSiC ", "processing_stack=[expt kept stack] flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Manual temporal_drift=Ignore correction_options=[Compute shading only] lambda_flat=4 lambda_dark=0.50"); //Compute shading profile based on the stack subset, you will use this to generate the flat field which will then be ran on the entire experiment stack
selectImage("Flat-field:expt kept stack");
run("BaSiC ", "processing_stack=[expt] flat-field=[Flat-field:expt kept stack] dark-field=None shading_estimation=[Skip estimation and use predefined shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=[Replace with zero] correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50"); //Compute shading profile for entire stack
selectImage("Corrected:expt");

}
}
close("\\Others");
run("Add...", "value=1 stack"); //Add 1 to all pixel values as bg has been set to 0 and want to avoid diving by 0 later when calculating dF/F0
rename("Corrected_Flo_Image");
selectImage("Corrected_Flo_Image");
run("Stack Splitter", "number="+well_number); //Split image stack according to number of wells
if (Channel_number > 1) {
File.mkdir(exfolder + File.separator + channel_name_string + File.separator + "Individual_Well"+""); //Make folder to save stacks in - divide into each channel if there
}else {
File.mkdir(exfolder + File.separator + "Individual_Well"+""); //if only 1 channel
}


// - - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - 
//FOR LOOP TO FURTHER SPLIT THE STACKS BASED ON FOV AND SAVE IN EACH FOLDER - If you have more than 99 Wells/FOVs you will need to update this/find a general solution however for now i cba
// - - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - - - - - - - - - - - - -- - - - - - - - - - - - - - - 

for (i = 0; i < well_number; i++) { //Loop through each split stack depending on well
	if (Channel_number > 1) {
	File.mkdir(exfolder + File.separator + channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+""); //If more than 1 channel  
	}else {
File.mkdir(exfolder + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+"");  //Make a folder for the active Well
	}
if (i < 9){ //Has to be done as for i less than 10 as i will be single digit- i.e. 0001 vs 0010
selectImage("stk_000"+(i+1)+"_Corrected_Flo_Image");
rename("Stack_Split_Image_"+(i+1)+"");
run("Stack Splitter", "number="+FOV_number);//Split the stack further based on FOV_number
}else {
selectImage("stk_00"+(i+1)+"_Corrected_Flo_Image");
rename("Stack_Split_Image_"+(i+1)+"");
run("Stack Splitter", "number="+FOV_number);
}
for (j = 0; j < FOV_number; j++) { //Nested for loop - saving each FOV
if (Channel_number > 1) {
File.mkdir(exfolder + File.separator + channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_"+(j+1)+""); //Make a folder for the active Well - if more than 1 channel
}else {
File.mkdir(exfolder + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_"+(j+1)+""); //Make a folder for the active Well
}
if (j < 9){
selectImage("stk_000"+(j+1)+"_Stack_Split_Image_"+(i+1)+"");
if (Channel_number > 1) {
run("Image Sequence... ", "dir="+exfolder + File.separator + channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_"+(j+1)+""+" format=TIFF");
}else {
run("Image Sequence... ", "dir="+exfolder + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_"+(j+1)+""+" format=TIFF");
}
}
if (j >= 9) {
selectImage("stk_00"+(j+1)+"_Stack_Split_Image_"+(i+1)+"");
if (Channel_number > 1) {
run("Image Sequence... ", "dir="+exfolder + File.separator + channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_"+(j+1)+""+" format=TIFF");
}else {
run("Image Sequence... ", "dir="+exfolder + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_"+(j+1)+""+" format=TIFF");
}
}
}
}
close("*"); //Close all open image windows
print("Images divided by well and FOV number");

// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --
// FOR EACH FOV, OPEN WELL
//CORRECT FOR DRIFT
//RUN STAR DIST, MAKE MASK - IF FIRST TIME, RUN ON EXAMPLE IMAGE AND IMPORT TO INSPECT IMAGES
//MULTIPLY BY INSTENSITY
//TAKE MEASUREMENT OF AVERAGE INSTENSITY - DO NOT REMOVE, KEEP ADDING ONTO COLUMN
//SAVE INTO FOLDER OF EACH WELL - ONLY AFTER ALL WELLS HAVE TAKEN MEASUREMENTS - SHOULD BE EACH COLUMN COUNTS MEASUREMENTS FOR EACH TIMEPOINT
//- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --


if (Channel_number > 1 || mask_check == true) {
File.mkdir(exfolder + File.separator + channel_name_string + File.separator + "Well_Averages"+"");
File.mkdir(exfolder + File.separator + channel_name_string + File.separator + "StarDist_Test"+"");
}
if (mask_check == false && Channel_number > 1) {
File.mkdir(exfolder + File.separator + "MASK_OUTPUT");
File.mkdir(exfolder + File.separator + "MASK_OUTPUT" + File.separator + "Individual_Well");
File.mkdir(exfolder + File.separator + "StarDist_Test"+"");
}
if (Channel_number == 1) {
File.mkdir(exfolder + File.separator + "Well_Averages"+"");
File.mkdir(exfolder + File.separator + "StarDist_Test"+"");
}

//Code below is for generating an example StarDist output to decide best settings for your experiment 
if ((matches(channel_name_string, "Brightfield") != true)) { //Dont care about brightfield settings, as will only have 1 setting anyway
	Star_Dist_Array = newArray(0.051,0.11,0.151,0.201,0.251,0.301,0.351,0.451,0.501,0.551,0.601,0.651,0.701,0.751,0.801,0.851,0.901,0.951,1);
   	if (mask_check == false && k==0) { //k = 0 ensures this is only run on mask channel - if only one channel is present this will be first anyway
     if (Channel_number == 1) {
     File.openSequence(exfolder + File.separator + "Individual_Well" + File.separator + "Well_Number_1"+ File.separator + "FOV_Number_1"+"","step=1");  
     }else {
   	  File.openSequence(exfolder + File.separator +  channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_1"+ File.separator + "FOV_Number_1"+"","step=1");
     }run("Z Project...", "projection=[Max Intensity]"); //find average area of cell containting regions
	  selectImage("MAX_FOV_Number_1"+""); 
   	  run("Duplicate...", "title=TEST duplicate"); //Dont need this but copied code across
   	  for (i = 0; i < 19; i+=1) {
	selectImage("TEST"); 
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'TEST', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.8', 'percentileTop':'99.60000000000001', 'probThresh':'"+Star_Dist_Array[i]+"', 'nmsThresh':'0.05', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	selectImage("TEST");
	run("Duplicate...", "title=TO_SAVE duplicate"); //To save having to reimport image stack over again - this is faster
	selectImage("TO_SAVE");
	roiManager("deselect"); 
	roiManager("fill"); //Fill roi regions 
	selectImage("TO_SAVE");
	save(exfolder + File.separator + "StarDist_Test" + File.separator +"STARDIST_THRESH_"+Star_Dist_Array[i]+"_TEST.tiff");
	selectImage("TO_SAVE");
	close();
	roiManager("reset");
	}
	close("*");
	sdfilelist = getFileList(exfolder + File.separator + "StarDist_Test");
for (sdfiles = 0; sdfiles < lengthOf(sdfilelist); sdfiles++) {
        open(exfolder + File.separator + "StarDist_Test"+File.separator+sdfilelist[sdfiles]); //open all StarDist images to save into stack - cant use import image sequence as will not keep file names
     
}	
     run("Images to Stack", "name=StarDist_Output use");  //to see the image filenames
     setBatchMode("exit and display"); //show images
	 if (Channel_number == 1) {
     File.openSequence(exfolder + File.separator + "Individual_Well" + File.separator + "Well_Number_1"+ File.separator + "FOV_Number_1"+"","step=1");  
     }else {
	 File.openSequence(exfolder + File.separator +  channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_1"+ File.separator + "FOV_Number_1"+"","step=1");
   	}
   	
   	}
   	
 if (mask_check == true) {
 	  File.openSequence(exfolder + File.separator +  channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_1"+ File.separator + "FOV_Number_1"+"","step=1");
  run("Z Project...", "projection=[Max Intensity]"); //find average area of cell containting regions
	  selectImage("MAX_FOV_Number_1"+""); 
   	  run("Duplicate...", "title=TEST duplicate");
   	  for (i = 0; i < 19; i+=1) {
	selectImage("TEST");
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'TEST', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.8', 'percentileTop':'99.60000000000001', 'probThresh':'"+Star_Dist_Array[i]+"', 'nmsThresh':'0.05', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	selectImage("TEST");
	run("Duplicate...", "title=TO_SAVE duplicate");
	selectImage("TO_SAVE");
	roiManager("deselect");
	roiManager("fill");
	selectImage("TO_SAVE");
	save(exfolder + File.separator + channel_name_string + File.separator + "StarDist_Test" + File.separator +"STARDIST_THRESH_"+Star_Dist_Array[i]+"_TEST.tiff");
	selectImage("TO_SAVE");
	close();
	roiManager("reset");
 }
    close("*");
    sdfilelist = getFileList(exfolder + File.separator + channel_name_string + File.separator + "StarDist_Test");
for (sdfiles = 0; sdfiles < lengthOf(sdfilelist); sdfiles++) {
        open(exfolder + File.separator + channel_name_string + File.separator + "StarDist_Test" +File.separator+sdfilelist[sdfiles]);     
}
    run("Images to Stack", "name=StarDist_Output use");  //to see the image filenames
    setBatchMode("exit and display"); //show images
    File.openSequence(exfolder + File.separator +  channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_1"+ File.separator + "FOV_Number_1"+"","step=1");
 }
   	Dialog.createNonBlocking("Fluorescent Mask Detected");
	Dialog.addMessage("Using a Fluorescent channel as mask, please choose values for StarDist:");
	Dialog.addNumber("Probability/Score Threshold (0.00 - 1.00)", 0.6);
	Dialog.addMessage("Higher values lead to fewer segmented objects, but will likely avoid false positives (unless heavily overlapping, leave this one)");
	Dialog.addNumber("Overlap Threshold (0.00- 1.00)", 0.05);
	Dialog.addMessage("Higher values allow segmented objects to overlap substantially");
	Dialog.show();
	Prob_int = Dialog.getNumber();
    Overlap_int = Dialog.getNumber();
 
   	}
   	close("*");
    setBatchMode(true);

for (i = 0; i < well_number; i++) {
	roi_count_empty_array = newArray(FOV_number); //For cell_counting - ffs
   for (j = 0; j < FOV_number; j++) {
   	
   	if (Channel_number > 1) {
   		
   	temp_file_Well_FOV_delete = getFileList(exfolder + File.separator +  channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+"");
   	File.mkdir(exfolder + File.separator + "MASK_OUTPUT" + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+""); 
   	File.mkdir(exfolder + File.separator + "MASK_OUTPUT" + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+"");  
   	File.openSequence(exfolder + File.separator +  channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+"","step=1");
   	}else {
   	
	    temp_file_Well_FOV_delete = getFileList(exfolder + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+"");
	    File.openSequence(exfolder + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+"","step=1");  
   
   }
  
   	if (Drift_check == true) {
   		if (channel_name_string == "Brightfield") {
   			run("Invert", "stack"); //This is so areas of interest are brighter in brightfield images - will make SIFT work slightly better - idea came from ImageJ forums
   		}
	run("Linear Stack Alignment with SIFT", "initial_gaussian_blur=1.60 steps_per_scale_octave=3 minimum_image_size=64 maximum_image_size=1024 feature_descriptor_size=10 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 maximal_alignment_error=25 inlier_ratio=0.05 expected_transformation=Translation interpolate");
    selectImage("Aligned "+real_timepoint_number + " of " + real_timepoint_number);
    rename("FOV_Number_"+(j+1)+"");
    }   
	    run("Z Project...", "projection=[Max Intensity]"); //find average area of cell containting regions
	    selectImage("MAX_FOV_Number_"+(j+1)+"");//select maximum intensity projection
    if ((matches(channel_name_string, "Brightfield") == true)) {
    	selectImage("FOV_Number_"+(j+1)+"");
    	run("32-bit");
    	if (Drift_check == true) {
    		run("Invert", "stack"); //back inverting if used drift correction on brightfield 
    	}
        run("Deinterleave", "how="+real_timepoint_number);
        for(x = 1; x <= real_timepoint_number; x++) {
        selectImage("FOV_Number_"+(j+1)+" #"+x);
        run("PHANTAST", "sigma="+ Sigma_int +" epsilon="+ Epsilon_int + " do selection new");
        selectImage("FOV_Number_"+(j+1)+" #"+x);
        run("Measure");
        if(matches(chosen_mask, "Brightfield") == true){
        selectImage("FOV_Number_"+(j+1)+" #"+x);
        roiManager("Add");
        roiManager("save", exfolder + File.separator + "MASK_OUTPUT" + File.separator + "Individual_Well"+ File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+File.separator+"StarDist_ROI.zip");
        roiManager("reset");
        }
        
        }
        
    }
    
    
        if (mask_check == false && (matches(chosen_mask, channel_name_string) == true) && ( matches(channel_name_string, "Brightfield") != true) && Channel_number > 1){

        selectImage("MAX_FOV_Number_"+(j+1));
        rename("TEST");
	    run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'TEST', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.8', 'percentileTop':'99.60000000000001', 'probThresh':'"+Prob_int+"', 'nmsThresh':'"+Overlap_int+"', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");  //REMEMBER TO CHANGE SETTNINGS FOR THIS PROTOCOL FUCK - run stardist
	  
	      	
	    	rawROInumber = roiManager('count');
	    	roi_count_empty_array[j] = rawROInumber;

	    	selectImage("FOV_Number_"+(j+1));

	    	
	    	if (rawROInumber != 0) {
	    	roiManager("multi-measure measure_all one append");
	    	}
	    	if (rawROInumber == 0) {
	    	makeRectangle(0, 1004, 22, 20);
	    	roiManager("add");
	    	roiManager("multi-measure measure_all one append");	
	    	}
	    	
	    roiManager("deselect");
	    roiManager("save", exfolder + File.separator + "MASK_OUTPUT" + File.separator + "Individual_Well"+ File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+File.separator+"StarDist_ROI.zip");

	    close("*");
	    roiManager("reset");

}
        if (mask_check == false && (matches(chosen_mask, channel_name_string) != true)  && (matches(channel_name_string, "Brightfield") != true)){ 
        	 roiManager("open", exfolder + File.separator + "MASK_OUTPUT" + File.separator + "Individual_Well"+ File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+File.separator+"StarDist_ROI.zip");
        	rawROInumber = roiManager('count'); //So ROI count is present even in MASKed datatable
	    	roi_count_empty_array[j] = rawROInumber; // /\
        selectImage("FOV_Number_"+(j+1));
	  if (rawROInumber != 0) {
	    	roiManager("multi-measure measure_all one append");
	  }
	  if (rawROInumber == 0) { //You get errors if StarDist doesnt segment any ROIS - this creates a huge rectangle which is easy to filter out in R anyway
	    	makeRectangle(0, 1004, 22, 20);
	    	roiManager("add");
	    	roiManager("multi-measure measure_all one append");	
	    	}
	    close("*");
	    roiManager("reset");
        }
        
     if ((matches(channel_name_string, "Brightfield") != true)) {
     if (mask_check == true || Channel_number == 1){
        selectImage("MAX_FOV_Number_"+(j+1));
        rename("TEST");
	    run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'TEST', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.8', 'percentileTop':'99.60000000000001', 'probThresh':'"+Prob_int+"', 'nmsThresh':'"+Overlap_int+"', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");  //REMEMBER TO CHANGE SETTNINGS FOR THIS PROTOCOL FUCK - run stardist
	    	
	    	rawROInumber = roiManager('count');
	    	roi_count_empty_array[j] = rawROInumber;

	    	selectImage("FOV_Number_"+(j+1));
	 if (rawROInumber != 0) {
	    	roiManager("multi-measure measure_all one append");
	 }
	 if (rawROInumber == 0) {
	    	makeRectangle(0, 1004, 22, 20);
	    	roiManager("add");
	    	roiManager("multi-measure measure_all one append");	
	    	}
	    close("*");
	    roiManager("reset");
       }
     }
      
close("*");
 	for (FOVfiledelete = 0; FOVfiledelete < lengthOf(temp_file_Well_FOV_delete); FOVfiledelete++) {
   		if (Channel_number > 1) {
   	File.delete(exfolder + File.separator +  channel_name_string + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+ File.separator + temp_file_Well_FOV_delete[FOVfiledelete]);
   	}else {
   		File.delete(exfolder + File.separator + "Individual_Well" + File.separator + "Well_Number_"+(i+1)+ File.separator + "FOV_Number_" +(j+1)+File.separator + temp_file_Well_FOV_delete[FOVfiledelete]);
   	}	
   	}
   } 
   

selectWindow("Results");
for (g = 0; g < nResults(); g++) {
    setResult("Channel_Name", g, channel_name_string);
    }
Table.create("TEXT"); //Create table 
Table.setColumn("METAID", infoArraydouble); //Set table column to my array containing image metadata

for (meta_loop = 0; meta_loop < total_image_number; meta_loop++) { //For loop setting image meta data to new column called Label_ID
	meta_loop_well_correct = meta_loop + (i*FOV_number*real_timepoint_number);
	metaidstring_loop = Table.getString("METAID", meta_loop_well_correct);
	for (timepoint_loop = 0; timepoint_loop < real_timepoint_number; timepoint_loop++) {
		final_index_num = meta_loop + timepoint_loop;
		setResult("Label_ID", final_index_num, metaidstring_loop);
	}
    }
close("TEXT");    
    
 if (channel_name_string != "Brightfield") {  //Same as above but with ROI count data, doing one first pass for 0th row because i couldnt figure out how to write neatly - wasted like 1 hour arrrgh i hate it when i cant find a nice solution but whatever this will do i guess
    Table.create("ROICOUNTER");
	Table.setColumn("ROI_Count", roi_count_empty_array);
	for (firstpoint = 0; firstpoint < real_timepoint_number; firstpoint++) {
    ROI_count_setting_var = Table.get("ROI_Count", 0);
    setResult("ROI_Number", firstpoint, ROI_count_setting_var);
    }
    for (bruh = 1; bruh < FOV_number; bruh++) {
    selectWindow("ROICOUNTER");
    ROI_count_setting_var = Table.get("ROI_Count", bruh);
    for (timepoint_loop = 0; timepoint_loop < real_timepoint_number+1; timepoint_loop++) {
    selectWindow("Results");
    first_pass_index = bruh*real_timepoint_number;
    final_index_num = first_pass_index+timepoint_loop;
    setResult("ROI_Number", final_index_num, ROI_count_setting_var);
    }
}
 }
updateResults();
selectWindow("Results");
if(Channel_number > 1){
	saveAs("Results", exfolder + File.separator + channel_name_string + File.separator + "Well_Averages" + File.separator + channel_name_string +"_Well_Number_"+(i+1) + ".csv");
	print("Results for Well " + (i+1) + " and FOV " + (j+1) + " collected");
}

if(Channel_number == 1) {
saveAs("Results", exfolder + File.separator + "Well_Averages" + File.separator + "Well_Number_"+(i+1) + ".csv");
}
 close("Results");
 
 

close("*");
}

if(Channel_number > 1){ //detelting temp files created during macro so as to not infalte experiment size for storage
Channel_folder_file_list = getFileList(exfolder + File.separator + channel_name_string);
temp_files_to_delete =  ImageFilesOnlyArray(Channel_folder_file_list);
for (tempfile = 0; tempfile < lengthOf(temp_files_to_delete); tempfile++) {
File.delete(exfolder + File.separator + channel_name_string + File.separator + temp_files_to_delete[tempfile]);
}
}
}


print("MACRO FINISHED SUCCESFULLY - PLEASE USE R TO CONCATENTATE CSV FILES");

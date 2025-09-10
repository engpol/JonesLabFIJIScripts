//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// PARAMETERS
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -

#@ File(label="Experiment folder", value = "C:/", style="directory") sample_folder
#@ Float (label="PHANTAST Sigma", value = 4, style="spinner") sigmaint
#@ Float (label="PHANTAST Epsilon", value = 0.05, style="spinner") epsiint
#@ File(label="Flat-field Image - Dependent", value = "C:/", style="file") ffimage
#@ Integer (label="Select Fluorescent Channel", value = 1, style="slider", min = 1, max = 2) flochannel
#@ String (label="Data from which Microscope?",choices={"Nikon", "EVOS"}, style="radioButtonHorizontal") Microscope_Choice
#@ File(label = "Select magick.exe from ImageMagick - EVOS Only") magick_path

run("Fresh Start"); //ALWAYS INCLUDE
setBatchMode(true);
setOption("ExpandableArrays",true);

//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// FUNCTIONS
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -

function ImageFilesOnlyArray (arr) {
	//pass array from getFileList through this e.g. NEWARRAY = ImageFilesOnlyArray(NEWARRAY);
	f=0;
	files = newArray;
	print(stacks_filelist[f])
	for (i = 0; i < arr.length; i++) {
		if(endsWith(arr[i], ".tif") || endsWith(arr[i], ".tiff") || endsWith(arr[i], ".TIF") || endsWith(arr[i], ".TIFF") || endsWith(arr[i], ".nd2") || endsWith(arr[i], ".LSM") || endsWith(arr[i], ".czi") || endsWith(arr[i], ".jpg") ) {   //if it's a tiff image add it to the new array
			files[f] = arr[i];
			f = f+1;
		}
	}
	arr = files;
	arr = Array.sort(arr);
	return arr;
	
}

//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// VARIABLES
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -

stacks_filelist = getFileList(sample_folder);
stacks_images = ImageFilesOnlyArray(stacks_filelist);
stacks_length = lengthOf(stacks_images);
bin_int = 1; // to make code less messy - if not downsampling, downsample by 1
input_dir = sample_folder; // important for evos when re-saving in new folder
if (flochannel == 1) {
	flo_int = 0;
	bf_int = 1;
}else {
	bf_int = 1;
	flo_int = 0;
}



//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// USER-INPUT
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
 
// Dialogs to get uinput for dsample and factor
Dialog.create("Use Downsampling?");
	Dialog.addMessage("Would you like to use sofware binning to downsample and reduce size of your images?");
	Dialog.addMessage("(This may improve speed significantly)");
	Dialog.addCheckbox("Use Downsampling?", false);
	Dialog.show();
	binning_test = Dialog.getCheckbox();	
	
if (binning_test == true) {
	Dialog.create("What is your desired downsampling factor?");
	Dialog.addMessage("2 = 4* smaller, 4 = 16* smaller etc.");
	Dialog.addNumber("Downsample Factor", 2);
	Dialog.show();
	bin_int = Dialog.getNumber();
	print("Shrinking image size by a factor of "+bin_int*bin_int);
}

// Dialog to get uinput for bground correction
Dialog.create("BASIC:Background Correction");
	Dialog.addMessage("Use pre-defined FFC image for correction or derive from experimental data?");
	Dialog.addMessage("(Not using a predfined profile may reduce speed significantly)");
	Dialog.addCheckbox("Use pre-defined flat-field image for FFC", true);
	Dialog.show();
	flat_field_test = Dialog.getCheckbox();

//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// RE-SAVING AND SHUFFLING EVOS DATA
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -

// If User Chooses EVOS: 
// Trim fat tiff files by removing bloated header file by re-saving using ImageMagick cli
// MESNA: Re-order images according to Well -> FOV -> Timepoint -> Channel

 if (Microscope_Choice == "EVOS") {
 	magick_dir = File.getParent(magick_path);
 	File.mkdir(sample_folder + File.separator + "EVOS_Tiff_Conv");
 	output_dir = sample_folder + File.separator + "Evos_Tiff_Conv";
 	command = "cd /d \"" + magick_dir + "\" && " + "\"" + magick_path + "\" mogrify -format tif -path \""+output_dir+"\" " + "\""+sample_folder+File.separator+"*.TIF\"";
 	print("Executing: " + command + " in terminal...");
 	exec("cmd", "/c", command);
 	print(stacks_length + " tif files re-saved");
 	input_dir = sample_folder + File.separator + "Evos_Tiff_Conv";
 }
 
if (Microscope_Choice == "EVOS") {
    print("Reformatting EVOS data using array-based sorting...");
    setBatchMode(true);

    // --- 1. Parse filenames and create sort keys ---
    // We'll create a "sort key" for each filename based on the desired order: Well -> FOV -> Channel -> Timepoint.
    // Example Filename:  prefix_p01_B02_f03_d0.tif
    // Corresponds to:    Timepoint=2, Well=B2, FOV=4, Channel=1
    // Desired sort key:  B02_f03_p01_d0  (This ensures a simple alphabetical sort gives the correct order)
    
    num_Images = lengthOf(stacks_images);
    originalFileNames = newArray(num_Images);
    sortKeys = newArray(num_Images);


for (i = 0; i < num_Images; i++) {
    filename = stacks_images[i];
    originalFileNames[i] = filename;
    combined_pattern = ".*_([A-H][0-9]{2})(f[0-9]{2})(d[0-9]).*";
 
    // Check if the filename matches the expected patterns before trying to extract parts.
    if (matches(filename, combined_pattern) && matches(filename, ".*_(p[0-9]{2})_.*")) {
        // Extract well, fov, and channel using their respective capture groups ($1, $2, $3)
        well = replace(filename, combined_pattern, "$1");    // Group 1: (B02)
        fov = replace(filename, combined_pattern, "$2");     // Group 2: (f00)
        channel = replace(filename, combined_pattern, "$3"); // Group 3: (d3)
        time = replace(filename, ".*_(p[0-9]{2})_.*", "$1");

        
        sortKeys[i] = well + "_" + fov + "_" + time + "_" + channel;
    } else {
        sortKeys[i] = "zzzz_parse_error"; // Put improperly named files at the end
        print("WARNING: Could not parse filename: " + filename);
    }
}
    Array.sort(sortKeys, originalFileNames);
    print("Sorted EVOS Images according to filenames...");
 
}
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// CODE - PROCESSING
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
 
// Housekeeping - - - - -
File.mkdir(sample_folder + File.separator + "PHANTAST") // For containing PHANTAST Mask output
File.mkdir(sample_folder + File.separator + "Results")
MetaIDArray = newArray(); // make empty array for holding image names to add to results at the end
// - - - - - - - - - - - - 

    
 for (i = bf_int; i <= num_Images-1; i+=4) { // Iterate over BF channel - open based on EVOS re-shuffle, run phantast, and save to temp file
	    print("Opening "+originalFileNames[i]);
    	open(input_dir + File.separator + originalFileNames[i]);
    	rename("Image_"+i);
    	run("Bin...", "x="+bin_int+" y="+bin_int+" bin=Average");
    	print("Downsampling Brightfield Image Num "+ i + " by " +bin_int+" in x and y");
        run("32-bit"); 
        run("PHANTAST", "sigma="+sigmaint+" epsilon="+epsiint+" do new"); 
    	selectImage("PHANTAST - Image_"+i);
	    save(sample_folder + File.separator + "PHANTAST" + File.separator + "Image_"+i+".tiff");
	    print("Saved BF Mask for Image "+i+" out of "+stacks_length);
	    close("*");
   }


for (i = flo_int; i <= num_Images-1; i+=4) {
	open(input_dir + File.separator + originalFileNames[i]);
	rename("Image_"+i);
	selectImage("Image_"+i);
	run("Bin...", "x="+bin_int+" y="+bin_int+" bin=Average");
	MetaIDArray = Array.concat(MetaIDArray, originalFileNames[i]);
	open(input_dir + File.separator + originalFileNames[i+2]);
	rename("Image_"+(i+2));
	selectImage("Image_"+(i+2));
	run("Bin...", "x="+bin_int+" y="+bin_int+" bin=Average");
	MetaIDArray = Array.concat(MetaIDArray, originalFileNames[i+2]);
}
run("Images to Stack", "name=Fluorescent_Stack use");
    

// Perform BASIC correction
if (flat_field_test == true) {
open(ffimage);
rename("FFC_Image");
print("Performing BASIC - Background Correction...");
run("BaSiC ", "processing_stack=Fluorescent_Stack flat-field=FFC_Image dark-field=None shading_estimation=[Skip estimation and use predefined shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=[Replace with zero] correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50");
}else {
if(num_images > 200){ //If number of images is large, run BaSiC only on subset, if it is short, just run on entire length of images
	print("Image Number > 200 - Running BASIC on Subset of Images!");
	print("Performing BASIC - Background Correction...");
	selectImage("Fluorescent_Stack");
	run("Slice Keeper", "first=1 last="+num_images+" increment=10");
	selectImage("Fluorescent Stack kept stack");
	run("BaSiC ", "processing_stack=[Fluorescent_Stack kept stack] flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Manual temporal_drift=Ignore correction_options=[Compute shading only] lambda_flat=4 lambda_dark=0.50");
	selectImage("Flat-field:Fluorescent_Stack kept stack");
	run("BaSiC ", "processing_stack=[Fluorescent_Stack] flat-field=[Flat-field:Fluorescent_Stack kept stack] dark-field=None shading_estimation=[Skip estimation and use predefined shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=[Replace with zero] correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50"); //Compute shading profile for entire stack
}
run("BaSiC ", "processing_stack=Fluorescent_Stack flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Manual temporal_drift=[Replace with zero] correction_options=[Compute shading and correct images] lambda_flat=5 lambda_dark=0.50");
}

// Extract intensity data from masked fluorescence images - - - - - -
selectImage("Corrected:Fluorescent_Stack");
run("Add...", "value=1 stack");
File.openSequence(sample_folder + File.separator + "PHANTAST"); //Import image sequence containing PHANTAST images
rename("PHANTAST");
run("Duplicate...", "title=PHANTAST_1 duplicate"); //Duplicate the PHANTAST output
run("Interleave", "stack_1=PHANTAST stack_2=PHANTAST_1"); //Re-interleave with itself to double up the stack so it matches length of the fluorescence stack
close("PHANTAST");
selectImage("Combined Stacks"); //Select image
rename("PHANTAST"); 
selectImage("PHANTAST");
run("Invert", "stack"); //Invert PHANTAST stack so cell containing regions are 255 (in 32 bit) and background is 0
run("Divide...", "value=255 stack");
imageCalculator("Multiply create stack", "Corrected:Fluorescent_Stack","PHANTAST");
setThreshold(1, 65535, "raw"); 
run("Set Measurements...", "area mean limit display redirect=None decimal=2");
run("Measure Stack...");
close("*");
print("Measurements Extracted!");
// - - - - - - - - -

//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// CODE -  POST-PROCESSING
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -

// DELETING ALL TEMP FILES - - - - - -
 if (Microscope_Choice == "EVOS") { // If evos was used also have to delete images made by ImageMagick
 	re_saved_tiff_filelist = getFileList(output_dir);
 	for (tempfile = 0; tempfile < lengthOf(re_saved_tiff_filelist); tempfile++) {
File.delete(output_dir + File.separator + re_saved_tiff_filelist[tempfile]);
print("Deleting Re-saved tiff #"+(tempfile+1)+" out of " + lengthOf(re_saved_tiff_filelist));
}
File.delete(output_dir);
 }
 
PHANTAST_Images = getFileList(sample_folder + File.separator + "PHANTAST");
for (tempfile = 0; tempfile < lengthOf(PHANTAST_Images); tempfile++) {
File.delete(sample_folder + File.separator + "PHANTAST" + File.separator + PHANTAST_Images[tempfile]);
print("Deleting PHANTAST Image #"+(tempfile+1)+" out of " + lengthOf(PHANTAST_Images));
}
File.delete(sample_folder + File.separator + "PHANTAST");

// - - - - - - - - - - - - - - - - -
 print("All Temp Files and Folders Deleted");
 
selectWindow("Results");

if (Microscope_Choice == "EVOS") {

for (i = 0; i < lengthOf(MetaIDArray); i++) {
    filename = MetaIDArray[i];
    combined_pattern = ".*_([A-H][0-9]{2})(f[0-9]{2})(d[0-9]).*";
    time_pattern = ".*_(p[0-9]{2})_.*";

    // Check if the filename matches the expected patterns
    if (matches(filename, combined_pattern) && matches(filename, time_pattern)) {
        // --- 1. Parse the data from the filename into variables ---
        well = replace(filename, combined_pattern, "$1");    // e.g., B02
        fov = replace(filename, combined_pattern, "$2");     // e.g., f00
        channel = replace(filename, combined_pattern, "$3"); // e.g., d3
        time = replace(filename, time_pattern, "$1");        // e.g., p00

        // --- 2. Set the parsed data into the results table for the current row 'i' ---
        setResult("Well", i, well);
        setResult("FOV", i, fov);
        setResult("Channel", i, channel);
        setResult("Timepoint", i, time);

    } else {
        // If parsing fails, still add a row but with error messages
        print("WARNING: Could not parse filename: " + filename);
        setResult("Well", i, "PARSE_ERROR");
        setResult("FOV", i, "PARSE_ERROR");
        setResult("Channel", i, "PARSE_ERROR");
        setResult("Timepoint", i, "PARSE_ERROR");
    }
}
}

for (g = 0; g < lengthOf(MetaIDArray); g++) { //For loop setting image meta data to new column called Label_ID
	metaidstring_loop = MetaIDArray[g]; // Get the string directly from the array!
	setResult("Image_Filename", g, metaidstring_loop);
}

print("Added Label-IDs to Results");


updateResults(); // needed because imagej
selectWindow("Results");
saveAs("Results.csv",  sample_folder + File.separator + "Results" + File.separator + "Results.csv");
print("Saved Results to Results.csv");
print("Macro Done!");
    



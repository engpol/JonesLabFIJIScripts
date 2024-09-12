// overview of Macro
//1: Open Brain slice tif file
//2: Divide into NxN grid - can play around - this should be fine at 7x7 it will lead to ridicoulous times otherwise, + seems to be about right deimension size to pickup
//3: Save into folder as seperate images
//4: For loop - for each image in split image stack
// - Open image
// - Run StarDist
// - Nested for loop to remove ROIs of size lower than ~8 - remove regions detected as cells from autofluorescence/ventricles etc.
// - Create emtpy image of dimensions equal to image and fill with filtered StarDist output
// - Use image calculator - add - to artifically increase contrast of original image only in cell regions
// - Save to temp folder
//5: Re-stitch as grid with pumped contrast images into full Image 



//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
//Global Parameters 
//- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - -- - - - -- -- - - - - - --

#@ File(label="TEST Folder", value = "C:/", style="directory") exfolder
#@ int(label="N x N grid to divide into (i.e., 2 = 4, 3 = 9 etc.) - Best to Match Image Stitch") n
#@ Float (label="StarDist Probabilty Score", value = 0.7, min = 0, max = 1) probs_float
#@ Float (label="StarDist Overlap Threshold", value = 0.05, min = 0, max = 1) overlap_float
#@ Float (label="Area Filter Min - PLEASE CHECK", value = 0.00000000000001, min = 0, max = 1) area_min
#@ Float (label="Area Filter Max - PLEASE CHECK", value = 0.00000025, min = 0, max = 100000) area_max

run("Fresh Start"); //ALWAYS INCLUDE - CLOSE ALL IMAGES AND RESET ALL OPTIONS TO DEFAULT
setBatchMode(true); //"TRUE" FOR FASTER PROCESSING
run("Set Measurements...", "area mean display redirect=None decimal=2"); //Having the right measurements for collecting data - change here if you want to collect any more data

//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -
// - VARIABLES + FUNCTIONS
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - --

Slide_filelist = getFileList(exfolder);

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


// - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - --  - - - -- -- - - - - - --
// CODE 
// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --
// SPLITTING IMAGE INTO 6x6 GRID
// - - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --- - - -- -- - - - - - --

for (slide_number = 0; slide_number < lengthOf(Slide_filelist); slide_number++) {
setBatchMode(true);
Current_file = Slide_filelist[slide_number];

array_for_regex = split(Current_file, "_.");
slide_number_char_array = Array.filter(array_for_regex, "(\\d{1})");
slide_number_char_x = slide_number_char_array[0]; //All stuff above and below is simply regex to extract slide number to be used in naming the final pumped image, in case your folders are out of order if some folders were moved/deleted - IMPORTANT FOR LATER R ANALYSIS
array_for_regex_2 = split(slide_number_char_x, "/");
slide_number_char = array_for_regex_2[0];


File.openSequence(exfolder + File.separator + Slide_filelist[slide_number],"step=1");
rename("TO_REMOVE");
run("Duplicate...", "title=MY_IMAGE");
close("TO_REMOVE");

id = getImageID(); 
title = getTitle(); 
getLocationAndSize(locX, locY, sizeW, sizeH); //Define active image window dimensions
width = getWidth(); 
height = getHeight(); 
tileWidth = width / n; //define width of tile = full width/divisor
tileHeight = height / n; //define height of each tile = full width/divisor
for (y = 0; y < n; y++) { 
offsetY = y * height / n; //find the offset - i.e. how many pixels to move across to find next tile - for the y axis
 for (x = 0; x < n; x++) { 
offsetX = x * width / n;  //find the offset - i.e. how many pixels to move across to find next tile - for the x axis
selectImage(id); 
call("ij.gui.ImageWindow.setNextLocation", locX + offsetX, locY + offsetY); //Set the next location - equal to current location + x+y axis offset
tileTitle = title + " [" + x + "," + y + "]"; //change title of tile
run("Duplicate...", "title=" + tileTitle); //Duplicate - to not lose original image when running crop command
makeRectangle(offsetX, offsetY, tileWidth, tileHeight); //make a rectangle around axis position of current tile
run("Crop"); //Crop into seperate image window
rename("Slice_"+y+"_"+x); //rename
} 
} 
selectImage(id); //Select original image
close(); //Close 
run("Images to Stack", "use"); //Turn all split images into a stack
File.mkdir(exfolder + File.separator + Slide_filelist[slide_number] + File.separator + "Split_Image"); //Make a folder to hold folders for Split_image FOVs - should be 6x6
run("Image Sequence... ", "dir="+exfolder + File.separator + Slide_filelist[slide_number] + File.separator + "Split_Image"+" format=TIFF"); //Save to said folder
close("*");


FOV_filelist = getFileList(exfolder + File.separator + Slide_filelist[slide_number] + File.separator + "Split_Image"); //folder containing split tiles

for (tileID = 0; tileID < lengthOf(FOV_filelist); tileID++) {
open(exfolder + File.separator + Slide_filelist[slide_number] + File.separator + "Split_Image" + File.separator + FOV_filelist[tileID]);
File.delete(exfolder + File.separator + Slide_filelist[slide_number] + File.separator + "Split_Image" + File.separator + FOV_filelist[tileID]);
// - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - --  - - - -- -- - - - - - --
// ONLY NEEDED IF TIFF IMAGES ARE STILL IN RGB STACK MODE/SPLIT INTO 3 CHANNELS - COMMENT OUT OTHERWISE
// - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - -- - - - -- -- - - - - - --  - - - -- -- - - - - - --
//run("Split Channels");
//if (tileID <= 9){
//selectImage(File.separator+"Split_Image"+File.separator+"Stack000"+tileID+".tif (red)");
//}else {
//selectImage(File.separator+"Split_Image"+File.separator+"Stack00"+tileID+".tif (red)");
//}
rename("Stack_"+tileID+"");
close("\\Others");
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'Stack_"+tileID+"', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'0.8', 'percentileTop':'99.60000000000001', 'probThresh':'"+probs_float+"', 'nmsThresh':'"+overlap_float+"', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'true', 'showProbAndDist':'false'], process=[false]");
rawROInumber = roiManager('count'); 
to_be_deleted = newArray();
if (rawROInumber > 0){
for (rawROI = 0; rawROI < rawROInumber; rawROI++) { //FOR EACH ROI GENERATED BY STARDIST - take measurement and apply relevant filters
    roiManager('select', rawROI);
    roiManager("Measure"); 
    area = getResult("Area", rawROI);   
    if (area < area_min || area > area_max) { //Might have to change Area values depending on your microscopy - don't think it warrants a parameter tbh (not easily distinguishable from within macro) - maybe a variable???
    	 to_be_deleted = Array.concat(to_be_deleted, rawROI);
    
}
}
roiManager("deselect");
roiManager("Select", to_be_deleted); //Select ROIS which dont pass filter requirements
roiManager("Delete"); //Delete said ROIS
}

selectImage("Stack_"+tileID+""); 
pixelheight = getHeight();
pixelwidth = getWidth();
newImage("HyperStack", "16-bit grayscale-mode", pixelwidth, pixelheight, 1, 1, 1); //Create black square of the same proportions as FOV
selectImage("HyperStack"); //select hyperstack
cleanedROInumber = roiManager('count');
if (cleanedROInumber > 0){
roiManager("Fill");
//run("Add...", "value=300");
//run("Divide...", "value=300");//Fill based on ROI manager of stardist output
}
imageCalculator("Add create", "Stack_"+tileID,"HyperStack"); //Add Hyperstack values to original tile image
File.mkdir(exfolder + File.separator + Slide_filelist[slide_number] + File.separator + "Split_Image_Contrast_Pump"); //Make a folder to hold folders for Split_image FOVs - should be 6x6
selectImage("Result of Stack_"+tileID);
if (tileID <= 9){
rename("Pumped_Stack_000"+tileID);
}else{
rename("Pumped_Stack_00"+tileID);
}
if (tileID <= 9){
save(exfolder + File.separator + Slide_filelist[slide_number] + File.separator + "Split_Image_Contrast_Pump" + File.separator + "Pumped_Stack_000"+tileID+".tiff");
}else {
save(exfolder + File.separator + Slide_filelist[slide_number] + File.separator + "Split_Image_Contrast_Pump" + File.separator + "Pumped_Stack_00"+tileID+".tiff");
}
close("*");
close("Results");
}
setBatchMode(false);
run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Right & Down                ] grid_size_x="+n+" grid_size_y="+n+" tile_overlap=0 first_file_index_i=0 directory="+ exfolder + File.separator + Slide_filelist[slide_number] + File.separator + "Split_Image_Contrast_Pump" + " file_names=Pumped_Stack_00{ii}.tiff output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display] use");
rename("Fused_Image_"+slide_number_char+"");
run("Subtract...", "value=100"); //Testing, think that pixel values at max limit of pixel intensities may be too large
save(exfolder+File.separator+ Slide_filelist[slide_number] + File.separator + "Fused_Image_"+slide_number_char+""+".tiff");
close("Fused_Image_"+slide_number_char+"");
contrastpumpfiles = getFileList(exfolder + File.separator + Slide_filelist[slide_number] + "Split_Image_Contrast_Pump");
temp_files_to_delete =  ImageFilesOnlyArray(contrastpumpfiles);
//for (tempfile = 0; tempfile < lengthOf(temp_files_to_delete); tempfile++) {
//File.delete(exfolder + File.separator + Slide_filelist[slide_number] + "Split_Image_Contrast_Pump" + File.separator + temp_files_to_delete[tempfile]);
//}
}





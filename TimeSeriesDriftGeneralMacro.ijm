     //Macro to deal with linear drift in calcium imaging files
     //General principle: select images at equally spaced time points apart given
     // by the iterations parameter 
     //select the same key point (i.e. bottom corner of a visible neuron/debris)
     //macro will calculate xy coords and adjust the ROIs first between 1st and second image
     //and then the second third image etc. - to adjust for changes in drift speed
   
      
      
      run("Fresh Start");
      
      //function to clean up files, as some folders contain metadata
      function ImageFilesOnlyArray (arr) {
	//pass array from getFileList through this e.g. NEWARRAY = ImageFilesOnlyArray(NEWARRAY);
	setOption("ExpandableArrays", true);
	f=0;
	files = newArray;
	for (i = 0; i < arr.length; i++) {
		if(endsWith(arr[i], ".tif") || endsWith(arr[i], ".tiff") || endsWith(arr[i], ".nd2") || endsWith(arr[i], ".LSM") || endsWith(arr[i], ".czi") || endsWith(arr[i], ".jpg") ) {   //if it's a tiff image add it to the new array
			files[f] = arr[i];
			f = f+1;
		}
	}
	arr = files;
	arr = Array.sort(arr);
	return arr;
}


//Define variables to allow for getCursorloc

      leftButton=16;
      x2=-1; y2=-1; z2=-1; flags2=-1;
      
//Define parameters for performing time series analysis      
    
#@ File(label="Folder containing image sequence", value = "C:/", style="directory") imagesequence
#@ File(label="File containing ROI", value = "C:/", style="open") NeuronROI
#@ File(label="Results Output Folder", value = "C:/", style="directory") folder
#@ Integer (label="Number of interpolations", value = -1, style="spinner") iterations

//Set the array of the lists of files as variables,
// invert the list to easily select final image in sequence


fileList = getFileList(imagesequence);

fileListinverse = getFileList(imagesequence);

fileList = ImageFilesOnlyArray(fileList);
fileListinverse = ImageFilesOnlyArray(fileListinverse);
fileListinverse = Array.reverse(fileListinverse);

//To divide the difference in pixel coords by the number of images 
image_number = (lengthOf(fileList))-1;




//Open first image, record mouse coords of left click, macro will stop if log is closed
//Save resulting X and Y coords in results column
//"Flags" paramter is for user input, you need z parameter even in 2D image so dont remove

for (n = 0; n <= iterations; n++) {
 count = round((image_number*n/iterations));
 open(fileList[count]);
     
         logOpened = false;
      while (!logOpened || isOpen("Log")) {
          getCursorLoc(x, y, z, flags);
          print(x+" "+y+" ");
            if (flags&leftButton!=0) {
            	close("Log");
            	logOpened = true;
            }
        
      }
     close();
     setResult("X"+n, 0, x);
     setResult("Y"+n, 0, y);
     updateResults();
}


     
     //Get the coords from the results table and set as columns in new table
     
 Table.create("Coords");
    for (n = 0; n <= (iterations); n++) {
    	Table.set("X"+n, 0, getResult("X"+n, 0));
    	Table.set("Y"+n, 0, getResult("Y"+n, 0));
    }
    
    
     //Calculate the pixel drift/image, multiply by 10 as these will be too small for integer
     //NOTE ROI MANAGER TRANSLATE ONLY ACCPETS INTEGERS NOT FLOATS THIS LOST ME DAYS OF WORK - WHY ISNT THIS MENTIONED ANYWHERE IN THE DOCS ARRGHGHGHGHGHGH!!!!

 
     for (n = 0; n <= iterations-1; n++) {
     	xcord = Table.get("X"+(n), 0);
     	xcord1 = Table.get("X"+(n+1), 0);
     	ycord = Table.get("Y"+(n), 0);
     	ycord1 = Table.get("Y"+(n+1), 0);
     	
     	Table.set("XDeltatime"+n, 0, (xcord1-xcord));
     	Table.set("YDeltatime"+n, 0, (ycord1-ycord));
     
     }
     
     //Clear results to not interfere with the neuron time series multi measure
     //Set batchmode to false so images dont cloud screen
     //Make folders to save results in
     //Load in the Neuron ROIs
     
     
     run("Clear Results");
     run("Set Measurements...", "mean redirect=None decimal=3");
     File.mkdir(folder + "/ResultsTables");
     setBatchMode(false);
     open(NeuronROI);


for (n = 0; n <= iterations-1; n++) {
	for (i = round((image_number*n)/iterations); i <= ((round(((n+1)*image_number)/iterations))-1); i++) {
		open(fileList[i]);
		roiManager("multi-measure measure_all one append");
	close();
	}
	roiManager("translate", Table.get("XDeltatime"+n, 0), Table.get("YDeltatime"+n, 0));
}


saveAs("Results", folder + "/ResultsTables" + "/Results_Drift.csv");

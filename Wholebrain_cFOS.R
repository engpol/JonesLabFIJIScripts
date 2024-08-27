## x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x 
## CODE FOR PERFORMING cFOS DATA EXPLORATION AND QUANTIFICATION
## x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x 

## PACKAGES - Will try and use only base R here, as I have no clue on any dependencies of SMART and wholebrain
library(wholebrain)
library(SMART)


## MAKE SURE YOU RUN THE IMAGEJ PUMP CONTRAST MACRO ON FOLDER CONTAINING IMAGES FIRST!!!!!
## THEN, FOR EACH BRAIN, RUN THE FOLLOWING FUNCTION ONCE TO FORMAT THE BRAIN IMAGE FOLDERS TO BE COMPATIABLE WITH SMART/Wholebrain

first_setup_brain_directory <- function(){
  
  exfolder <- tcltk::tk_choose.dir(default = "~/")
  
  exfolder_image_folder <<- paste0(exfolder,"/All_Slices") #Place to add all slices which will be aligned for current brain
  
  exfolder_output_folder <<- paste0(exfolder,"/Output") # For output of SMART pipeline
  
  exfolder_directories <- list.dirs(path = exfolder, full.names = TRUE) #A character vector of all directories
  
  exfolder_directories_cleaned <- subset(exfolder_directories, grepl(pattern = "Slice_\\d", exfolder_directories)) ##Removing all folders which have DELETE in name - REMEMBER TO NAME FOLDERS TO DELETE AS - Slice_DELETE
  list_of_extracted_image_files <- list.files(path = exfolder_directories_cleaned, pattern = "Fused_Image_\\d+", full.names = TRUE, recursive = TRUE) #Fetch all .tif image files from non deleted Slices
  
  dir.create(exfolder_image_folder) #Create directory as mentioned above
  
  dir.create(exfolder_output_folder) #Create directory as mentioned above
  
  file.copy(from = list_of_extracted_image_files, to = exfolder_image_folder, overwrite = TRUE) ##Copy files to new dir
  
  list_bregma_files <- list.files(path = exfolder_directories_cleaned, pattern = "Bregma", full.names = TRUE, recursive = TRUE) #Get .txt files containing bregma coords
  
  combined_data <- read.delim(list_bregma_files[1], header = FALSE, col.names = "Bregma") #Read first txt file in empty array to save making empty dataframe of right dimensions
  
  bregma_files_no_first <- list_bregma_files[2:length(list_bregma_files)] ## JUST SO WE DONT ADD THE FIRST txt IN THE array TWICE
  
  for (file in bregma_files_no_first) {
    temp_data <- read.delim(file, header = FALSE, col.names = "Bregma") #Read first txt file in empty array to save making empty dataframe of right dimensions
    combined_data <- rbind(combined_data, temp_data)
  }
   
  Bregma_array <- combined_data$Bregma
  
  Slice_pattern <- "Fused_Image_\\d+"
  
  Number_pattern <- "\\d+"
  
  Slice_array_reg_match <- regexpr(Slice_pattern, list_of_extracted_image_files)
  
  Slice_array <- regmatches(list_of_extracted_image_files, Slice_array_reg_match)
  
  ##Slice_array_reg_match_number_only <- regexpr(Number_pattern, Slice_array)
  
  ##Slice_number_array <- regmatches(Slice_array, Slice_array_reg_match_number_only)
  
  Bregma_to_Slice <- data.frame(Bregma = Bregma_array, Slice_number = Slice_array)
  
  Bregma_to_Slice <- Bregma_to_Slice[order(Bregma_to_Slice$Bregma, decreasing = TRUE),]
  
  Bregma_to_Slice$Row_num <- c(1:length(Bregma_to_Slice$Bregma))
  
  
  
  
  for (z in 1:length(Bregma_to_Slice$Row_num)) {
    temp_Fused_num <- Bregma_to_Slice$Slice_number[z] ##Get "Fused_Image_X" of all slices in order of Bregma anterior to posterior
    temp_path_file <- list.files(path = exfolder_image_folder, pattern = paste0(temp_Fused_num,".tif"), full.names = TRUE, recursive = TRUE) #Fetch the corresponding .tif image file
    cropped_path_file <- gsub('.{5}$', '', temp_path_file) ##Remove the .tiff part
    appended_path_file <- paste0(cropped_path_file,"_z_",z,"_slice.tiff") ##rename based on re-ordered count
    file.rename(from = temp_path_file, to = appended_path_file) ##as above
    ##print(appended_path_file) ##this doesnt do anything, just to check if it is running as intended
  }
  
  
  return(Bregma_to_Slice)
  
} ##Also returns a Table of co-ords re-ordered by Bregma position

Ex_D3_1_Bregma_Coords <- first_setup_brain_directory() ## Would recommend always naming here, so you don't forget which Brain you are currently working on 

paste(Ex_D3_1_Bregma_Coords$Bregma, collapse = ", ") ##Run this to get comma delimted bregma coords for SMART pipeline

paste(Ex_D3_1_Bregma_Coords$Row_num, collapse = ", ") ##Run this to get comma delimted Slice numbers for SMART pipeline

exfolder_image_folder ##This will be your "Registration" and "Segmentation" folder for SMART

exfolder_output_folder ##This will be your "Output" folder for SMART

## x x x x x x x x x x x x x x x x x x x x x x x x
## SMART PIPELINE - - - - - - - - - -
## x x x x x x x x x x x x x x x x x x x x x x x x


## ONLY DO THE FOLLOWING SETUP ONCE - YOU SHOULD USE THE SAME FILTER SETTINGS FOR ALL BRAIN SLICES AFTER FINALISING, SAVE F

folder <- "C:/Users/olikc/Desktop/PhD_Research/cFOS/Testing_use_of_wholebrain/test_sections_SLICES" ##Folder containing some example slices from your experiment

images_testing <- list.files(path = folder, full.names = TRUE) ## list all files in folder

images_testing[2] ## Checking if correct image you want to segment on

seg_testing <-segment(images_testing[2]) ##Run seg func

my_filter_save <- seg_testing$filter ##Save final filter params into object

setup <- setup_pl() ##Make the setup directory - Run this and input required infromation into the Console. 

setup <- im_sort(setup, extension = "tif") ##Image sort your tif files - not sure if you should do this 

setup$image_paths

setup <- get_savepaths(setup) ## Check where outputs of analysis will be saved

setup$savepaths ##Output to console


## RUN THE FOLLOWING CODE ONCE, THE FIRST TIME YOU LOAD IN A NEW BRAIN - - - - - - - - 
regi_loop(setup, filter = my_filter_save, autoloop = TRUE)
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


setup$image_paths$regi_paths

setup <- setup_pl()

setup <- im_sort(setup, extension = "tif")

setup$image_paths

setup <- get_savepaths(setup)

setup$savepaths

regi_loop(setup, filter = my_filter_save, autoloop = TRUE)

regi_loop(setup, regis = regis, filter = my_filter_save, reference = FALSE, touchup = 71)

filter_final <- filter_loop(setup, channel = "seg")

segs <- seg_loop(setup, my_filter_save)
##you have to check for plate names in Output folder - will add this tommorow

final_dataset <- forward_warp(setup = setup, segs = segs, regis = regis)

glassbrain_plot <- glassbrain2(final_dataset, high.res = "FALSE", hemisphere = "left")


#regions = -1.755, 0.02

setup$regi_channel

setup$seg_channel






folder <- "C:/Users/olikc/Desktop/PhD_Research/cFOS/Testing_use_of_wholebrain/test_sections_SLICES"

images <- list.files(path = folder, full.names = TRUE)

images[1]

seg<-segment(images[1])

names(seg)

my_filter_save <- seg$filter

plot(seg$soma$x, seg$soma$y, ylim=rev(range(seg$soma$y)))

quartz()

regi2<-registration(images[1],  coordinate= -1.755, filter=seg$filter)

dataset<-inspect.registration(regi2, seg, forward.warps = TRUE)

regi2 <- add.corrpoints(regi2, 1)

regi2<-registration(images[1], coordinate= -1.755, filter=seg$filter, correspondance = regi2)

regi2 <- change.corrpoints(regi2, 17:22)

save(seg, regi, file = 'Example_Section_hemi.Rdata')


get.atlas.image(coordinate = -1.755)

dataset <- inspect.registration(regi, seg)

dataset_right = dataset %>%
  filter(right.hemisphere == TRUE)

bargraph(dataset)

schematic.plot(dataset, 
               title=FALSE, 
               scale.bar=TRUE, 
               mm.grid=FALSE, 
               pch=21, 
               col=gray(0.1), 
               dev.size=c(13.54595, 10.65946)
)
schemat

##
## THIS CODE WILL COMBINE ALL CSV FILES IN YOUR EXPERIMENT FOLDER AND FORMAT IT INTO A USEFUL DATA TABLE
## SIMPLY PRESS CTRL + SHIFT + ENTER, AND SELECT THE EXPERIMENT FOLDER WHICH YOU RAN THE IMAGEJ MACRO ON
## YOUR RESULTS WILL BE SAVED INTO YOUR EXPERIMENT FOLDER AS A "RESULTS_CONC.CSV" FILE
##

exfolder <- tcltk::tk_choose.dir(default = "~/")

exfolder_ext <- paste(exfolder, "/Well_Averages", sep = "")

c_csv_extracted_data <- function() {
  
  list_of_extracted_csv <- list.files(path = exfolder_ext, pattern ="Well_Number_\\d+.csv", full.names = TRUE, recursive = TRUE) #Fetch all "Results_Conc.csv" files from the parent directory of all experiments
  
  combined_data <- read.csv(list_of_extracted_csv[1]) #Read first csv file in empty array to save making empty dataframe of right dimensions
  
  csv_files_no_first <- list_of_extracted_csv[2:length(list_of_extracted_csv)] ## JUST SO WE DONT ADD THE FIRST CSV IN THE LIST TWICE
  
  for (file in csv_files_no_first) { ##AS ABOVE BUT LOOPING THROUGH ALL REMAINING CSVS
    temp_data <- read.csv(file)
    combined_data <- rbind(combined_data, temp_data)
  }
  
  combined_data <- transform(combined_data, Well_number = sapply(regmatches(Label, regexec("[a-zA-Z]\\d+-Site", Label)), "[", 1))
  
  combined_data <- transform(combined_data, Well_number = sapply(regmatches(Well_number, regexec("[a-zA-Z]\\d+", Well_number)), "[", 1))
  
  unique_data <- combined_data[!duplicated(combined_data$Label), ]
  
  distinct_data <- subset(unique_data, select = c('Well_number', 'Slice','Mean'))  
  
  pred <- function(subset_df){    
    df <- data.frame(Well_number = subset_df$Well_number[[1]], 
                     Slice = subset_df$Slice[[1]],
                     Average_Intensity = mean(subset_df$Mean)
    )                      
    return(df)
  }
  
  averaged_data_list <- by(distinct_data, list(unique_data$Well_number,unique_data$Slice), pred)
  averaged_data <- do.call(rbind, averaged_data_list)
  
  averaged_data <- averaged_data[order(averaged_data$Well_number), ]
  
  return(averaged_data)
  
} #Function to loop and append through all "Well_Number_.csv" files in parent directory, add well labels, AND  and take averages for each slice/well

c_csv_extracted_data_no_average <- function() {
  
  list_of_extracted_csv <- list.files(path = exfolder_ext, pattern ="Well_Number_\\d+.csv", full.names = TRUE, recursive = TRUE) #Fetch all "Results_Conc.csv" files from the parent directory of all experiments
  
  combined_data <- read.csv(list_of_extracted_csv[1]) #Read first csv file in empty array to save making empty dataframe of right dimensions
  
  csv_files_no_first <- list_of_extracted_csv[2:length(list_of_extracted_csv)] ## JUST SO WE DONT ADD THE FIRST CSV IN THE LIST TWICE
  
  for (file in csv_files_no_first) { ##AS ABOVE BUT LOOPING THROUGH ALL REMAINING CSVS
    temp_data <- read.csv(file)
    combined_data <- rbind(combined_data, temp_data)
  }
  
  combined_data <- transform(combined_data, Well_number = sapply(regmatches(Label, regexec("[a-zA-Z]\\d+-Site", Label)), "[", 1))
  
  combined_data <- transform(combined_data, Well_number = sapply(regmatches(Well_number, regexec("[a-zA-Z]\\d+", Well_number)), "[", 1))
  
  unique_data <- combined_data[!duplicated(combined_data$Label), ]
  
  distinct_data <- subset(unique_data, select = c('Well_number', 'Slice','Mean'))  
  
  return(distinct_data)
  
} #Function to loop and append through all "Well_Number_.csv" files in parent directory, add well labels, AND  and take averages for each slice/well

my_data <- c_csv_extracted_data()

my_data_no_average <- c_csv_extracted_data_no_average()

write.csv(my_data , paste(exfolder, "/Results_Conc.csv", sep = ""), row.names = FALSE)

write.csv(my_data , paste(exfolder, "/Results_Conc_No_Average.csv", sep = ""), row.names = FALSE)



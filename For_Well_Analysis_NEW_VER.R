##-----------------------------------------------------------------------------
##  I G N O R E 
##  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

packages <- c("dplyr","stringr") ## packages required to get code running

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
options(scipen = 999) ##Disable scientific notation - dont like how they look - personal preference remove if u want
# Packages loading
invisible(lapply(packages, library, character.only = TRUE))
##-----------------------------------------------------------------------------
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## C H A N G E    S E T T I N G S   H E R E   B E F O R E   R U N N I N G 
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

boolean_filter <- F ## PLEASE SET TO FALSE IF YOU DO NOT WISH TO APPLY ANY FILTERS

Masking_Filter <- F ## ONLY WORKS IF YOU USED A CHANNEL FILTER DURING IMAGEJ ANALYSIS!!!!! IF SET TO TRUE, IF BOOLEAN_FILTER REMOVES A CELL IN ONE CHANNEL - IT WILL REMOVE THE SAME CELL FROM ALL OTHER CHANNELS

Masking_Filter_Pattern <- c("GFP") ## NAME OF THE CHANNEL YOU USED AS A FILTER - I GUESS IN THEORY YOU COULD CHANGE THE FILTERING CHANNEL EVEN IF YOU DIDNT STARDIST ACCORDING TO THIS

Global_Max_Mean <- 1000000 ## MAX CELL INTENSITY

Global_Min_Mean <- 100  ## MINIMUM CELL INTENSITY

Global_Max_Area <- 10000000 ## MAXIMUM CELL AREA
  
Global_Min_Area <- 1 ## MINIMUM CELL AREA

Channel_escape_pattern <- c("Brightfield") ## Add any channels you would like to escape boolean filtering - by default only Brightfield - do it like this -  c("Brightfield","GFP","SNAP") - etc. 
                                                        ## Don't worry, if masking filter is on, it will still remove the corresponding cells

## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##------------------------------------------------------------------------------
Microscope_Choice <- readline('Which Microscope was Used? \n 1. "EVOS" \n 2. "Nikon" \n')

if(boolean_filter == FALSE){
  Masking_Filter = FALSE
} ## In case someone forgot to change the setting

if(Microscope_Choice == "2") {

exfolder <- tcltk::tk_choose.dir(default = "~/")

iterate_rbind <-  function(csv_file_list) {
  
  combined_data <- read.csv(csv_file_list[1]) #Read first csv file in empty array to save making empty dataframe of right dimensions
  
  csv_files_no_first <- csv_file_list[2:length(csv_file_list)] ## JUST SO WE DONT ADD THE FIRST CSV IN THE LIST TWICE
  
  for (file in csv_files_no_first) { ##AS ABOVE BUT LOOPING THROUGH ALL REMAINING CSVS
    temp_data <- read.csv(file)
    combined_data <- dplyr::bind_rows(combined_data, temp_data)
  }
  
  return(combined_data)
  
} #func to rbind all rows in list - actually uses bind_rows from dplyr - tomato tomatoe

list_of_extracted_csv <- list.files(path = exfolder, pattern ="Well_Number_\\d+.csv", full.names = TRUE, recursive = TRUE) #Fetch all "Results_Conc.csv" files from the parent directory of all experiments

# Step 1: Extract prefixes
prefixes <- unique(sub("Well_Number.*", "", list_of_extracted_csv))

# Step 2: Split the vector into groups based on these prefixes
split_by_prefix <- lapply(prefixes, function(prefix) {
  grep(paste0("^", prefix, "Well_Number"), list_of_extracted_csv, value = TRUE)
})

# Step 3: Assign names to the list - mostly for readability
names(split_by_prefix) <- prefixes

combined_list <- lapply(split_by_prefix, iterate_rbind) ##For each Channel Grouping bind csv files together into 1 dataframe

testing2 <- combined_list[[1]]

if(Masking_Filter == TRUE){

    names(combined_list)
    Masking_FIlter_Pattern_REGEXED = paste0("/",Masking_Filter_Pattern,"/")
    match_index <- grep(Masking_FIlter_Pattern_REGEXED, names(combined_list))
    if(length(match_index) > 0) {
      combined_list <- c(combined_list[match_index], combined_list[-match_index])
    }
   names(combined_list)
}

Filter_iterate <- function(list_element) {
  active_dataframe <- as.data.frame(list_element)
  active_dataframe_one_row <- active_dataframe[1,]
  colnames(active_dataframe) <- sub(".*\\.", "", colnames(active_dataframe))
  if(boolean_filter == TRUE && any(grepl(active_dataframe_one_row$Channel_Name, Channel_escape_pattern)) == FALSE && Masking_Filter == FALSE){
  active_dataframe[ , grepl("Mean", names(active_dataframe))] <- lapply(active_dataframe[ , grepl("Mean", names(active_dataframe))], function(col) { ##For all rows but only columns containg "Mean", apply the following filters
      col[col > Global_Max_Mean] <- NA  # Set values larger than X to NA
      col[col < Global_Min_Mean] <- NA # Set values smaller than X to NA
    
    col[col = 0] <- NA ##So empty columns - i.e. FOVs which had less cells then other ones -  are not later included in Mean calculations - set to NA
    return(col)
  }
  ) ##Filter Mean columns
  active_dataframe[ , grepl("Area", names(active_dataframe))] <- lapply(active_dataframe[ , grepl("Area", names(active_dataframe))], function(col) { ##For all rows but only columns containg "Mean", apply the following filters
      col[col > Global_Max_Area] <- NA  # Set values larger than X to NA
      col[col < Global_Min_Area] <- NA # Set values smaller than X to NA
    
    col[col = 0] <- NA ##So empty columns - i.e. FOVs which had less cells then other ones -  are not later included in Mean calculations - set to NA
    return(col)
  })##Filter Area columns
  }
  if(boolean_filter == TRUE && any(grepl(active_dataframe_one_row$Channel_Name, Masking_Filter_Pattern)) == TRUE && Masking_Filter == TRUE){
    active_dataframe[ , grepl("Mean", names(active_dataframe))] <- lapply(active_dataframe[ , grepl("Mean", names(active_dataframe))], function(col) { ##For all rows but only columns containg "Mean", apply the following filters
      col[col > Global_Max_Mean] <- NA  # Set values larger than X to NA
      col[col < Global_Min_Mean] <- NA # Set values smaller than X to NA
      
      col[col = 0] <- NA ##So empty columns - i.e. FOVs which had less cells then other ones -  are not later included in Mean calculations - set to NA
      return(col)
    }
    ) ##Filter Mean columns
    active_dataframe[ , grepl("Area", names(active_dataframe))] <- lapply(active_dataframe[ , grepl("Area", names(active_dataframe))], function(col) { ##For all rows but only columns containg "Mean", apply the following filters
      col[col > Global_Max_Area] <- NA  # Set values larger than X to NA
      col[col < Global_Min_Area] <- NA # Set values smaller than X to NA
      
      col[col = 0] <- NA ##So empty columns - i.e. FOVs which had less cells then other ones -  are not later included in Mean calculations - set to NA
      return(col)
    })##Filter Area columns
  }
  
  active_dataframe[active_dataframe == 0] <- NA
  mean_cols <- grep("Mean", colnames(active_dataframe), value = TRUE)
  active_dataframe <- active_dataframe %>%
    mutate(Filtered_ROI = rowSums(across(all_of(mean_cols), ~ . != 0), na.rm = TRUE))
  
  return(active_dataframe) 
} ##Function to filter columns based on area and mean - Global values are on top of script

filtered_list <- lapply(combined_list, Filter_iterate) ##apply filter to all channel dataframes

NA_clean_up <- function(list_element) {
  active_dataframe <- as.data.frame(list_element)
  active_dataframe_one_row <- active_dataframe[1,]
  colnames(active_dataframe) <- sub(".*\\.", "", colnames(active_dataframe))
  
  # Step 1: Identify suffixes based on pattern matching - All cells should have same suffixes so no point doubling or using intersect
  mean_cols <- grep("Mean", colnames(active_dataframe), value = TRUE)
  
  # Step 2: Extract the numeric suffixes (the part after the "_") to find matching pairs
  num_suffixes <- str_extract(mean_cols, "\\d+$")
  
  for (suffix in num_suffixes) {
    mean_col <- paste0("Mean", suffix)
    area_col <- paste0("Area", suffix)
    
    # Vectorized ifelse to set both columns to NA if either one is NA in that row
    na_indices <- is.na(active_dataframe[[mean_col]]) | is.na(active_dataframe[[area_col]])
    
    active_dataframe[na_indices, c(mean_col, area_col)] <- NA
  }
  if(Masking_Filter == TRUE && grepl(Masking_Filter_Pattern,active_dataframe_one_row$Channel_Name) == TRUE){
    na_positions <- is.na(active_dataframe)
    na_indices <- which(na_positions, arr.ind = T) ## convert into indices for data frames
    assign("na_indices", na_indices, envir = .GlobalEnv) 
  }
  return(active_dataframe)
} ##Function to remove NA values from Mean if Area was removed and vice versa

filtered_list_NA_cleaned <- lapply(filtered_list, NA_clean_up) ##apply NA clean to all channel dataframes

Masking_filter <- function(list_element) {
  active_dataframe <- as.data.frame(list_element)
  active_dataframe_one_row <- active_dataframe[1,]
  if(Masking_Filter == TRUE  && any(grepl(active_dataframe_one_row$Channel_Name,"Brightfield")) == FALSE){
    active_dataframe[na_indices] <- NA
    mean_cols <- grep("Mean", colnames(active_dataframe), value = TRUE)
    active_dataframe <- active_dataframe %>%
      mutate(Filtered_ROI = rowSums(across(all_of(mean_cols), ~ . != 0), na.rm = TRUE))
    return(active_dataframe)
  }else{
    return(active_dataframe)
  }
} ## Needs to be done as position of filter channel is not nessarily 1st in factor levels - will be dependent on alphebetical sorting

filtered_list_NA_cleaned_Masking_filtered <- lapply(filtered_list_NA_cleaned, Masking_filter)

no_dup_rows <- function(list_element) {
  testing_un_NA_unique <- list_element[!duplicated(list_element$Label_ID), ]
  testing_un_NA_unique_2 <- testing_un_NA_unique[(testing_un_NA_unique$Label_ID != 0),]
  testing_un_NA_unique_2 <- testing_un_NA_unique[is.na(testing_un_NA_unique$Label_ID) != T,]
  return(testing_un_NA_unique_2)
} ##Func to remove dup rows and nonsensical rows - i.e. If for loop went and measured an empty image etc.

filtered_list_cleaned_FINAL <- lapply(filtered_list_NA_cleaned_Masking_filtered, no_dup_rows) ##Apply above func to all channel dataframes

row_wise_mean_and_area_avg <- function(list_element) {
  list_element$Average_Cell_Intensity <- rowMeans(list_element[grep('^Mean', names(list_element))], na.rm = T) ##Take get an average of mean for each FOV
  
  list_element$Area_Sum <- rowSums(list_element[grep('^Area', names(list_element))], na.rm = T)##To get a sum of fluorescent area
  
  list_element$Average_Area <- rowMeans(list_element[grep('^Area', names(list_element))], na.rm = T)##To get a sum of fluorescent area
  
  list_element <- transform(list_element, Well_ID = sapply(regmatches(Label_ID, regexec("MMStack_[a-zA-Z]\\d+", Label_ID)), "[", 1)) ##Make Well_ID more readable
  
  list_element <- transform(list_element, Well_ID = sapply(regmatches(Well_ID, regexec("[a-zA-Z]\\d+", Well_ID)), "[", 1)) ##As above
  
  list_element <- transform(list_element, Timepoint = sapply(regmatches(Label_ID, regexec(".tif:\\d+", Label_ID)), "[", 1)) ##As above but for timepoint
  
  list_element <- transform(list_element, Timepoint = sapply(regmatches(Timepoint, regexec("\\d+", Timepoint)), "[", 1)) ##As above but for timepoint
  
  return(list_element)
} ##Here also adding Well_ID variable

dataframes_summary_stats <- lapply(filtered_list_cleaned_FINAL, row_wise_mean_and_area_avg)

summary_stats_selected <- lapply(dataframes_summary_stats, function(df){
  read_table <- as.data.frame(df)
  if(read_table[1,]$Channel_Name != "Brightfield"){ ##Brightfield will not have Filtered_ROI label as will not use ROI_Counter
  df_summed <- subset(read_table, select = c('Well_ID', 'Label','Average_Cell_Intensity','Average_Area','Area_Sum','Channel_Name', 'Timepoint','Filtered_ROI'))
  }else{
    df_summed <- subset(read_table, select = c('Well_ID', 'Label','Average_Cell_Intensity','Average_Area','Area_Sum','Channel_Name','Timepoint'))
  }
  return(df_summed)
})

summary_stats_rbind <- bind_rows(summary_stats_selected)

summary_stats_rbind<- transform(summary_stats_rbind, Label = sapply(regmatches(Label, regexec("FOV_Number_\\d+", Label)), "[", 1))

if(any(grepl("Brightfield", summary_stats_rbind$Channel_Name))==FALSE){

summary_stats_rbind_averaged <- summary_stats_rbind %>%
  mutate(Well_Label_Timepoint_Channel_Name = paste(Well_ID,Timepoint,Channel_Name, sep = "_")) %>%
  group_by(Well_Label_Timepoint_Channel_Name) %>%
  mutate( Average_Cell_Intensity_Well = mean(Average_Cell_Intensity, na.rm = T),
          Average_Cell_Number = mean(Filtered_ROI, na.rm = T),
          Average_Area_Well = mean(Average_Area, na.rm = T),
          Total_Area_Well = sum(Area_Sum)) %>%
  ungroup() %>%
  dplyr::select(-c(Filtered_ROI,Average_Cell_Intensity,Well_Label_Timepoint_Channel_Name,Label,Average_Area,Area_Sum)) %>%
  distinct()
} ##This is so shit because it writes over the global dataframe summary_stats_rbind so you have to call it twice. arghh

if(any(grepl("Brightfield", summary_stats_rbind$Channel_Name))==TRUE) {

Brightfield_area_func <- function(){
  
  summary_stats_rbind_bf <- summary_stats_rbind %>% ##Get BF Area
    filter(Channel_Name == "Brightfield") %>%
    mutate(BF_Area = Area_Sum) %>%
    mutate(Well_Label = paste(Well_ID, Label)) %>%
    dplyr::select(BF_Area, Well_Label)
  
  summary_stats_rbind_non_bf <- summary_stats_rbind %>% ##Set non BF channels to Na
    mutate(Well_Label = paste(Well_ID, Label))
  
  summary_stats_rbind_rejoin <- merge(summary_stats_rbind_bf,summary_stats_rbind_non_bf) ##Rejoined
  
  summary_stats_rbind_rejoin <- subset(summary_stats_rbind_rejoin, select = -c(Well_Label))
  
  summary_stats_rbind_rejoin <- summary_stats_rbind_rejoin %>%
    mutate(Fluorescent_Area_Prop = Area_Sum/BF_Area)

  summary_stats_rbind_rejoin <- summary_stats_rbind_rejoin[str_order(summary_stats_rbind_rejoin$Label, numeric = TRUE),]
  summary_stats_rbind_rejoin <- summary_stats_rbind_rejoin[str_order(summary_stats_rbind_rejoin$Well_ID),]
  summary_stats_rbind_rejoin <- summary_stats_rbind_rejoin[str_order(summary_stats_rbind_rejoin$Channel_Name),]

  return(summary_stats_rbind_rejoin)
}

summary_stats_rbind <- Brightfield_area_func()

summary_stats_rbind_averaged <- summary_stats_rbind %>%
  mutate(Well_Label_Timepoint_Channel_Name = paste(Well_ID,Timepoint,Channel_Name, sep = "_")) %>%
  group_by(Well_Label_Timepoint_Channel_Name) %>%
  mutate( Average_Cell_Intensity_Well = mean(Average_Cell_Intensity, na.rm = T),
          Average_Cell_Number = mean(Filtered_ROI, na.rm = T),
          Average_Area_Well = mean(Average_Area, na.rm = T),
          Total_Area_Well = sum(Area_Sum),
          Average_Fluorescent_Prop = mean(Fluorescent_Area_Prop, na.rm = T)) %>%
  ungroup() %>%
  dplyr::select(-c(Filtered_ROI,Average_Cell_Intensity,Well_Label_Timepoint_Channel_Name,Label,Average_Area,Area_Sum,BF_Area, Fluorescent_Area_Prop)) %>%
  distinct()

 } ##For if you have bright field

Raw_data_clean_up_func <- function(list_element) {
  list_element <- transform(list_element, Well_ID = sapply(regmatches(Label_ID, regexec("MMStack_[a-zA-Z]\\d+", Label_ID)), "[", 1)) ##Make Well_ID more readable
  
  list_element <- transform(list_element, Well_ID = sapply(regmatches(Well_ID, regexec("[a-zA-Z]\\d+", Well_ID)), "[", 1)) ##As above
  
  list_element <- transform(list_element, Timepoint = sapply(regmatches(Label_ID, regexec(".tif:\\d+", Label_ID)), "[", 1)) ##As above but for timepoint
  
  list_element <- transform(list_element, Timepoint = sapply(regmatches(Timepoint, regexec("\\d+", Timepoint)), "[", 1))
}

Raw_data_cleaned <- lapply(filtered_list_cleaned_FINAL, Raw_data_clean_up_func)

rbinded_list_raw_data  <- dplyr::bind_rows(Raw_data_cleaned)
raw_data_for_export <- rbinded_list_raw_data %>% 
  relocate(Channel_Name,Well_ID,Label,Filtered_ROI,Timepoint, .before = Label) %>% ##Move Info Columns to beginning for readability
  dplyr::select(-c(X,Label_ID)) ##Remove duplicate/unimportant columns

raw_data_for_export_mean_only <- raw_data_for_export %>%
  dplyr::select(-c(starts_with("Area")))

write.csv(summary_stats_rbind , paste(exfolder, "/Results_Conc_Cleaned_No_Average.csv", sep = ""), row.names = FALSE) ##Save anotated data as .csv file

write.csv(summary_stats_rbind_averaged , paste(exfolder, "/Results_Conc_Cleaned_Averaged.csv", sep = ""), row.names = FALSE) ##Same but for averaged

write.csv(raw_data_for_export , paste(exfolder, "/Raw_Data.csv", sep = ""), row.names = FALSE)

write.csv(raw_data_for_export_mean_only , paste(exfolder, "/Raw_Data_Mean_Only.csv", sep = ""), row.names = FALSE) ##For people who dont use R but want to plot average traces
}
                                  
if(Microscope_Choice == "1") {
  
  exfolder <- tcltk::tk_choose.dir(default = "~/")
  
  iterate_rbind <-  function(csv_file_list) {
    
    combined_data <- read.csv(csv_file_list[1]) #Read first csv file in empty array to save making empty dataframe of right dimensions
    
    csv_files_no_first <- csv_file_list[2:length(csv_file_list)] ## JUST SO WE DONT ADD THE FIRST CSV IN THE LIST TWICE
    
    for (file in csv_files_no_first) { ##AS ABOVE BUT LOOPING THROUGH ALL REMAINING CSVS
      temp_data <- read.csv(file)
      combined_data <- dplyr::bind_rows(combined_data, temp_data)
    }
    
    return(combined_data)
    
  } #func to rbind all rows in list - actually uses bind_rows from dplyr - tomato tomatoe
  
  list_of_extracted_csv <- list.files(path = exfolder, pattern ="Well_Number_\\d+.csv", full.names = TRUE, recursive = TRUE) #Fetch all "Results_Conc.csv" files from the parent directory of all experiments
  
  # Step 1: Extract prefixes
  prefixes <- unique(sub("Well_Number.*", "", list_of_extracted_csv))
  
  # Step 2: Split the vector into groups based on these prefixes
  split_by_prefix <- lapply(prefixes, function(prefix) {
    grep(paste0("^", prefix, "Well_Number"), list_of_extracted_csv, value = TRUE)
  })
  
  # Step 3: Assign names to the list - mostly for readability
  names(split_by_prefix) <- prefixes
  
  combined_list <- lapply(split_by_prefix, iterate_rbind) ##For each Channel Grouping bind csv files together into 1 dataframe
  
  if(Masking_Filter == TRUE){
    
    names(combined_list)
    Masking_FIlter_Pattern_REGEXED = paste0("/",Masking_Filter_Pattern,"/")
    match_index <- grep(Masking_FIlter_Pattern_REGEXED, names(combined_list))
    if(length(match_index) > 0) {
      combined_list <- c(combined_list[match_index], combined_list[-match_index])
    }
    names(combined_list)
  }
  
  Filter_iterate <- function(list_element) {
    active_dataframe <- as.data.frame(list_element)
    colnames(active_dataframe) <- sub(".*\\.", "", colnames(active_dataframe))
    active_dataframe_one_row <- active_dataframe[1,]
    if(boolean_filter == TRUE && any(grepl(active_dataframe_one_row$Channel_Name,Channel_escape_pattern)) == FALSE && Masking_Filter == FALSE){
      active_dataframe[ , grepl("Mean", names(active_dataframe))] <- lapply(active_dataframe[ , grepl("Mean", names(active_dataframe))], function(col) { ##For all rows but only columns containg "Mean", apply the following filters
        col[col > Global_Max_Mean] <- NA  # Set values larger than X to NA
        col[col < Global_Min_Mean] <- NA # Set values smaller than X to NA
        
        col[col = 0] <- NA ##So empty columns - i.e. FOVs which had less cells then other ones -  are not later included in Mean calculations - set to NA
        return(col)
      }
      ) ##Filter Mean columns
      active_dataframe[ , grepl("Area", names(active_dataframe))] <- lapply(active_dataframe[ , grepl("Area", names(active_dataframe))], function(col) { ##For all rows but only columns containg "Area", apply the following filters
        col[col > Global_Max_Area] <- NA  # Set values larger than X to NA
        col[col < Global_Min_Area] <- NA # Set values smaller than X to NA
        
        col[col = 0] <- NA ##So empty columns - i.e. FOVs which had less cells then other ones -  are not later included in Mean calculations - set to NA
        return(col)
      }) ##Filter Area columns
    }
    if(boolean_filter == TRUE && any(grepl(active_dataframe_one_row$Channel_Name, Masking_Filter_Pattern)) == TRUE && Masking_Filter == TRUE){
      active_dataframe[ , grepl("Mean", names(active_dataframe))] <- lapply(active_dataframe[ , grepl("Mean", names(active_dataframe))], function(col) { ##For all rows but only columns containg "Mean", apply the following filters
        col[col > Global_Max_Mean] <- NA  # Set values larger than X to NA
        col[col < Global_Min_Mean] <- NA # Set values smaller than X to NA
        
        col[col = 0] <- NA ##So empty columns - i.e. FOVs which had less cells then other ones -  are not later included in Mean calculations - set to NA
        return(col)
      }
      ) ##Filter Mean columns
      active_dataframe[ , grepl("Area", names(active_dataframe))] <- lapply(active_dataframe[ , grepl("Area", names(active_dataframe))], function(col) { ##For all rows but only columns containg "Mean", apply the following filters
        col[col > Global_Max_Area] <- NA  # Set values larger than X to NA
        col[col < Global_Min_Area] <- NA # Set values smaller than X to NA
        
        col[col = 0] <- NA ##So empty columns - i.e. FOVs which had less cells then other ones -  are not later included in Mean calculations - set to NA
        return(col)
      })##Filter Area columns
    }
    active_dataframe[active_dataframe == 0] <- NA
    mean_cols <- grep("Mean", colnames(active_dataframe), value = TRUE)
    active_dataframe <- active_dataframe %>%
      mutate(Filtered_ROI = rowSums(across(all_of(mean_cols), ~ . != 0), na.rm = TRUE))
    
    return(active_dataframe) 
  } ##Function to filter columns based on area and mean - Global values are on top of script
  
  filtered_list <- lapply(combined_list, Filter_iterate) ##apply filter to all channel dataframes

  NA_clean_up <- function(list_element) {
    active_dataframe <- as.data.frame(list_element)
    active_dataframe_one_row <- active_dataframe[1,]
  
    # Step 1: Identify suffixes based on pattern matching - All cells should have same suffixes so no point doubling or using intersect
    mean_cols <- grep("Mean", colnames(active_dataframe), value = TRUE)
    
    # Step 2: Extract the numeric suffixes (the part after the "_") to find matching pairs
    num_suffixes <- str_extract(mean_cols, "\\d+$")
    
    for (suffix in num_suffixes) {
      mean_col <- paste0("Mean", suffix)
      area_col <- paste0("Area", suffix)
      
      # Vectorized ifelse to set both columns to NA if either one is NA in that row
      na_indices <- is.na(active_dataframe[[mean_col]]) | is.na(active_dataframe[[area_col]])
      
      active_dataframe[na_indices, c(mean_col, area_col)] <- NA
    }
    if(Masking_Filter == TRUE && any(grepl(active_dataframe_one_row$Channel_Name, Masking_Filter_Pattern) == TRUE)){
      na_positions <- is.na(active_dataframe) ## Get logical matrix of values which have been filtered out/ are NA
      na_indices <- which(na_positions, arr.ind = T) ## convert into indices for data frames
      assign("na_indices", na_indices, envir = .GlobalEnv) 
    }
    return(active_dataframe)
  } ##Function to remove NA values from Mean if Area was removed and vice versa
  
  filtered_list_NA_cleaned <- lapply(filtered_list, NA_clean_up) ##apply NA clean to all channel dataframes
  
  Masking_filter <- function(list_element) {
    active_dataframe <- as.data.frame(list_element)
    active_dataframe_one_row <- active_dataframe[1,]
    if(Masking_Filter == TRUE  && any(grepl(active_dataframe_one_row$Channel_Name,"Brightfield")) == FALSE){
      active_dataframe[na_indices] <- NA
      mean_cols <- grep("Mean", colnames(active_dataframe), value = TRUE)
      active_dataframe <- active_dataframe %>%
        mutate(Filtered_ROI = rowSums(across(all_of(mean_cols), ~ . != 0), na.rm = TRUE))
      return(active_dataframe)
    }else{
      return(active_dataframe)
    }
  } ## Needs to be done as position of filter channel is not nessarily 1st in factor levels - will be dependent on alphebetical sorting
  
  filtered_list_NA_cleaned_Masking_filtered <- lapply(filtered_list_NA_cleaned, Masking_filter)
  
  no_dup_rows <- function(list_element) {
    testing_un_NA_unique <- list_element[!duplicated(list_element$Label_ID), ]
    testing_un_NA_unique_2 <- testing_un_NA_unique[(testing_un_NA_unique$Label_ID != 0),]
    testing_un_NA_unique_2 <- testing_un_NA_unique[is.na(testing_un_NA_unique$Label_ID) != T,]
    return(testing_un_NA_unique_2)
  } ##Func to remove dup rows and nonsensical rows - i.e. If for loop went and measured an empty image etc.
  
  filtered_list_cleaned_FINAL <- lapply(filtered_list_NA_cleaned_Masking_filtered, no_dup_rows) ##Apply above func to all channel dataframes
  
  row_wise_mean_and_area_avg <- function(list_element) {
    list_element$Average_Cell_Intensity <- rowMeans(list_element[grep('^Mean', names(list_element))], na.rm = T) ##Take get an average of mean for each FOV
    
    list_element$Area_Sum <- rowSums(list_element[grep('^Area', names(list_element))], na.rm = T)##To get a sum of fluorescent area
    
    list_element$Average_Area <- rowMeans(list_element[grep('^Area', names(list_element))], na.rm = T)##To get a sum of fluorescent area
    
    list_element <- transform(list_element, Well_ID = sapply(regmatches(Label_ID, regexec("[a-zA-Z]\\d+f", Label_ID)), "[", 1)) ##Make Well_ID more readable
    
    list_element <- transform(list_element, Well_ID = sapply(regmatches(Well_ID, regexec("[a-zA-Z]\\d+", Well_ID)), "[", 1)) ##As above
    
    list_element <- transform(list_element, Well_ID = gsub("([A-Za-z])0([0-9])", "\\1\\2", Well_ID)) 
    
    list_element <- transform(list_element, Timepoint = sapply(regmatches(Label_ID, regexec("p\\d+", Label_ID)), "[", 1)) ##As above but for timepoint
    
    list_element <- transform(list_element, Timepoint = sapply(regmatches(Timepoint, regexec("\\d+", Timepoint)), "[", 1)) ##As above but for timepoint
    
    list_element <- transform(list_element, Timepoint = as.numeric(Timepoint))
    
    list_element <- transform(list_element, Timepoint = Timepoint + 1)
    
    
    
    
    return(list_element)
  } ##Here also adding Well_ID variable
  
  dataframes_summary_stats <- lapply(filtered_list_cleaned_FINAL, row_wise_mean_and_area_avg)
  
  summary_stats_selected <- lapply(dataframes_summary_stats, function(df){
    read_table <- as.data.frame(df)
    if(read_table[1,]$Channel_Name != "Brightfield"){
      df_summed <- subset(read_table, select = c('Well_ID', 'Label','Average_Cell_Intensity','Average_Area','Area_Sum','Channel_Name','Timepoint','Filtered_ROI'))
    }else{
      df_summed <- subset(read_table, select = c('Well_ID', 'Label','Average_Cell_Intensity','Average_Area','Area_Sum','Channel_Name','Timepoint'))
    }
    return(df_summed)
  })
  
  summary_stats_rbind <- bind_rows(summary_stats_selected)
  
  summary_stats_rbind<- transform(summary_stats_rbind, Label = sapply(regmatches(Label, regexec("FOV_Number_\\d+", Label)), "[", 1))
  
  if(any(grepl("Brightfield", summary_stats_rbind$Channel_Name))==FALSE){
    
    summary_stats_rbind_averaged <- summary_stats_rbind %>%
      mutate(Well_Label_Timepoint_Channel_Name = paste(Well_ID,Timepoint,Channel_Name, sep = "_")) %>%
      group_by(Well_Label_Timepoint_Channel_Name) %>%
      mutate( Average_Cell_Intensity_Well = mean(Average_Cell_Intensity, na.rm = T),
              Average_Cell_Number = mean(Filtered_ROI, na.rm = T),
              Average_Area_Well = mean(Average_Area, na.rm = T),
              Total_Area_Well = sum(Area_Sum)) %>%
      ungroup() %>%
      dplyr::select(-c(Filtered_ROI,Average_Cell_Intensity,Well_Label_Timepoint_Channel_Name,Label,Average_Area,Area_Sum)) %>%
      distinct()
  } ##This is so shit because it writes over the global dataframe summary_stats_rbind so you have to call it twice. arghh
  
  if(any(grepl("Brightfield", summary_stats_rbind$Channel_Name))==TRUE) {
    
    Brightfield_area_func <- function(){
      
      summary_stats_rbind_bf <- summary_stats_rbind %>% ##Get BF Area
        filter(Channel_Name == "Brightfield") %>%
        mutate(BF_Area = Area_Sum) %>%
        mutate(Well_Label = paste(Well_ID, Label)) %>%
        dplyr::select(BF_Area, Well_Label)
      
      summary_stats_rbind_non_bf <- summary_stats_rbind %>% ##Set non BF channels to Na
        mutate(Well_Label = paste(Well_ID, Label))
      
      summary_stats_rbind_rejoin <- merge(summary_stats_rbind_bf,summary_stats_rbind_non_bf) ##Rejoined
      
      summary_stats_rbind_rejoin <- subset(summary_stats_rbind_rejoin, select = -c(Well_Label))
      
      summary_stats_rbind_rejoin <- summary_stats_rbind_rejoin %>%
        mutate(Fluorescent_Area_Prop = Area_Sum/BF_Area)
      
      summary_stats_rbind_rejoin <- summary_stats_rbind_rejoin[str_order(summary_stats_rbind_rejoin$Label, numeric = TRUE),]
      summary_stats_rbind_rejoin <- summary_stats_rbind_rejoin[str_order(summary_stats_rbind_rejoin$Well_ID),]
      summary_stats_rbind_rejoin <- summary_stats_rbind_rejoin[str_order(summary_stats_rbind_rejoin$Channel_Name),]
      
      return(summary_stats_rbind_rejoin)
    }
    
    summary_stats_rbind <- Brightfield_area_func()
    
    summary_stats_rbind_averaged <- summary_stats_rbind %>%
      mutate(Well_Label_Timepoint_Channel_Name = paste(Well_ID,Timepoint,Channel_Name, sep = "_")) %>%
      group_by(Well_Label_Timepoint_Channel_Name) %>%
      mutate( Average_Cell_Intensity_Well = mean(Average_Cell_Intensity, na.rm = T),
              Average_Cell_Number = mean(Filtered_ROI, na.rm = T),
              Average_Area_Well = mean(Average_Area, na.rm = T),
              Total_Area_Well = sum(Area_Sum),
              Average_Fluorescent_Prop = mean(Fluorescent_Area_Prop, na.rm = T)) %>%
      ungroup() %>%
      dplyr::select(-c(Filtered_ROI,Average_Cell_Intensity,Well_Label_Timepoint_Channel_Name,Label,Average_Area,Area_Sum,BF_Area, Fluorescent_Area_Prop)) %>%
      distinct()
    
  } 
  
  Raw_data_clean_up_func <- function(list_element) {
    list_element <- transform(list_element, Well_ID = sapply(regmatches(Label_ID, regexec("MMStack_[a-zA-Z]\\d+", Label_ID)), "[", 1)) ##Make Well_ID more readable
    
    list_element <- transform(list_element, Well_ID = sapply(regmatches(Well_ID, regexec("[a-zA-Z]\\d+", Well_ID)), "[", 1)) ##As above
    
    list_element <- transform(list_element, Timepoint = sapply(regmatches(Label_ID, regexec(".tif:\\d+", Label_ID)), "[", 1)) ##As above but for timepoint
    
    list_element <- transform(list_element, Timepoint = sapply(regmatches(Timepoint, regexec("\\d+", Timepoint)), "[", 1))
  }
  
  Raw_data_cleaned <- lapply(filtered_list_cleaned_FINAL, Raw_data_clean_up_func)
  
  rbinded_list_raw_data  <- dplyr::bind_rows(Raw_data_cleaned)
  raw_data_for_export <- rbinded_list_raw_data %>% 
    relocate(Channel_Name,Well_ID,Label,Filtered_ROI,Timepoint, .before = Label) %>% ##Move Info Columns to beginning for readability
    dplyr::select(-c(X,Label_ID)) ##Remove duplicate/unimportant columns
  
  raw_data_for_export_mean_only <- raw_data_for_export %>%
    dplyr::select(-c(starts_with("Area")))
  
  write.csv(summary_stats_rbind , paste(exfolder, "/Results_Conc_Cleaned_No_Average.csv", sep = ""), row.names = FALSE) ##Save anotated data as .csv file
  
  write.csv(summary_stats_rbind_averaged , paste(exfolder, "/Results_Conc_Cleaned_Averaged.csv", sep = ""), row.names = FALSE) ##Same but for averaged
  
  write.csv(raw_data_for_export , paste(exfolder, "/Raw_Data.csv", sep = ""), row.names = FALSE)
  
  write.csv(raw_data_for_export_mean_only , paste(exfolder, "/Raw_Data_Mean_Only.csv", sep = ""), row.names = FALSE) ##For people who dont use R but want to plot average traces
}

if(boolean_filter == TRUE){
  Filter_Settings <- data.frame(Maximum_Area = Global_Max_Area, Minimum_Area = Global_Min_Area, Maximum_Intensity = Global_Max_Mean, Minimum_Intensity = Global_Min_Mean, Escaped_Channels = Channel_escape_pattern)
  if(Masking_Filter == TRUE){
    Filter_Settings <- data.frame(Maximum_Area = Global_Max_Area, Minimum_Area = Global_Min_Area, Maximum_Intensity = Global_Max_Mean, Minimum_Intensity = Global_Min_Mean, Escaped_Channels = paste0(Channel_escape_pattern, collapse = ","), Masking_Filter_Channel = Masking_Filter_Pattern)
  }
  write.csv(Filter_Settings , paste(exfolder, "/Filter_Settings.csv", sep = ""), row.names = FALSE) ##Save anotated data as .csv file
  
} ## In case someone forgot to change the setting
##


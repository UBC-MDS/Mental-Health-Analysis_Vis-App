#! /usr/bin/env Rscript

###################################################
## Project: 00_clean_data.csv 
## Date: 2019 Jan 
## Author: Mengda (Albert) Yu and Chao Wang
## Script purpose: 
## Example: Rscript 
##################################################

# libraries 
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(maps))
suppressPackageStartupMessages(library(countrycode))

# read in file 
raw_data <- read.csv("./data/survey.csv", na.strings = "EMPTY")
dim(raw_data)
raw_data <- as_tibble(raw_data)

##################################################
## Section: clean age
##################################################

# This contains 8 outliers
age_outlier <-
  raw_data %>% 
  filter(Age < 16 | Age > 75)

# We include participator whose age is between 16 and 75 (employment consideration)
age_clean <- 
  raw_data %>%
  filter(Age >= 16 & Age < 75) %>%
  mutate(Age = as.integer(Age))

# We can group age into four bins if you want 
# Fresh (Later Adolescence): 16 - 24
# Junior (Early Adulthood): 25 - 34
# Senior (Middle Adulthood): 35 - 60
# Super (Later Adulthood): >60
# age_clean$Age<- cut(age_clean$Age, breaks = c(16, 24, 34, 60, 75), 
#                     labels = c('Fresh', 'Junior', 'Senior', 'Super'))

age_clean %>%
  ggplot(aes(x=Age)) +
  geom_bar() + 
  theme_bw() +
  xlab("Age") + 
  ylab("Density") +
  ggtitle("The distribution of age in the 2014 Mental Health Tech Survey") +
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5))

age_clean %>%
  group_by(family_history) %>%
  summarise (n = n()) %>%
  mutate(freq = n / sum(n) * 100)
##################################################
## Section: Clean gender
##################################################    

# lower case gender 
gender_clean <- 
  age_clean %>%
  mutate(Gender = tolower(Gender))

# Check how many kinds of gender 
# unique(gender_clean$Gender)
# length(unique(gender_clean$Gender))

## Cisgender: individuals whose biological sex, gender expression, and gender identity neatly align.
cis_female <- c('female', 'cis female', 'f', 'woman', 'femake', 'female ', 
                'cis-female/femme', 'female (cis)', 'femail')
cis_male <- c('m', 'male', 'male-ish', 'maile', 'cis male', 'mal', 'male (cis)', 
              'make', 'male ', 'man', 'msle', 'mail', 'malr', 'cis man')

## Transgender: individuals whose gender identity does not match their assigned birth gender.
trans_female <- c('trans-female', 'trans woman', 'female (trans)')
trans_male <- c('something kinda male?')

## Genderqueer (GQ): also termed non-binary or enby or fluid, 
##          is a catch-all category for gender identities that are not exclusively 
##          masculine or feminine identities which are thus outside of the gender binary and cisnormativity.
GQ <- c('queer/she/they', 'non-binary', 'nah', 'enby', 'fluid', 'genderqueer', 
        'androgyne', 'agender', 'guy (-ish) ^_^', 'male leaning androgynous', 'neuter', 
        'queer', 'ostensibly male, unsure what that really means')

# Clean data 
gender_clean <- 
  gender_clean %>%
  mutate(Gender = ifelse(Gender %in% cis_female, "cis-female", Gender),
         Gender = ifelse(Gender %in% cis_male, "cis-male", Gender),
         Gender = ifelse(Gender %in% trans_female, "trans-female", Gender),
         Gender = ifelse(Gender %in% trans_male, "trans-male", Gender),
         Gender = ifelse(Gender %in% GQ, "genderqueer", Gender))

gender_clean %>%
  group_by(Gender) %>%
  summarise( n = n() ) %>%
  ggplot() +
  geom_bar(aes(x = Gender , y = n, fill = Gender), stat = "identity", alpha = 0.5) +
  theme_bw() +
  xlab("Gender") + 
  ylab("The count") +
  ggtitle("Gender diversity in the 2014 Mental Health Tech Survey") +
  theme(plot.title = element_text(size = 13, face = "bold", hjust = 0.5))


##################################################
## Section:
##################################################

map_clean <- 
  gender_clean %>%
  select(Country) %>%
  group_by(Country) %>%
  summarise( count = n()) %>%
  mutate(ISO = countrycode(Country, "country.name", "iso2c"))

# store a word map data into a dataframe 
map_data("world")%>% 
  mutate(ISO = countrycode(region, "country.name", "iso2c")) %>% 
  as_tibble() %>%
  left_join(map_clean, by = "ISO") %>%
  ggplot(aes(long, lat)) +
  geom_polygon(aes(group = group, fill = count)) +
  theme(axis.title=element_blank(), legend.justification = c(0, 0), legend.position = c(0, 0)) +
  scale_fill_gradientn(colours = c("#f0f9e8", "#ccebc5", "#a8ddb5","#7bccc4","#4eb3d3","#2b8cbe", "#08589e"))
  

# Save Demographic information as 'demo_info.csv' in the data folder.
demo_info <- 
  gender_clean %>% 
  select(Gender, Age, Country)
write.csv(x= demo_info, file = "./data/01_demo_info.csv")

mh_condition <- 
  gender_clean %>% 
  select(family_history,treatment, work_interfere)
write.csv(x = mh_condition, file = "./data/02_mh_condition.csv")

workplace_info <- 
  gender_clean %>% 
  select(self_employed, no_employees, remote_work, tech_company)
write.csv(x= workplace_info, file = "./data/03_workplace_info.csv")

org_support <- 
  gender_clean %>% 
  select(benefits, care_options, wellness_program, seek_help, anonymity, leave)
write.csv(x= org_support, file = "./data/04_org_support.csv")

attitude <- 
  gender_clean %>%
  select(mental_health_consequence, phys_health_consequence, coworkers, supervisor,
         mental_health_interview, phys_health_interview, mental_vs_physical,
         obs_consequence)
write.csv(x=attitude, file = "./data/05_openness_about_mh.csv")


write.csv(gender_clean, file = "./data/06_data_tidy.csv")
  
  





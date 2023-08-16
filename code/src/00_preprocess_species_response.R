## ---------------------------
##
## Script name: 00_preprocess_species_specific_response.R
##
## Purpose of script: create species specific response function
##
## Author: Peter Pothmann
##
## Date Created: 10-17-2022
##
## Copyright (c) Peter Pothmann, 2022
## Email: peter.pothmann@idiv.de
##
## ---------------------------
##
## Notes:
##
##
## ---------------------------


cli_h1("Initiating generation of species respones to intensification")


# read data
cli_progress_step(msg = "Import species habitat information",
                  msg_done = "Imported species habitat information")

AOHInfo <- read_csv(paste0(metaPath, "aoh-info.csv"))

cli_process_done()

# filter for vertebrates with AOH Map
# ----------------------------------
cli_progress_step(msg = "Filter species habitat information for species that occur in Brazil",
                  msg_done = "Filtered species habitat information")

AOHFiles <- list.files(path = paste0(inPath, "aoh"), full.names = T, pattern = ".tif$") # kann ich dann auch raus schmeissen

BrazilVertebrates <- tibble(taxonID = AOHFiles) %>%
  separate(taxonID, sep = "-", into = c("rest", "taxonID")) %>%
  mutate(taxonID = as.numeric(str_extract(taxonID, "[^_]+")),
         filtervalue = 1) %>%
  select(taxonID, filtervalue) %>%
  distinct(taxonID, .keep_all = TRUE)

AOHInfo <- AOHInfo %>%
  left_join(., BrazilVertebrates, by = "taxonID") %>%
  drop_na(filtervalue) %>%
  select(-filtervalue) %>%
  mutate(suitability = tolower(suitability))

cli_progress_done()

# Forest specialists
# ------------------
# only Forest biomes as habiat
AOHInfoWide <- AOHInfo %>%
  mutate(values = 1) %>%
  separate(habitat, sep = "-", into = c("habitat", "rest")) %>%
  mutate(habitat = trimws(habitat)) %>%
  pivot_wider(id_cols = taxonID, names_from = habitat, values_from = values)

features <- names(AOHInfoWide)[3:19] # all not Forest classes should be NULL

FS <- AOHInfoWide %>%
  as_tibble() %>%
  filter_at(
    features,
    all_vars(. == "NULL")) %>% # and
  select(taxonID) %>%
  mutate(response = "FS")


AOHInfoUpd <- AOHInfo[!AOHInfo$taxonID %in% FS$taxonID,] # remove FS from AOHInfo -- so i dont have one species in multiple classes, just to be sure

# create new wider format data frame
AOHInfoWide <- AOHInfoUpd %>%
  mutate(values = 1) %>%
  pivot_wider(id_cols = taxonID, names_from = habitat, values_from = values)

# Regular cropland user
# ---------------------
#  all Artificial (Terrestrial & Aquatic) - all sub-categories and suitable
Urban <- c("Artificial/Terrestrial - Urban Areas")

features <- c("Artificial/Aquatic & Marine",
              "Artificial/Terrestrial",
              "Artificial/Terrestrial - Rural Gardens",
              "Artificial/Terrestrial - Arable Land",
              "Artificial/Terrestrial - Plantations",
              "Artificial/Terrestrial - Pastureland",
              "Artificial/Terrestrial - Subtropical/Tropical Heavily Degraded Former Forest",
              "Artificial/Aquatic - Ponds (below 8ha)",
              "Artificial/Aquatic - Water Storage Areas (over 8ha)",
              "Artificial/Aquatic - Aquaculture Ponds",
              "Artificial/Aquatic - Canals and Drainage Channels, Ditches",
              "Artificial/Aquatic - Excavations (open)",
              "Artificial/Aquatic - Wastewater Treatment Areas",
              "Artificial/Aquatic - Irrigated Land (includes irrigation channels)",
              "Artificial/Aquatic - Seasonally Flooded Agricultural Land",
              "Artificial/Aquatic - Salt Exploitation Sites"
#             "Artificial/Aquatic - Karst and Other Subterranean Hydrological Systems (human-made)" --> no species has this class as preference
              )

UrbanUser <- AOHInfoWide %>%
  as_tibble() %>%
  filter_at(
    Urban,
    any_vars(. != "NULL")) %>%
  select(taxonID) %>%
  left_join(AOHInfo, by = "taxonID")

RCU <- AOHInfoWide %>%
  as_tibble() %>%
  filter_at(
    features,
    any_vars(. != "NULL")) %>% # or
  select(taxonID) %>%
  distinct(taxonID) %>%
  left_join(AOHInfo, by = "taxonID") %>%
  filter(all(suitability == "suitable")) %>% # filter out all species that have unkown/marginal suitability in one LUC
  bind_rows(., UrbanUser) %>%
  distinct(taxonID) %>% # remove duplicates
  select(taxonID) %>%
  mutate(response = "RCU")


AOHInfoUpd <- AOHInfoUpd[!AOHInfoUpd$taxonID %in% RCU$taxonID,] # remove RCU from AOHInfo -- so i dont have one species in multiple classes, just to be sure

# Marginal cropland user
# -----------------------
# all Artificial (Terrestrial & Aquatic) - all sub-categories except for Urban Areas and marginal & Unknown

MCU <- AOHInfoWide %>%
  as_tibble() %>%
  filter_at(
    vars(features),
    any_vars(. != "NULL")) %>% # or
  select(taxonID) %>%
  anti_join(., RCU) %>%
  left_join(., AOHInfo, by = "taxonID") %>%
  group_by(taxonID) %>%
  filter(any(suitability == "marginal" | suitability == "unknown" | is.na(suitability) == TRUE)) %>%
  distinct(taxonID) %>% # remove duplicates
  select(taxonID) %>%
  mutate(response = "MCU")


AOHInfoUpd <- AOHInfoUpd[!AOHInfoUpd$taxonID %in% MCU$taxonID,] # remove MCU from AOHInfo -- so i dont have one species in multiple classes, just to be sure

# Natural habitat specialist
# --------------------------
NHS <- AOHInfoUpd %>%
  select(taxonID) %>%
  distinct(taxonID) %>%
  mutate(response = "NHS")

AOHResponse <- bind_rows(FS, RCU, MCU, NHS)

cli_process_done()
# write output
# ---------------
cli_progress_step(msg = "Writing output to 99_metadata",
                  msg_done = paste0("Wrote response information to 99_metadata"))

write_csv(AOHResponse, paste0(metaPath, "species-response-group-classification.csv"))

cli_process_done()


cli_h1("Closing species response functions generation")

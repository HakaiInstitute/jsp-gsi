# Read in the required packages
library(googlesheets4)
library(xlsx)
library(tidyr)

# Load the Hakai Translation file to match Hakai IDs to DFO
hakai <- readxl::read_xlsx(here::here("coastwide baseline results", "Hakai_Translation.xlsx"))
hakai <- hakai %>%
  tidyr::separate(`Hakai Sample`,
                  into = c("whatman_col", "whatman_row"),
                  sep = "(?<=[0-9])(?=\\s?[A-Z])") %>%
  rename("whatman_sheet" = `Hakai Sheet Number`)

# Read in 2022 and 2023 Hakai fin clip data
slug2022 <- "1ezxMrD7g-0ExabJv6mLWg4gPthOSiEyLo5vi-D-BGxI"
slug2023 <- "1Y8Nw82hHSb_GDXYzwg5hKI34bYlFnkLsir_V_fGdVCw"

year2022 <- googlesheets4::read_sheet(slug2022, sheet = "fin_clips") %>% mutate(whatman_col = as.character(whatman_col)) %>% filter(!is.na(ufn)) %>%
  select(ufn, sample_id, whatman_sheet, whatman_col, whatman_row)
year2023 <- googlesheets4::read_sheet(slug2023, sheet = "fin_clips") %>% mutate(whatman_col = as.character(whatman_col)) %>% filter(!is.na(ufn)) %>%
  select(ufn, sample_id, whatman_sheet, whatman_col, whatman_row)

years <- bind_rows(year2022, year2023)

# Join and ensure that each sample_id has a corresponding PSC Sample ID
gsi <- left_join(hakai, years, by = c("whatman_sheet", "whatman_col", "whatman_row")) %>%
  select(`PSC Sample`, ufn, sample_id) %>%
  rename(Fish = `PSC Sample`)

# Read in the data files sent by S. Latham:
stockid22 <- readxl::read_xlsx(here::here("coastwide baseline results", "msk2022AREA13SMOLTS_2024-06-11.xlsx"), sheet = "Individual IDs", skip = 3)
stockid23 <- readxl::read_xlsx(here::here("coastwide baseline results", "msk2023AREA12&13SMOLTS_2024-06-11(Hakai only) (1).xlsx"), sheet = "Individual IDs", skip = 3)
stockids <- bind_rows(stockid22, stockid23)

# Join data, matching DFO GSI data to our sample_ids:
jsp_gsi <- left_join(stockids, gsi, by = "Fish") %>% filter(!is.na(sample_id)) %>%
  select(sample_id, Stock_1:Prob_5, everything()) %>% as.data.frame()
jsp_gsi[is.na(jsp_gsi)] <- ""

# write and save .xlsx file, to add to the Master JSP Data Tables spreadsheet:
xlsx::write.xlsx(jsp_gsi, "data", "jsp_gsi_2022-2023.xlsx",
                 row.names = FALSE)

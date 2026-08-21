#!/usr/bin/env Rscript

library(httr)

token <- Sys.getenv("GITHUB_PAT", unset = "")

# Your personal access token
if (nzchar(token) && token != "None") {
    # Create a config with your token
    print("Your GITHUB token configuration is")
    response <- GET("https://api.github.com/rate_limit",
        add_headers(Authorization = paste("Bearer", token, sep = " ")))

    stop_for_status(response)

    # Extract the rate limit data
    rate_limit_data <- content(response, as = "parsed")

    # Print the rate limit data
    message(
        "GitHub API rate limit: ", 
        rate_limit_data$resources$core$remaining, "/", 
        rate_limit_data$resources$core$limit 
    ) 
} else { 
    message("GITHUB_PAT is not set; continuing without authentication.") 
}

remotes::install_github(c("satijalab/seurat-data","satijalab/seurat-wrappers","mojaveazure/seurat-disk"),
                    upgrade="never",
                    quiet=TRUE)

remotes::install_github("NightingaleHealth/ggforestplot",
    upgrade="never", 
    quiet=TRUE )

remotes::install_github("jhrcook/ggasym", 
    upgrade="never", 
    quiet=TRUE )

install.packages('GOplot', 
    repos='https://cloud.r-project.org', 
    quiet=TRUE )

install.packages('languageserver', 
    repos='https://cloud.r-project.org', 
    quiet=TRUE )

remotes::install_github("SamueleSoraggi/DoubletFinder", 
    upgrade="never",
    quiet=TRUE )


remotes::install_github("smorabit/hdWGCNA", 
    upgrade="never",
    quiet=TRUE )
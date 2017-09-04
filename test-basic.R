library(testthat)
library(RSelenium)

user <- "adamrobinson361" # Your Sauce Labs username
pass <- "557fd7e6-badb-4989-a531-61502fb9f837" # Your Sauce Labs access key 
port <- 4445
ip <- paste0(user, ':', pass, "@localhost")
rdBrowser <- "firefox"
version <- "26"
platform <- "Linux"
extraCapabilities <- list(name = "RSelenium OS/Browsers vignette second example", username = user
                          , accessKey = pass, tags = list("RSelenium-vignette", 
                                                          "OS/Browsers-vignette", "Example 2"))
remDr <- remoteDriver$new(remoteServerAddr = ip, port = port, browserName = rdBrowser
                          , version = version, platform = platform
                          , extraCapabilities = extraCapabilities)

remDr$open(silent = TRUE)
appURL <- "http://127.0.0.1:6012"

test_that("can connect to app", {  
  remDr$navigate(appURL)
  appTitle <- remDr$getTitle()[[1]]
  expect_equal(appTitle, "Old Faithful Geyser Data")  
})

remDr$close()
library(RSelenium)

user <- "adamrobinson361" # Your Sauce Labs username
pass <- "557fd7e6-badb-4989-a531-61502fb9f837" # Your Sauce Labs access key 
port <- 80
ip <- paste0(user, ':', pass, "@ondemand.saucelabs.com")
rdBrowser <- "chrome"
version <- "33"
platform <- "OS X 10.9"
extraCapabilities <- list(name = "RSelenium OS/Browsers vignette first example", username = user
                          , accessKey = pass, tags = list("RSelenium-vignette", "OS/Browsers-vignette"))

remDr <- remoteDriver$new(remoteServerAddr = ip, port = port, browserName = rdBrowser
                          , version = version, platform = platform
                          , extraCapabilities = extraCapabilities)

testScript <- function(remDr){
  remDr$open()
  remDr$navigate("http://127.0.0.1:6012")
  Sys.sleep(10)
  remDr$close()
}

testScript(remDr)

# R Shiny Testing Workflow [![Build Status](https://travis-ci.org/adamrobinson361/travis.svg?branch=master)](https://travis-ci.org/adamrobinson361/travis)

This R project has been developed to act as a template on how to test GitHub code hosted **[R Shiny](https://shiny.rstudio.com/)** web applications with **[RSelenium](https://github.com/ropensci/RSelenium)**, **[Travis CI](https://travis-ci.org/)** and **[Sauce Labs](https://saucelabs.com/)**. 

## Background

R Shiny allows you to create interactive visual web applications using the R Programming lanugage.

When deploying these applications to customers it is important to be confident that the application works as expected accross multiple environments. 

## Project Scope

This project defines a template and illustrates the setup for an end to end continuous integration solution to testing Shiny applications in the cloud. 

## Tools Used

### RSelenium 

At the time of writing **RSelenium** appears to be the most stable option for testing Shiny Applications. R Selenium is an R client for Selenium Remote WebDriver. It is well documented via its [vignettes](https://cran.r-project.org/web/packages/RSelenium/vignettes).

RSelenium allows you to do the following:

- Connect to a server using Selenium
- Navigate through the browser using R
- Run testthat tests on outputs from the browser

### Travis CI

Travis CI is a hosted, distributed continuous integration service used to build and test projects hosted at GitHub. 

It allows you to do the following:

- Create a Virtual Machine (VM) in the cloud with all dependencies required for code to run
- Run the Shiny Application on the VM in the background
- Run any other R Scripts

### Sauce Labs

Sacue labs is a web and mobile application automated testing platfrom. 

It allows us to do the following:

- Run the web application hosted on travis on up to 5 concurrent devices
- Use R Selenium to direct the browsers in order to undertake the tests. 

## How it all fits together

### 1 - Get your application running on Travis

Go to http://travis-ci.org and sign up with GitHub. 

Go to your profile page and you will see instructions on how to add a GitHub public repo. These are as follows:

1. Flick the switch on travis for the GitHub repo you want to enable
2. Add the .travis.yml file
3. Push to GitHub

The travis template without Sauce labs is as follows:

``` yml
language: r
before_install:
- sudo mkdir -p /usr/lib/R/library
- echo 'R_LIBS=/usr/lib/R/library:/usr/lib/R/site-library/' > ~/.Renviron
- sudo chmod 2777 /usr/lib/R/library
install:
- R -e "0" --args --bootstrap-packrat
cache:
  directories:
  - "$TRAVIS_BUILD_DIR/packrat/src"
  - "$TRAVIS_BUILD_DIR/packrat/lib"
  packages: true
script:
- nohup R --slave --no-restore -e 'shiny::runApp(port = 3000)' &
```

As a summary of what it is doing is the following:

1. Defining the language we are using as r
2. Before doing anything with the code it edits where the library is stored. This is because it is using packrat and is not a package. 
3. Unpack the packages from packrat
4. Create a cache for those packages so they dont need to be installed each time
5. Run the app in the background

At this point everytime you push changes to your code to github it should run this process (minus install packages if already cached in previous push). If the build passes then this means that your application has been able to run. 

### 2 - Set up Sauce Labs

As an extension to if an application has been able to run we may want to test that application on different browsers and use the Selenium web driver to control what these browsers do. 

To get set up with Sauce Labs on travis do the following:

1. Sign up for free for public GitHub repos [here](https://saucelabs.com/open-source
2. Get your access key via the *My Account* section and are ready to set up with travis.
3. Create two environemnt variables in Travis by going to the settings page of your travis build. These should be SAUCE_USERNAME and SAUCE_SECRET_KEY where the first is your username and the second your access key. 
4. Edit your .travis.yml file so that it can connect to sauce labs via sauce connect. 

The final .travis.yml file should be as follows:

``` yml
language: r
before_install:
- sudo mkdir -p /usr/lib/R/library
- echo 'R_LIBS=/usr/lib/R/library:/usr/lib/R/site-library/' > ~/.Renviron
- sudo chmod 2777 /usr/lib/R/library
install:
- R -e "0" --args --bootstrap-packrat
cache:
  directories:
  - "$TRAVIS_BUILD_DIR/packrat/src"
  - "$TRAVIS_BUILD_DIR/packrat/lib"
  packages: true
script:
- nohup R --slave --no-restore -e 'shiny::runApp(port = 3000)' &
addons:
  sauce_connect:
    username: "$SAUCE_USERNAME"
    access_key: "$SAUCE_SECRET_KEY"
```

### 3 - Create your tests with RSelenium

To complete the testing template we now need to write a basic test using RSelenium.

The following is a template of setting up and running a simple test that the title is correct

``` r
library(testthat)
library(RSelenium)

user <- Sys.getenv("SAUCE_USERNAME") # Your Sauce Labs username
pass <- Sys.getenv("SAUCE_SECRET_KEY") # Your Sauce Labs access key 
port <- 4445
ip <- paste0(user, ':', pass, "@localhost")
rdBrowser <- "chrome"
version <- "48"
platform <- "Linux"
extraCapabilities <- list(name = "R Shiny Testing", username = user
                          , accessKey = pass, 
                          tags = list("R", "Travis", "Shiny"), 
                          'tunnel-identifier' = 
                            Sys.getenv("TRAVIS_JOB_NUMBER"))
remDr <- remoteDriver$new(remoteServerAddr = ip, port = port, 
                          browserName = rdBrowser
                          , version = version, platform = platform
                          , extraCapabilities = extraCapabilities)

remDr$open()
# check tunnel identifier
Sys.getenv("TRAVIS_JOB_NUMBER")
appURL <- "http://localhost:3000"

test_that("can connect to app", {  
  remDr$setImplicitWaitTimeout(2000) # wait for elements for 2 seconds
  remDr$navigate(appURL)
  Sys.sleep(2)
  appTitle <- remDr$getTitle()[[1]]
  expect_equal(appTitle, "Old Faithful Geyser Data")  
})

remDr$close()
```

Between `appURL` and `remDr$close()` you can add any RSelenium tests that you would like. The core part to take from here is the strucure. Initially it was not clear that the 'tunnel-identifier' parameter was required in the extraCapabilities. 

To run this test on travis we simply add this to the script part of .travis.yml as follows:

``` yml
language: r
before_install:
- sudo mkdir -p /usr/lib/R/library
- echo 'R_LIBS=/usr/lib/R/library:/usr/lib/R/site-library/' > ~/.Renviron
- sudo chmod 2777 /usr/lib/R/library
install:
- R -e "0" --args --bootstrap-packrat
cache:
  directories:
  - "$TRAVIS_BUILD_DIR/packrat/src"
  - "$TRAVIS_BUILD_DIR/packrat/lib"
  packages: true
script:
- nohup R --slave --no-restore -e 'shiny::runApp(port = 3000)' &
- R -f test-basic.R
addons:
  sauce_connect:
    username: "$SAUCE_USERNAME"
    access_key: "$SAUCE_SECRET_KEY"
```

This test file and .travis.yml file are found in the project directory. 







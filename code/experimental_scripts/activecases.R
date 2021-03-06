
ccfrdata <- read.csv("../data/estimates-ccfr-based/PlotData/PT-estimate.csv")
#confdata <- read.csv("../data/estimates-confirmed/PlotData/PT-estimate.csv")


#baselineA <- 1.38
#baselineB <- 1.38

#clean negative daily cases to 0
for (i in 1:length(ccfrdata$cases))
{
  if (ccfrdata$cases[i] < 0)
    ccfrdata$cases[i] <- 0
}

num <- length(ccfrdata$cases)
cum <- cumsum(ccfrdata$cases)


mult_fact_raw <- (ccfrdata$p_cases*ccfrdata$population)/cum
mult_fact <- rep(0,num)

#make sure we never estimate less than measured cases
for (i in 1:num)
{
  if (mult_fact_raw[i] < 1 | is.na(mult_fact_raw[i]))
     mult_fact[i] <- 1
  else
  {
#    x <- mult_fact_raw[i] * baselineA
#    y <- x / baselineB
#    mult_fact[i] <- y
    mult_fact[i] <- mult_fact_raw[i]
  }

}

# estimate correct by undersampling 
daily_est <- mult_fact*ccfrdata$cases
# cases stay active for at most 12
infect_window <- rep(0,12) # https://www.ams.edu.sg/view-pdf.aspx?file=media%5C5556_fi_331.pdf&ofile=Period+of+Infectivity+Position+Statement+(final)+23-5-20+(logos).pdf
# to discount later
negative_daily_est <- c(infect_window,daily_est)
positive_daily_est <- c(daily_est,infect_window)

# total cases we estimate to be active
current_est <- cumsum(positive_daily_est-negative_daily_est) # cumsum(c(daily_est[1:12], diff(daily_est, lag = 12)))



plot(current_est[1:num],type="l",lty=1,xlab="Days (cases considered active for 12 days)",ylab="Cases",main="Estimate of active COVID-19")


legend(x="topleft", legend=c("total active cases estimate", "undetected active cases estimate","active reported cases"), lty=1:3, cex=1)
abline(h=0,lty=1)


detected_daily <- c(ccfrdata$cases,infect_window)
negative_daily_undetected_est <- c(infect_window,   daily_est - ccfrdata$cases)
# cases that have been detected are not infective if isolated, so discount those
undetected_current_est <- cumsum(positive_daily_est - negative_daily_undetected_est - detected_daily )
lines(undetected_current_est[1:num],lty=2)


# plot(ccfrdata$p_cases_active*ccfrdata$population, type="l",lty=1)
# lines(ccfrdata$p_cases_active_undetected*ccfrdata$population, type = "l", lty = 2)
# ab <- daily_est - ccfrdata$cases
# cumsum(c(ab[1:12],diff(ab, lag = 12) ))




negative_detected_daily <- c(infect_window,ccfrdata$cases)
# the naif approach is just to assume detected cases as all cases
naif_current_est <- cumsum(detected_daily-negative_detected_daily) # cumsum(c(ccfrdata$cases[1:12], diff(ccfrdata$cases, lag = 12)))
lines(naif_current_est[1:num],lty=3)

#--- ends here
#--------- only run bellow this line for specific countries ----

#recentdata <- read.csv("../data/estimates-W/PlotData/ES-estimate.csv")
#pwdata <- c(rep(NA,80-7),recentdata$p_cases_recent) # W=15?
#pwdata <- c(rep(NA,80-7),recentdata$recent_p_m_country) # W=15
#lines(pwdata*ccfrdata$population[1],lty=1,col="red")


#recentdata <- read.csv("../data/estimates-W/PlotData/PT-estimate.csv")
#pwdata <- c(rep(NA,20),recentdata$p_cases_recent)
#lines(pwdata*ccfrdata$population[1],lty=1,col="red")

#library(tidyverse)
#library(httr)
#library(jsonlite)

# adding url
#path <- "https://covidmap.umd.edu/api/resources?indicator=covid&type=daily&country=Spain&daterange=20200423-20200626"
#path <- "https://covidmap.umd.edu/api/resources?indicator=covid&type=smoothed&country=Spain&daterange=20200423-20200626"

# request data from api
#request <- GET(url = path)

# make sure the content is encoded with 'UTF-8'
#response <- content(request, as = "text", encoding = "UTF-8")

# now we can have a dataframe for use!
#coviddata <- fromJSON(response, flatten = TRUE) %>% data.frame()

#facebook <- c(rep(NA,114),coviddata$data.percent_cli)
#facebook <- c(rep(NA,114),coviddata$data.smoothed_cli)
#lines(facebook*ccfrdata$population[1],lty=1,col="blue")

undetected_current_est[num]
undetected_current_est[num] / ccfrdata$population[1] * 100

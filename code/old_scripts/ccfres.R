#install.packages("readxl")
library(readxl)
library(httr)

zmeanHDT <- 13
zsdHDT <- 12.7
zmedianHDT <- 9.1
muHDT <- log(zmedianHDT)
sigmaHDT <- sqrt(2*(log(zmeanHDT) - muHDT))
cCFRBaseline <- 1.38
cCFREstimateRange <- c(1.23, 1.53)
#cCFRIQRRange <- c(1.3, 1.4)


# Functions from https://cmmid.github.io/topics/covid19/severity/global_cfr_estimates.html
# Hospitalisation to death distribution
hospitalisation_to_death_truncated <- function(x)
{
  dlnorm(x, muHDT, sigmaHDT)
}
# Function to work out correction CFR
scale_cfr <- function(data_1_in, death_incidence, delay_fun){
  case_incidence <- data_1_in$confirmados
  death_incidence <- data_1_in$obitos
  cumulative_known_t <- 0 # cumulative cases with known outcome at time tt
  # Sum over cases up to time tt
  for(ii in 1:length(case_incidence)){
    known_i <- 0 # number of cases with known outcome at time ii
    for(jj in 0:(ii - 1)){
      known_jj <- (case_incidence[ii - jj]*delay_fun(jj))
      known_i <- known_i + known_jj
    }
    cumulative_known_t <- cumulative_known_t + known_i # Tally cumulative known
  }
  # naive CFR value
  b_tt <- sum(death_incidence)/sum(case_incidence) 
  # corrected CFR estimator
  p_tt <- sum(death_incidence)/cumulative_known_t
  data.frame(nCFR = b_tt, cCFR = p_tt, total_deaths = sum(death_incidence), 
             cum_known_t = round(cumulative_known_t), total_cases = sum(case_incidence))
}


#url <- paste("https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-",format(Sys.time(), "%Y-%m-%d"), ".xlsx", sep = "")
url <- "https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-2020-03-28.xlsx"
GET(url, authenticate(":", ":", type="ntlm"), write_disk(tf <- tempfile(fileext = ".xlsx")))
data <- read_excel(tf)

data<-data[data$geoId=="ES",]
data<-list(confirmados=cumsum(rev(data$cases)),obitos=cumsum(rev(data$deaths)))

size=length(data$confirmados)
est_ccfr<-rep(NaN,size)

for (rr in 0:(size-1))
{
    last <- size-rr
    data2 <- list(confirmados=diff(data$confirmados[1:last]),obitos=diff(data$obitos[1:last]))
    ccfr<-scale_cfr(data2, delay_fun = hospitalisation_to_death_truncated)
    
    fraction_reported=cCFRBaseline / (ccfr$cCFR*100)
    
    est_ccfr[last]<-data$confirmados[last]*1/fraction_reported
}
#data2 <- list(confirmados=diff(data$confirmados),obitos=diff(data$obitos))
#ccfr<-scale_cfr(data2, delay_fun = hospitalisation_to_death_truncated)
#
#fraction_reported=cCFRBaseline / (ccfr$cCFR*100) 


populationSP<-46754778
survey_twitter<-rep(NaN,size)
survey_gforms<-rep(NaN,size)

#position 89 is March 28 results about March 27 cases
#survey[23]=(11/(63*276))*populationPT #18 Mar
#survey[25]=15/(45*276)*populationPT #20 Mar
survey_twitter[76]<-(374.05/(762*150))*populationSP #14 Mar
survey_twitter[78]<-(66.13/(85*150))*populationSP #16 Mar
survey_twitter[80]<-(116.16/(120*150))*populationSP #16 Mar
#survey_twitter[25]<-15/(45*150)*populationSP #20 Mar
survey_gforms[85]<-1408474 #23 Mar cf=1, pool 6
survey_gforms[87]<-1689103 #25 Mar cf=1, pool 7
survey_gforms[89]<-2061923 #27 Mar cf=1, pool 8

#est_ccfr[size]<-data$confirmados[size]*1/fraction_reported

plot(data$obitos*400,log="y",ylim=c(1,10000000),type="l",xlab="Days",main="Different estimates of SARS-COV2 cases in Spain",ylab="Total cases",lty=4)
lines(data$confirmados)
points(survey_twitter,pch=23)
points(survey_gforms,pch=24)
points(est_ccfr,pch=20)



library(ggplot2)
obitos_400 <- data$obitos*400
obitos_400[obitos_400 == 0] <- NA
dt_plot <- data.frame(obitos_400 = obitos_400,
                      confirmados = data$confirmados, 
                      est_ccfr = est_ccfr,
                      days = 1:length(obitos_400))
scientific_10 <- function(x) {
  parse(text=gsub("e", " %*% 10^", scales::scientific_format()(x)))
}

ggplot(data = dt_plot, mapping = aes(x = days)) +
  geom_line(mapping = aes(y = confirmados)) +
  geom_line(mapping = aes(y = obitos_400), linetype = "dashed") +
  ylab("Total Cases") + 
  xlab("Days") +
  #xlim(15, 30) +
  #ylim(0, 100000) +
  scale_y_continuous(trans='log10', label = scientific_10) +
  ggtitle("Different estimates of COVID−19 cases in Spain") +
  theme_bw()

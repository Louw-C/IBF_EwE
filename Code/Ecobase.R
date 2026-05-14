#To get the list of available Ewe models

library(RCurl)
library(XML)
library(plyr)
library(dplyr)


#To obtain the list of available model
h=basicTextGatherer()
curlPerform(url = 'http://sirs.agrocampus-ouest.fr/EcoBase/php/webser/soap-client_3.php',writefunction=h$update)

data<-xmlTreeParse(h$value(),useInternalNodes=TRUE)
liste_mod<-ldply(xmlToList(data),data.frame)%>% filter(model.dissemination_allow =='true')

#liste_mod contains a list and description of available models in EcoBase    
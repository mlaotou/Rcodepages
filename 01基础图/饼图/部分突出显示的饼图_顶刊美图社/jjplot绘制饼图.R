library(tidyverse)
library(jjPlot) 
library(rstudioapi);setwd(dirname(getActiveDocumentContext()$'path'));getwd()
library(ggplot2)
# 是将点更改为pie
# ref ： https://junjunlab.github.io/jjPlot-manual/geom_jjpointpie.html
# prepare test
set.seed(123)
test <- data.frame(gene = rep(LETTERS[1:5],each = 10),
                   id = rep(as.character(1:10),5),
                   group = 1:50,
                   r = rep(c(0.4,0.8,1.2,1,1.6),each = 10),
                   s1 = abs(rnorm(50,sd = 10)),
                   s2 = abs(rnorm(50,sd = 10)),
                   s3 = abs(rnorm(50,sd = 10)))

# check
head(test,3)

# widte to long
df.long <- reshape2::melt(test,id.vars = c('gene','id','group','r'),
                          variable.name = 'type',value.name = 'per')

# check
head(df.long,3)
# p1
ggplot(df.long,aes(x = id,y = gene,group = group)) +
  geom_jjPointPie(aes(pievar = per,
                      fill = type),
                  add.circle = TRUE,
                  circle.radius = 0.07) +
  coord_fixed()+
  scale_fill_manual(values = c('#737fb0','#c16360','grey93')) +
  theme_bw() +
  labs(x= "ID",y = "Gene")
# p2
# make hollow circle
ggplot(df.long,aes(x = id,y = gene,group = group)) +
  geom_jjPointPie(aes(pievar = per,
                      fill = type),
                  add.circle = TRUE,
                  circle.rev = TRUE,
                  circle.radius = 0.03,
                  circle.fill = 'grey90') + # 中心填充颜色
  coord_fixed() +
  scale_fill_manual(values = c('#737fb0','#c16360','grey93')) +
  theme_bw() +
  labs(x= "ID",y = "Gene")

#突出显示部分
ggplot(df.long,aes(x = id,y = gene,group = group)) +
  geom_jjPointPie(aes(pievar = per,
                      fill = type,
                      filltype = type),
                  explode = "s1") +
  coord_fixed() +
  scale_fill_manual(values = c('#737fb0','#c16360','grey93')) +
  theme_bw() +
  labs(x= "ID",y = "Gene")
png("p1.png",width = 8,height = 4,unit = "in",res = 600,family = "serif")
dev.off()

library(rstudioapi)
# 获取当前文件所在目录并设置为工作目录
setwd(dirname(getActiveDocumentContext()$path))
getwd()
library(ggplot2)
library(ggforce)
library(dplyr)
library(ggrepel)
library(patchwork)
library(ggpubr)
library(export) #可导出ppt格式图片，用于调整

# 创建数据框
data <- data.frame(
  gene = c("HRAS", "NRAS", "RET fusion", "MAP2K1", "ROS1 fusion", "ERBB2", "ALK fusion", "MET ex14", 
           "BRAF", "EGFR", "KRAS", "None", "RIT1", "ERBB2 amp", "MET amp", "NF1"),
  percentage = c(0.4, 0.4, 0.9, 0.9, 1.7, 1.7, 1.3, 4.3, 
                 7.0, 11.3, 32.2, 24.4, 2.2, 0.9, 2.2, 8.3)
)
data$gene <- factor(data$gene,levels = data$gene)
data$focus = c(rep(0, 12), rep(0.2, 4))

data$anno <- ifelse(data$gene == "KRAS", "KRAS\n(32.2%)",
                    ifelse(data$gene == "EGFR", "EGFR\n(11.3%)",
                           ifelse(data$gene == "BRAF", "BRAF\n(7.0%)",
                                  ifelse(data$gene == "None", "None\n(24.4%)",
                                         ifelse(data$gene == "NF1", "NF1\n(8.3%)", NA)))))
write.csv(data, "data.csv", row.names = FALSE)
data  <- data %>%
  mutate(end_angle = 2*pi*cumsum(percentage)/100,
         start_angle = lag(end_angle, default = 0),
         mid_angle = 0.5*(start_angle + end_angle)) %>%
  mutate(legend = paste0(gene," (",percentage,"%)"))

data$legend <- factor(data$legend,levels = data$legend)
#R语言自带的pie函数可以直接画饼图，但是效果很不理想，占比较小的类目的文本标签都叠在一起
#pie(x = data$percentage,labels = data$legend,radius = 1,clockwise=T) 

#使用ggplot绘制饼图
pie <- ggplot()+
  geom_arc_bar(data=data,stat = "pie", #在正常的笛卡尔坐标系中绘制饼图，不必使用极坐标
               aes(x0=0,y0=0,r0=0,r=2, #需要甜甜圈图只需要将r0改为1即可
                   amount=percentage,
                   fill=gene,color=gene,
                   explode=focus), #设置需要突出展示的饼图部分
               show.legend = F
  )+
  geom_arc(data=data[1:8,], #添加注释弧线
               size=1,color="black",
               aes(x0=0,y0=0,r=2.1, 
                   start = start_angle, end = end_angle)
  )+
  geom_arc(data=data[11,],
               size=1,color="#0F0032",
               aes(x0=0,y0=0,r=2, 
                   start = start_angle-0.3, end = end_angle+0.3)
  )+
  geom_arc(data=data[13:15,],
               size = 1,color="black",
               aes(x0=0,y0=0,r=2.3,size = index,
                   start = start_angle, end = end_angle)
  )+
  coord_fixed() +
#对于比例较大的组分，直接添加文本标签和百分比到饼图内部
  #批量添加饼图内的文本标签
  # geom_text_repel(data=data,
  #                 aes(x = 1*sin(mid_angle), 
  #                     y = 1*cos(mid_angle), 
  #                     label = anno),nudge_y = 0.01,
  #                 size = 6,
  #                 show.legend = FALSE) +
  annotate("text",                     
           x=1.3,       
           y=0.9,                       
           label=expression(atop(italic("BRAF"),"(7.0%)")), 
           size=6,                    
           angle=0,                   
           hjust=0.5)+
  annotate("text",                       
           x=1.4,        
           y=0.08,                       
           label=expression(atop(italic("EGFR"),"(11.3%)")), 
           size=6,                    
           angle=0,                      
           hjust=0.5)+
  annotate("text",                       
           x=0.2,        
           y=-1.1,                       
           label=expression(atop(italic("KRAS"),"(32.2%)")),
           size=6,                    
           angle=0,                      
           hjust=0.5)+
  annotate("text",                       
           x=-1.2,        
           y=0.1,                       
           label="None\n(24.4%)", 
           size=6,                    
           angle=0,                      
           hjust=0.5)+
  annotate("text",                       
           x=-0.5,        
           y=1.75,                       
           label=expression(atop(italic("NF1"),"(8.3%)")),
           size=6,                    
           angle=0,                      
           hjust=0.5)+
  theme_no_axes()+
  scale_fill_manual(values = c("#040503","#891619","#AF353D","#CF5057","#EE2129","#E7604D","#F58667","#F7A387","#FBC4AE","#FDE2D6","#FDF1EA","#AAD9C0","#0073AE","#069BDA","#68B0E1","#B8CBE8"
  ))+
  scale_color_manual(values = c("#040503","#891619","#AF353D","#CF5057","#EE2129","#E7604D","#F58667","#F7A387","#FBC4AE","#FDE2D6","#FDF1EA","#AAD9C0","#0073AE","#069BDA","#68B0E1","#B8CBE8"
  ))+
  theme(panel.border = element_blank(),
        legend.key.width = unit(0.5,"cm"),
        legend.key.height = unit(0.5,"cm"))
pie
#对于比例较小，不适合直接添加文本标签和百分比的组分使用图例展示标签和百分比数据
leg <- ggplot(data=data[c(1:8, 13:15),],aes(x=1,y=legend))+
  geom_tile(aes(width = 0.5, height = 0.5,fill = legend))+
  scale_fill_manual(values = c("#040503","#891619","#AF353D","#CF5057","#EE2129","#E7604D","#F58667","#F7A387","#0073AE","#069BDA","#68B0E1"))+
  theme_bw()+
  theme(panel.border = element_blank(),
        legend.margin = margin(t = 1,r = 0,b = 0,l = 0,unit = "cm"),
        legend.title = element_blank(),
        legend.text = element_text(size=14),
        legend.key.spacing.y = unit(0.3,"cm"),
        legend.key.width = unit(0.4,"cm"),
        legend.key.height = unit(0.4,"cm"))
leg <- as_ggplot(get_legend(leg)) #获取legend，并将其转变为一个ggplot对象
leg
# 拼图、导出为PPT并调整细节
p <- pie + leg + plot_layout(widths = c(1.2,1)) 
p
ggsave(filename = "pie.pdf",height = 12,width = 16)
#export包可导出图片为PPT，图的各部分都可以独立调整细节，非常方便
graph2ppt(file="Pie chart.pptx", width=7, height=5) #导出为PPT，继续调整细节
#我调整的细节包括：饼图与图例之间的间距，基因名称斜体、饼图中的标签和百分比的位置等

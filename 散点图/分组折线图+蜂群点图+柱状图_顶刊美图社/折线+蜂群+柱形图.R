###BarDotLine###
library(rstudioapi)
# 获取当前文件所在目录并设置为工作目录
setwd(dirname(getActiveDocumentContext()$path))
getwd()
library(ggplot2)
library(grid)
library(gridExtra)
#绘制折线图
data1 <- openxlsx::read.xlsx("data.xlsx",sheet = "b_WC_Smoking",colNames = T)
data1 <- reshape2::melt(data1,id.vars=c("Day","Treatment"),na.rm = T)
data1$value <- as.numeric(data1$value)

a <- mean(data1$value[data1$Day == 35 & data1$Treatment == "SMK"])
b <- mean(data1$value[data1$Day == 35 & data1$Treatment == "NS+abx"])
c <- mean(data1$value[data1$Day == 35 & data1$Treatment == "SMK+abx"])

p1 <- ggplot(data1,aes(x = Day,y = value,color = Treatment,group = Treatment)) +
  geom_rect(aes(xmin=21,xmax=40,ymin=(-Inf),ymax=Inf),
            fill='grey90',color='grey90')+
  geom_vline(xintercept =21,linetype=2,cex=1)+
  stat_summary(geom = "line",fun="mean",cex=3)+
  stat_summary(geom = "errorbar",
               fun.data = "mean_se",
               width = 1.2,cex=0.8, color="black")+
  stat_summary(geom = "point",fun="mean",aes(fill=Treatment),key_glyph='rect',#指定legend.key的形状为矩形
               cex=4,shape = 21, stroke = 1.2,color='black')+
  annotate(geom = 'linerange',x=36.2,ymin = c,ymax = a,cex=1.2)+
  annotate(geom = 'text',label='***',x=37.5,y=24,size=7,angle=90)+
  annotate(geom = 'linerange',x = 38,ymin = c,ymax = b,cex=1.2)+
  annotate(geom = 'text',label='****',x=39.5,y=28,size=7,angle=90)+
  ylab("Weight change (%)") +
  coord_cartesian(clip = 'off',expand = F) + #设置坐标轴范围，clip = 'off' 关闭裁剪，允许数据点超出坐标轴范围
  scale_fill_manual(name = "",values = c("NS" = "#4489C8", "SMK" = "#ED7E7A", "NS+abx" = "#008F91", "SMK+abx" = "#FFCD44")) +
  scale_color_manual(name = "",values = c("NS" = "#4489C8", "SMK" = "#ED7E7A", "NS+abx" = "#008F91", "SMK+abx" = "#FFCD44")) +
  scale_x_continuous(expand = c(0,0), limits = c(0,40), breaks = c(0,7,14,21,28,35)) +
  scale_y_continuous(expand = c(0,0), limits = c(0,60), breaks = seq(0, 60, by = 20)) +
  theme_classic(base_size = 18)+
  theme(legend.position = "top",
        legend.margin = margin(0,0,0,0), #图例周围没有扩展
        legend.key.width = unit(0.6,"cm"), #图例方块宽度
        legend.key.height = unit(0.1,"cm"), #图例方块高度
        legend.key = element_rect(colour = "black"),#设置图例键的边框颜色为黑色。
        axis.text = element_text(size = 18, face = "plain",color = "black"), #坐标轴刻度标签
        axis.title = element_text(size = 18,face = "plain",hjust = 0.525), #坐标轴标题
        axis.line = element_line(size = 1.2), #坐标轴线的粗细
        axis.ticks = element_line(size = 0.8,color='black')) #坐标轴刻度线的粗细
p1

#绘制左上柱形图
data2 <- openxlsx::read.xlsx("data.xlsx",sheet = "b_iAUC_active",colNames = T)
data2 <- reshape2::melt(data2,variable.name = "Treatment",na.rm = T)
data2$Treatment <- factor(data2$Treatment, levels = c("SMK+abx","NS+abx","SMK","NS"))

p2 <- ggplot(data2,aes(x = Treatment,y = value)) +
  geom_jitter(aes(color = Treatment),cex = 1.5,width=0.2)+
  stat_summary(geom = "bar",
               fun="mean",
               fill='transparent',color='black',width=0.5,cex=0.8)+
  stat_summary(geom = "errorbar",
               fun.data = "mean_se",
               width = 0.2,cex=0.8, color="black")+
  geom_hline(yintercept =0,cex=0.6)+
  annotate(geom = 'linerange',xmin=1,xmax=2,y=660,cex=1)+
  annotate(geom = 'text',label='****',x=1.5,y=720,size=6,angle=90)+
  annotate(geom = 'linerange',xmin=3,xmax =4,y=570,cex=1.2)+
  annotate(geom = 'text',label='****',x=3.5,y=630,size=6,angle=90)+
  scale_color_manual(name = "",values = c("NS" = "#4489C8", "SMK" = "#ED7E7A", "NS+abx" = "#008F91", "SMK+abx" = "#FFCD44")) +
  scale_y_continuous(limits = c(-200,800),breaks = c(-200,300,800), expand = c(0,0))+
  coord_flip()+
  labs(title = "iAUC: Exposure",x = "", y = "")+
  theme_classic(base_size = 18)+
  theme(plot.title = element_text(size = 15,hjust = 0.5,margin = margin(0,0,0,0)),
        legend.position = 'none',
        plot.margin = margin(0,0,0,0),
        plot.background = element_rect(fill = "transparent",colour = "transparent"),
        panel.background = element_rect(fill = "transparent",colour = "transparent"),
        axis.line = element_line(size = 0.6),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank())
p2

#绘制右上柱形图
data3 <- openxlsx::read.xlsx("data.xlsx",sheet = "b_iAUC_cessation",colNames = T)
data3 <- reshape2::melt(data3,variable.name = "Treatment",na.rm = T)
data3$Treatment <- factor(data3$Treatment, levels = c("SMK+abx","NS+abx","SMK","NS"))

p3 <- ggplot(data3,aes(x = Treatment,y = value)) +
  geom_jitter(aes(color = Treatment),cex = 1.5,width=0.2)+
  stat_summary(geom = "bar",
               fun="mean",
               fill='transparent',color='black',width=0.5,cex=0.8)+
  stat_summary(geom = "errorbar",
               fun.data = "mean_se",
               width = 0.2,cex=0.8, color="black")+
  geom_hline(yintercept =0,cex=0.8)+
  annotate(geom = 'linerange',xmin=1,xmax=2,y=330,cex=1)+
  annotate(geom = 'text',label='****',x=1.5,y=360,size=6,angle=90)+
  annotate(geom = 'linerange',xmin=3,xmax =4,y=310,cex=1.2)+
  annotate(geom = 'text',label='****',x=3.5,y=340,size=6,angle=90)+
  scale_color_manual(name = "",values = c("NS" = "#4489C8", "SMK" = "#ED7E7A", "NS+abx" = "#008F91", "SMK+abx" = "#FFCD44")) +
  scale_y_continuous(limits = c(0,400),breaks = c(0,200,400), expand = c(0,0))+
  coord_flip()+
  labs(title = "iAUC: Cessation",x = "", y = "")+
  theme_classic(base_size = 18)+
  theme(plot.title = element_text(size = 15,hjust = 0.5,margin = margin(0,0,0,0)),
        legend.position = 'none',
        plot.margin = margin(0,0,0,0),
        plot.background = element_rect(fill = "transparent",colour = "transparent"),
        panel.background = element_rect(fill = "transparent",colour = "transparent"),
        axis.line = element_line(size = 0.6),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank())
p3

# 创建图形元素
p2 = ggplotGrob(p2)#通过 ggplotGrob 将它们转换为 grob 对象（图片），以便后续可以将它们作为自定义注释添加到主图 p1 中
p3 = ggplotGrob(p3)
p <- p1 +
  annotation_custom(p2,xmin=0,xmax=19,ymin=35,ymax=60)+
  annotation_custom(p3,xmin=22,xmax=39,ymin=35,ymax=60)
p
#下面这段代码通过调整z值，使得绘图层位于坐标轴之前，因此原点的坐标轴可以被数据点遮盖
#参考：https://stackoverflow.com/questions/62237365/how-to-put-axes-behind-the-graph
pdf("BarDotLine.pdf",height = 5.5, width = 5.5)
ggp <- ggplot_gtable(ggplot_build(p))
ggp$layout$z[which(ggp$layout$name == "panel")] <- max(ggp$layout$z) + 1
grid::grid.draw(ggp)
dev.off()
#ggsave("BarDotLine.pdf", plot =p, height = 6, width = 5,device = cairo_pdf)


#绘制蜂群图
library(ggbeeswarm)
data4 <- openxlsx::read.xlsx("data.xlsx",sheet = "c_weight_gain_rate",colNames = T)
data4 <- reshape2::melt(data4,id.vars = "Treatment",variable.name = "Group",na.rm = T)
data4$Treatment <- factor(data4$Treatment, levels = c("NS","SMK","NS+abx","SMK+abx"))
data4$Group <- factor(data4$Group,levels = c("Smoking","Cessation"),labels = c("Exposure","Cessation"))

p4 <- ggplot(data4,aes(x = Group,y = value)) +
  geom_rect(aes(xmin=1.5,xmax=Inf,ymin=(-Inf),ymax=Inf),
            fill='grey90',color='grey90')+ #使用geom_rect函数添加一个灰色背景矩形，覆盖Group为Cessation的部分
  geom_beeswarm(aes(fill = Treatment),dodge.width = 0.8,corral.width=1.2,
                key_glyph='rect',#指定legend.key的形状为矩形，dodge.width控制点的水平偏移，corral.width控制点的聚集宽度
                color = "black",size =2.5,shape = 21)+
  stat_summary(geom = "crossbar",aes(group = Treatment),
               fun = "mean",position = position_beeswarm(dodge.width = 0.8),
               color='black',linewidth=0.3,width = 0.6)+ #使用stat_summary函数计算每个Treatment组的均值，并用crossbar几何对象表示
  
  geom_hline(yintercept =  0,linetype=1,linewidth = 0.8)+
  geom_vline(xintercept =  1.5,linetype=2,linewidth = 0.8)+
  
  annotate(geom = 'linerange',xmin=0.7,xmax=0.9,y=2.4,cex=1)+ #查看dodge后的坐标位置:test <- ggplot_build(p4)$data[[2]]
  annotate(geom = 'text',label='****',x=0.8,y=2.5,size=6)+
  
  annotate(geom = 'linerange',xmin=1.1,xmax =1.3,y=2.6,cex=1)+
  annotate(geom = 'text',label='****',x=1.2,y=2.7,size=6)+
  
  annotate(geom = 'linerange',xmin=1.7,xmax =1.9,y=3.1,cex=1)+
  annotate(geom = 'text',label='****',x=1.8,y=3.2,size=6)+
  
  annotate(geom = 'linerange',xmin=2.1,xmax =2.3,y=3.5,cex=1)+
  annotate(geom = 'text',label='****',x=2.2,y=3.6,size=6)+
  
  scale_fill_manual(name = "",values = c("NS" = "#4489C8", "SMK" = "#ED7E7A", "NS+abx" = "#008F91", "SMK+abx" = "#FFCD44")) +
  scale_x_discrete( expand = c(0.05,0))+ #控制第一个分组和Y轴的距离，在x轴的最小值处向外扩展5%的空间，最大不扩0
  scale_y_continuous(limits = c(-1,4),breaks = seq(-1,4,1), expand = c(0,0))+
  labs(title = "",x = "", y = "Weight gain rate (% day^-1)")+
  theme_classic(base_size = 18)+
  theme(legend.position = "top",
        legend.margin = margin(0,0,0,0),
        legend.key.width = unit(0.6,"cm"),
        legend.key.height = unit(0.1,"cm"),
        legend.key = element_rect(colour = "black"),
        axis.title = element_text(size = 18,face = "plain"),
        axis.text = element_text(size = 18, face = "plain",colour = "black"))
p4
ggsave("Beeswarm.pdf", plot =p4, height = 5.5, width = 5.5,device = cairo_pdf)

#绘制柱形图
data5 <- openxlsx::read.xlsx("data.xlsx",sheet = "h_stool calories",colNames = T)
data5 <- reshape2::melt(data5,id.vars = "Treatment",variable.name = "Group",na.rm = T)
data5$Treatment <- factor(data5$Treatment, levels = c("NS","SMK","NS+abx","SMK+abx"))
data5$Group <- factor(data5$Group,levels = c("Smoking","Cessation"),labels = c("Exposure","Cessation"))
#蜂群图的核心在于通过“偏移”或“聚集”算法，使每个数据点都能被清晰地展示出来，即使数据点很多也不会重叠,是散点图经过适当
#调整变化来的
p5 <- ggplot(data5,aes(x = Group,y = value)) +
  geom_rect(aes(xmin=1.5,xmax=Inf,ymin=(-Inf),ymax=Inf),
            fill='grey90',color='grey90')+
  geom_beeswarm(aes(fill = Treatment),dodge.width = 0.9,corral.width=1.2,
                key_glyph='rect',#指定legend.key的形状为矩形
                color = "black",size =3.5,shape = 21)+ 
  stat_summary(geom = "errorbar",aes(group = Treatment),
               fun.data = "mean_se",position = position_dodge(width = 0.9),
               color='black',width = 0.2)+
  stat_summary(geom = "bar",aes(group = Treatment),
               fun = "mean",position = position_beeswarm(dodge.width = 0.9),
               color='black',fill="transparent",width = 0.5,size=1)+
  
  geom_vline(xintercept =  1.5,linetype=2,linewidth = 0.8)+
  
  annotate(geom = 'linerange',xmin=0.7,xmax=0.9,y=5000,cex=1)+ #查看dodge后的坐标位置:test <- ggplot_build(p4)$data[[2]]
  annotate(geom = 'text',label='****',x=0.8,y=5100,size=6)+
  
  annotate(geom = 'linerange',xmin=1.1,xmax =1.35,y=5000,cex=1)+
  annotate(geom = 'text',label='****',x=1.23,y=5100,size=6)+
  
  annotate(geom = 'linerange',xmin=1.7,xmax =1.9,y=5000,cex=1)+
  annotate(geom = 'text',label='****',x=1.8,y=5100,size=6)+
  
  annotate(geom = 'linerange',xmin=1.95,xmax =2.35,y=5200,cex=1)+
  annotate(geom = 'text',label='****',x=2.15,y=5300,size=6)+
  
  scale_fill_manual(name = "",values = c("NS" = "#4489C8", "SMK" = "#ED7E7A", "NS+abx" = "#008F91", "SMK+abx" = "#FFCD44")) +
  scale_x_discrete( expand = c(0.05,0))+ #控制第一个分组和Y轴的距离
  scale_y_continuous(limits = c(0,6000),breaks = seq(0,6000,2000), expand = c(0,0))+
  labs(title = "",x = "", y = "Fecal calories per g")+
  theme_classic(base_size = 18)+
  theme(legend.position = "top",
        legend.margin = margin(0,0,0,0),
        legend.key.width = unit(0.6,"cm"),
        legend.key.height = unit(0.1,"cm"),
        legend.key = element_rect(colour = "black"),
        axis.title = element_text(size = 18,face = "plain"),
        axis.text = element_text(size = 18,face = "plain",colour = "black"))
p5
ggsave("BarDotErrorBar.pdf", plot =p5, height = 5.5, width = 5.5,device = cairo_pdf)

#组合
#利用grid包将ggplot_gtable对象和其他图像拼图
pdf("combined.pdf", width = 6, height = 12)
grid.arrange(ggp, ggplotGrob(p4),ggplotGrob(p5),nrow=3,ncol = 1,widths=unit(4, "null"), heights=unit(rep(6, 3), "null"))
dev.off()

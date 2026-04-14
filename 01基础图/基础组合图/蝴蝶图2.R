# 蝴蝶图是一种镜像对称的双向条形图，常用于展示同一特征在两个不同组之间的差异。条形图的左右分别展示两个组，中心为特征标签，有如蝴蝶张开的双翼。
# 常见的应用场景：
# 宏基因组研究：展示抗生素处理前 vs 后小鼠粪便菌群变化
#转录组分析：展示不同发育阶段组织的差异表达基因
# 单细胞组学：可展示 marker 基因在不同群体之间的表达差异
# 相比普通柱状图，蝴蝶图能快速扫视对称结构，直观比较分组间变化，还能美观整合多个维度（如棒棒糖图添加点代表 EC_score 等额外信息）。
### 模拟数据构建 ----
set.seed(42)
marker <- c('CD34','IL3RA','SMIM24','CLEC12A','IL2RA','FAM30A','BEX3',
            'CD96','CD200','CDK6','IL1RAP','CD33','SOCS2','CD9','KIT',
            'CD99','CD82','CPXM1','CD47','CD38')

dt_r <- data.frame(
  marker = factor(marker, levels = rev(marker)),
  gene_impact_score = runif(20, 2, 18),
  EC_score = runif(20, 0, 8),
  group = 'Pei'
)

dt_l <- data.frame(
  marker = factor(marker, levels = rev(marker)),
  gene_impact_score = runif(20, 2, 18),
  EC_score = runif(20, 0, 8),
  group = 'van Galen'
)
### 📦 加载所需R包 ----
library(ggplot2)
library(patchwork)

### 🎨 设置通用主题 ----
mytheme <- theme(
  axis.title = element_blank(),
  axis.text.y = element_blank(),
  axis.ticks.y = element_blank(),
  axis.ticks.x = element_blank(),
  panel.grid = element_blank(),
  panel.border = element_blank(),
  axis.text = element_text(size = 12)
)
### 🎯 右侧棒棒糖图（Pei组） ----
p_right <- ggplot(dt_r, aes(x = gene_impact_score, y = marker)) +
  geom_col(width = 0.1, aes(fill = gene_impact_score)) +
  geom_point(aes(size = EC_score,color = gene_impact_score),show.legend = F) +
  scale_size_continuous(limits=c(0,8), range = c(0.5, 8)) +
  scale_x_continuous(limits = c(0, 20), breaks = seq(0, 20, 5)) +
  cols4all::scale_fill_continuous_c4a_seq('reds3',reverse = T) +
  cols4all::scale_color_continuous_c4a_seq('reds3',reverse = T) +
  labs(title = 'Pei') +
  theme_bw() + mytheme +
  theme(plot.title = element_text(face = 'bold', color = '#d72422', size = 16))

### 🎯 左侧棒棒糖图（van Galen组） ----
p_left <- ggplot(dt_l, aes(x = gene_impact_score, y = marker)) +
  geom_col(width = 0.1, aes(fill = gene_impact_score)) +
  geom_point(aes(size = EC_score,color = gene_impact_score)) +
  scale_size_continuous(limits=c(0,8), range = c(0.5, 8)) +
  cols4all::scale_fill_continuous_c4a_seq('purples') +
  cols4all::scale_color_continuous_c4a_seq('purples') +
  scale_x_reverse(limits = c(20, 0), breaks = seq(0, 20, 5)) +
  scale_y_discrete(position = "right") +
  labs(title = 'van Galen') +
  theme_bw() + mytheme +
  theme(plot.title = element_text(face = 'bold', color = '#5f3c99', hjust = 1, size = 16))

### 🏷️ 中央标签层（marker标签） ----
p_label <- ggplot() +
  geom_text(data = dt_l, aes(x = 0, y = marker, label = marker), size = 4.5, hjust = 0.5) +
  theme_void()

### 🧩 拼接三个部分形成蝴蝶图 ----
final_plot <- p_left + p_label + p_right + plot_layout(widths = c(8, 1.8, 8), guides = 'collect')
final_plot

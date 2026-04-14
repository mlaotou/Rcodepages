rm(list=ls())  # 清除环境变量
# 加载必要的 R 包
library(tidyverse)
library(patchwork)

# 模拟数据：生成两个数据框，分别代表 M1 和 M2 特征
set.seed(123)
features <- c("MΦ-CCL2", "MΦ-CXCL9", "MΦ-ISG15", "MΦ-CCL3L1", "MΦ-FN1", "MΦ-FOLR2",
              "MΦ-RNASE1", "MΦ-LL1B", "MΦ-SELENOP", "MΦ-MT1X", "MΦ-NUPR1", "MΦ-FTH1")

# 每个特征生成 50 个值
data_M1 <- as_tibble(map_dfc(set_names(features), ~ rnorm(50, mean = runif(1, 0.1, 0.5), sd = 0.1)))
data_M2 <- as_tibble(map_dfc(set_names(features), ~ rnorm(50, mean = runif(1, 0.1, 0.5), sd = 0.1)))

# 转换为长格式
long_data_M1 <- pivot_longer(data_M1, cols = everything(), names_to = "Variable", values_to = "Value")
long_data_M2 <- pivot_longer(data_M2, cols = everything(), names_to = "Variable", values_to = "Value")

# 设置变量顺序
order <- features
long_data_M1$Variable <- factor(long_data_M1$Variable, levels = order)
long_data_M2$Variable <- factor(long_data_M2$Variable, levels = order)

# 自定义颜色
col <- c("#66a686", "#52be87", "#b47a3d", "#5292c4", "#fbcdcb", "#c1938d",
         "#f8a4d5", "#c7a8d9", "#e56ebe", "#a4e0e4", "#b3c8ea", "#a6dfbe")
text_col <- c("#000000", "#f04625", "#161112", "#f04625", "#00a8ee", "#f04625",
              "#00a8ee", "#161112", "#161112", "#00a8ee", "#161112", "#161112")

# 绘制右半边小提琴图（M2）
M2_plot <- ggplot(long_data_M2, aes(y = Variable, x = Value, fill = Variable)) +
  geom_violin(trim = FALSE) +
  geom_boxplot(width = 0.15, fill = "white", outlier.shape = NA) +
  geom_vline(xintercept = 0.25, linetype = "dashed", color = "#bf1a2c", size = 1) +
  scale_x_continuous(expand = c(0, 0), position = "top", guide = guide_axis(angle = -90)) +
  scale_fill_manual(values = col) +
  labs(title = "M2 Feature", x = "Score") +
  theme_classic() +
  theme(
    axis.text.y = element_text(size = 28, hjust = 0.5, colour = text_col),
    axis.text.x = element_text(size = 28, color = "black"),
    axis.title.x = element_text(hjust = -0.8, size = 33),
    axis.title.y = element_blank(),
    axis.ticks.length = unit(2, "mm"),
    plot.title = element_text(hjust = 0.5, vjust = -82, size = 30, color = "#00a8ee"),
    legend.position = "none",
    plot.margin = margin(r = 10, b = 50)
  )

# 绘制左半边小提琴图（M1）
M1_plot <- ggplot(long_data_M1, aes(y = Variable, x = -Value, fill = Variable)) +
  geom_violin(trim = FALSE) +
  geom_boxplot(width = 0.15, fill = "white", outlier.shape = NA) +
  geom_vline(xintercept = -0.25, linetype = "dashed", color = "#bf1a2c", size = 1) +
  scale_x_continuous(
    expand = c(0, 0),
    position = "top",
    guide = guide_axis(angle = -90),
    labels = function(x) format(abs(x), nsmall = 1)
  ) +
  scale_y_discrete(position = "right") +
  scale_fill_manual(values = col) +
  labs(title = "M1 Feature") +
  theme_classic() +
  theme(
    axis.text.x = element_text(size = 28, color = "black"),
    axis.text.y = element_blank(),
    axis.title = element_blank(),
    axis.ticks.length = unit(2, "mm"),
    plot.title = element_text(hjust = 0.5, vjust = -82, size = 30, color = "#f04625"),
    legend.position = "none",
    plot.margin = margin(l = 5, b = 50)
  )

# 合并左右图
p1 <- M1_plot + M2_plot
#==============
# 蝴蝶堆积柱形图
# 加载必要的 R 包
library(tidyverse)
library(patchwork)
library(cowplot)
library(grid)

# 模拟数据：构建与网页一致的结构
set.seed(123)
cell_types <- c("VenEC", "ArtEC", "Stalk_SII", "Stalk_SIII", "Tip_SII",
                "Transition", "Tip_SIII", "Stalk_SI", "APLN+Tip_SI")
responses <- c("Risk", "Protective")
groups <- c("PFS in TCGA", "OS in TCGA")

# 构建数据框
data <- expand.grid(type = cell_types, response = responses, group = groups)
data$number <- sample(1:15, nrow(data), replace = TRUE)

# 设置因子顺序
data$type <- factor(data$type, levels = cell_types)
data$response <- factor(data$response, levels = c("Risk", "Protective"))

# 自定义颜色
col <- c("#b33c44", "#4f94b9")

# 绘制右半边堆积柱形图（OS）
OS_plot <- ggplot(data[data$group == "OS in TCGA", ], aes(number, type)) +
  geom_col(aes(fill = response), color = "black", width = 0.7) +
  scale_x_continuous(breaks = seq(0, 15, 5)) +
  scale_fill_manual(values = col) +
  labs(subtitle = "OS in TCGA") +
  theme_classic() +
  theme(
    axis.text.y = element_text(size = 20, hjust = 0.5, color = "black"),
    axis.text.x = element_text(size = 20, color = "black"),
    axis.title = element_blank(),
    axis.ticks.length = unit(2, "mm"),
    axis.ticks = element_line(color = "black", linewidth = 1),
    axis.line = element_line(color = "black", linewidth = 1),
    plot.subtitle = element_text(hjust = 0.5, size = 22),
    legend.position = "none",
    plot.margin = margin(r = 15)
  )

# 绘制左半边堆积柱形图（PFS）
PFS_plot <- ggplot(data[data$group == "PFS in TCGA", ], aes(-number, type)) +
  geom_col(aes(fill = response), color = "black", width = 0.7) +
  scale_x_continuous(labels = function(x) format(abs(x))) +
  scale_y_discrete(position = "right") +
  scale_fill_manual(values = col) +
  labs(subtitle = "PFS in TCGA") +
  theme_classic() +
  theme(
    axis.text.x = element_text(size = 20, color = "black"),
    axis.text.y = element_blank(),
    axis.title = element_blank(),
    axis.ticks.length = unit(2, "mm"),
    axis.ticks = element_line(color = "black", linewidth = 1),
    axis.line = element_line(color = "black", linewidth = 1),
    plot.subtitle = element_text(hjust = 0.5, size = 22),
    legend.title = element_blank(),
    legend.text = element_text(size = 15, color = "black"),
    legend.key.size = unit(0.5, "cm"),
    legend.key.spacing.y = unit(1, "mm"),
    legend.position = "bottom",
    plot.margin = margin(l = 15)
  )

# 合并左右图并添加注释
combined_plot <- PFS_plot + OS_plot +
  plot_annotation(caption = "Number of cancer types",
                  theme = theme(plot.caption = element_text(hjust = 0.5, size = 22)))

# 添加红色虚框强调区域
p2 <- ggdraw(combined_plot) +
  draw_grob(
    rectGrob(
      x = unit(0.5, "npc"), y = unit(0.88, "npc"),
      width = unit(0.9, "npc"), height = unit(0.098, "npc"),
      gp = gpar(col = "#b33c44", fill = NA, lwd = 2, lty = 2)
    )
  )
# ggsave(p1,filename = "对向提琴图.pdf",height = 8,width = 10,family = "serif")
# ggsave(p2,filename = "对向堆叠柱形图.pdf",height = 8,width = 10,family = "serif")

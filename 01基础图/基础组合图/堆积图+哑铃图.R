# 加载必要的R包
library(ggplot2)
library(dplyr)
library(patchwork)

# -----------------------------
# 模拟数据（与网页结构一致）
# -----------------------------

# 模拟哑铃图数据
set.seed(123)
families <- paste0("Family_", LETTERS[1:20])
data_dumbbell <- data.frame(
  family = families,
  observed_num = sample(10:100, 20),
  expected_median = sample(10:100, 20),
  expected_quartile0.05 = sample(5:20, 10),
  expected_quartile0.95 = sample(80:100, 20)
)

# 模拟堆积柱形图数据
depths <- c("Shallow", "Intermediate", "Deep")
data_bar <- expand.grid(family = families, tridepth = depths)
data_bar$nsp <- sample(1:50, nrow(data_bar), replace = TRUE)

# -----------------------------
# 数据处理
# -----------------------------

# 对哑铃图数据按差值排序，并添加颜色标签
data_dumbbell_sorted <- data_dumbbell %>%
  arrange(observed_num - expected_median) %>%
  mutate(col = case_when(
    observed_num >= expected_quartile0.05 & observed_num <= expected_quartile0.95 ~ "Within expectation",
    observed_num > expected_quartile0.95 ~ "Above expectation",
    observed_num < expected_quartile0.05 ~ "Below expectation"
  ))

# 设置排序因子
order <- data_dumbbell_sorted$family
data_dumbbell_sorted$family <- factor(data_dumbbell_sorted$family, levels = order)
data_bar$family <- factor(data_bar$family, levels = order)
data_bar_sorted <- data_bar[order(data_bar$family), ]

# 设置特殊物种颜色
mark_fams <- c("Family_A", "Family_C", "Family_E")
famcol <- ifelse(levels(factor(data_bar$family)) %in% mark_fams, "#F8766D", "grey30")

# -----------------------------
# 绘制堆积柱形图
# -----------------------------
p1 <- ggplot(data_bar_sorted, aes(x = family, y = nsp, fill = factor(tridepth, levels = c("Deep", "Intermediate", "Shallow")))) +
  geom_bar(position = "fill", stat = "identity", width = 0.7) +
  scale_fill_manual(values = c("#6946A6", "#A178DF", "#DCB0FF")) +
  coord_flip() +
  labs(x = NULL, y = NULL) +
  theme_classic() +
  theme(
    axis.text.y = element_text(colour = famcol),
    axis.text.x = element_blank(),
    axis.ticks = element_blank(),
    axis.line = element_blank(),
    legend.title = element_blank(),
    legend.position = "bottom"
  ) +
  guides(fill = guide_legend(ncol = 3))

# -----------------------------
# 绘制哑铃图
# -----------------------------
p2 <- ggplot(data_dumbbell_sorted, aes(x = family, y = observed_num)) +
  geom_segment(aes(xend = family, y = expected_quartile0.05, yend = expected_quartile0.95), col = "grey90", lwd = 3, lineend = "round") +
  geom_segment(aes(xend = family, y = expected_median, yend = observed_num), col = "grey50", lwd = 0.6) +
  geom_point(aes(y = expected_median), pch = 21, fill = "white", col = "grey50", size = 3, stroke = 1) +
  geom_point(aes(col = factor(col, levels = c("Above expectation", "Within expectation", "Below expectation"))), size = 3.3) +
  scale_color_manual(values = c("#D65DB1", "grey40", "#F2AD00")) +
  coord_flip() +
  ylab("Number of Transitions") +
  theme_classic() +
  theme(
    axis.text.y = element_blank(),
    axis.title.y = element_blank(),
    legend.title = element_blank(),
    legend.position = "bottom"
  )

# -----------------------------
# 拼接图形
# -----------------------------
p1 + p2 + plot_layout(widths = c(1, 9))

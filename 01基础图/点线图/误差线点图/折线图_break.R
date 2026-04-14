# 1. Load required libraries
library(ggplot2)
library(dplyr)
library(ggbreak) # Required for scale_y_break()

# 2. Simulate the data based on visual estimation of the image
tissues <- c("Bone", "Brain", "Fat", "Gonad", "Gut", "Heart", "Kidney", "Liver", "Muscle", "Skin")
age_bins <- c("Agebin1", "Agebin2", "Agebin3", "Agebin4", "Agebin5")

df.sex <- expand.grid(tissue = tissues, age_bin = age_bins)
df.sex$age_bin <- factor(df.sex$age_bin, levels = age_bins)

# Hand-coded percentage values to visually match the image lines
values <- c(
  # Agebin 1
  4, 1, 19, 99, 1, 1, 19, 36, 3, 24,
  # Agebin 2
  1, 1, 11, 99, 4, 3, 11, 24, 0.5, 13,
  # Agebin 3
  1, 3, 0.5, 91, 0.5, 0.5, 2, 14, 1, 5,
  # Agebin 4
  2, 1, 4, 85, 1, 3, 12, 23, 2, 16,
  # Agebin 5
  8, 1, 23, 96, 0.5, 0.5, 28, 27, 4, 15
)
df.sex$tot.deg.number.perc <- values

# 3. Define the exact color palette from your script
colTPS <- c(
  'Bone'       = '#d8413f',
  'Brain'      = '#00a550',
  'Fat'        = '#eee09b',
  'Gonad'      = '#7962A3',
  'Gut'        = '#010101',
  'Heart'      = '#f0932e',
  'Kidney'     = '#fcd328',
  'Liver'      = '#6cc0ee',
  'Muscle'     = '#f4c489',
  'Skin'       = '#ab5673'
)

# 4. Filter labels for the right side of the plot
label_df <- df.sex %>% 
  filter(age_bin == "Agebin5" & tissue %in% c("Gonad", "Liver", "Kidney", "Skin", "Fat"))

# 5. Define data for the colored rectangular boxes below the x-axis
boxes_df <- data.frame(
  xmin = c(0.6, 1.6, 2.6, 3.6, 4.6),
  xmax = c(1.4, 2.4, 3.4, 4.4, 5.4),
  ymin = -4,
  ymax = -1,
  fill = c("#3b6293", "#4594bb", "#e4ecee", "#f0d5af", "#f4b172") # Hex matching image bottom bars
)

# 6. Generate the plot
p <- ggplot() +
  # Add the data lines and points
  geom_line(data = df.sex, aes(x = age_bin, y = tot.deg.number.perc, group = tissue, color = tissue), alpha = 0.5) +
  geom_point(data = df.sex, aes(x = age_bin, y = tot.deg.number.perc, group = tissue, color = tissue), alpha = 0.5, size = 1.5) +
  
  # Add the right-side tissue labels
  geom_text(data = label_df, aes(x = age_bin, y = tot.deg.number.perc, label = tissue, color = tissue), 
            hjust = -0.2, vjust = 0.5, size = 5, fontface = "plain") +
  
  # Add the colored boxes below the x-axis
  geom_rect(data = boxes_df, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax), 
            fill = boxes_df$fill, color = "white", linewidth = 0.5) +
  
  # Axis limits, labels, and color scales
  scale_y_continuous(breaks = seq(0, 100, by = 10), limits = c(-5, 100)) +
  scale_color_manual(values = colTPS) +
  labs(y = "% of genes expressed") +
  
  # Theme customization
  theme_classic() +
  theme(
    legend.position = "none",
    axis.title.x = element_blank(),
    axis.title.y = element_text(size = 14, color = "black"),
    axis.text.y = element_text(size = 12, color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 12, color = "black"),
    axis.line.x = element_blank(), # Hide original x line to rely on the boxes/ticks
    axis.ticks.x = element_blank(),
    plot.margin = margin(t = 10, r = 60, b = 10, l = 10) # Expand right margin for labels
  ) +
  # Coordinate setup to allow drawing outside boundaries (specifically for labels)
  coord_cartesian(clip = "off") + 
  
  # Add the Y-axis break
  scale_y_break(c(40, 80), scales = "fixed")

# Print the plot
print(p)
ggsave(filename = "折线图.pdf",height = 4,width = 3,family = "serif")

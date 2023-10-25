# Load required libraries
library(ggplot2)
library(caret)
library(randomForest)
library(forecast)

# Set seed for reproducibility
set.seed(123)

# Phase 2: Data Collection and Preparation
# Generate synthetic stock and bond prices for 100 days
n <- 100
stock_prices <- cumprod(1 + rnorm(n, 0, 0.02))
bond_yields <- cumprod(1 + rnorm(n, 0, 0.01))

# Combine stock and bond prices into a data frame
data <- data.frame(
  Date = seq.Date(from = as.Date("2022-01-01"), by = "days", length.out = n),
  Stock_Price = stock_prices,
  Bond_Yield = bond_yields
)

# Phase 3: Exploratory Data Analysis (EDA)
# Plot stock and bond prices
ggplot(data, aes(x = Date)) +
  geom_line(aes(y = Stock_Price, color = "Stock Price")) +
  geom_line(aes(y = Bond_Yield, color = "Bond Yield")) +
  labs(title = "Stock and Bond Data", y = "Price/Yield") +
  theme_minimal()

# Phase 4: Model Building
# Prepare data for machine learning
data$Prev_Stock_Price <- c(NA, head(stock_prices, -1))
data$Prev_Bond_Yield <- c(NA, head(bond_yields, -1))
data <- na.omit(data)

# Split data into training and testing sets
trainIndex <- createDataPartition(data$Stock_Price, p = .8, list = FALSE)
dataTrain <- data[trainIndex,]
dataTest  <- data[-trainIndex,]

# Train a random forest model to predict stock prices
model <- randomForest(Stock_Price ~ Prev_Stock_Price + Prev_Bond_Yield, data = dataTrain)

# Make predictions
predictions <- predict(model, newdata = dataTest)

# Phase 5: Risk Assessment using Monte Carlo Simulation
n_simulations <- 1000
final_stock_prices <- numeric(n_simulations)

for (i in 1:n_simulations) {
  simulated_prices <- cumprod(1 + rnorm(n, 0, 0.02))
  final_stock_prices[i] <- tail(simulated_prices, 1)
}

# Calculate risk metrics: mean, standard deviation, and VaR at 95% confidence level
mean_final_price <- mean(final_stock_prices)
std_dev <- sd(final_stock_prices)
VaR_95 <- quantile(final_stock_prices, 0.05)

# Visualize the Monte Carlo Simulation results
ggplot(data.frame(Final_Stock_Prices = final_stock_prices), aes(x = Final_Stock_Prices)) +
  geom_histogram(binwidth = 2, fill = "blue", alpha = 0.7) +
  geom_vline(aes(xintercept = VaR_95), color = "red", linetype = "dashed", size = 1) +
  annotate("text", x = VaR_95, y = 50, label = paste("VaR 95%:", round(VaR_95, 2))) +
  labs(title = "Monte Carlo Simulation of Final Stock Prices", x = "Final Stock Price", y = "Frequency") +
  theme_minimal()

# Reset graphical parameters
dev.off() # Reset the graphical device
par(mfrow = c(1, 1), mar = c(5, 4, 2, 2))

# Fit an ARIMA model to the stock prices
arima_model <- auto.arima(dataTrain$Stock_Price)

# Forecast next 30 days
forecast_results <- forecast(arima_model, h = 30)

# Plot the forecast
plot(forecast_results, main = "30-Day Stock Price Forecast using ARIMA")
ggsave("my_plot.png")

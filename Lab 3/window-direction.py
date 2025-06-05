import pandas as pd

df = pd.read_csv("GlobalWeatherRepository.csv")
# Всі напрямки вітру csv
print(sorted(df['wind_direction'].unique()))

# Перевірка на пропущені значення
missing_count = df['wind_direction'].isnull().sum()

if missing_count == 0:
    print("Усі значення в колонці 'wind_direction' заповнені.")
else:
    print(f"Є {missing_count} пропущених значень у колонці 'wind_direction'.")

from extract import extract_data
from transform import change_to_datetime, last_2_months, column_checker
import pandas as pd

''' EXTRACT PROCESS '''
# Define file path for each data frames
budget_path = './data/campaign_budget.csv'
campaign_path = './data/campaign_result.csv'
checkout_path = './data/product_checkout.csv'

data_frame= {
    'campaign_budget' : extract_data(budget_path),
    'campaign_result' : extract_data(campaign_path),
    'product_checkout' : extract_data(checkout_path)
}

''' TRANSFORM PROCESS '''
# CLEANSING PROCESS
init_transformation_processes = [
    change_to_datetime, # Change str into datetime type
    last_2_months # Set range on last 2 month
]

for name, df in data_frame.items():
    for transform in init_transformation_processes:
        df = transform(df)
    data_frame[name] = df


print(len(data_frame['campaign_budget']))




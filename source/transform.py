import pandas as pd

def change_to_datetime(data_frame):

    data_frame['date'] = pd.to_datetime(data_frame['date'],  format= '%Y-%m-%d')

    return data_frame

def last_2_months(data_frame):

    recent_day = data_frame['date'].max()
    last_60_days = recent_day - pd.Timedelta(days= 61)

    data_frame = data_frame[(data_frame['date'] >= last_60_days) & (data_frame['date'] < recent_day)]

    return data_frame


def column_checker(data_frame):

    rules_of_checker = {
        'campaign_budget' : {
            'campaign_id' : int,
            'budget' : float
        },
        'campaign_result' : {
            'campaign_id' : int,
            'user_id' : int,
            'checkout_id' : int,
            'is_click' : int
        },
        'product_checkout' : {
            'checkout_id' : int,
            'is_checkout' : int,
            'qty' : int,
            'unit_price' : float
        }
    }

    

    print(data_frame.name())
    return data_frame
import pandas as pd
import os

# THIS ONE IS WORK BUT NOT SAFE TO USE
# def extract_data():
#     data_frames = {}
#     data_folder_path = './data'

#     for filename in os.listdir(data_folder_path):
#         name = os.path.splitext(filename)[0]
#         filepath = os.path.join(data_folder_path, filename)
#         data_frames[name] = pd.read_csv(filepath)

#     return data_frames


def extract_data(path):
    ext = os.path.splitext(path)[1].lower()

    if ext == '.csv':
        df = pd.read_csv(path)
    elif ext in ['.xls', '.xlsx']:
        df = pd.read_excel(path)
    else :
        return "Failed to extract file into data frame"
    
    return df

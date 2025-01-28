# the metadata comes from "Our World in Data"
# We prefer this metadata over OxCGRT because it is already normalized
# see https://github.com/owid/covid-19-data/tree/master/public/data

import pandas as pd
import sys
import requests
import datacommons_pandas as dc
from time import sleep
import numpy as np
import pyarrow as pa
import pyarrow.parquet as pq
from datetime import datetime
from pathlib import Path


# NATIONAL LEVEL WE USE "OUR WORLD IN DATA"


URL = "https://catalog.ourworldindata.org/garden/covid/latest/cases_deaths/cases_deaths.csv"
RELEVANT_COLS = ['date', 'country', 'new_deaths_per_million', 'new_cases_per_million']
df = pd.read_csv(URL,  usecols=RELEVANT_COLS)
df['Jurisdiction'] = "NAT_TOTAL"


# SUBNATIONAL WE USE OXCGRT 


URL = "https://raw.githubusercontent.com/OxCGRT/covid-policy-dataset/main/data/OxCGRT_compact_subnational_v1.csv"
df_sub=pd.read_csv(URL)

countries_with_subnational = ['United States', 'Canada', 'Australia', 'Brazil', 'United Kingdom']

df_sub = df_sub[df_sub.CountryName.isin(countries_with_subnational)]
df_sub = df_sub[df_sub.Jurisdiction == 'STATE_TOTAL']

sel_cols = ['CountryName', 'RegionName', 'Date', 'Jurisdiction', 'ConfirmedCases', 'ConfirmedDeaths']
df_sub = df_sub.loc[~df_sub.RegionName.isna(), sel_cols]

df_sub['Date'] = df_sub.Date.astype(str).map(lambda x: x[:4] + '-' + x[4:6] + '-' + x[6:])
df_sub.rename(columns={'CountryName': 'country', 'Date': 'date'}, inplace=True)

# The ConfirmedCases and Deaths in OxCGRT are cumulative.
# We take the Diff to get the daily new cases, as with "our world in data"
# If there are fewer cases, we put 0 new cases.
df_sub['new_cases'] = df_sub.groupby(["country", "RegionName"])['ConfirmedCases'].diff().fillna(0)
df_sub['new_cases'] = np.where(df_sub.new_cases < 0, 0, df_sub.new_cases)

df_sub['new_deaths'] = df_sub.groupby(["country", "RegionName"])['ConfirmedDeaths'].diff().fillna(0)
df_sub['new_deaths'] = np.where(df_sub.new_deaths < 0, 0, df_sub.new_deaths)

df_sub.drop(['ConfirmedCases', 'ConfirmedDeaths'], axis=1, inplace=True)

# Now we need to resample the subnational data to weekly data
# We take the sum of new cases and deaths for each week
# for the same time interval as the national data
df['date'] = pd.to_datetime(df['date'])
df_sub['date'] = pd.to_datetime(df_sub['date'])

# Get the min and max date per country from df
df_min_max = df.groupby('country')['date'].agg(['min', 'max']).reset_index()

# Merge min/max dates with df_sub so we know the range for each country
df_merged = pd.merge(df_sub, df_min_max, on='country', how='left')

def resample_region(df):
    df_min_date = df['min'].iloc[0]  # The min date for this group
    df_max_date = df['max'].iloc[0]  # The max date for this group
    
    # Filter data within the date range
    df = df[(df['date'] >= df_min_date) & (df['date'] <= df_max_date)]
    
    # Set 'date' as the index
    df = df.set_index('date')
    
    # Resample by 7 days, starting from the min date, summing new cases and deaths
    df_resampled = df[['new_cases', 'new_deaths']].resample('7D', origin=df_min_date).sum()
    
    # Reset index to get 'date' back as a column
    return df_resampled.reset_index()

df_sub = df_merged.groupby(['country', 'RegionName', 'Jurisdiction'])\
                  .apply(resample_region).reset_index()\
                  .drop("level_3", axis=1)


# POPULATION DATA FROM DATA COMMONS

def load_pop_from_data_commons():
    """data commons doesn't like when we query too many regions at once"""
    usa = 'country/USA'
    can = 'country/CAN'
    brasil = 'country/BRA'
    aus = 'country/AUS'
    uk = 'country/GBR'

    us_states = dc.get_places_in([usa], 'State')[usa]
    can_provs = dc.get_places_in([can], 'AdministrativeArea1')[can]
    brasil_districts = dc.get_places_in([brasil], 'AdministrativeArea1')[brasil]
    aus_districts = dc.get_places_in([aus], 'AdministrativeArea1')[aus]
    uk_districts = dc.get_places_in([uk], 'EurostatNUTS1')[uk]

    regions = us_states+can_provs+brasil_districts+aus_districts+uk_districts

    geoID2name = dc.get_property_values(regions, 'name')

    df_pop = []
    for region in regions:
        print(f"doing {region}")
        try:
            time_series = dc.build_time_series_dataframe(region, "Count_Person").reset_index()
            time_series = time_series.melt(id_vars='place', var_name='year', value_name='Count_Person')
            time_series = time_series[~time_series.Count_Person.isna()]
            time_series = time_series.drop_duplicates(['place', 'year'])
            time_series['RegionName'] = time_series.place.map(lambda x: geoID2name[x][0])
            df_pop.append(time_series)
        except:
            print(f"failed {region}")

    df_pop = pd.concat(df_pop, axis=0)
    df_pop['year'] = df_pop.year.map(lambda x: int(x[:4]))
    df_pop = df_pop[(df_pop['year'] >= 2020) & (df_pop['year'] <= 2022)]
    df_pop.drop_duplicates(["place", "year"], inplace=True)
    return df_pop

dc_fname = Path("src/.observablehq/cache/data/population_dc.parquet")
if dc_fname.exists():
    df_pop = pd.read_parquet(dc_fname)
else:
    df_pop = load_pop_from_data_commons()
    df_pop.to_parquet(dc_fname)


# MERGE Region Metadata with "Data Commons" data


df_sub['year'] = df_sub.date.map(lambda x: int(str(x)[:4]))
df_sub = df_sub.merge(df_pop[['year', 'RegionName', 'Count_Person']], how='left', on=['year', 'RegionName'])
df_sub.drop('year', axis=1, inplace=True)

df_sub['new_cases_per_100k'] = df_sub.new_cases / df_sub.Count_Person * 100_000
df_sub['new_deaths_per_100k'] = df_sub.new_deaths / df_sub.Count_Person * 100_000

df_sub.drop(["Count_Person", "new_cases", "new_deaths"], axis=1, inplace=True)

# CONCAT National Metadata with subnational    

df = pd.concat([df, df_sub], axis=0)

df.country.replace("United States", "United States of America", inplace=True)
df.country.replace("Czechia", "Czech Republic", inplace=True)

# # Parquet doesn't take pandas datetime64, so we convert to string
df['date'] = df.date.astype(str)

# Write DataFrame to a temporary file-like object

buf = pa.BufferOutputStream()
table = pa.Table.from_pandas(df)
pq.write_table(table, buf, compression="snappy")

# Get the buffer as a bytes object
buf_bytes = buf.getvalue().to_pybytes()

# Write the bytes to standard output
sys.stdout.buffer.write(buf_bytes)

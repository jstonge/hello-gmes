# See https://github.com/OxCGRT/covid-policy-dataset/blob/main/documentation_and_codebook.md for documentation

import pandas as pd
import sys
import requests
import numpy as np
import pyarrow as pa
import pyarrow.parquet as pq

URL = "https://raw.githubusercontent.com/OxCGRT/covid-policy-dataset/main/data/OxCGRT_compact_national_v1.csv"
df = pd.read_csv(URL)

# pd.options.display.max_rows = None
# df.columns

df = df.loc[:, ~df.columns.str.endswith("Flag")]
df = df.loc[:, ~df.columns.str.endswith("Notes")]

closure_policies = df.columns[df.columns.str.contains("^C\d", regex=True)].tolist()
economic_policies = df.columns[df.columns.str.contains("^E\d", regex=True)].tolist()
health_policies = df.columns[df.columns.str.contains("^H\d", regex=True)].tolist()
vaccination_policies = df.columns[df.columns.str.contains("^V\d", regex=True)].tolist()

sel_cols = ['CountryName', 'Date', 'Jurisdiction', 'ConfirmedCases', 'ContainmentHealthIndex_Average'] + closure_policies + economic_policies + health_policies + vaccination_policies

df = df[sel_cols]

age_order = ['0-4 yrs', '5-15 yrs', '16-19 yrs', '20-24 yrs', '25-29 yrs',
             '30-34 yrs', '35-39 yrs', '40-44 yrs', '45-49 yrs', '50-54 yrs',
             '55-59 yrs', '60-64 yrs', '65-69 yrs', '70-74 yrs', '75-79 yrs',
             '80+ yrs']

df['V2B_Vaccine age eligibility/availability age floor (general population summary)'] = pd.Categorical(df['V2B_Vaccine age eligibility/availability age floor (general population summary)'], categories=age_order, ordered=True)
df['V2B_Vaccine age eligibility/availability age floor (general population summary)'] = df['V2B_Vaccine age eligibility/availability age floor (general population summary)'].cat.codes.replace(-1, np.nan)

df['V2C_Vaccine age eligibility/availability age floor (at risk summary)'] = pd.Categorical(df['V2C_Vaccine age eligibility/availability age floor (at risk summary)'], categories=age_order, ordered=True)
df['V2C_Vaccine age eligibility/availability age floor (at risk summary)'] = df['V2C_Vaccine age eligibility/availability age floor (at risk summary)'].cat.codes.replace(-1, np.nan)

df['Date'] = df.Date.astype(str).map(lambda x: x[:4] + '-' + x[4:6] + '-' + x[6:])

df.CountryName.replace({'United States': 'United States of America'}, inplace=True)

df_long = df.melt(id_vars=['CountryName', 'Jurisdiction', 'Date', 'ConfirmedCases', 'ContainmentHealthIndex_Average'], var_name='PolicyType', value_name='PolicyValue')

# Write DataFrame to a temporary file-like object
buf = pa.BufferOutputStream()
table = pa.Table.from_pandas(df_long)
pq.write_table(table, buf, compression="snappy")

# Get the buffer as a bytes object
buf_bytes = buf.getvalue().to_pybytes()

# Write the bytes to standard output
sys.stdout.buffer.write(buf_bytes)

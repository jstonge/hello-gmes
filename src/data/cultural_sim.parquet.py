import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from pathlib import Path
import sys

# DOWNLOAD FROM https://world.culturalytics.com/table?countryA=&countryB=&countries=All&dimension=POLITICAL%3ANeoliberalism..capitalism&question&years=2010-2014&years=2005-2009&confidenceInterval=false&level=dimension&search=&appearance=flag-name

fpath = Path("src/.observablehq/cache/data/culturaldistance-80-countries-neoliberalism-capitalism-2005-2014-years-table-combined.csv")

df = pd.read_csv(fpath)
df = df.rename(columns={"Name": "country"})\
    .melt(id_vars="country", var_name="country2", value_name="cultural_distance")\
    .assign(
        country=lambda x: x.country.str.replace("2005-2014", ""),
        country2=lambda x: x.country2.str.replace("2005-2014", "")
        )

# Write DataFrame to a temporary file-like object

buf = pa.BufferOutputStream()
table = pa.Table.from_pandas(df)
pq.write_table(table, buf, compression="snappy")

# Get the buffer as a bytes object
buf_bytes = buf.getvalue().to_pybytes()

# Write the bytes to standard output
sys.stdout.buffer.write(buf_bytes)

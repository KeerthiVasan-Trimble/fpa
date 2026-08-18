# Amortization waterfall using pure pandas (no SQL)
# Co-authored with CoCo

import pandas as pd
import numpy as np
from snowflake.snowpark.context import get_active_session


def compute_amortization_waterfall(
    revenue_table: str,
    schedule_table: str,
    output_table: str,
    calendar_table: str
):
    session = get_active_session()

    # Load all tables into pandas
    revenue_df = session.table(revenue_table).to_pandas()
    schedule_df = session.table(schedule_table).to_pandas()
    calendar_df = session.table(calendar_table).select("FISCAL_MONTH_START").to_pandas()

    # Build fiscal month sequence: distinct months from today onward
    today = pd.Timestamp.today().normalize().replace(day=1)
    fiscal_df = (
        calendar_df[["FISCAL_MONTH_START"]]
        .drop_duplicates()
        .rename(columns={"FISCAL_MONTH_START": "MONTH_START"})
        .sort_values("MONTH_START")
        .reset_index(drop=True)
    )
    fiscal_df = fiscal_df[fiscal_df["MONTH_START"] >= today].reset_index(drop=True)
    fiscal_df["MONTH_SEQ"] = fiscal_df.index + 1

    # Join revenue with schedule
    input_df = revenue_df.merge(schedule_df, on="USER_NAME")
    input_df["BASE_AMOUNT"] = np.round(input_df["AMOUNT"] / input_df["MONTHS"], 2)

    # Expand each row into target months
    rows = []
    for _, row in input_df.iterrows():
        lag = int(row["LAG_MONTHS"])
        months = int(row["MONTHS"])
        half = bool(row["HALF_MONTH"])
        total_months = months + (1 if half else 0)

        targets = fiscal_df[
            (fiscal_df["MONTH_SEQ"] >= lag + 1) &
            (fiscal_df["MONTH_SEQ"] <= lag + total_months)
        ]

        for _, fm in targets.iterrows():
            month_number = int(fm["MONTH_SEQ"]) - lag

            if half and month_number == 1:
                amt = round(row["BASE_AMOUNT"] / 2, 2)
            elif half and month_number == months + 1:
                amt = round(row["BASE_AMOUNT"] / 2, 2)
            else:
                amt = row["BASE_AMOUNT"]

            rows.append({
                "USER_NAME": row["USER_NAME"],
                "CURRENT_MONTH": row["CURRENT_MONTH"],
                "TARGET_MONTH": fm["MONTH_START"],
                "AMOUNT": amt
            })

    expanded_df = pd.DataFrame(rows)

    # Aggregate by user + target month
    result_df = (
        expanded_df
        .groupby(["USER_NAME", "TARGET_MONTH"])
        .agg(
            AMOUNT=("AMOUNT", "sum"),
            SOURCE_MONTHS=("CURRENT_MONTH", lambda x: ", ".join(sorted(x.unique())))
        )
        .reset_index()
        .sort_values(["USER_NAME", "TARGET_MONTH"])
    )
    result_df["AMOUNT"] = result_df["AMOUNT"].round(2)

    # Write back to Snowflake
    session.write_pandas(
        result_df,
        table_name=output_table.split(".")[-1],
        database=output_table.split(".")[0],
        schema=output_table.split(".")[1],
        overwrite=True
    )

    print(f"Done: {len(result_df)} rows written to {output_table}")
    print(result_df.to_string(index=False))
    return result_df


result = compute_amortization_waterfall(
    revenue_table="FIELD_SYSTEMS_EDW.GENERAL.USER_REVENUE",
    schedule_table="FIELD_SYSTEMS_EDW.GENERAL.USER_SCHEDULE",
    output_table="FIELD_SYSTEMS_EDW.GENERAL.AMORTIZATION_OUTPUT",
    calendar_table="FIELD_SYSTEMS_EDW.GENERAL.DIMENSION_FISCAL_CALENDAR"
)

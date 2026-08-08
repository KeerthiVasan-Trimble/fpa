from snowflake.snowpark.context import get_active_session
from datetime import date as dt_date
import pandas as pd


class FiscalCalendar:
    """Singleton class for fiscal calendar lookups backed by DIMENSION_FISCAL_CALENDAR."""

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return
        session = get_active_session()
        self._df = session.table("FIELD_SYSTEMS_EDW.GENERAL.DIMENSION_FISCAL_CALENDAR").to_pandas()
        date_cols = [
            "CALENDAR_DATE", "FISCAL_MONTH_START", "FISCAL_QUARTER_START",
            "FISCAL_YEAR_START", "FISCAL_MONTH_END", "FISCAL_QUARTER_END", "FISCAL_YEAR_END"
        ]
        for col in date_cols:
            self._df[col] = pd.to_datetime(self._df[col]).dt.date
        self._events_df = session.table("FIELD_SYSTEMS_EDW.GENERAL.FISCAL_CALENDAR_EVENTS").to_pandas()
        self._events_df["CALENDAR_DATE"] = pd.to_datetime(self._events_df["CALENDAR_DATE"]).dt.date
        self._initialized = True

    def get_date_details(self, date_str: str) -> dict:
        """Return all fiscal calendar attributes for the given date (YYYY-MM-DD)."""
        target = dt_date.fromisoformat(date_str)
        row = self._df[self._df["CALENDAR_DATE"] == target]
        if not row.empty:
            return row.iloc[0].to_dict()
        return None

    def get_weeks_of_month(self, year_month: str) -> int:
        """Return the number of weeks in the given fiscal month (YYYY-MM)."""
        year, month = year_month.split("-")
        fiscal_month_code = f"{year}-M{month}"
        filtered = self._df[self._df["FISCAL_MONTH_CODE"] == fiscal_month_code]
        if not filtered.empty:
            return int(filtered["WEEKS_IN_MONTH"].iloc[0])
        return None

    def get_current_quarter(self, date_str: str) -> dict:
        """Return the fiscal quarter code and number for the given date (YYYY-MM-DD)."""
        row = self.get_date_details(date_str)
        if row is not None:
            return {
                "fiscal_quarter_code": row["FISCAL_QUARTER_CODE"],
                "fiscal_quarter": int(row["FISCAL_QUARTER"])
            }
        return None

    def get_current_month(self, date_str: str) -> dict:
        """Return the fiscal month code and number for the given date (YYYY-MM-DD)."""
        row = self.get_date_details(date_str)
        if row is not None:
            return {
                "fiscal_month_code": row["FISCAL_MONTH_CODE"],
                "fiscal_month": int(row["FISCAL_MONTH"])
            }
        return None

    def get_current_week(self, date_str: str) -> dict:
        """Return the fiscal week code and number for the given date (YYYY-MM-DD)."""
        row = self.get_date_details(date_str)
        if row is not None:
            return {
                "fiscal_week_code": row["FISCAL_WEEK_CODE"],
                "fiscal_week": int(row["FISCAL_WEEK"])
            }
        return None

    def get_month_start(self, date_str: str) -> str:
        """Return the fiscal month start date for the given date (YYYY-MM-DD)."""
        row = self.get_date_details(date_str)
        if row is not None:
            return str(row["FISCAL_MONTH_START"])
        return None

    def get_quarter_start(self, date_str: str) -> str:
        """Return the fiscal quarter start date for the given date (YYYY-MM-DD)."""
        row = self.get_date_details(date_str)
        if row is not None:
            return str(row["FISCAL_QUARTER_START"])
        return None

    def get_year_start(self, date_str: str) -> str:
        """Return the fiscal year start date for the given date (YYYY-MM-DD)."""
        row = self.get_date_details(date_str)
        if row is not None:
            return str(row["FISCAL_YEAR_START"])
        return None

    def get_month_close(self, date_str: str) -> str:
        """Return the fiscal month end date for the given date (YYYY-MM-DD)."""
        row = self.get_date_details(date_str)
        if row is not None:
            return str(row["FISCAL_MONTH_END"])
        return None

    def get_quarter_close(self, date_str: str) -> str:
        """Return the fiscal quarter end date for the given date (YYYY-MM-DD)."""
        row = self.get_date_details(date_str)
        if row is not None:
            return str(row["FISCAL_QUARTER_END"])
        return None

    def get_year_close(self, date_str: str) -> str:
        """Return the fiscal year end date for the given date (YYYY-MM-DD)."""
        row = self.get_date_details(date_str)
        if row is not None:
            return str(row["FISCAL_YEAR_END"])
        return None

    # --- Event methods ---

    def get_events(self, date_str: str) -> list:
        """Return all events for the given date (YYYY-MM-DD)."""
        target = dt_date.fromisoformat(date_str)
        filtered = self._events_df[self._events_df["CALENDAR_DATE"] == target]
        if not filtered.empty:
            return filtered.to_dict("records")
        return []

    def get_events_by_month(self, year_month: str) -> list:
        """Return all events in the given fiscal month (YYYY-MM)."""
        year, month = year_month.split("-")
        fiscal_month_code = f"{year}-M{month}"
        filtered = self._events_df[self._events_df["FISCAL_MONTH_CODE"] == fiscal_month_code]
        if not filtered.empty:
            return filtered.to_dict("records")
        return []

    def get_events_by_quarter(self, year_quarter: str) -> list:
        """Return all events in the given fiscal quarter (YYYY-QN, e.g. '2026-Q3')."""
        filtered = self._events_df[self._events_df["FISCAL_QUARTER_CODE"] == year_quarter]
        if not filtered.empty:
            return filtered.to_dict("records")
        return []

    def get_events_by_year(self, year: int) -> list:
        """Return all events in the given fiscal year."""
        filtered = self._events_df[self._events_df["FISCAL_YEAR"] == year]
        if not filtered.empty:
            return filtered.to_dict("records")
        return []

    def is_freeze_date(self, date_str: str) -> bool:
        """Check if the given date is a freeze date."""
        events = self.get_events(date_str)
        return any(e["EVENT_TYPE"] == "FREEZE_DATE" for e in events)

    def is_pay_day(self, date_str: str) -> bool:
        """Check if the given date is a pay day."""
        events = self.get_events(date_str)
        return any(e["EVENT_TYPE"] == "PAY_DAY" for e in events)


# --- Test: one test case per function ---
fc = FiscalCalendar()

print("1.  get_date_details('2026-08-06'):")
d = fc.get_date_details("2026-08-06")
print(f"    FISCAL_WEEK_CODE={d['FISCAL_WEEK_CODE']}, DAY_OF_WEEK={d['DAY_OF_WEEK']}")

print(f"2.  get_weeks_of_month('2026-01'):       {fc.get_weeks_of_month('2026-01')}")
print(f"3.  get_current_quarter('2026-08-06'):   {fc.get_current_quarter('2026-08-06')}")
print(f"4.  get_current_month('2026-08-06'):     {fc.get_current_month('2026-08-06')}")
print(f"5.  get_current_week('2026-08-06'):      {fc.get_current_week('2026-08-06')}")
print(f"6.  get_month_start('2026-08-06'):       {fc.get_month_start('2026-08-06')}")
print(f"7.  get_quarter_start('2026-08-06'):     {fc.get_quarter_start('2026-08-06')}")
print(f"8.  get_year_start('2026-08-06'):        {fc.get_year_start('2026-08-06')}")
print(f"9.  get_month_close('2026-08-06'):       {fc.get_month_close('2026-08-06')}")
print(f"10. get_quarter_close('2026-08-06'):     {fc.get_quarter_close('2026-08-06')}")
print(f"11. get_year_close('2026-08-06'):        {fc.get_year_close('2026-08-06')}")
print(f"12. get_events('2026-01-30'):            {fc.get_events('2026-01-30')}")
print(f"13. get_events_by_month('2026-01'):      {len(fc.get_events_by_month('2026-01'))} events")
print(f"14. get_events_by_quarter('2026-Q1'):    {len(fc.get_events_by_quarter('2026-Q1'))} events")
print(f"15. get_events_by_year(2026):            {len(fc.get_events_by_year(2026))} events")
print(f"16. is_freeze_date('2026-01-30'):        {fc.is_freeze_date('2026-01-30')}")
print(f"17. is_pay_day('2026-01-16'):            {fc.is_pay_day('2026-01-16')}")


# --- SQL for tracking (one-time setup) ---
#
# CREATE TABLE IF NOT EXISTS FIELD_SYSTEMS_EDW.GENERAL.FISCAL_CALENDAR_EVENTS (
#     CALENDAR_DATE       DATE         NOT NULL,
#     EVENT_TYPE          VARCHAR(50)  NOT NULL,
#     FISCAL_MONTH_CODE   VARCHAR(10),
#     FISCAL_QUARTER_CODE VARCHAR(10),
#     FISCAL_YEAR         NUMBER(4, 0),
#     DESCRIPTION         VARCHAR(255),
#     CREATED_BY          VARCHAR(100),
#     CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
# );
#
# INSERT INTO FIELD_SYSTEMS_EDW.GENERAL.FISCAL_CALENDAR_EVENTS
#     (CALENDAR_DATE, EVENT_TYPE, FISCAL_MONTH_CODE, FISCAL_QUARTER_CODE, FISCAL_YEAR, DESCRIPTION, CREATED_BY)
# VALUES
#     ('2026-01-30', 'FREEZE_DATE',       '2026-M01', '2026-Q1', 2026, 'Month 1 freeze',           'KKUMARA'),
#     ('2026-01-16', 'PAY_DAY',           '2026-M01', '2026-Q1', 2026, 'Mid-month payday',         'KKUMARA'),
#     ('2026-01-31', 'PAY_DAY',           '2026-M01', '2026-Q1', 2026, 'End-month payday',         'KKUMARA'),
#     ('2026-01-10', 'CORPORATE_ROLLUP',  '2026-M01', '2026-Q1', 2026, 'Q1 first rollup (M01)',    'KKUMARA'),
#     ('2026-01-24', 'CORPORATE_ROLLUP',  '2026-M01', '2026-Q1', 2026, 'Q1 second rollup (M01)',   'KKUMARA'),
#     ('2026-02-14', 'CORPORATE_ROLLUP',  '2026-M02', '2026-Q1', 2026, 'Q1 rollup (M02)',          'KKUMARA'),
#     ('2026-02-27', 'FREEZE_DATE',       '2026-M02', '2026-Q1', 2026, 'Month 2 freeze',           'KKUMARA'),
#     ('2026-02-15', 'PAY_DAY',           '2026-M02', '2026-Q1', 2026, 'Mid-month payday',         'KKUMARA'),
#     ('2026-02-28', 'PAY_DAY',           '2026-M02', '2026-Q1', 2026, 'End-month payday',         'KKUMARA'),
#     ('2026-03-14', 'CORPORATE_ROLLUP',  '2026-M03', '2026-Q1', 2026, 'Q1 rollup (M03)',          'KKUMARA'),
#     ('2026-08-01', 'FREEZE_DATE',       '2026-M07', '2026-Q3', 2026, 'Month 7 freeze',           'KKUMARA'),
#     ('2026-08-15', 'PAY_DAY',           '2026-M07', '2026-Q3', 2026, 'Mid-month payday',         'KKUMARA');

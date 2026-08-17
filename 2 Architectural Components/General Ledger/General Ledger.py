from snowflake.snowpark.context import get_active_session
from typing import Optional, List


# ============================================================
# SAFETY CHECK RULES
# ============================================================
# Add, remove, or edit rules here. Each rule is a dictionary:
#
#   cost_center:     "1000"          (exact match)
#                    "2100 to 2150"  (inclusive range)
#                    "3000 to 6999"  (inclusive range)
#
#   natural_account: "40XXX"         (must start with "40")
#
#   location:        "0000"          (must be exactly 0000)
#                    "not 0000"      (must be anything other than 0000)
#                    "any"           (no restriction)
#
# If a cost center has multiple valid combinations, list them
# as separate entries under "allows". The input is valid if it
# matches ANY one of the listed combinations.
# ============================================================

RULES = [
    {
        "cost_center": "1000",
        "allows": [
            {"natural_account": "40XXX", "location": "0000"},
        ],
    },
    {
        "cost_center": "2100 to 2150",
        "allows": [
            {"natural_account": "50XXX", "location": "0000"},
        ],
    },
    {
        "cost_center": "2151",
        "allows": [
            {"natural_account": "60XXX", "location": "0000"},
            {"natural_account": "70XXX", "location": "not 0000"},
        ],
    },
    {
        "cost_center": "3000 to 6999",
        "allows": [
            {"natural_account": "70XXX", "location": "any"},
        ],
    },
]


class GeneralLedger:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return
        self._initialized = True

        session = get_active_session()

        # Business Group
        bg_df = session.table("FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_GL_BUSINESS_GROUP").select("BUSINESS_AREA", "DESCRIPTION").collect()
        self._bg_lookup = {row["BUSINESS_AREA"]: row["DESCRIPTION"] for row in bg_df}
        self._bg_reverse = {row["DESCRIPTION"]: row["BUSINESS_AREA"] for row in bg_df}

        # Location
        loc_df = session.table("FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_GL_LOCATION").select("LOCATION", "DESCRIPTION").collect()
        self._loc_lookup = {row["LOCATION"]: row["DESCRIPTION"] for row in loc_df}
        self._loc_reverse = {row["DESCRIPTION"]: row["LOCATION"] for row in loc_df}

        # Cost Center
        cc_df = session.table("FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_GL_COST_CENTER").select("COST_CENTER", "DESCRIPTION").collect()
        self._cc_lookup = {row["COST_CENTER"]: row["DESCRIPTION"] for row in cc_df}
        self._cc_reverse = {row["DESCRIPTION"]: row["COST_CENTER"] for row in cc_df}

        # Natural Account
        na_df = session.table("FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_GL_NATURAL_ACCOUNT").select("NATURAL_ACCOUNT", "DESCRIPTION").collect()
        self._na_lookup = {row["NATURAL_ACCOUNT"]: row["DESCRIPTION"] for row in na_df}
        self._na_reverse = {row["DESCRIPTION"]: row["NATURAL_ACCOUNT"] for row in na_df}

    # --- Business Group ---
    def get_business_group_description(self, code: str) -> str:
        return self._bg_lookup.get(code, f"Unknown code: {code}")

    def get_business_group_code(self, description: str) -> str:
        return self._bg_reverse.get(description, f"Unknown description: {description}")

    # --- Location ---
    def get_location_description(self, code: str) -> str:
        return self._loc_lookup.get(code, f"Unknown code: {code}")

    def get_location_code(self, description: str) -> str:
        return self._loc_reverse.get(description, f"Unknown description: {description}")

    # --- Cost Center ---
    def get_cost_center_description(self, code: str) -> str:
        return self._cc_lookup.get(code, f"Unknown code: {code}")

    def get_cost_center_code(self, description: str) -> str:
        return self._cc_reverse.get(description, f"Unknown description: {description}")

    # --- Natural Account ---
    def get_natural_account_description(self, code: str) -> str:
        return self._na_lookup.get(code, f"Unknown code: {code}")

    def get_natural_account_code(self, description: str) -> str:
        return self._na_reverse.get(description, f"Unknown description: {description}")

    # --- Rule Engine ---
    def _parse_cost_center_match(self, spec: str):
        if " to " in spec:
            low, high = spec.split(" to ")
            return ("range", low.strip(), high.strip())
        return ("exact", spec.strip())

    def _match_cost_center(self, cc: str, spec: str) -> bool:
        parsed = self._parse_cost_center_match(spec)
        if parsed[0] == "exact":
            return cc == parsed[1]
        if parsed[0] == "range":
            return parsed[1] <= cc <= parsed[2]
        return False

    def _parse_na_prefix(self, spec: str) -> str:
        return spec.replace("X", "").replace("x", "")

    def _check_location(self, location: Optional[str], rule: str) -> bool:
        if rule == "any":
            return True
        if rule == "0000":
            return location is None or location == "0000"
        if rule == "not 0000":
            return location is not None and location != "0000"
        return True

    def safety_check(
        self,
        business_group: Optional[str] = None,
        location: Optional[str] = None,
        cost_center: Optional[str] = None,
        natural_account: Optional[str] = None,
    ) -> List[str]:
        if not any([business_group, location, cost_center, natural_account]):
            return ["At least one code must be provided."]

        errors = []

        if cost_center:
            for rule in RULES:
                if not self._match_cost_center(cost_center, rule["cost_center"]):
                    continue

                valid = False
                for combo in rule["allows"]:
                    na_prefix = self._parse_na_prefix(combo["natural_account"])
                    loc_rule = combo["location"]
                    na_ok = (natural_account is None) or natural_account.startswith(na_prefix)
                    loc_ok = self._check_location(location, loc_rule)
                    if na_ok and loc_ok:
                        valid = True
                        break

                if not valid:
                    allowed = ", ".join(
                        f"NA {c['natural_account']} + Location {c['location']}"
                        for c in rule["allows"]
                    )
                    details = []
                    if natural_account:
                        details.append(f"NA='{natural_account}' ({self.get_natural_account_description(natural_account)})")
                    if location:
                        details.append(f"Location='{location}' ({self.get_location_description(location)})")
                    errors.append(
                        f"Cost Center {cost_center} ({self.get_cost_center_description(cost_center)}) "
                        f"allows: [{allowed}]. Got: {', '.join(details)}."
                    )
                break

        return errors


# Initialize the singleton
gl = GeneralLedger()

# Test safety check
print("=== Safety Check Tests ===\n")

tests = [
    ("CC=1000, NA=40010, LOC=0000",  {"cost_center": "1000", "natural_account": "40010", "location": "0000"}),
    ("CC=1000, NA=10010, LOC=0000",  {"cost_center": "1000", "natural_account": "10010", "location": "0000"}),
    ("CC=1000, NA=40010, LOC=1234",  {"cost_center": "1000", "natural_account": "40010", "location": "1234"}),
    ("CC=2100, NA=50010, LOC=0000",  {"cost_center": "2100", "natural_account": "50010", "location": "0000"}),
    ("CC=2100, NA=40010, LOC=0000",  {"cost_center": "2100", "natural_account": "40010", "location": "0000"}),
    ("CC=2151, NA=60010, LOC=0000",  {"cost_center": "2151", "natural_account": "60010", "location": "0000"}),
    ("CC=2151, NA=70010, LOC=1234",  {"cost_center": "2151", "natural_account": "70010", "location": "1234"}),
    ("CC=2151, NA=70010, LOC=0000",  {"cost_center": "2151", "natural_account": "70010", "location": "0000"}),
    ("CC=4000, NA=70010, LOC=5678",  {"cost_center": "4000", "natural_account": "70010", "location": "5678"}),
    ("CC=4000, NA=50010, LOC=5678",  {"cost_center": "4000", "natural_account": "50010", "location": "5678"}),
    ("All empty",                     {}),
]

for label, kwargs in tests:
    result = gl.safety_check(**kwargs)
    print(f"  {label} -> {result or 'PASS'}")

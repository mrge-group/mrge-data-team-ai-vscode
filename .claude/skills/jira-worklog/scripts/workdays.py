#!/usr/bin/env python3
"""Compute German working days (Mon-Fri, minus public holidays) from the 1st
of a month up to and including a given day.

Usage:
    python3 workdays.py --year 2026 --month 7 --until 7 [--state BE]

Prints JSON: {"working_days": [...], "count": N, "total_hours": N*8,
              "holidays_excluded": [...], "holiday_source": "..."}

Uses the `holidays` package when installed (supports per-state subdivisions
like BE, BY, NW). Falls back to the 9 nationwide German public holidays
computed locally (Easter via the Anonymous Gregorian algorithm).
"""
import argparse
import calendar
import datetime as dt
import json


def easter(year: int) -> dt.date:
    a = year % 19
    b = year // 100
    c = year % 100
    d = b // 4
    e = b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i = c // 4
    k = c % 4
    ell = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * ell) // 451
    month = (h + ell - 7 * m + 114) // 31
    day = ((h + ell - 7 * m + 114) % 31) + 1
    return dt.date(year, month, day)


def german_holidays(year: int, state: str | None):
    """Returns (holiday_map, source, warning_or_None)."""
    try:
        import holidays as _hol

        hd = _hol.Germany(years=year, subdiv=state) if state else _hol.Germany(years=year)
        return {d: name for d, name in hd.items()}, f"holidays package (state={state or 'nationwide'})", None
    except ImportError:
        warning = (
            f"--state {state} requested but the 'holidays' package is not installed; "
            "falling back to NATIONWIDE holidays only — state-specific holidays are MISSED. "
            "Install it (poetry install / pip install holidays) and re-run."
            if state
            else None
        )
        e = easter(year)
        fallback = {
            dt.date(year, 1, 1): "Neujahr",
            e - dt.timedelta(days=2): "Karfreitag",
            e + dt.timedelta(days=1): "Ostermontag",
            dt.date(year, 5, 1): "Tag der Arbeit",
            e + dt.timedelta(days=39): "Christi Himmelfahrt",
            e + dt.timedelta(days=50): "Pfingstmontag",
            dt.date(year, 10, 3): "Tag der Deutschen Einheit",
            dt.date(year, 12, 25): "1. Weihnachtstag",
            dt.date(year, 12, 26): "2. Weihnachtstag",
        }
        return fallback, "built-in fallback (nationwide holidays only)", warning


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--year", type=int, required=True)
    p.add_argument("--month", type=int, required=True)
    p.add_argument("--until", type=int, required=True, help="last day of month to include")
    p.add_argument("--state", default=None, help="German state code, e.g. BE, BY, NW (optional)")
    args = p.parse_args()

    if not 1 <= args.month <= 12:
        p.error(f"--month must be 1-12, got {args.month}")
    days_in_month = calendar.monthrange(args.year, args.month)[1]
    if not 1 <= args.until <= days_in_month:
        p.error(f"--until must be 1-{days_in_month} for {args.year}-{args.month:02d}, got {args.until}")

    hols, source, warning = german_holidays(args.year, args.state)
    working, excluded = [], []
    for day in range(1, args.until + 1):
        d = dt.date(args.year, args.month, day)
        if d.weekday() >= 5:
            continue
        if d in hols:
            excluded.append({"date": d.isoformat(), "name": hols[d]})
            continue
        working.append(d.isoformat())

    result = {
        "working_days": working,
        "count": len(working),
        "total_hours": len(working) * 8,
        "holidays_excluded": excluded,
        "holiday_source": source,
    }
    if warning:
        result["warning"] = warning
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()

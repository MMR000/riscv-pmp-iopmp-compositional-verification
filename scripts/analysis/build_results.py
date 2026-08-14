#!/usr/bin/env python3
"""Aggregate experiment outputs."""
import argparse
from pathlib import Path

root = Path(__file__).resolve().parents[2]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--m2", action="store_true")
    args = p.parse_args()
    if args.m2:
        m2 = root / "results" / "simulation" / "m2_summary.md"
        if m2.exists():
            print(m2.read_text())
    else:
        m1 = root / "results" / "simulation" / "m1_summary.md"
        if m1.exists():
            print(m1.read_text())
        else:
            print("No results yet. Run: make m1")


if __name__ == "__main__":
    main()

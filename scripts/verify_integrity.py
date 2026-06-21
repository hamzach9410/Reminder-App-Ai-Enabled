import os
import sys
import subprocess
import time

def run_command(command, description):
    print(f"\n[RUNNING] {description}...")
    start_time = time.time()
    try:
        # Use shell=True for Windows compatibility with flutter/dart/python commands
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        duration = time.time() - start_time
        print(f"PASSED ({duration:.2f}s)")
        return True
    except subprocess.CalledProcessError as e:
        print(f"FAILED")
        print(f"Error Output:\n{e.stderr}")
        return False

def main():
    print("="*60)
    print("VAULT SYSTEM INTEGRITY MANIFEST (SIM) VERIFIER v1.0")
    print("="*60)

    # 1. Cost Guardrail Scan
    if not run_command("python scripts/cost_guard.py", "Scanning for Paid-Tier Infrastructure"):
        sys.exit(1)

    # 2. Edge-AI Performance Profile
    if not run_command("flutter test scripts/nlp_benchmark.dart", "Benchmarking Edge-Inference Latency"):
        sys.exit(1)

    # 3. Data Sync Integrity Tests
    if not run_command("flutter test test/sync_logic_test.dart", "Verifying Delta-Reconciliation Logic"):
        sys.exit(1)

    # 4. Linter Check
    if not run_command("flutter analyze", "Checking Code Consistency (Linter)"):
        sys.exit(1)

    print("\n" + "="*60)
    print("ALL SYSTEMS OPERATIONAL. NUCLEAR-GRADE STATUS: VERIFIED.")
    print("="*60)

if __name__ == "__main__":
    main()

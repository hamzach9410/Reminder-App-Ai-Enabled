import sys
import os

# Definitions of "Dangerous" keywords that imply paid infrastructure
FORBIDDEN_KEYWORDS = [
    'google_cloud_vision',
    'aws_lambda',
    'stripe_payment', # Unless specifically asked
    'firebase_ml_vision',
    'cloud_functions', # Free limit exists but risky
    'openai',
    'anthropic',
    'azure_openai'
]

def check_files():
    violations = []
    
    files_to_check = [
        'pubspec.yaml',
        'backend/package.json'
    ]

    for file_path in files_to_check:
        if not os.path.exists(file_path):
            continue
            
        with open(file_path, 'r') as f:
            content = f.read().lower()
            for kw in FORBIDDEN_KEYWORDS:
                if kw in content:
                    violations.append(f"VIOLATION: '{kw}' found in {file_path}")

    return violations

if __name__ == "__main__":
    print("--- Cost-Guardrail Scanning ---")
    violations = check_files()
    
    if violations:
        for v in violations:
            print(f"\x1B[31m{v}\x1B[0m")
        print("[REJECTED] Paid-tier infrastructure detected. Aborting commit.")
        sys.exit(1)
    else:
        print("[VERIFIED] $0.00 footprint maintained. Proceeding.")
        sys.exit(0)

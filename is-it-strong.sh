#!/usr/bin/env python3
import argparse
import math
from collections import Counter


def calculate_entropy(password):
    """Calculate Shannon entropy of password in bits."""
    if not password:
        return 0.0

    freq = Counter(password)
    length = len(password)
    entropy = -sum((count/length) * math.log2(count/length)
                   for count in freq.values())
    return entropy * length


def get_charset_size(password):
    """Determine character set size used in password."""
    size = 0
    if any(c.islower() for c in password):
        size += 26
    if any(c.isupper() for c in password):
        size += 26
    if any(c.isdigit() for c in password):
        size += 10
    if any(not c.isalnum() for c in password):
        size += 32  # approximation for common symbols
    return size


def rate_strength(entropy, length):
    """Rate password strength based on entropy and length."""
    if entropy < 28:
        return "Very Weak"
    elif entropy < 36:
        return "Weak"
    elif entropy < 60:
        return "Moderate"
    elif entropy < 128:
        return "Strong"
    else:
        return "Very Strong"


def main():
    parser = argparse.ArgumentParser(description='Calculate password entropy and strength')
    parser.add_argument('-p', '--password', required=True, help='Password to analyze')
    args = parser.parse_args()

    password = args.password
    entropy = calculate_entropy(password)
    charset = get_charset_size(password)
    theoretical_entropy = len(password) * math.log2(charset) if charset > 0 else 0
    strength = rate_strength(entropy, len(password))

    print(f"Length: {len(password)}")
    print(f"Character set size: {charset}")
    print(f"Shannon entropy: {entropy:.2f} bits")
    print(f"Theoretical max entropy: {theoretical_entropy:.2f} bits")
    print(f"Strength rating: {strength}")


if __name__ == "__main__":
    main()

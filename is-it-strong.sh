#!/usr/bin/env python3
import argparse
import math
import sys
import getpass
import termios
import tty
from collections import Counter


def get_password_masked(prompt="Password: "):
    """Get password with asterisk masking."""
    sys.stdout.write(prompt)
    sys.stdout.flush()
    password = []
    
    # Save terminal settings
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    
    try:
        # Switch to raw mode
        tty.setraw(sys.stdin.fileno())
        
        while True:
            ch = sys.stdin.read(1)
            
            # Enter (CR or LF)
            if ch == '\r' or ch == '\n':
                sys.stdout.write('\r\n')
                break
                
            # Backspace (DEL or Backspace)
            elif ch == '\x7f' or ch == '\x08':
                if password:
                    password.pop()
                    # Move back, overwrite with space, move back again
                    sys.stdout.write('\b \b')
                    sys.stdout.flush()
            
            # Ctrl+C
            elif ch == '\x03':
                raise KeyboardInterrupt
                
            # Ctrl+D (EOF)
            elif ch == '\x04':
                if not password:
                    raise EOFError
                break
                
            # Normal characters
            else:
                password.append(ch)
                sys.stdout.write('*')
                sys.stdout.flush()
                
    finally:
        # Restore terminal settings
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        
    return "".join(password)


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
    parser = argparse.ArgumentParser(description='Calculate password entropy and strength. reads from stdin or prompts securely.')
    args = parser.parse_args()

    if not sys.stdin.isatty():
        # Read from pipe, removing only the trailing newline (preserve other whitespace)
        password = sys.stdin.read().rstrip('\r\n')
    else:
        # Interactive secure prompt
        try:
            password = get_password_masked("Enter password to analyze: ")
        except KeyboardInterrupt:
            print("\nAborted.")
            sys.exit(1)
        except EOFError:
            print("\nAborted.")
            sys.exit(1)

    if not password:
        print("Error: Empty password provided.")
        sys.exit(1)

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

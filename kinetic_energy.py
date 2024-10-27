#!/usr/bin/env python3

import argparse

# get kinetic energy for any object you know the speed and weight
# To use, just run python3 kinetic_energy.py --speed 30 --weight 1500
# speed is in Km/h, weight in Kg


def calculate_energy(weight, velocity):
    # Convert weight from kg to Newtons (1 kg = 9.81 N)
    mass = weight * 9.81

    # Calculate kinetic energy (in Joules)
    kinetic_energy = 0.5 * mass * (velocity**2)

    return kinetic_energy


def convert_kmh_to_ms(kmh):
    return kmh * (1000 / 3600)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Calculate kinetic energy of a moving vehicle"
    )
    parser.add_argument(
        "-s", type=float, required=True, help="Velocity in kilometers per hour"
    )
    parser.add_argument("-w", type=float, required=True, help="Weight in kilograms")
    args = parser.parse_args()

    velocity_km = args.s
    velocity_ms = convert_kmh_to_ms(velocity_km)
    weight = args.w

    energy = calculate_energy(weight, velocity_ms)

    print(f"Kinetic Energy: {energy:.2f} J")

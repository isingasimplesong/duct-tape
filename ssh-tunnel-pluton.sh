#!/usr/bin/env bash

# crée un tunnel ssh exposant pluton:port sur localhost:port
ssh -L 5001:localhost:5001 -L 8200:localhost:8200 pluton

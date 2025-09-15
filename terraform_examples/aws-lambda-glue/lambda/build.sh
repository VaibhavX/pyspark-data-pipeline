#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building hello_lambda..."
zip -r hello_payload.zip lambda_function.py

echo "Buildiing data_processor_lambda..."
zip -r processor_payload.zip processor.py

echo "Build complete"
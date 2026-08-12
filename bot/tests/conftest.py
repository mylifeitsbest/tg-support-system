import os
import pytest

# Set env before any app import so Settings picks them up
os.environ["BOT_TOKEN"] = "1234567890:test_token_for_tests_only"
os.environ["API_BASE_URL"] = "http://localhost:8000"

import random
import string
import datetime

def generate_soc_id():
    """
    Generates a unique SOC ID.
    Format: SOC-<YEAR>-<6 RANDOM ALPHANUMERIC>
    """
    year = datetime.datetime.now().year
    random_str = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
    return f"SOC-{year}-{random_str}"

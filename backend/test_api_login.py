import urllib.request
import urllib.parse
import json

url = "http://127.0.0.1:8000/api/v1/auth/login"
data = urllib.parse.urlencode({
    "username": "test5@gmail.com",
    "password": "test5#123"
}).encode()

try:
    req = urllib.request.Request(url, data=data, method='POST')
    with urllib.request.urlopen(req) as response:
        print(f"Status Code: {response.status}")
        print(f"Response: {response.read().decode()}")
except urllib.error.HTTPError as e:
    print(f"HTTP Error: {e.code}")
    print(f"Response: {e.read().decode()}")
except Exception as e:
    print(f"Error: {e}")

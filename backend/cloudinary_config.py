import cloudinary
import cloudinary.uploader
import cloudinary.api
from dotenv import load_dotenv
import os

load_dotenv()  # load .env file

cloudinary.config(
    cloud_name = os.getenv("dyi7xoqhy"),
    api_key = os.getenv("587679965546116"),
    api_secret = os.getenv("**********"),
    secure = True
)

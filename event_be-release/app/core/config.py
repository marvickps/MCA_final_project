# app/core/config.py
from datetime import timedelta
from pydantic_settings import BaseSettings 
from pydantic import field_validator
from typing import List
from dotenv import load_dotenv
import os
import json

JWT_SECRET_KEY = "YOUR_SECRET_KEY"            # change to a strong random value!
JWT_ALGORITHM  = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7     # 7 days


# load environment file
env_file =  ".env.local"
load_dotenv(env_file)

GOOGLE_MAPS_API_KEY=os.getenv("GOOGLE_MAPS_API_KEY")


class Settings(BaseSettings):
    ENV: str
    DATABASE_URL: str
    ASYNC_DATABASE_URL: str
    CORS_ORIGINS: List[str]
    GOOGLE_MAPS_API_KEY: str
    AWS_ACCESS_KEY: str
    AWS_SECRET_KEY: str
    S3_BUCKET_NAME: str
    S3_REGION: str


    @field_validator("CORS_ORIGINS", mode="before")
    def parse_cors(cls, value):
        """
        This validator ensures it can handle either:
            * list (like ["url"]), or
            * comma-separated string (url1,url2)
        """
        if isinstance(value, str):
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return [v.strip() for v in value.split(",")]
        return value

    class Config:
        env_file = env_file
        case_sensitive = True

settings = Settings()

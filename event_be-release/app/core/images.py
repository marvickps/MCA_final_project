
from fastapi import File, UploadFile, HTTPException, APIRouter
import boto3
import os
from dotenv import load_dotenv
import time
from core.config import settings
import random, string
# Initialize S3 client
s3 = boto3.client(
    "s3",
    region_name=settings.S3_REGION,
    aws_access_key_id=settings.AWS_ACCESS_KEY,
    aws_secret_access_key=settings.AWS_SECRET_KEY
)
S3_BUCKET_NAME = settings.S3_BUCKET_NAME

async def upload_image(file: UploadFile = File(...)):
    # filename = f"{int(os.path.getmtime(file.file.fileno()))}_{file.filename}"
    filename = f"{int(time.time())}_{''.join(random.choices(string.digits, k=6))}_{(file.filename)}"

    try:
        s3.upload_fileobj(file.file, S3_BUCKET_NAME, filename)
        return {"message": "Image uploaded successfully", "filename": filename}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def view_image(selected_image_key: str = None):
    current_image = selected_image_key
    if not current_image:
        raise HTTPException(status_code=404, detail="No image uploaded")
    url = s3.generate_presigned_url('get_object',
                                    Params={'Bucket': S3_BUCKET_NAME, 'Key': current_image},
                                    ExpiresIn=3600)
    return {"url": url, "filename": current_image}


def delete_image(selected_image_key: str = None):
    current_image = selected_image_key
    if not current_image:
        raise HTTPException(status_code=404, detail="No image to delete")

    try:
        s3.delete_object(Bucket=S3_BUCKET_NAME, Key=current_image)
        return {"message": "Image deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

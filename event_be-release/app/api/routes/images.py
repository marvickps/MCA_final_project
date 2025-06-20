from fastapi import APIRouter, UploadFile, File, Query
from core import images

router = APIRouter(prefix="/api/images", tags=["images"])

@router.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    return await images.upload_image(file)

@router.get("/view/{selected_image_key}")
def view_image(selected_image_key: str):
    return images.view_image(selected_image_key)

@router.delete("/delete/{selected_image_key}")
def delete_image(selected_image_key: str):
    return images.delete_image(selected_image_key)

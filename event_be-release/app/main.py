import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn



# make sure you create tables before serving
from core.database import engine
from models import events
from core.database import Base

from api.routes import (user,hotel_route, itinerary, events,
                        connection_request, otp, to_request, client,
                        images, booking)
from api.routes.resources.hotels.hotel_route import router as hotel_router
from api.routes.resources.hotels.hotel_room_route import router as hotel_room_router
from api.routes.auth import router as auth_router
from api.routes.google_maps_router import router as google_maps_router
from core.config import settings
# from services import google_maps_service

app = FastAPI(title="EventBE")

# allow your Vite dev server
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    from core.database import engine as sync_engine
    Base.metadata.create_all(bind=sync_engine)

@app.on_event("shutdown")
async def shutdown_event():
    # async disposal
    from core.async_database import async_engine
    await async_engine.dispose()

app.include_router(user.router)
app.include_router(events.router)
app.include_router(connection_request.router)
app.include_router(otp.router)
app.include_router(to_request.router)
app.include_router(client.router)
app.include_router(images.router)
app.include_router(booking.router)
app.include_router(hotel_room_router)
app.include_router(hotel_router)
app.include_router(auth_router)

# Include the users router
app.include_router(hotel_route.router)
app.include_router(itinerary.router)
app.include_router(google_maps_router)


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
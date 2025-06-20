from fastapi import HTTPException, status
from sqlalchemy.orm import session
from models.itinerary_modal import Itinerary, ItineraryDays, ItineraryItem
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select



def get_itinerary_item(itinerary_item_id, db):
        item = db.query(ItineraryItem).filter(ItineraryItem.itinerary_item_id == itinerary_item_id).first()
        return item

async def get_item(itinerary_item_id, session):
    stmt = select(ItineraryItem).where(ItineraryItem.itinerary_item_id == itinerary_item_id)
    result = await session.execute(stmt)
    item = result.scalars().first()
    return item
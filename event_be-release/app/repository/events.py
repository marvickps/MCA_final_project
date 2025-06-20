from sqlalchemy.orm import Session
from models.events import RoomBedPricing

def get_all_room_bed_pricing(db: Session):
    room_bed_pricing = db.query(RoomBedPricing).all()
    return room_bed_pricing

def get_room_bed_pricing_by_id(db: Session, room_bed_pricing_id: int):
    room_bed_pricing = db.query(RoomBedPricing).filter(RoomBedPricing.room_bed_pricing_id == room_bed_pricing_id).first()
    return room_bed_pricing

def get_room_bed_pricing_by_event_id(db: Session, event_id: int):
    room_bed_pricing = db.query(RoomBedPricing).filter(RoomBedPricing.event_id == event_id).all()
    return room_bed_pricing
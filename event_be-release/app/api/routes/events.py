from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from core.database import get_db
from repository import client as client_repo
from datetime import date
from typing import Optional

from models.events import EventInfo, EventPlan, ItineraryInfo, StopSetting, EventInCategory, RoomBedPricing, MasterEventCategory
from schemas.events import EventCreate, EventSchema, EventUpdate, CategorySchema, RoomBedPricingCreate, RoomBedPricingSchema, ItineraryInfoBase, ItineraryInfoSchema, ItineraryUpdate, EventPlanBase, EventPlanSchema, EventPlanUpdate, StopSettingBase, StopSettingSchema, StopSettingUpdate, CategoryWithEventsSchema, EventInCategorySchema, BasicEventSchema

# router = APIRouter()
router = APIRouter(prefix="/api", tags=["Events"])


@router.get("/events", response_model=List[EventSchema])
def get_all_events(db: Session = Depends(get_db), status: Optional[str]=None):
    if status:
        events = db.query(EventInfo).filter(EventInfo.status == status).all()
    else:
        events = db.query(EventInfo).all()
    enriched_events = []

    for event in events:
        # Filter event_plans for this event
        filtered_event_plans = [
            plan for plan in event.event_plans
            if not plan.booking_end_date or plan.booking_end_date >= date.today()
        ]

        # Get categories
        categories = [
            CategorySchema.from_orm(relation.category)
            for relation in event.event_categories
        ]

        # Build enriched schema
        enriched_event = EventSchema.from_orm(event)
        enriched_event.categories = categories
        enriched_event.event_plans = filtered_event_plans

        enriched_events.append(enriched_event)

    return enriched_events



@router.get("/events/basic", response_model=List[BasicEventSchema])
def get_basic_events(db: Session = Depends(get_db)):
    events = db.query(EventInfo).all()
    return [BasicEventSchema.from_orm(event) for event in events]


@router.post("/events", response_model=EventSchema)
def create_complete_event(event: EventCreate, db: Session = Depends(get_db)):
    """
    Create a new event with its itineraries, plans, and settings in a single operation.
    """
    try:
        # Extract main event data (exclude relationships)
        event_data = {k: v for k, v in event.dict().items() 
              if k not in ["itineraries", "event_plans", "stop_settings", "category_ids", "room_bed_pricing"]}
        
        # Create the main event
        db_event = EventInfo(**event_data)
        db.add(db_event)
        db.flush()  # Flush to get the ID without committing transaction
        
        # Now we have the event_id to use for relationships
        event_id = db_event.event_id
        
        # Add room bed pricing
        for pricing in event.room_bed_pricing:
            db_pricing = RoomBedPricing(event_id=event_id, **pricing.dict())
            db.add(db_pricing)

        # Add itineraries
        for itinerary_data in event.itineraries:
            db_itinerary = ItineraryInfo(
                **itinerary_data.dict(),
                event_id=event_id
            )
            db.add(db_itinerary)
        
        # Add event plans (date options)
        for plan_data in event.event_plans:
            db_plan = EventPlan(
                **plan_data.dict(),
                event_id=event_id
            )
            db.add(db_plan)
        
        # Add stop settings
        for setting_data in event.stop_settings:
            db_setting = StopSetting(
                **setting_data.dict(),
                event_id=event_id
            )
            db.add(db_setting)

        for cat_id in event.category_ids:
            event_category = EventInCategory(
                event_id=event_id,
                category_id=cat_id
            )
            db.add(event_category)
        
        # Commit all changes
        db.commit()
        db.refresh(db_event)
        return db_event
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create event: {str(e)}")

@router.get("/events/{event_id}", response_model=EventSchema)
def get_event(event_id: int, db: Session = Depends(get_db), status: Optional[str]=None):
    if status:
        event = db.query(EventInfo).filter(EventInfo.event_id == event_id, EventInfo.status == status).first()
    else:
        event = db.query(EventInfo).filter(EventInfo.event_id == event_id).first()
    client_url = client_repo.get_client_by_id(db, event.client_id).url if event else None
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    categories = [
        CategorySchema.from_orm(relation.category)
        for relation in event.event_categories
    ]

    filtered_event_plans = [
        plan for plan in event.event_plans
        if not plan.booking_end_date or plan.booking_end_date >= date.today()
    ]

    enriched_event = EventSchema.from_orm(event)
    enriched_event.categories = categories
    enriched_event.event_plans = filtered_event_plans
    enriched_event.client_url = client_url
    return enriched_event

@router.put("/events/{event_id}", response_model=EventSchema)
def update_event(event_id: int, event: EventUpdate, db: Session = Depends(get_db)):
    db_event = db.query(EventInfo).filter(EventInfo.event_id == event_id).first()
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")
    # Update fields from EventUpdate, excluding event_id
    update_data = event.dict(exclude_unset=True, exclude={"event_id"})
    for key, value in update_data.items():
        setattr(db_event, key, value)
    db.commit()
    db.refresh(db_event)
    return db_event

@router.post("/events/{event_id}/pricing", response_model=RoomBedPricingSchema)
def add_room_bed_pricing(
    event_id: int,
    pricing: RoomBedPricingCreate,
    db: Session = Depends(get_db)
):
    if event_id != pricing.event_id:
        raise HTTPException(status_code=400, detail="Mismatched event_id in URL and body")

    db_pricing = RoomBedPricing(**pricing.dict())
    db.add(db_pricing)
    db.commit()
    db.refresh(db_pricing)
    return db_pricing

@router.get("/events/{event_id}/pricing", response_model=List[RoomBedPricingSchema])
def get_room_bed_pricing(event_id: int, db: Session = Depends(get_db)):
    pricing_data = db.query(RoomBedPricing).filter(RoomBedPricing.event_id == event_id).all()
    return pricing_data

@router.put("/events/pricing", response_model=RoomBedPricingSchema)
def update_room_bed_pricing(
    pricing: RoomBedPricingSchema,
    db: Session = Depends(get_db)
):
    db_pricing = db.query(RoomBedPricing).filter_by(pricing_id=pricing.pricing_id, event_id=pricing.event_id).first()
    if not db_pricing:
        raise HTTPException(status_code=404, detail="Room bed pricing not found")
    
    for k, v in pricing.dict(exclude={"pricing_id", "event_id"}).items():
        setattr(db_pricing, k, v)
    
    db.commit()
    db.refresh(db_pricing)
    return db_pricing

# ITINERARY
@router.get("/events/{event_id}/itinerary", response_model=List[ItineraryInfoSchema])
def get_itinerary(event_id: int, db: Session = Depends(get_db)):
    itineraries = db.query(ItineraryInfo).filter(ItineraryInfo.event_id == event_id).all()
    return itineraries

@router.post("/events/{event_id}/itinerary", response_model=ItineraryInfoSchema)
def add_itinerary(event_id: int, data: ItineraryInfoBase, db: Session = Depends(get_db)):
    obj = ItineraryInfo(**data.dict(), event_id=event_id)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.put("/events/itinerary", response_model=ItineraryInfoSchema)
def update_itinerary(data: ItineraryUpdate, db: Session = Depends(get_db)):
    obj = db.query(ItineraryInfo).filter_by(itinerary_id=data.itinerary_id, event_id=data.event_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Itinerary not found")
    for k, v in data.dict(exclude={"itinerary_id", "event_id"}).items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj

@router.delete("/events/{event_id}/itinerary/{itinerary_id}")
def delete_itinerary(event_id: int, itinerary_id: int, db: Session = Depends(get_db)):
    obj = db.query(ItineraryInfo).filter_by(event_id=event_id, itinerary_id=itinerary_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Itinerary not found")
    db.delete(obj)
    db.commit()
    return {"message": "Itinerary deleted successfully"}

# EVENT PLAN
@router.get("/events/{event_id}/plan", response_model=List[EventPlanSchema])
def get_event_plans(event_id: int, db: Session = Depends(get_db)):
    plans = db.query(EventPlan).filter(EventPlan.event_id == event_id).all()
    return plans

@router.post("/events/{event_id}/plan", response_model=EventPlanSchema)
def add_event_plan(event_id: int, data: EventPlanBase, db: Session = Depends(get_db)):
    obj = EventPlan(**data.dict(), event_id=event_id)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.put("/events/{even_id}/plan", response_model=EventPlanSchema)
def update_event_plan(data: EventPlanUpdate, db: Session = Depends(get_db)):
    obj = db.query(EventPlan).filter_by(ep_id=data.ep_id, event_id=data.event_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Event plan not found")
    for k, v in data.dict(exclude={"ep_id", "event_id"}).items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj

@router.delete("/events/{event_id}/plan/{ep_id}")
def delete_event_plan(event_id: int, ep_id: int, db: Session = Depends(get_db)):
    obj = db.query(EventPlan).filter_by(event_id=event_id, ep_id=ep_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Event plan not found")
    db.delete(obj)
    db.commit()
    return {"message": "Event plan deleted successfully"}

# STOP SETTING
@router.post("/events/{event_id}/stop-setting", response_model=StopSettingSchema)
def add_stop_setting(event_id: int, data: StopSettingBase, db: Session = Depends(get_db)):
    obj = StopSetting(**data.dict(), event_id=event_id)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.put("/events/stop-setting", response_model=StopSettingSchema)
def update_stop_setting(data: StopSettingUpdate, db: Session = Depends(get_db)):
    obj = db.query(StopSetting).filter_by(stop_setting_id=data.stop_setting_id, event_id=data.event_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Stop setting not found")
    for k, v in data.dict(exclude={"stop_setting_id", "event_id"}).items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj
# GET ALL CATEGORIES
@router.get("/events/categories/all", response_model=List[CategorySchema])
def get_all_categories(db: Session = Depends(get_db)):
    categories = db.query(MasterEventCategory).all()
    return [CategorySchema.from_orm(category) for category in categories]

@router.delete("/events/{event_id}/stop-setting/{stop_setting_id}")
def delete_stop_setting(event_id: int, stop_setting_id: int, db: Session = Depends(get_db)):
    obj = db.query(StopSetting).filter_by(event_id=event_id, stop_setting_id=stop_setting_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Stop setting not found")
    db.delete(obj)
    db.commit()
    return {"message": "Stop setting deleted successfully"}

# CATEGORY (EVENT IN CATEGORY)
@router.get("/events/{event_id}/category", response_model=List[EventInCategorySchema])
def get_event_categories(event_id: int, db: Session = Depends(get_db)):
    categories = db.query(EventInCategory).filter(EventInCategory.event_id == event_id).all()
    return [EventInCategorySchema.from_orm(category) for category in categories]

@router.post("/events/{event_id}/category/{category_id}")
def add_event_category(event_id: int, category_id: int, db: Session = Depends(get_db)):
    obj = EventInCategory(event_id=event_id, category_id=category_id)
    db.add(obj)
    db.commit()
    return {"message": "Category added"}

@router.delete("/events/{event_id}/category/{category_id}")
def delete_event_category(event_id: int, category_id: int, db: Session = Depends(get_db)):
    obj = db.query(EventInCategory).filter_by(event_id=event_id, category_id=category_id).first()
    if not obj:
        raise HTTPException(status_code=404, detail="Category not found for event")
    db.delete(obj)
    db.commit()
    return {"message": "Category removed"}


# GET EVENTS BY CATEGORY
@router.get("/events/categories/categories-and-events", response_model=List[CategoryWithEventsSchema])
def get_categories_with_events(db: Session = Depends(get_db)):
    """
    Get all categories with up to 10 events per category
    """
    categories = db.query(MasterEventCategory).all()
    result = []
    
    for category in categories:
        # Get events for this category (limit to 10)
        events_query = (
            db.query(EventInfo)
            .join(EventInCategory, EventInfo.event_id == EventInCategory.event_id)
            .filter(EventInCategory.category_id == category.category_id)
            .order_by(EventInfo.created_at.desc())
            .limit(10)
            .all()
        )
        
        # Create enriched events with their categories
        enriched_events = []
        for event in events_query:
            # Get categories for this event
            event_categories = [
                CategorySchema.from_orm(relation.category)
                for relation in event.event_categories
            ]
            
            # Create enriched event
            enriched_event = EventSchema.from_orm(event)
            enriched_event.categories = event_categories
            enriched_events.append(enriched_event)
        
        # Create category with events
        category_with_events = CategoryWithEventsSchema(
            category_id=category.category_id,
            name=category.name,
            description=category.description,
            events=enriched_events
        )
        
        result.append(category_with_events)
    
    return result

@router.get("/events/categories/{category_id}", response_model=CategoryWithEventsSchema)
def get_category_events(category_id: int, db: Session = Depends(get_db)):
    """
    Get all events for a specific category
    """
    # Check if category exists
    category = db.query(MasterEventCategory).filter(MasterEventCategory.category_id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail=f"Category with ID {category_id} not found")
    
    # Get all events for this category
    events_query = (
        db.query(EventInfo)
        .join(EventInCategory, EventInfo.event_id == EventInCategory.event_id)
        .filter(EventInCategory.category_id == category_id)
        .order_by(EventInfo.created_at.desc())
        .all()
    )
    
    # Create enriched events with their categories
    enriched_events = []
    for event in events_query:
        # Get categories for this event
        event_categories = [
            CategorySchema.from_orm(relation.category)
            for relation in event.event_categories
        ]
        
        # Create enriched event
        enriched_event = EventSchema.from_orm(event)
        enriched_event.categories = event_categories
        enriched_events.append(enriched_event)
    
    # Create category with events
    category_with_events = CategoryWithEventsSchema(
        category_id=category.category_id,
        name=category.name,
        description=category.description,
        events=enriched_events
    )
    
    return category_with_events

@router.get("/events/client/{client_id}", response_model=List[EventSchema])
def get_events_by_client(client_id: int, db: Session = Depends(get_db)):
    events = db.query(EventInfo).filter(EventInfo.client_id == client_id).all()
    enriched_events = []
    for event in events:
        filtered_event_plans = [
            plan for plan in event.event_plans
            if not plan.booking_end_date or plan.booking_end_date >= date.today()
        ]

        categories = [
            CategorySchema.from_orm(relation.category)
            for relation in event.event_categories
        ]
        enriched_event = EventSchema.from_orm(event)
        enriched_event.categories = categories
        enriched_event.event_plans = filtered_event_plans
        enriched_events.append(enriched_event)
    return enriched_events

@router.get("/events/client/{client_id}/categories", response_model=List[CategoryWithEventsSchema])
def get_client_categories_with_events(client_id: int, db: Session = Depends(get_db)):
    """
    Get all categories with up to 10 events per category for a specific client
    """
    categories = db.query(MasterEventCategory).all()
    result = []
    
    for category in categories:
        # Get events for this category (limit to 10)
        events_query = (
            db.query(EventInfo)
            .join(EventInCategory, EventInfo.event_id == EventInCategory.event_id)
            .filter(EventInCategory.category_id == category.category_id, EventInfo.client_id == client_id)
            .order_by(EventInfo.created_at.desc())
            .limit(10)
            .all()
        )
        
        # Create enriched events with their categories
        enriched_events = []
        for event in events_query:
            # Get categories for this event
            event_categories = [
                CategorySchema.from_orm(relation.category)
                for relation in event.event_categories
            ]
            
            # Create enriched event
            enriched_event = EventSchema.from_orm(event)
            enriched_event.categories = event_categories
            enriched_events.append(enriched_event)
        
        # Create category with events
        category_with_events = CategoryWithEventsSchema(
            category_id=category.category_id,
            name=category.name,
            description=category.description,
            events=enriched_events
        )
        
        result.append(category_with_events)
    
    return result

@router.get("/events/clientURL/{client_url}", response_model=List[EventSchema])
def get_client_events(client_url: str, db: Session = Depends(get_db)):
    client = client_repo.get_client_by_url(db, client_url)
    events = db.query(EventInfo).filter(EventInfo.client_id == client.client_id).all()
    enriched_events = []
    for event in events:
        filtered_event_plans = [
            plan for plan in event.event_plans
            if not plan.booking_end_date or plan.booking_end_date >= date.today()
        ]

        categories = [
            CategorySchema.from_orm(relation.category)
            for relation in event.event_categories
        ]
        enriched_event = EventSchema.from_orm(event)
        enriched_event.categories = categories
        enriched_event.event_plans = filtered_event_plans
        enriched_events.append(enriched_event)
    return enriched_events

@router.get("/events/clientURL/{client_url}/categories", response_model=List[CategoryWithEventsSchema])
def get_client_events_by_category(client_url: str, db: Session = Depends(get_db)):
    """
    Get all categories with up to 10 events per category for a specific client
    """
    client = client_repo.get_client_by_url(db, client_url)
    categories = db.query(MasterEventCategory).all()
    result = []
    
    for category in categories:
        # Get events for this category (limit to 10)
        events_query = (
            db.query(EventInfo)
            .join(EventInCategory, EventInfo.event_id == EventInCategory.event_id)
            .filter(EventInCategory.category_id == category.category_id, EventInfo.client_id == client.client_id)
            .order_by(EventInfo.created_at.desc())
            .limit(10)
            .all()
        )
        
        # Create enriched events with their categories
        enriched_events = []
        for event in events_query:
            # Get categories for this event
            event_categories = [
                CategorySchema.from_orm(relation.category)
                for relation in event.event_categories
            ]
            filtered_event_plans = [
            plan for plan in event.event_plans
            if not plan.booking_end_date or plan.booking_end_date >= date.today()
            ]
            
            # Create enriched event
            enriched_event = EventSchema.from_orm(event)
            enriched_event.categories = event_categories
            enriched_event.event_plans = filtered_event_plans
            enriched_events.append(enriched_event)
        
        # Create category with events
        category_with_events = CategoryWithEventsSchema(
            category_id=category.category_id,
            name=category.name,
            description=category.description,
            events=enriched_events
        )
        
        result.append(category_with_events)
    
    return result

@router.get("/events/clientURL/{client_url}/basics", response_model=List[BasicEventSchema])
def get_client_events_basics(client_url: str, db: Session = Depends(get_db)):
    client = client_repo.get_client_by_url(db, client_url)
    events = db.query(EventInfo).filter(EventInfo.client_id == client.client_id).all()
    return [BasicEventSchema.from_orm(event) for event in events]

@router.put("/events/sequence/update", response_model=EventSchema)
def update_event_sequence(event_id: int, sequence: float, db: Session = Depends(get_db)):
    event = db.query(EventInfo).filter(EventInfo.event_id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    event.display_sequence = sequence
    db.commit()
    db.refresh(event)
    return event
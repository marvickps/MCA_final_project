from fastapi import APIRouter, Depends, HTTPException, status, Response, Query,Path
from sqlalchemy.ext.asyncio import AsyncSession

from models.itinerary_modal import ItineraryShareCode
from models.user import User
from schemas.itinerary import CreatePackage, ItineraryItemResponse, PackageCostDetailsResponse, PackageData, GetPackageDetail, GetPackageList, ItineraryInput, AddItineraryItem, ItineraryItemStopUpdate, UpdateItemCost, UpdateItemDescription, UpdateItemDuration
from services.itinerary_service import add_itinerary_item, create_initial_itinerary, create_share_code, day_cost_breakup, delete_item, get_all_itinerary, get_day_summary, get_itinerary_menu_details, get_local_resource, get_route, get_share_code, get_shared_itinerary, get_timeline, itinerary_cost_breakup,reorder_itinerary_items, update_item_cost, update_item_description, update_item_duration

from typing import Any, Dict, List, Optional, Union
from sqlalchemy.orm import Session
from core.database import get_db
from core.dependencies import get_current_client, get_current_user, get_session
# from logger import logger
from datetime import time

router = APIRouter(
    prefix='/api/itinerary',
    tags=['itinerary']
)

@router.post('/')
async def create_initial_itinerary_api(
    request:ItineraryInput,
    session: AsyncSession = Depends(get_session),
    current_user=Depends(get_current_user),
    client_id=Depends(get_current_client)):
    try:
        itinerary = await create_initial_itinerary(
            user_id=current_user.user_id,
            client_id=client_id,
            itineraryName=request.itineraryName,
            itineraryPlaceID=request.itineraryPlaceID,
            accommodation=request.accommodation,
            startingPoint=request.startingPoint,
            startDate=request.startDate,
            endDate=request.endDate,
            session=session
        )
        return itinerary.itinerary_id
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error creating itinerary: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create itinerary: {str(e)}")

@router.get('/menu_details/{id}')
def get_itinerary_menu_details_api(id: int, db: Session = Depends(get_db)) -> Dict[str, Any]:
    try:
        with db.begin():
            return get_itinerary_menu_details(id, db)
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error fetching itinerary menu details: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch itinerary details.error: {e}")


@router.get('/timeline/{id}')
def get_timeline_api(id: int, db: Session = Depends(get_db)):
    try:
        with db.begin():
            return get_timeline(id, db)
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error fetching itinerary timeline for id {id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch itinerary timeline")

@router.get('/get_route/{id}') #id = itinerary id
def get_route_api(id:int=Path(...), day: Union[int,str] = Query(...), db:Session = Depends(get_db)):
    try:
        with db.begin():
            return get_route(id, day, db)
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error fetching route for itinerary {id}, day: {day} - {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch route")

@router.get('/get_day_details/{id}') #id = itinerary day id
def get_day_details_api(id:int=Path(...), db:Session = Depends(get_db)):
    try:
        with db.begin():
            return get_day_summary(id, db)
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error fetching day details for id {id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch day details: {str(e)}")
    
@router.post('/add_itinerary_item',  response_model=ItineraryItemResponse)
async def add_itinerary_item_api(
    request: AddItineraryItem, 
    session: AsyncSession = Depends(get_session),
    current_user=Depends(get_current_user),
    client_id=Depends(get_current_client)
): 
    try:
        result = await add_itinerary_item(request, session, client_id=client_id, user_id=current_user.user_id)
        return result
    except Exception as e:
        #logger.error(f"Error adding itinerary item: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to add itinerary item: {str(e)}")
    

@router.put('/reorder_itinerary_items')
async def reorder_itinerary_items_api(request:ItineraryItemStopUpdate, session: AsyncSession = Depends(get_session)):
    try:
        return await reorder_itinerary_items(request, session)
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error adding itinerary item: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to add itinerary item: {str(e)}")
    
@router.get('/get_all_itinerary/{id}') #id = user id
def get_all_itinerary_api(id: int, db: Session = Depends(get_db)):
    try:
        with db.begin():
            return get_all_itinerary(id, db)
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error fetching day details for id {id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch day details: {str(e)}")


@router.put('/update_item_cost')
async def update_item_cost_api(payload:UpdateItemCost, db:Session = Depends(get_db)):
    try:
        with db.begin():
            return update_item_cost(payload, db)
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error fetching day details for id {id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch day details: {str(e)}")
    
@router.put('/update_item_description')
async def update_item_description_api(payload:UpdateItemDescription, db:Session = Depends(get_db)):
    try:
        with db.begin():
            return update_item_description(payload, db)
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error fetching day details for id {id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch day details: {str(e)}")
    
@router.put('/update_item_duration')
async def update_item_duration_api(payload:UpdateItemDuration, session: AsyncSession = Depends(get_session)):
    try:
        return await update_item_duration(payload, session)
    except HTTPException as e:
        raise e
    except Exception as e:
        #logger.error(f"Error fetching day details for id {id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch day details: {str(e)}")
    
@router.delete('/delete_item/{id}') # id = itinerary item id
async def delete_item_api(id:int, session: AsyncSession = Depends(get_session)):
    try:
        return await delete_item(id, session)
    except Exception as e:
        #logger.error(f"Error fetching day details for id {id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch day details: {str(e)}")

@router.get('/day_cost_breakup/{day_id}',status_code=status.HTTP_200_OK)
def day_cost_breakup_api(day_id:int, db:Session = Depends(get_db)):
    try:
        return day_cost_breakup(day_id, db)

    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch day cost breakup details: {str(e)}")
    
@router.get('/itinerary_cost_breakup/{itinerary_id}', status_code=status.HTTP_200_OK) 
def itinerary_cost_breakup_api(itinerary_id:int, db:Session = Depends(get_db)):
    try:
        return itinerary_cost_breakup(itinerary_id, db)

    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch day cost breakup details: {str(e)}")
    

  
@router.get('/get_local_resource/{user_id}/{resource_type}',status_code=status.HTTP_200_OK)
def get_local_resource_api(user_id:int,resource_type:str,db: Session = Depends(get_db)):
    try:
        return get_local_resource(user_id,resource_type,db)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update default values, {e}")
    


@router.post('/create_share_code/{itinerary_id}',status_code=status.HTTP_200_OK)
async def create_share_code_api(itinerary_id:int, session: AsyncSession = Depends(get_session),):
    return await create_share_code(itinerary_id, session)
    
@router.get("/shared_itinerary_id/{share_code}")
def get_shared_itinerary_api(share_code: str, db: Session = Depends(get_db)):
    return get_shared_itinerary(share_code, db)
    

@router.get("/get_share_code/{itinerary_id}")
def get_share_code_api(itinerary_id: int, db: Session = Depends(get_db)):
    return get_share_code(itinerary_id, db)






#api for future use

@router.post('/create_package')
async def create_package(payload: CreatePackage,  db:Session = Depends(get_db)):
    package = {
        "package_id": 1
    }
    return {"package_id": package["package_id"]}

@router.get('/get_package_detail/{id}') # id = package id
async def get_package_detail_api(id:int,  db:Session = Depends(get_db) ):
    return GetPackageDetail

@router.get('/get_all_package/{id}') # id = user id
async def get_package_detail_api(id:int,  db:Session = Depends(get_db) ):
    return GetPackageList

@router.put('/edit_package')
async def edit_package_api(payload: PackageData,db: Session = Depends(get_db)):
    return "package updated successfully"


@router.delete('/delete_package/{id}') # id = package id
async def delete_package(id:int, db:Session = Depends(get_db)):
    return "package deleted successfully"


@router.get('/package_cost_details/{id}', response_model=PackageCostDetailsResponse)  # id = package id
async def package_cost_details_api(
    id: int,
    day_id: Optional[int] = Query(None),
    db: Session = Depends(get_db)
):
    if day_id:
        return PackageCostDetailsResponse(
            trip_label="Trip to Shillong",
            day_label="Day 1",
            cost_items=[
                {
                    "title": "STAY",
                    "unit_price": "₹1500",
                    "quantity": 1,
                    "total_price": 1500
                },
                {
                    "title": "CAB",
                    "unit_price": "₹1000 /D (300km)",
                    "quantity": 1,
                    "total_price": 1000
                },
                {
                    "title": "DRIVER - Night Stay",
                    "unit_price": "₹500 /N",
                    "quantity": 1,
                    "total_price": 500
                }
            ],
            cost_summary={
                "sub_total": 3000,
                "discount_percentage": 0,
                "discount_amount": 0,
                "gst_percentage": 18,
                "gst_amount": 540,
                "final_amount": 3540
            }
        )
    else:
        return PackageCostDetailsResponse(
            trip_label="Trip to Shillong",
            cost_items=[
                {
                    "title": "STAY",
                    "unit_price": "₹1500",
                    "quantity": 1,
                    "total_price": 1500
                },
                {
                    "title": "STAY",
                    "unit_price": "₹2000",
                    "quantity": 1,
                    "total_price": 2000
                },
                {
                    "title": "STAY",
                    "unit_price": "₹1800",
                    "quantity": 1,
                    "total_price": 1800
                },
                {
                    "title": "CAB",
                    "unit_price": "₹1000 /D (300km)",
                    "quantity": 4,
                    "total_price": 4000
                },
                {
                    "title": "DRIVER - Night Stay",
                    "unit_price": "₹500 /N",
                    "quantity": 3,
                    "total_price": 1500
                }
            ],
            cost_summary={
                "sub_total": 10800,
                "discount_percentage": 0,
                "discount_amount": 0,
                "gst_percentage": 18,
                "gst_amount": 1940,
                "final_amount": 12740
            }
        )


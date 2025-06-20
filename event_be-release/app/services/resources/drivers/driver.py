from sqlalchemy.ext.asyncio import AsyncSession

from fastapi import HTTPException, status
from models.drivers.driver import Driver
from repository.resources.drivers.driver import DriverRepository
from schemas.resources.drivers.driver import DriverCreate, DriverUpdate, DriverResponse
from schemas.paginate import PaginatedDriverResponse, PaginationParams

class DriverService:
    @staticmethod
    async def create_driver(session: AsyncSession, data: DriverCreate, client_id: int, user_id: int) -> DriverResponse:
        driver = Driver(
            client_id=client_id,
            user_id=user_id,
            name=data.name,
            dl_number=data.dl_number,
            dl_valid_until=data.dl_valid_until,
            working_hours=data.working_hours,
            description=data.description
        )
        created_driver = await DriverRepository.create(session, driver)
        return DriverResponse.model_validate(created_driver)

    @staticmethod
    async def get_driver_by_id(session: AsyncSession, driver_id: int, client_id: int) -> DriverResponse:
        driver = await DriverRepository.get_by_id(session, driver_id)
        if not driver or driver.client_id != client_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Driver not found")
        return DriverResponse.model_validate(driver)

    @staticmethod
    async def list_drivers(session: AsyncSession, client_id: int, pagination: PaginationParams) -> PaginatedDriverResponse:
        drivers, total = await DriverRepository.list_by_client(session, client_id, pagination.offset, pagination.size)
        driver_responses = [DriverResponse.model_validate(driver) for driver in drivers]
        return PaginatedDriverResponse.create(items=driver_responses, total=total, page=pagination.page, size=pagination.size)

    @staticmethod
    async def update_driver(session: AsyncSession, driver_id: int, data: DriverUpdate, client_id: int) -> DriverResponse:
        driver = await DriverRepository.get_by_id(session, driver_id)
        if not driver or driver.client_id != client_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Driver not found")
        update_data = data.model_dump(exclude_unset=True)
        updated_driver = await DriverRepository.update(session, driver_id, update_data)
        return DriverResponse.model_validate(updated_driver)

    @staticmethod
    async def delete_driver(session: AsyncSession, driver_id: int, client_id: int) -> None:
        driver = await DriverRepository.get_by_id(session, driver_id)
        if not driver or driver.client_id != client_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Driver not found")
        await DriverRepository.hard_delete(session, driver_id)

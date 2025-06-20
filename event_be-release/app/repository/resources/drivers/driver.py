from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update, delete, func
from sqlalchemy.orm import selectinload
from typing import Optional, List, Tuple
from models.drivers.driver import Driver

class DriverRepository:
    @staticmethod
    async def get_by_id(session: AsyncSession, driver_id: int, include_vehicles: bool = False) -> Optional[Driver]:
        query = select(Driver).where(Driver.driver_id == driver_id)
        if include_vehicles:
            query = query.options(selectinload(Driver.vehicles))
        result = await session.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def create(session: AsyncSession, driver: Driver) -> Driver:
        session.add(driver)
        await session.commit()
        await session.refresh(driver)
        return driver

    @staticmethod
    async def list_by_client(session: AsyncSession, client_id: int, skip: int = 0, limit: int = 10) -> Tuple[List[Driver], int]:
        count_query = select(func.count()).select_from(Driver).where(
            Driver.client_id == client_id,
            Driver.is_active == True
        )
        total_result = await session.execute(count_query)
        total = total_result.scalar_one()

        query = select(Driver).where(
            Driver.client_id == client_id,
            Driver.is_active == True
        ).offset(skip).limit(limit)
        result = await session.execute(query)
        drivers = result.scalars().all()

        return list(drivers), total

    @staticmethod
    async def update(session: AsyncSession, driver_id: int, data: dict) -> Optional[Driver]:
        await session.execute(
            update(Driver)
            .where(Driver.driver_id == driver_id)
            .values(**data)
        )
        await session.commit()
        return await DriverRepository.get_by_id(session, driver_id)

    @staticmethod
    async def hard_delete(session: AsyncSession, driver_id: int) -> None:
        await session.execute(delete(Driver).where(Driver.driver_id == driver_id))
        await session.commit()

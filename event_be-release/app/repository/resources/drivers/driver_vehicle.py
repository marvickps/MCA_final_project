from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import delete, func, update
from fastapi import HTTPException, status
from typing import Optional, List, Tuple

from models.drivers.driver import DriverVehicle

class DriverVehicleRepository:
    @staticmethod
    async def get_by_id(session: AsyncSession, vehicle_id: int) -> Optional[DriverVehicle]:
        result = await session.execute(
            select(DriverVehicle).where(DriverVehicle.id == vehicle_id)
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def create(session: AsyncSession, vehicle: DriverVehicle) -> DriverVehicle:
        session.add(vehicle)
        await session.commit()
        await session.refresh(vehicle)
        return vehicle

    @staticmethod
    async def list_by_driver(session: AsyncSession, driver_id: int) -> List[DriverVehicle]:
        result = await session.execute(
            select(DriverVehicle).where(DriverVehicle.driver_id == driver_id)
        )
        return result.scalars().all()

    @staticmethod
    async def update(session: AsyncSession, vehicle_id: int, data: dict) -> Optional[DriverVehicle]:
        await session.execute(
            update(DriverVehicle)
            .where(DriverVehicle.id == vehicle_id)
            .values(**data)
        )
        await session.commit()
        return await DriverVehicleRepository.get_by_id(session, vehicle_id)

    @staticmethod
    async def hard_delete(session: AsyncSession, vehicle_id: int) -> None:
        await session.execute(delete(DriverVehicle).where(DriverVehicle.id == vehicle_id))
        await session.commit()

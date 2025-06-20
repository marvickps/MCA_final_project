from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.pool import NullPool
from core.config import settings

# Create async engine with pooling disabled
async_engine = create_async_engine(
    settings.ASYNC_DATABASE_URL,
    poolclass=NullPool,  # Disable connection pooling
    echo=False,
    pool_pre_ping=True,
)

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)



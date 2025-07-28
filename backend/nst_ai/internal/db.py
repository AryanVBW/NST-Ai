import json
import logging
from contextlib import contextmanager
from typing import Any, Optional

from nst_ai.internal.wrappers import register_connection
from nst_ai.env import (
    nst_ai_DIR,
    DATABASE_URL,
    DATABASE_SCHEMA,
    SRC_LOG_LEVELS,
    DATABASE_POOL_MAX_OVERFLOW,
    DATABASE_POOL_RECYCLE,
    DATABASE_POOL_SIZE,
    DATABASE_POOL_TIMEOUT,
)
from peewee_migrate import Router
from sqlalchemy import Dialect, create_engine, MetaData, types
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker
from sqlalchemy.pool import QueuePool, NullPool
from sqlalchemy.sql.type_api import _T
from typing_extensions import Self

log = logging.getLogger(__name__)
log.setLevel(SRC_LOG_LEVELS["DB"])


class JSONField(types.TypeDecorator):
    impl = types.Text
    cache_ok = True

    def process_bind_param(self, value: Optional[_T], dialect: Dialect) -> Any:
        return json.dumps(value)

    def process_result_value(self, value: Optional[_T], dialect: Dialect) -> Any:
        if value is not None:
            return json.loads(value)

    def copy(self, **kw: Any) -> Self:
        return JSONField(self.impl.length)

    def db_value(self, value):
        return json.dumps(value)

    def python_value(self, value):
        if value is not None:
            return json.loads(value)


# Workaround to handle the peewee migration
# This is required to ensure the peewee migration is handled before the alembic migration
def handle_peewee_migration(DATABASE_URL):
    db = None
    try:
        # Replace the postgresql:// with postgres:// to handle the peewee migration
        db = register_connection(DATABASE_URL.replace("postgresql://", "postgres://"))
        migrate_dir = nst_ai_DIR / "internal" / "migrations"
        
        # Validate migration directory exists
        if not migrate_dir.exists():
            log.error(f"Migration directory does not exist: {migrate_dir}")
            raise FileNotFoundError(f"Migration directory not found: {migrate_dir}")
        
        router = Router(db, logger=log, migrate_dir=migrate_dir)
        router.run()
        
        # Explicitly close the connection after successful migration
        if db and not db.is_closed():
            db.close()

    except FileNotFoundError as e:
        log.error(f"Migration setup error: {e}")
        raise
    except Exception as e:
        log.error(f"Failed to initialize the database connection: {e}")
        log.warning(
            "Hint: If your database password contains special characters, you may need to URL-encode it."
        )
        # Try to provide more specific error information
        if "authentication failed" in str(e).lower():
            log.error("Database authentication failed. Please check your credentials.")
        elif "connection refused" in str(e).lower():
            log.error("Database connection refused. Please check if the database server is running.")
        elif "does not exist" in str(e).lower():
            log.error("Database does not exist. Please create the database first.")
        raise
    finally:
        # Properly closing the database connection
        if db and not db.is_closed():
            try:
                db.close()
            except Exception as close_error:
                log.warning(f"Error closing database connection: {close_error}")

        # Verify connection is closed
        if db and not db.is_closed():
            log.warning("Database connection is still open after cleanup attempt")


handle_peewee_migration(DATABASE_URL)


SQLALCHEMY_DATABASE_URL = DATABASE_URL
if "sqlite" in SQLALCHEMY_DATABASE_URL:
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )
else:
    if isinstance(DATABASE_POOL_SIZE, int):
        if DATABASE_POOL_SIZE > 0:
            engine = create_engine(
                SQLALCHEMY_DATABASE_URL,
                pool_size=DATABASE_POOL_SIZE,
                max_overflow=DATABASE_POOL_MAX_OVERFLOW,
                pool_timeout=DATABASE_POOL_TIMEOUT,
                pool_recycle=DATABASE_POOL_RECYCLE,
                pool_pre_ping=True,
                poolclass=QueuePool,
            )
        else:
            engine = create_engine(
                SQLALCHEMY_DATABASE_URL, pool_pre_ping=True, poolclass=NullPool
            )
    else:
        engine = create_engine(SQLALCHEMY_DATABASE_URL, pool_pre_ping=True)


SessionLocal = sessionmaker(
    autocommit=False, autoflush=False, bind=engine, expire_on_commit=False
)
metadata_obj = MetaData(schema=DATABASE_SCHEMA)
Base = declarative_base(metadata=metadata_obj)
Session = scoped_session(SessionLocal)


def get_session():
    db = None
    try:
        db = SessionLocal()
        yield db
    except Exception as e:
        log.error(f"Database session error: {e}")
        if db:
            try:
                db.rollback()
            except Exception as rollback_error:
                log.error(f"Failed to rollback transaction: {rollback_error}")
        raise
    finally:
        if db:
            try:
                db.close()
            except Exception as close_error:
                log.warning(f"Error closing database session: {close_error}")


get_db = contextmanager(get_session)
